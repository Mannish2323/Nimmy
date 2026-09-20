# Nimmy Voice and Hands-free Wake

## Current status

Phase 6 is `IN_PROGRESS`. The Flutter path and Android service boundary are implemented, but the feature is not certified.

Implemented behavior:

- A local Android wake-word service uses a visible microphone foreground-service notification.
- Wake events cross an EventChannel as metadata only; raw microphone audio is not sent to Flutter or the cloud.
- A wake event pauses the detector, starts command STT, routes the transcript through the existing intent → confirmation → controlled-tool path, then resumes wake detection.
- Text and manual microphone capture remain available as fallbacks.
- The native bridge reports `WAKE_ENGINE_UNAVAILABLE` when the app-specific classifier is absent.

## Required asset

`apps/mobile/android/app/src/main/assets/wakeword/nimmy.onnx` is intentionally absent. It must be an openWakeWord-compatible classifier trained and evaluated for both `Hey Nimmy` and `Nimmy`. Do not substitute a different phrase model or claim hands-free detection works without it.

## Verification evidence

- `flutter analyze`: passed — `No issues found!`.
- `flutter test`: timed out without a test summary in the current environment; no pass claim is made.
- Physical Android device: not run in this session.
- Screen-off, locked, background, restart, battery, false-positive, false-negative, latency, and battery measurements: unverified.

## Privacy and platform boundary

The service is user-started, visible, permission-gated, and not boot-started. Android may restrict microphone foreground services in background or locked states; the app must report the failure and retain text/manual voice fallback.

The wake detector has no database, network, tool, or repository dependency. State-changing work remains behind Flutter's controlled tool executor and confirmation gate.

## Files

- `apps/mobile/lib/services/voice/wake_word_service.dart`
- `apps/mobile/lib/core/native/nimmy_wake_word_platform.dart`
- `apps/mobile/lib/features/voice/voice_screen.dart`
- `apps/mobile/android/app/src/main/kotlin/ai/nimmy/nimmy/NimmyForegroundService.kt`
- `apps/mobile/android/app/src/main/kotlin/ai/nimmy/nimmy/WakeWordRuntime.kt`
- `apps/mobile/android/app/src/main/AndroidManifest.xml`
