#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:-$root/benchmarks/results/sensevoice-$(date +%Y%m%d-%H%M%S).jsonl}"
binary="$root/build/lasay-benchmark"
libraries="$root/LaSay/LaSay/Libraries/sherpa-onnx/lib"

cd "$root"
python3 benchmarks/sample.py verify
xcrun swiftc -O -import-objc-header LaSay/LaSay/LaSay-Bridging-Header.h \
  -I LaSay/LaSay/Libraries/sherpa-onnx/include \
  benchmarks/run.swift LaSay/LaSay/Services/SenseVoiceCppWrapper.swift LaSay/LaSay/Utilities/AudioConverter.swift \
  -o "$binary" -L "$libraries" \
  -lsherpa-onnx-c-api -lsherpa-onnx-core -lonnxruntime -lkaldi-native-fbank-core \
  -lssentencepiece_core -lkaldi-decoder-core -lsherpa-onnx-fst -lsherpa-onnx-fstfar \
  -lsherpa-onnx-kaldifst-core -lkissfft-float -lsherpa-onnx-cxx-api \
  -framework AVFoundation -framework Foundation -lc++
"$binary" --output "$output"
python3 benchmarks/score.py "$output"
