# NIMMY — Phase-wise Backlog

## Phase 0 — Repository and truth baseline (complete)

- Inspect the existing monorepo and preserve working code.
- Establish `PRODUCT_SPEC.md` as the canonical product boundary.
- Mark unsupported platform actions as unavailable rather than simulating them.

## Phase 1 — MVP foundation (implemented; verification ongoing)

- Flutter Android project and dark Nimmy design system.
- Shell navigation, command center, particle orb, empty/coming-soon states.
- Hive local repository and in-memory test repository.
- Typed reminder/memory/audit models.
- Deterministic intent parser for reminder and explicit-memory commands.
- Central confirmation policy and allow-listed tool registry.
- Local notification scheduling with truthful warnings.
- Voice STT/TTS with text fallback.
- Permission Center and Android allow-listed bridge.
- Supabase repository adapter and local-first wrapper when authenticated.
- SQL RLS/action foundation migration.
- Parser, tool, and widget tests.

Exit gate: both canonical flows pass automated tests and on-device voice,
notification, cancellation, and permission checks are recorded.

## Phase 2 — Account and sync hardening

- Supabase Auth UI and session restore.
- Persistent offline outbox for creates, updates, and deletes.
- Conflict resolution with explicit user-visible outcomes.
- Secure token/keystore policy and data export/delete account flows.

## Phase 3 — Core productivity

- Task, note, and calendar tools with typed contracts.
- Day/week/month calendar and conflict detection.
- Goal and project relationships.

## Phase 4 — Memory intelligence

- Search across local entities.
- Provenance and correction records.
- “What happened?” timeline over retained data.
- Optional pgvector/RAG only after privacy and deletion semantics are proven.

## Phase 5 — Recording

- Explicit recording UX and Android foreground service.
- Transcript, summary, task/deadline extraction with review gates.
- Seven-day temporary retention including derived transcript/summary cleanup.

## Phase 6 — Automation and supported integrations

- User-authored automation rules.
- Supported app/deep-link actions.
- Message drafts/scheduling only where official APIs and Android policy permit.

## Phase 7 — Web control center and scale

- Next.js management dashboard.
- Analytics, sync center, device management, and multi-device conflict UX.
- Add Go/Rust/C++ only when a measured requirement justifies them.

