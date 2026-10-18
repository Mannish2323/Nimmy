# NIMMY — Master TODO

> Categories: BLOCKING, HIGH, MEDIUM, LOW, FUTURE
> Rule: Never hide unfinished work. `[ ]` → `[x]` only after verification with evidence.

---

## BLOCKING
- [ ] **No `.env` file configured** — Supabase and Gemini API keys needed for cloud features. Local-only mode works without them.
- [x] **State management consolidation** — pubspec lists only `provider`. Consolidated and verified.
- [x] **Flutter SDK located** — Verified at `flutter\bin\flutter.bat`.

## HIGH

- [ ] Create all `docs/phases/PHASE_X.md` documents as each phase begins (PHASE_0, PHASE_1, PHASE_2, PHASE_3, PHASE_4 created)
- [x] Build comprehensive test suite (81 unit and widget tests passing with 100% success rate across mobile codebase)
- [x] Wire Supabase Auth UI and AuthService for Phase 2
- [x] Implement Phase 3 Task domain models (NimmyTask, NimmyProject, NimmyGoal, NimmyHabit) with local Hive & Supabase storage
- [x] Implement Phase 3 Controlled Tools (create_task, edit_task, complete_task, delete_task, reschedule_task) with confirmation policy and audit logging
- [x] Implement Phase 3 Task Management UI (tasks_screen.dart) with project filtering, completion toggles, and modal creation
- [x] Implement Phase 4 Calendar + Reminders + Scheduling with multi-layer repo, 6 controlled tools, natural language intent parser, glassmorphic UI, and 81 tests passing
- [ ] Integrate FastAPI AI brain with mobile app for Phase 5
- [ ] Replace the partial FastAPI Gemini boundary with an authenticated provider adapter and application-owned tool proposal endpoint; no direct AI persistence or side effects.
- [ ] Android device verification for notifications, voice, recording
- [ ] Provide and evaluate `apps/mobile/android/app/src/main/assets/wakeword/nimmy.onnx`; the local detector intentionally refuses to start without this app-specific classifier.

## MEDIUM

- [ ] Remove Go gateway from docker-compose (not needed in MVP, per PRODUCT_SPEC)
- [ ] Create Dockerfile for AI brain service
- [ ] Add CI/CD pipeline (.github/workflows/)
- [x] Add structured logging throughout the app (`nimmy_logger.dart` with auto-redaction and active app wiring)
- [x] Implement `flutter_secure_storage` for sensitive data (Keystore-backed auth tokens in `auth_service.dart`)

## LOW

- [ ] Add app icon and splash screen assets
- [ ] Configure ProGuard/R8 rules for release build
- [ ] Add code coverage reporting
- [ ] Add pre-commit hooks for linting

## FUTURE

- [ ] Rust/C++/Go modules (only if benchmarks justify — §26)
- [ ] Multi-device sync with conflict resolution UI
- [ ] Knowledge graph / pgvector RAG pipeline
- [ ] Desktop and wearable platforms
- [ ] Android Auto / smart home integrations
