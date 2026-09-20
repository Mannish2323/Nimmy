# Phase 6 — Voice, STT, TTS, and Nimmy Orb

## GOAL

Provide a truthful voice-first path with local wake detection boundaries, command STT, controlled tools, confirmation, TTS, interruption, and text fallback.

## FEATURES

State model, wake-word bridge, visible Android microphone service, command capture, TTS bridge, wake-to-command wiring, orb state updates, and recovery messages.

## DEPENDENCIES

Flutter speech-to-text, Android microphone and notification permissions, Android foreground-service microphone support, trained `wakeword/nimmy.onnx`, existing intent parser, ToolRegistry, repository, and audit path.

## UI SCREENS / USER FLOWS

Voice screen supports text and manual microphone fallback. When the local service is enabled and a valid model is installed: IDLE → wake event → LISTENING → STT → existing confirmation/tool flow → TTS → IDLE.

## DATABASE CHANGES / API CONTRACTS

No new database schema. Wake detection emits status, phrase, score, timestamp, and error metadata only. State-changing actions continue through existing typed tools and audit events.

## PERMISSIONS / SECURITY

`RECORD_AUDIO`, `POST_NOTIFICATIONS`, foreground service microphone declaration, visible notification, and runtime checks. Wake service has no database or network authority.

## ERROR STATES / OFFLINE BEHAVIOR

Permission denial, missing classifier, unavailable microphone, background restriction, STT failure, no speech, TTS failure, and offline conditions retain a readable error and text/manual fallback. Cloud-independent wake and parsing boundaries are local; the existing cloud sync state remains separate.

## TESTS with actual output

- `flutter analyze` — `No issues found!`.
- `flutter test` — timed out after 184 seconds without a test summary; status remains unverified.
- Physical device tests — not run.

## ACCEPTANCE CRITERIA

The implementation is not complete until a real device demonstrates no-touch wake, command transcript without the wake phrase, controlled confirmation, real database/audit mutation, TTS response, interruption, and return to idle.

## KNOWN LIMITATIONS

The trained classifier asset is absent. Screen-off/background/locked behavior, battery cost, latency, false activations, and Android device compatibility have not been measured.

## VERIFICATION RESULTS

Status: `IN_PROGRESS`. Static analysis passed. Automated test runner and real-device evidence are unresolved.

## FILES CHANGED

See `docs/VOICE.md` and the working-tree diff for the complete file list; the key integration files are `lib/core/bootstrap/app_bootstrap.dart`, `lib/main.dart`, `lib/features/voice/voice_screen.dart`, and `test/services/wake_word_service_test.dart`.
