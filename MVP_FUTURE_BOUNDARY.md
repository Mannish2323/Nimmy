# NIMMY — MVP / Future Boundary

## Implemented and testable now

- Android-first Flutter shell and dark Nimmy visual language.
- Interactive orb with distinct workflow states.
- Local Hive persistence for reminders, memories, and action history.
- Text fallback and speech-to-text/TTS service wiring.
- Deterministic parsing for canonical reminder and explicit-memory commands.
- Confirmation sheet and centralized tool policy.
- `create_reminder` with validation, idempotency, local notification attempt,
  and audit history.
- `save_memory` with explicit confirmation, provenance, edit/delete controls,
  idempotency, and audit history.
- Permission Center for microphone and notifications.
- Optional authenticated Supabase mirror with RLS migration.
- Truthful offline/local-only status and coming-soon screens.

## Scaffolded but not complete

- Supabase Auth UI/session restoration.
- Durable sync outbox and conflict-resolution UI.
- Full task, calendar, note, recording, and web-dashboard workflows.
- Physical Android verification of notification behavior and speech capture.

## Future only — do not claim as working

- Background/lock-screen recording and seven-day recording cleanup.
- Transcription, meeting summaries, speaker analysis, and task extraction.
- “What happened?” timeline and semantic universal search.
- Goals, projects, habits, focus mode, analytics, daily briefing/review.
- Automation engine and supported message scheduling integrations.
- Knowledge graph, pgvector/RAG, autonomous agents, multi-device resolution.
- Rust, C++, Go, desktop, wearable, Android Auto, and smart-home modules.

## Release rule

An item is complete only when its UI, state, backend/local persistence,
permissions, error path, actual action, audit behavior, and tests are present.
Otherwise label it `COMING SOON`, `NOT AVAILABLE`, or `VERIFICATION PENDING`.

