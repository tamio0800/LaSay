# Third-Party Notices

LaSay's original source code is licensed under the MIT License. The bundled
model and native runtime remain under their respective licenses below and are
not relicensed by LaSay.

## SenseVoiceSmall model

The bundled `model.int8.onnx` and `tokens.txt` are the unmodified
`sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17` conversion of
Alibaba FunAudioLLM's SenseVoiceSmall model.

- Source archive: <https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17.tar.bz2>
- Model SHA-256: `c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51`
- Tokens SHA-256: `f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc`
- Author/source: Alibaba Group, FunAudioLLM, SenseVoiceSmall
- License: FunASR Model Open Source License Agreement v1.1

The license requires attribution to the source and author and retention of the
SenseVoiceSmall model name. Its full text is bundled beside the model.

## Native runtime

The checked-in native libraries were built from sherpa-onnx `v1.12.25`, commit
`4ca7d91c8e7941a3550df013a10fcaf7df65b263`, with TTS and speaker diarization
disabled. This intentionally excludes eSpeak NG, Piper Phonemize, and libucd.

| Component | License | Source |
| --- | --- | --- |
| sherpa-onnx | Apache-2.0 | <https://github.com/k2-fsa/sherpa-onnx/tree/v1.12.25> |
| ONNX Runtime 1.23.2 | MIT | <https://github.com/microsoft/onnxruntime/tree/v1.23.2> |
| kaldi-native-fbank 1.22.3 | Apache-2.0 | <https://github.com/csukuangfj/kaldi-native-fbank> |
| kaldi-decoder 0.2.11 | Apache-2.0 | <https://github.com/k2-fsa/kaldi-decoder> |
| kaldifst 1.7.17 | Apache-2.0 | <https://github.com/k2-fsa/kaldifst> |
| OpenFst sherpa-onnx-2024-06-19 | Apache-2.0 | <https://github.com/csukuangfj/openfst> |
| simple-sentencepiece 0.7 | Apache-2.0 | <https://github.com/pkufool/simple-sentencepiece> |
| Eigen | MPL-2.0 | <https://gitlab.com/libeigen/eigen> |
| KISS FFT | BSD-3-Clause | <https://github.com/mborgerding/kissfft> |
| nlohmann/json 3.12.0 | MIT | <https://github.com/nlohmann/json> |

Full license texts and required copyright notices are included in
`LaSay/LaSay/Resources/ThirdPartyLicenses/` and in distributed app
bundles.
