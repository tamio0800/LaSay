#!/usr/bin/env python3
"""Score a local LaSay benchmark JSONL result without third-party packages."""

from __future__ import annotations

import argparse
import json
import re
import statistics
import unicodedata
from collections import defaultdict
from pathlib import Path


def tokens(text: str) -> list[str]:
    text = re.sub(r"\[UNK\]", " ", text, flags=re.IGNORECASE)
    output, word = [], []
    for character in unicodedata.normalize("NFKC", text):
        codepoint = ord(character)
        is_cjk = 0x3400 <= codepoint <= 0x9FFF or 0xF900 <= codepoint <= 0xFAFF
        if is_cjk:
            if word:
                output.append("".join(word).lower())
                word = []
            output.append(character)
        elif character.isalnum():
            word.append(character)
        elif word:
            output.append("".join(word).lower())
            word = []
    if word:
        output.append("".join(word).lower())
    return output


def edits(reference: list[str], hypothesis: list[str]) -> tuple[int, int, int]:
    previous = [(index, index, 0, 0) for index in range(len(hypothesis) + 1)]
    for ref_index, ref_token in enumerate(reference, 1):
        current = [(ref_index, 0, ref_index, 0)]
        for hyp_index, hyp_token in enumerate(hypothesis, 1):
            if ref_token == hyp_token:
                current.append(previous[hyp_index - 1])
                continue
            substitution = previous[hyp_index - 1]
            deletion = previous[hyp_index]
            insertion = current[hyp_index - 1]
            candidates = [
                (substitution[0] + 1, substitution[1] + 1, substitution[2], substitution[3]),
                (deletion[0] + 1, deletion[1], deletion[2] + 1, deletion[3]),
                (insertion[0] + 1, insertion[1], insertion[2], insertion[3] + 1),
            ]
            current.append(min(candidates, key=lambda item: item[0]))
        previous = current
    _, substitutions, deletions, insertions = previous[-1]
    return substitutions, deletions, insertions


def score(records: list[dict]) -> dict:
    groups: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        if record.get("type") == "clip":
            groups[record["category"]].append(record)

    summary = {}
    for category, clips in groups.items():
        substitutions = deletions = insertions = reference_tokens = failures = 0
        times, audio_seconds = [], 0.0
        for clip in clips:
            if clip.get("error"):
                failures += 1
                continue
            ref, hyp = tokens(clip.get("normalized_reference", clip["reference"])), tokens(clip["hypothesis"])
            s, d, i = edits(ref, hyp)
            substitutions += s
            deletions += d
            insertions += i
            reference_tokens += len(ref)
            times.append(clip["pipeline_seconds"])
            audio_seconds += clip["duration_seconds"]
        metric = {"chinese": "CER", "english_clean": "WER", "english_other": "WER", "mixed": "MER"}[category]
        summary[category] = {
            "metric": metric, "clips": len(clips), "failures": failures,
            "reference_tokens": reference_tokens, "substitutions": substitutions,
            "deletions": deletions, "insertions": insertions,
            "error_rate": (substitutions + deletions + insertions) / reference_tokens if reference_tokens else None,
            "mean_pipeline_seconds": statistics.mean(times) if times else None,
            "real_time_factor": sum(times) / audio_seconds if audio_seconds else None,
        }
    return summary


def self_test() -> None:
    assert tokens("你好，Hello World!") == ["你", "好", "hello", "world"]
    assert edits(["a", "b"], ["a", "c", "b"]) == (0, 0, 1)
    assert edits(["a", "b"], ["a"]) == (0, 1, 0)
    assert edits(["a"], ["b"]) == (1, 0, 0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path, nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        print("score.py self-test passed")
        return
    if not args.results:
        parser.error("results is required")
    records = [json.loads(line) for line in args.results.read_text().splitlines() if line]
    summary = score(records)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    args.results.with_suffix(".summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
