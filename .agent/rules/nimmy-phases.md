# NIMMY Phase Rules

This is the phase map referenced by the repository `AGENTS.md`. Work proceeds
in order. A later phase may be designed, but it may not be marked COMPLETE or
used to justify skipping an earlier phase.

Every phase exit requires the evidence gates in `AGENTS.md`: implementation
across the relevant UI/state/backend/database/API/validation/permission/error/
security/offline/sync/audit/test/device/documentation surfaces, or an explicit
platform-limitation record with the strongest supported fallback.

## Phase 0 - Foundation and architecture

Repository structure, Flutter/Kotlin build, configuration, local persistence,
repository boundaries, error handling, dependency policy, RLS migration
baseline, CI/verification documentation, and truthful offline-only behavior.

## Phase 1 - Design system and app shell

Dark Nimmy visual language, theme tokens, navigation shell, reusable cards and
states, responsive layout, and accessible loading/empty/error/offline surfaces.

## Phase 2 - Authentication, user, and security baseline

Supabase Auth lifecycle, session restore/logout/account deletion, user profile,
secure token storage, permission explanations, and authenticated RLS access.

## Phase 3 - Tasks, projects, goals, and habits

Typed task/project/goal/habit models, CRUD tools, relationships, recurrence,
progress, validation, local persistence, sync, audit, and test coverage.

## Phase 4 - Calendar, reminders, and scheduling

Calendar views, timezone-safe event planning, conflict detection, reminder
types, notification scheduling, cancellation, recurrence, permission handling,
and device verification.

## Phase 5 - AI brain and tool system

Intent/entity contracts, context retrieval, typed tool proposals, confirmation
policy, idempotency, audit events, model failure handling, and provider-safe API
boundaries. Models never receive unrestricted storage or platform access.

## Phase 6 - Voice, STT, TTS, and Nimmy Orb

User-initiated speech recognition, interruption/error states, truthful TTS,
orb state transitions, text fallback, microphone permission flow, and physical
Android verification.

## Phase 7 - Memory, learning, and corrections

Explicit saved memory, temporary context boundaries, categories, provenance,
edit/delete, correction records, retrieval, privacy controls, and sync/audit.

## Phase 7B - Correction engine

User corrections, conflict resolution, confidence changes, correction history,
and tests proving that corrections do not silently overwrite unrelated memory.

## Phase 8 - Recording, transcription, and AI summary

Visible user-started recording, Android foreground service, pause/stop,
transcription, speaker/section handling where supported, reviewed summaries,
task extraction, permissions, retention, and device testing.

## Phase 8B - Seven-day retention

Temporary audio/transcript/derived-data lifecycle, save/review decision,
scheduled deletion, recovery/error handling, audit, and verified cleanup.

## Phase 9 - What Happened timeline

Cross-entity timeline over authorized tasks, notes, events, memories,
recordings, and audit metadata with source links and explicit uncertainty.

## Phase 9B - Universal search

User-scoped indexed search, filters, ranking, source provenance, offline
behavior, synchronization, deletion semantics, and performance evidence.

## Phase 10 - Automation engine

Typed trigger/action rules, permissions, confirmation policy, retries,
idempotency, audit, pause/delete controls, and safe failure behavior.

## Phase 11 - Messaging, app launcher, and integrations

Allow-listed deep links and official APIs only. Draft/preview/confirmation for
external sends, platform restriction handling, integration error states, audit,
and real-device verification.

## Phase 12 - Offline-first sync and conflict resolution

Outbox, retries, authenticated sync, stable IDs, conflict detection and
resolution UI, deletion propagation, connectivity states, and multi-device
tests.

## Phase 13 - Analytics, daily briefing, and focus

Local/user-authorized analytics, morning briefing, night review, focus sessions,
actionable explanations, privacy controls, offline behavior, and validation.

## Phase 14 - Web control center

Authenticated Next.js dashboard for management, search, memory, recordings,
analytics, automations, and settings using the same contracts and RLS rules.

## Phase 15 - Security, privacy, and data controls

Permission dashboard, memory controls, app lock, encryption/Keystore, export,
account deletion, audit visibility, secure communication, and cross-user RLS
denial tests.

## Phase 16 - Performance and native optimization

Measured performance work only: startup, battery, storage, rendering, native
bridges, and profiling evidence. Rust/C++/Go require a measured need.

## Phase 17 - Testing and real-device QA

Full regression suite, Android matrix, permissions, background/lock/restart,
offline/sync, accessibility, failure injection, and recorded device evidence.

## Phase 18 - Production hardening and release

Release signing, CI/CD gates, migration/rollback plan, observability, privacy
and security review, store policy checks, backups, incident response, and
release artifact verification.
