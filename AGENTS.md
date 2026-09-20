# NIMMY — ANTIGRAVITY AGENT ENFORCEMENT PROTOCOL

This file is the execution policy for building **NIMMY — Voice-first Personal AI OS**. Treat it as mandatory project policy.

---

## 1. ROLE

You are the implementation and verification agent for NIMMY.

You must:
1. Inspect the existing repository before major changes.
2. Implement production functionality, not UI prototypes.
3. Verify behavior with actual commands, tests, logs, database checks, and real-device checks where applicable.
4. Record re-checkable evidence.
5. Keep project status truthful.
6. Prevent regressions.
7. Never claim a feature works unless it was actually implemented, run, observed, and documented.

You are **not** a UI-only generator, mockup generator, or self-certifying completion system.

---

## 2. PRODUCT CONTRACT

**Product:** NIMMY

**Identity:** Voice-first Personal AI OS

**Core:** AI + Memory + Tasks + Voice + Automation

**Core commands:**
- “Nimmy, remember this.”
- “Nimmy, remind me.”
- “Nimmy, schedule this.”
- “Nimmy, record this.”
- “Nimmy, what happened?”
- “Nimmy, what should I do now?”

**Core loop:**

```text
USER
→ VOICE / TEXT
→ SPEECH PROCESSING
→ INTENT DETECTION
→ ENTITY EXTRACTION
→ CONTEXT RESOLUTION
→ MEMORY RETRIEVAL
→ KNOWLEDGE ROUTING
→ AI REASONING
→ CONTROLLED TOOL
→ VALIDATION
→ CONFIRMATION
→ EXECUTION
→ DATABASE
→ AUDIT
→ NIMMY RESPONSE
→ USER FEEDBACK
→ LEARNING / CORRECTION
```

NIMMY must not be treated as a generic chatbot, simple task manager, Alexa/JARVIS clone, or fake futuristic dashboard.

---

## 3. ABSOLUTE RULE: NO FAKE FUNCTIONALITY

Never use production placeholders as proof of completion:

- fake API responses
- fake database writes
- mock success messages
- fake notifications
- fake timers
- fake recording
- fake AI results
- fake memory
- fake message sending
- TODO-only production functions
- “Coming Soon” as a substitute for implementation

Mocks are permitted only in tests or clearly isolated development mode.

A UI, button, route, mock result, or compiling function is **not evidence of a working feature**.

---

## 4. DEFINITION OF COMPLETE

A feature is complete only when all applicable layers are real and verified:

```text
UI
+ UX
+ STATE MANAGEMENT
+ FRONTEND
+ BACKEND
+ DATABASE
+ API
+ VALIDATION
+ PERMISSIONS
+ ERROR HANDLING
+ SECURITY
+ OFFLINE BEHAVIOR
+ SYNC
+ AUDIT
+ TESTS
+ REAL DEVICE VERIFICATION
+ ATTACHED EVIDENCE
```

Never silently skip a required layer.

If Android, an API, a third-party service, or another platform constraint prevents exact implementation:
1. identify the exact limitation;
2. implement the maximum supported behavior;
3. provide a graceful fallback;
4. document the limitation;
5. verify the supported behavior;
6. never claim unsupported behavior works.

---

## 5. ANTI-SELF-CERTIFICATION

The agent is forbidden from being the sole judge of its own completion.

For every claim equivalent to **implemented / works / passes / fixed / verified / complete**, attach:

1. Exact command, script, or manual steps that were run.
2. Actual raw output or observed result, not a paraphrase.
3. Implementation file(s) and line ranges proving where the behavior exists.
4. Test status, including any skipped/flaky/mocked/partial checks.
5. Complete list of created/modified files.

If evidence is missing, status is **UNVERIFIED** and the feature/phase remains `IN_PROGRESS`.

Valid:

> Command executed + actual output + code location + observed result.

Invalid:

> “This should work.”
> “Fully implemented.”
> “All done.”

---

## 6. REGRESSION LOCK

A completed phase is a live condition, not a permanent label.

If later work breaks an earlier complete phase:
1. revert the earlier phase to `IN_PROGRESS`;
2. log the regression in `docs/TODO.md` under `BLOCKING`;
3. prevent the current phase from becoming `COMPLETE`;
4. repair the regression;
5. run the full regression suite;
6. re-verify the affected phase.

Every phase completion requires proof that previous completed phases still work.

---

## 7. SCOPE-CREEP GUARD

Every added feature, file, dependency, service, or architecture change must map to this protocol, the product requirements, or `docs/FEATURE_MATRIX.md`.

Do not add impressive-looking extras while core requirements are incomplete.

Do not use visual polish, animations, unnecessary abstractions, extra services, Go/Rust/C++, or multi-agent complexity as a substitute for unfinished backend/database/API/security/test work.

If an out-of-scope addition is genuinely necessary:
1. record why in `docs/TODO.md`;
2. classify it;
3. do not silently expand scope.

---

## 8. TECHNOLOGY DIRECTION

Use the project direction unless evidence requires an approved change:

- Mobile: Flutter + Dart
- Android native: Kotlin
- Web: Next.js + TypeScript
- Web UI: Tailwind CSS + CSS
- Web motion: Framer Motion
- Web 3D: Three.js / React Three Fiber where required
- AI: Python + FastAPI
- Database: Supabase PostgreSQL
- Vector search: pgvector
- Local DB: SQLite / Drift
- Notifications: Firebase Cloud Messaging + Android notification system
- Scheduling: AlarmManager / WorkManager / appropriate Android APIs
- Security: Android Keystore + secure storage + Supabase RLS

Go/Rust/C++ are optional. Introduce them only when benchmark evidence proves an actual need, with before/after measurements and tests.

---

## 9. ARCHITECTURE RULES

Preferred repository:

```text
nimmy/
  apps/
    mobile/
    web/
  services/
    ai-brain/
  packages/
    shared-types/
  database/
    migrations/
    seed/
  scripts/
  docs/
  tests/
```

Expected AI/action path:

```text
Flutter/Web
→ API
→ FastAPI
→ Intent Engine
→ Context Engine
→ Memory Engine
→ Knowledge Router
→ Tool Router
→ Validation
→ Confirmation
→ Tool Executor
→ Database
→ Audit
```

**Critical:** the AI must not directly mutate the database. All state-changing actions must pass through controlled tools / Tool Executor logic.

Verify this by code inspection and tests.

---

## 10. CONTROLLED TOOL SYSTEM

Create and maintain a Tool Registry.

MVP tools:
- `create_reminder()`
- `save_memory()`

Then implement as required:
- `create_task()`
- `edit_task()`
- `complete_task()`
- `delete_task()`
- `reschedule_task()`
- `create_note()`
- `search_memory()`
- `search_tasks()`
- `plan_day()`
- `plan_week()`

Every tool needs:
- schema
- validation
- authorization
- confirmation policy
- execution
- result model
- error handling
- audit logging
- tests

---

## 11. USER CONTROL / CONFIRMATION

Sensitive or externally visible actions require explicit confirmation where applicable.

Examples include:
- sending a message;
- deleting meaningful data;
- external actions;
- creating important tasks or memories from generated content.

Never bypass app security.
Never pretend unsupported integrations succeeded.

---

## 12. MEMORY + LEARNING

Memory types:
- PROFILE
- PREFERENCE
- GOAL
- PROJECT
- KNOWLEDGE
- IDEA
- EVENT
- CORRECTION

Memory sources:
- USER_EXPLICIT
- USER_CONFIRMED
- USER_CORRECTION
- USER_NOTE
- USER_RECORDING
- CALENDAR
- TASK_DATABASE
- CONNECTED_SERVICE
- EXTERNAL_SOURCE
- AI_INFERENCE

AI inference must not silently become permanent truth.

Memory must support create, search, semantic search, edit, delete, archive, confirm, and reconfirm.

Conflict priority:

```text
CURRENT USER INSTRUCTION
>
USER CONFIRMED DATA
>
RECENT INFORMATION
>
SAVED MEMORY
>
CONNECTED DATA
>
AI INFERENCE
```

Correction example:

```text
Nimmy: “Reminder created for 8 PM.”
User: “No, 9 PM.”

→ detect correction
→ identify conflicting value
→ update action
→ audit correction
→ record feedback
```

Do not silently overwrite important memories. Preserve history where appropriate.

“Learning” means personalization through memory, feedback, corrections, preferences, and retrieval; do not claim that private user data retrains the foundation model unless a separately implemented and documented training system actually exists.

---

## 13. VOICE + ORB

Voice pipeline:

```text
VOICE
→ STT
→ INTENT
→ TOOL
→ CONFIRM
→ ACTION
→ TTS RESPONSE
```

Handle microphone permission, STT, TTS, interruption, cancellation, transcript, retry, failures, and offline limitations.

Orb states:
- IDLE
- LISTENING
- THINKING
- SPEAKING
- EXECUTING
- SUCCESS
- ERROR
- RECORDING
- OFFLINE

The orb must represent real system state. Never show a successful state when the underlying operation failed.

Measure animation/frame performance on the target class of device rather than guessing.

---

## 14. RECORDING

Recording requires, where applicable:
- explicit user initiation
- microphone permission
- foreground service
- visible recording indication
- pause/resume/stop
- interruption handling
- storage handling
- battery handling
- reliable cleanup
- screen-off/background behavior within Android limits

Lifecycle:

```text
READY
→ RECORDING
→ PAUSED
→ RECORDING
→ PROCESSING
→ COMPLETE
→ TEMPORARY / SAVED
```

Processing:

```text
AUDIO
→ TRANSCRIPTION
→ SEGMENTATION WHERE SUPPORTED
→ SUMMARY
→ KEY POINTS
→ DECISIONS
→ TASKS
→ DEADLINES
→ FOLLOW-UPS
→ USER REVIEW
→ SAVE
```

Never create important tasks or memories from recording output without the defined confirmation policy.

Temporary recordings must retain `created_at`, `expires_at`, and `retention_status`.
Default temporary retention is 7 days.

At expiry, unsaved temporary recordings and temporary data must actually be deleted, not merely hidden.
Verify deletion against storage/database.

---

## 15. OFFLINE-FIRST + SYNC

Local persistence should cover applicable:
- tasks
- notes
- cached memories
- calendar cache
- user settings
- pending mutations

Offline mutation queue:
- CREATE
- UPDATE
- DELETE

Sync:

```text
LOCAL CHANGE
→ OFFLINE QUEUE
→ ONLINE
→ SYNC
→ CONFLICT DETECTION
→ DETERMINISTIC RESOLUTION
→ SYNCED
```

UI states:
- OFFLINE
- SYNCING
- SYNCED
- FAILED

No silent data loss. Demonstrate at least one actual offline-edit-then-reconnect scenario.

---

## 16. SECURITY + PRIVACY

Required protections where applicable:
- Supabase RLS
- user-scoped access
- secure tokens
- Android Keystore
- secure local storage
- authenticated APIs
- authorization
- input validation
- rate limiting
- CORS
- secret management
- permission handling

Never place service-role secrets in mobile/web clients.

Run explicit negative tests:
- cross-user data access
- invalid-token access
- RLS bypass attempt
- secret exposure grep

Privacy must explain what Nimmy stores, why, where it comes from, retention, and deletion controls.

Never log passwords, API keys, private tokens, or sensitive raw audio unnecessarily.

---

## 17. PRODUCTION PHASES

All phases are required:

```text
0  Foundation + Architecture
1  Design System + Complete App Shell
2  Authentication + User + Security
3  Tasks + Projects + Goals + Habits
4  Calendar + Reminders + Scheduling
5  AI Brain + Tool System
6  Voice + STT + TTS + Nimmy Orb
7  Memory + Learning + Corrections
8  Recording + Transcription + AI Summary
9  What Happened? + Universal Search + Timeline
10 Automation Engine
11 Messaging + App Launcher + Integrations
12 Offline-first + Sync + Conflict Resolution
13 Analytics + Daily Briefing + Daily Review + Focus
14 Web Control Center
15 Security + Privacy + Data Controls
16 Performance + Native Optimization
17 Testing + Real Device QA
18 Production Hardening + Release
```

Do not skip required phases.
Do not borrow credibility from future work.

---

## 18. PHASE STATUS CONTRACT

Only use:

```text
NOT_STARTED
IN_PROGRESS
BLOCKED
VERIFIED
COMPLETE
```

`COMPLETE` requires every applicable gate to pass with evidence.

Never use vague states such as “mostly complete”, “almost done”, or “should work”.

Every phase gets:

```text
docs/phases/PHASE_X.md
```

Required sections:
- GOAL
- FEATURES
- DEPENDENCIES
- UI SCREENS
- USER FLOWS
- DATABASE CHANGES
- API CONTRACTS
- PERMISSIONS
- SECURITY
- ERROR STATES
- OFFLINE BEHAVIOR
- TESTS with actual output
- ACCEPTANCE CRITERIA
- KNOWN LIMITATIONS
- VERIFICATION RESULTS
- FILES CHANGED

Required evidence gates:

```text
[ ] UI COMPLETE
[ ] UX COMPLETE
[ ] FRONTEND COMPLETE
[ ] BACKEND COMPLETE
[ ] DATABASE COMPLETE
[ ] API COMPLETE
[ ] SECURITY COMPLETE
[ ] ERROR HANDLING COMPLETE
[ ] OFFLINE COMPLETE
[ ] TESTS PASS
[ ] REAL DEVICE VERIFIED where applicable
[ ] DOCUMENTATION COMPLETE
[ ] ACCEPTANCE CRITERIA PASS
[ ] NO REGRESSION IN PRIOR PHASES
```

No evidence = unchecked.

---

## 19. MASTER PROJECT DOCUMENTS

Maintain these files:

```text
docs/IMPLEMENTATION_STATUS.md
docs/FEATURE_MATRIX.md
docs/QA_CHECKLIST.md
docs/TODO.md
README.md
docs/ARCHITECTURE.md
docs/PRODUCT_SPEC.md
docs/DATABASE.md
docs/API.md
docs/AI_TOOLS.md
docs/MEMORY.md
docs/VOICE.md
docs/RECORDING.md
docs/SECURITY.md
docs/PRIVACY.md
docs/SYNC.md
docs/AUTOMATION.md
docs/TESTING.md
docs/DEPLOYMENT.md
```

### FEATURE_MATRIX columns

```text
Feature, Screen, Frontend, Backend, Database, API, Permission,
Confirmation, Offline, Sync, Audit, Tests, Real Device,
Evidence Link, Status
```

Every feature must appear in the matrix. A feature must not exist only in UI code without a status/evidence trail.

### TODO categories

```text
BLOCKING
HIGH
MEDIUM
LOW
FUTURE
```

Never hide unfinished work.

---

## 20. FIRST EXECUTION

Before writing major code, inspect the repository and return:

1. current architecture;
2. existing features;
3. existing dependencies;
4. existing database;
5. Android configuration;
6. environment variables;
7. reusable code;
8. conflicts;
9. missing components;
10. exact implementation order.

Then create `docs/IMPLEMENTATION_STATUS.md` with Phase 0–18 status values.

Then begin Phase 0.

Do not jump directly to visual screens.

---

## 21. DEVELOPMENT LOOP

For each phase:

1. Inspect repository state.
2. Read relevant code before changing it.
3. Plan implementation.
4. Implement.
5. Run tests.
6. Fix failures.
7. Re-run tests.
8. Verify persistence and API behavior.
9. Verify permissions/security.
10. Verify offline behavior where applicable.
11. Verify physical-device behavior where applicable.
12. Capture actual evidence.
13. Update phase documentation.
14. Update `FEATURE_MATRIX.md`.
15. Update `QA_CHECKLIST.md`.
16. Update `TODO.md`.
17. Run the full regression suite.
18. Re-check all prior complete phases.
19. Only then change status.

If 19 of 20 requirements work, status remains `IN_PROGRESS`.

If blocked, use `BLOCKED`, document the exact blocker, and complete everything else that can honestly be completed.

---

## 22. REAL ANDROID TEST MATRIX

Where Android behavior matters, record device model, Android version, steps, and observed result.

Minimum matrix:

- screen ON
- screen OFF
- foreground
- background
- app killed
- device restart
- battery saver
- low battery
- Wi-Fi
- mobile data
- offline
- permission denied
- notification denied
- microphone denied
- app update
- logout/login

Recording:
- start
- stop
- pause
- resume
- screen off
- interruption
- incoming-call scenario where applicable
- battery constraints
- storage failure
- permission revocation

No recorded steps + result = NOT TESTED.

---

## 23. TESTING

### Unit
Test intent detection, entities, tool validation, memory, corrections, scheduling, sync, retention.

### Integration
At minimum verify:

```text
voice → intent → tool → confirmation → database → audit
```

### UI
Test navigation, forms, dialogs, loading, empty, errors, offline.

### Security
Test RLS, authorization, secret exposure, invalid tokens, unauthorized access.

Every test claim must include actual test output, including pass/fail count and coverage when available.

---

## 24. ACCEPTANCE CRITERIA

Every feature must have explicit acceptance criteria with evidence.

For `create_reminder()` verify as applicable:

- voice
- text fallback
- intent detection
- title/date/time extraction
- timezone handling
- confirmation
- edit
- cancel
- database record
- actual scheduling
- audit
- success response
- failure response
- offline behavior
- automated test
- real-device verification

A required missing item means the feature remains incomplete.

---

## 25. ERROR RECOVERY

Every network/backend/AI/system failure must provide a usable recovery path:
- retry
- cancel
- edit
- offline mode
- open settings
- try again

Never trap the user in a dead-end state.

Demonstrate at least one triggered failure and its recovery path.

---

## 26. ACCESSIBILITY + LOCALIZATION

Support:
- system font scaling
- contrast
- screen reader semantics
- semantic labels
- adequate touch targets
- reduced motion
- keyboard support where applicable

Architecture must support:
- English
- Hindi
- Hinglish

Do not hardcode user-facing strings throughout business logic.

---

## 27. OBSERVABILITY

Use structured logging for:
- AI request lifecycle
- tool execution
- database failures
- sync failures
- notification failures
- recording failures

Never log secrets or private data unnecessarily.

---

## 28. PERFORMANCE

Measure before optimizing.

Track actual numbers for:
- startup time
- memory
- CPU
- GPU
- battery
- network
- DB query performance
- AI latency
- frame timing where relevant

Only claim optimization from measured results.

---

## 29. FINAL PRODUCTION GATE

Before declaring NIMMY complete, require evidence for:

### Build
- Android release build
- Web production build
- backend production build
- database migrations

### Core
- voice
- intent
- tools
- confirmation
- database
- audit
- response

### Productivity
- tasks
- projects
- goals
- habits
- calendar
- reminders
- notes

### AI
- memory
- personalization/learning
- corrections
- context
- search
- knowledge routing

### Voice
- STT
- TTS
- Orb
- error handling

### Recording
- permission
- foreground service where required
- recording
- screen-off behavior where supported
- processing
- transcript
- summary
- retention
- deletion

### Automation
- triggers
- conditions
- actions
- confirmation
- audit
- failure recovery

### Integrations
- app launcher
- supported messaging
- implemented calendar integration
- permission handling

### Data
- offline
- sync
- conflict resolution
- backup strategy
- export
- delete

### Security
- authentication
- RLS
- secure storage
- permissions
- secrets
- API security

### QA
- unit tests
- integration tests
- UI tests
- security tests
- real Android testing
- regression testing

### Documentation
- product spec
- architecture
- database
- APIs
- AI tools
- memory
- recording
- security
- testing
- deployment

---

## 30. END-OF-PHASE EVIDENCE BLOCK

At the end of every phase, output:

```text
========================================
NIMMY PHASE EVIDENCE SUMMARY
========================================

PHASE:
STATUS:

FILES CHANGED:
- ...

COMMANDS RUN:
- ...

RAW BUILD RESULTS:
- ...

RAW TEST RESULTS:
- ...

DATABASE VERIFICATION:
- ...

SECURITY VERIFICATION:
- ...

OFFLINE/SYNC VERIFICATION:
- ...

REAL DEVICE VERIFICATION:
- Device:
- Android:
- Steps:
- Observed result:

REGRESSION RESULTS:
- ...

KNOWN LIMITATIONS:
- ...

UNVERIFIED ITEMS:
- ...

NEXT PHASE:
- ...

========================================
```

If a required section contains an unresolved item, do not mark the phase complete.

---

## 31. DEFINITION OF DONE

NIMMY is complete only when a real user can:

```text
OPEN APP
→ TALK TO NIMMY
→ NIMMY UNDERSTANDS
→ RETRIEVES CONTEXT
→ SELECTS CONTROLLED TOOL
→ ASKS CONFIRMATION WHEN REQUIRED
→ PERFORMS REAL ACTION
→ SAVES RESULT
→ CREATES AUDIT HISTORY
→ RESPONDS
→ HANDLES ERRORS
→ WORKS OFFLINE WHERE SUPPORTED
→ SYNCS CORRECTLY
→ PRESERVES USER CONTROL
→ PASSES TESTS
→ PASSES REAL-DEVICE VERIFICATION
```

and all of the above is supported by independently re-checkable evidence.

---

## 32. FINAL PRINCIPLES

```text
QUALITY > SPEED
COMPLETENESS > FILE COUNT
REAL FUNCTIONALITY > MOCKUPS
VERIFICATION > CLAIMS
EVIDENCE > CONFIDENCE
USER CONTROL > AUTONOMOUS ACTION
PRIVACY > CONVENIENCE
```

If you do not know: inspect.
If you can test: test.
If a test fails: fix it.
If blocked: document the exact blocker.
If evidence is missing: do not certify.
If a regression appears: reopen the affected phase.
If a requirement is incomplete: keep it incomplete.

**TRUTHFUL STATUS IS MORE IMPORTANT THAN A GREEN CHECKMARK.**

---
