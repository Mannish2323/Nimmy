# NIMMY Repository Audit

**Audit date:** 2026-09-20  
**Repository:** `C:\Users\ADMIN\Downloads\Nimmy`  
**Authority:** `AGENTS.md`, `docs/PRODUCT_SPEC.md`, and the attached Master Engineering / Code Generation Specification.

## Executive result

Nimmy is a Flutter/Android-first monorepo with an existing FastAPI AI service, Supabase migrations through migration 015, local Hive persistence, a typed MVP tool path, and a Next.js web application. The repository is not production-complete. The truthful current baseline remains:

- Phase 0: `IN_PROGRESS` — software foundation exists; physical-device verification is pending.
- Phase 1: `VERIFIED` in the current status file, subject to the project’s real-device limitation.
- Phase 5: `IN_PROGRESS` — provider boundary and AI service exist, but authenticated application-owned tool execution and live integration verification are pending.
- Phase 6: `IN_PROGRESS` — voice/STT/TTS and a local wake-word boundary exist, but the app-specific wake classifier and physical Android verification are pending.
- Phases 2–4 and 7–18: not complete.

No feature is certified merely because a screen, route, mock, or compiling function exists.

## 1. Repository structure

Relevant top-level areas found:

```text
apps/mobile/                 Flutter application and Android project
apps/web/                    Next.js application
services/ai-brain/           FastAPI/Python AI service
database/migrations/         Supabase PostgreSQL migrations 001–015
docs/                        Product, architecture, phase, QA, and status documents
scripts/                     Repository scripts
tools/                       Development tooling
flutter/                     Workspace-local Flutter SDK
```

The repository also contains `docker-compose.yml`, `.github/`, `.agent/`, and root-level source/specification documents. Existing working-tree modifications were present before this audit and were preserved.

## 2. Existing application and reusable code

### Mobile

- `apps/mobile/lib/main.dart` and `core/bootstrap/app_bootstrap.dart` initialize the application.
- Provider is the state-management library; `NimmyController` owns command submission, confirmation, execution state, refresh, and direct user edits.
- `NimmyIntentParser` currently recognizes the canonical reminder and explicit-memory commands.
- `ToolRegistry` currently executes `create_reminder` and `save_memory` through typed inputs, confirmation policy, repository persistence, scheduling, idempotency lookup, and audit events.
- Storage implementations include in-memory, Hive/local, offline-first, and Supabase repositories behind `NimmyRepository`.
- Shared UI infrastructure includes the app shell, theme, glass cards, loading/error/empty states, dialogs, snackbars, and the Nimmy orb.

### Android/Kotlin

- `MainActivity.kt` and `NimmyBridgeChannel.kt` provide the controlled Flutter/native bridge.
- `NimmyForegroundService.kt` provides a visible microphone-service boundary.
- `NimmyAlarmReceiver.kt` provides the reminder alarm boundary.
- `WakeWordRuntime.kt` provides a local wake-word boundary, but the app-specific `wakeword/nimmy.onnx` classifier is absent.
- `AudioRecordingDaemon.kt` exists and requires device/lifecycle verification before any recording claim.

### AI service

- FastAPI entrypoint: `services/ai-brain/app/main.py`.
- Existing routers cover chat, memory, summarization, task parsing, and intelligence endpoints.
- Existing internal modules include memory, knowledge routing, corrections, conflict resolution, confidence, recording processing, and “what happened?” logic.
- `llm_engine.py` has a Gemini REST adapter and an offline heuristic fallback. Current tool extraction is not yet the complete authenticated, application-owned Tool Request → validation → authorization → confirmation → execution path required by the contract.

### Web

- `apps/web` is a Next.js 16 / React 19 application with Tailwind, Framer Motion, Three.js, and Lucide dependencies.
- The web control center is not yet connected and verified against the same authenticated backend/database flow as mobile.

## 3. Dependencies and configuration

- Mobile dependencies include Provider, Hive, Supabase, HTTP/Dio, secure storage, connectivity, permissions, speech-to-text, and UUID support.
- AI dependencies include FastAPI, Pydantic, HTTPX, Gemini, Supabase, JWT, multipart, NumPy, scikit-learn, and sentence-transformers.
- Web dependencies include Next.js, React, Tailwind, Framer Motion, Three.js, and TypeScript.
- `.env.example` exists. No repository `.env` was certified by this audit.
- Client code must continue to receive only public configuration through environment or `--dart-define`; service-role credentials remain server-only.

## 4. Database and API state

- Supabase migrations 001–015 exist.
- Migration 015 adds request-id idempotency, audit logs, preferences, compatibility views, ownership helpers, and RLS policies for the MVP foundation.
- Local persistence is implemented through Hive and an offline-first repository boundary.
- The FastAPI service exposes `/health`, `/api/v1/chat`, `/api/v1/memory`, `/api/v1/summarize`, `/api/v1/tasks`, and intelligence routes.
- The canonical mobile MVP path is currently local-first. Live Supabase/auth/RLS execution and cross-client sync remain unverified in this checkout.

## 5. Android configuration and permissions

The Android project contains microphone, notification, foreground-service, scheduling, and native bridge configuration. The relevant behavior is not certified until it is tested on a physical Android device across foreground/background, screen-off, permission-denied, offline, restart, and battery conditions.

Firebase configuration was not certified as present by this audit. Notification scheduling must therefore remain truthful about local scheduler availability and must not claim cloud push delivery without evidence.

## 6. Conflicts and missing components

The attached specification describes the full long-term system. The repository’s canonical MVP and memory boundary intentionally remain narrower: `Voice/Text → Intent → Controlled Tool → Confirmation → Database → Audit → Response`, beginning with `create_reminder` and `save_memory`.

Important current gaps:

1. Authentication UI and end-to-end authenticated API context are not complete.
2. The AI service needs an authenticated, schema-validated, application-owned tool proposal/execution boundary; the model must not persist directly.
3. The Gemini adapter currently uses permissive CORS and a development JWT default; production hardening is required before deployment.
4. The app-specific wake-word model is absent, so wake-word detection is not a working product feature.
5. Flutter analyzer/test verification in this audit turn was blocked by multiple long-running Dart/Java processes and timed out without a final summary. Earlier results recorded in `docs/phases/PHASE_0.md` are historical evidence, not a substitute for a clean current rerun.
6. Physical Android, live Supabase, notification, recording, offline-reconnect, and cross-client synchronization evidence is missing.
7. The required phase documents do not yet exist for every phase; create each document when that phase begins.

## 7. Recommended implementation order

1. Preserve the existing working-tree changes and baseline the current checkout.
2. Finish Phase 0 evidence: clean Flutter analyze/test run, Android debug build, security grep, and documentation refresh.
3. Finish Phase 1 regression checks on a physical device where applicable.
4. Implement Phase 2 authentication, user scoping, secure session handling, and negative authorization tests.
5. Implement Phase 3 tasks/projects/goals/habits through domain services and controlled tools.
6. Implement Phase 4 reminders/calendar scheduling with timezone, idempotency, notification, and device evidence.
7. Replace the AI service’s partial provider path with authenticated structured proposals and an application-owned Tool Registry/Executor boundary; keep database mutation out of the model.
8. Re-verify the existing MVP tools end to end before expanding memory, recording, automation, messaging, or integrations.
9. Implement Phases 6–13 incrementally, each with tests, persistence checks, security checks, offline behavior, and device evidence.
10. Build the web control center only after the shared authenticated contracts and sync behavior are real.
11. Perform security/privacy, performance, complete QA, and release hardening last; leave every unresolved gate `IN_PROGRESS` or `BLOCKED`.

## 8. Verification record for this audit

Commands attempted in this audit:

```text
git status --short --branch
rg --files apps/mobile apps/web services/ai-brain database/migrations docs
..\..\flutter\bin\flutter.bat analyze       (timed out; no final summary)
..\..\flutter\bin\flutter.bat test          (timed out; no final summary)
npm exec tsc -- --noEmit                       (batch timed out before an isolated result)
python -m compileall -q app                    (batch timed out before an isolated result)
tasklist /FI "IMAGENAME eq dart.exe"
tasklist /FI "IMAGENAME eq java.exe"
```

Observed process evidence included multiple `dart.exe` and `java.exe` processes. No process was terminated because ownership and purpose were not established safely.

Therefore this audit records repository facts and gaps, but it does not upgrade any phase to `COMPLETE` or certify current automated verification.

