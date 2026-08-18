# Tiny ASR benchmark sample

`sample.py` fetches exactly 20 untouched source clips per category with seed
`20260818`; it never downloads a complete dataset or concatenates/transcodes
audio. `english_clean` and `english_other` together are the 20-clip English
category (10 from each LibriSpeech test split).

```sh
python3 benchmarks/sample.py fetch
python3 benchmarks/sample.py verify
python3 benchmarks/score.py --self-test
./benchmarks/run.sh
```

Only Python 3 and macOS's built-in audio tools are required.

The rows API supplies metadata and short-lived per-clip audio URLs. Generated
audio, JSONL manifests, and the byte-count report are intentionally ignored;
rerun `fetch` to recreate them. Manifests contain the dataset, split, source
ID, transcript, duration, source/license URLs, and the direct URL used.

`run.sh` compiles a small CLI with the app's bundled `SenseVoiceCppWrapper`
and `AudioConverter`, then writes ignored JSONL results under
`benchmarks/results/`. `score.py` reports Chinese CER, English WER (clean and
other separately), and Mandarin-English MER. Metrics strip punctuation and
case; `[UNK]` transcript placeholders are excluded. The runner applies the
app's `Hans-Hant` conversion to both output and reference before scoring.
It also reports real-time factor (pipeline seconds divided by input audio
seconds). These are smoke-test signals, not a claim of production accuracy.

Sources and licenses:

- Chinese: [Taiwan-Tongues-ASR-CE](https://huggingface.co/datasets/adi-gov-tw/Taiwan-Tongues-ASR-CE-dataset-zhtw), TRAIL-D 0.1.
- English: [LibriSpeech](https://huggingface.co/datasets/openslr/librispeech_asr), CC-BY-4.0.
- Mixed: [ASCEND](https://huggingface.co/datasets/CAiRE/ASCEND), CC-BY-SA-4.0.
