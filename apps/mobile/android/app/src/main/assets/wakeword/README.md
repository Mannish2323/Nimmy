# Nimmy wake-word classifier contract

Production hands-free detection requires this exact asset:

```text
wakeword/nimmy.onnx
```

The classifier must be an openWakeWord-compatible ONNX model trained and
evaluated for both intended phrases:

- `Hey Nimmy`
- `Nimmy`

This repository intentionally does not rename or substitute a classifier for a
different phrase. Until a trained model is placed here, the Android bridge
returns `WAKE_ENGINE_UNAVAILABLE` and the app keeps manual microphone and text
fallbacks available.

Before distribution, record the model's provenance, license, SHA-256, training
configuration, held-out recall/false-activation results, threshold, and real
device results in `docs/VOICE.md` and `docs/phases/PHASE_6.md`.
