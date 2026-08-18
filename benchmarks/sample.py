#!/usr/bin/env python3
"""Fetch a deterministic, 20-clip-per-category ASR smoke benchmark.

The rows API returns metadata without downloading a split.  Audio is fetched
only for the selected rows and is copied byte-for-byte into benchmarks/data/.
"""

from __future__ import annotations

import argparse
import json
import random
import re
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


SEED = 20260818
ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"

DATASETS = {
    "chinese": {
        "dataset": "adi-gov-tw/Taiwan-Tongues-ASR-CE-dataset-zhtw",
        "config": "default",
        "split": "test",
        "count": 20,
        "license": "TRAIL-D 0.1",
        "license_url": "https://huggingface.co/datasets/adi-gov-tw/Taiwan-Tongues-ASR-CE-dataset-zhtw/blob/main/LICENSE",
        "source_url": "https://huggingface.co/datasets/adi-gov-tw/Taiwan-Tongues-ASR-CE-dataset-zhtw",
        "audio_field": "mp3",
        "text_field": "txt",
    },
    "english_clean": {
        "dataset": "openslr/librispeech_asr",
        "config": "all",
        "split": "test.clean",
        "count": 10,
        "license": "CC-BY-4.0",
        "license_url": "https://creativecommons.org/licenses/by/4.0/",
        "source_url": "https://huggingface.co/datasets/openslr/librispeech_asr",
        "audio_field": "audio",
        "text_field": "text",
    },
    "english_other": {
        "dataset": "openslr/librispeech_asr",
        "config": "all",
        "split": "test.other",
        "count": 10,
        "license": "CC-BY-4.0",
        "license_url": "https://creativecommons.org/licenses/by/4.0/",
        "source_url": "https://huggingface.co/datasets/openslr/librispeech_asr",
        "audio_field": "audio",
        "text_field": "text",
    },
    "mixed": {
        "dataset": "CAiRE/ASCEND",
        "config": "main",
        "split": "test",
        "count": 20,
        "license": "CC-BY-SA-4.0",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/",
        "source_url": "https://huggingface.co/datasets/CAiRE/ASCEND",
        "audio_field": "audio",
        "text_field": "transcription",
        "audio_filter": lambda row: row.get("language") == "mixed",
    },
}

ROWS_API = "https://datasets-server.huggingface.co/rows"
URL_OPENER = urllib.request.build_opener()
URL_OPENER.addheaders = [("User-Agent", "LaSay benchmark sampler/1.0")]


def get_json(url: str) -> dict:
    last_error = None
    for attempt in range(5):
        try:
            with URL_OPENER.open(url, timeout=90) as response:
                return json.load(response)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            last_error = error
            if attempt < 4:
                if isinstance(error, urllib.error.HTTPError) and error.code == 429:
                    time.sleep(65)
                else:
                    time.sleep(min(30, 2**attempt))
                continue
    raise RuntimeError(f"request failed: {url}: {last_error}")


def selected_rows(name: str, spec: dict) -> list[dict]:
    size = get_json(f"https://datasets-server.huggingface.co/size?{urllib.parse.urlencode({'dataset': spec['dataset'], 'config': spec['config']})}")
    splits = size.get("size", {}).get("splits", [])
    total = next((item["num_rows"] for item in splits if item.get("split") == spec["split"]), 0)
    if not total:
        raise RuntimeError(f"could not read size for {spec['dataset']} {spec['split']}")

    rng = random.Random(f"{SEED}:rows:{name}")
    predicate = spec.get("audio_filter")
    selected_indices = None if predicate else rng.sample(range(total), spec["count"])
    page_offsets = range(0, total, 100) if predicate else sorted({index // 100 * 100 for index in selected_indices})
    rows = []
    for offset in page_offsets:
        query = urllib.parse.urlencode(
            {
                "dataset": spec["dataset"],
                "config": spec["config"],
                "split": spec["split"],
                "offset": offset,
                "length": min(100, total - offset),
            }
        )
        page = get_json(f"{ROWS_API}?{query}")
        for item in page.get("rows", []):
            row = {**item["row"], "_row_idx": item.get("row_idx")}
            if (predicate and predicate(row)) or (selected_indices and row["_row_idx"] in selected_indices):
                rows.append(row)

    if len(rows) < spec["count"]:
        raise RuntimeError(f"{name}: only {len(rows)} eligible rows")
    if predicate:
        rows = rng.sample(rows, spec["count"])
    else:
        order = {row_index: index for index, row_index in enumerate(selected_indices)}
        rows.sort(key=lambda row: order[row["_row_idx"]])
    return rows


def row_id(spec: dict, row: dict) -> str:
    if spec["dataset"].startswith("adi-gov-tw/"):
        return row.get("json", {}).get("sentence_id") or row["__key__"]
    return row.get("id") or row["__key__"]


def text_for(spec: dict, row: dict) -> str:
    value = row.get(spec["text_field"])
    if value is None and spec["dataset"].startswith("adi-gov-tw/"):
        value = row.get("json", {}).get("sentence")
    if not isinstance(value, str) or not value.strip():
        raise RuntimeError(f"missing transcript for {row_id(spec, row)}")
    return value


def audio_url(spec: dict, row: dict) -> str:
    values = row.get(spec["audio_field"])
    if not isinstance(values, list) or not values or "src" not in values[0]:
        raise RuntimeError(f"missing audio URL for {row_id(spec, row)}")
    return values[0]["src"]


def safe_name(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_.-]+", "_", value)
    return value[:96] or "clip"


def extension(url: str) -> str:
    suffix = Path(urllib.parse.urlparse(url).path).suffix.lower()
    return suffix if suffix in {".mp3", ".flac", ".wav", ".ogg", ".m4a"} else ".audio"


def download(url: str, destination: Path) -> int:
    if destination.exists() and destination.stat().st_size:
        return 0
    destination.parent.mkdir(parents=True, exist_ok=True)
    with URL_OPENER.open(url, timeout=120) as response:
        with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as temporary:
            temporary_path = Path(temporary.name)
            total = 0
            while chunk := response.read(1024 * 1024):
                temporary.write(chunk)
                total += len(chunk)
    temporary_path.replace(destination)
    return total


def duration(path: Path) -> float:
    result = subprocess.run(
        ["afinfo", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    match = re.search(r"estimated duration:\s+([0-9.]+) sec", result.stdout)
    if not match:
        raise RuntimeError(f"could not read duration: {path}")
    return float(match.group(1))


def fetch() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    bytes_downloaded = 0
    manifests = {}
    for name, spec in DATASETS.items():
        output = DATA / name
        output.mkdir(parents=True, exist_ok=True)
        manifest = []
        for index, row in enumerate(selected_rows(name, spec)):
            source_id = row_id(spec, row)
            url = audio_url(spec, row)
            path = output / f"{index:02d}-{safe_name(source_id)}{extension(url)}"
            bytes_downloaded += download(url, path)
            record = {
                "sample_id": f"{name}-{index:02d}",
                "audio": str(path.relative_to(ROOT)),
                "dataset": spec["dataset"],
                "config": spec["config"],
                "split": spec["split"],
                "source_url": spec["source_url"],
                "source_audio_url": url,
                "license": spec["license"],
                "license_url": spec["license_url"],
                "original_id": source_id,
                "source_row_index": row.get("_row_idx"),
                "transcript": text_for(spec, row),
                "duration_seconds": duration(path),
            }
            manifest.append(record)
        manifest_path = DATA / f"{name}.jsonl"
        manifest_path.write_text("".join(json.dumps(item, ensure_ascii=False) + "\n" for item in manifest))
        expected = {Path(item["audio"]).name for item in manifest}
        for stale in output.iterdir():
            if stale.is_file() and stale.suffix in {".mp3", ".flac", ".wav", ".ogg", ".m4a", ".audio"} and stale.name not in expected:
                stale.unlink()
        manifests[name] = manifest_path
        print(f"{name}: {len(manifest)} clips, {sum(item['duration_seconds'] for item in manifest):.3f}s")
    report = {"seed": SEED, "bytes_downloaded_this_run": bytes_downloaded, "manifests": [str(path.relative_to(ROOT)) for path in manifests.values()]}
    (DATA / "download-report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"bytes downloaded this run: {bytes_downloaded}")


def verify() -> None:
    total_files = 0
    english_files = 0
    with tempfile.TemporaryDirectory() as temporary_directory:
        decoded = Path(temporary_directory) / "decoded.wav"
        for name in DATASETS:
            manifest_path = DATA / f"{name}.jsonl"
            assert manifest_path.exists(), f"missing {manifest_path}; run fetch"
            records = [json.loads(line) for line in manifest_path.read_text().splitlines() if line]
            assert len(records) == DATASETS[name]["count"], f"{name}: wrong count"
            assert len({record["original_id"] for record in records}) == len(records), f"{name}: duplicate IDs"
            for record in records:
                path = ROOT / record["audio"]
                assert path.exists() and path.stat().st_size, f"missing audio: {path}"
                actual = duration(path)
                assert actual > 0, f"zero duration: {path}"
                assert abs(actual - record["duration_seconds"]) < 0.05, f"duration mismatch: {path}"
                decoded.unlink(missing_ok=True)
                subprocess.run(
                    ["afconvert", str(path), str(decoded), "-f", "WAVE", "-d", "LEI16@16000", "-c", "1"],
                    check=True,
                    capture_output=True,
                )
                total_files += 1
                if name.startswith("english_"):
                    english_files += 1
            seconds = sum(record["duration_seconds"] for record in records)
            print(f"{name}: {len(records)} decodable clips, {seconds:.3f}s")
    assert english_files == 20
    assert total_files == 60
    print("verified 60 decodable source clips")


parser = argparse.ArgumentParser()
parser.add_argument("command", choices=("fetch", "verify"))
args = parser.parse_args()
if args.command == "fetch":
    fetch()
else:
    verify()
