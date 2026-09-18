# 🟣 Nimmy

**Remember everything. Manage anything. Just ask Nimmy.**

Nimmy is an Android-first, voice-first personal AI operating system. The first
verified product slice is intentionally narrow and real:

```text
voice or text
  → intent + entity detection
  → controlled tool proposal
  → confirmation
  → local/cloud persistence
  → audit history
  → truthful Nimmy response
```

The executable MVP tools are `create_reminder` and `save_memory`. Unsupported
recording, messaging, calendar, task, and autonomous-agent behavior is labeled
future work instead of being simulated.

## Repository

```text
apps/mobile/       Flutter + Dart Android-first app
apps/web/          Next.js control-center placeholder
services/ai-brain/ Optional FastAPI boundary for future AI routing
database/          PostgreSQL/Supabase migrations
PRODUCT_SPEC.md    Canonical product rules and MVP scope
SYSTEM_ARCHITECTURE.md
DATABASE_SCHEMA.md
AI_TOOL_CONTRACTS.md
PERMISSION_CONFIRMATION_MATRIX.md
SCREEN_NAVIGATION_MAP.md
PHASE_BACKLOG.md
ACCEPTANCE_CRITERIA.md
MVP_FUTURE_BOUNDARY.md
```

Rust, C++, and Go directories that exist in the repository are deferred
experiments. They are not required by, or part of, the MVP runtime.

## Mobile development

The project uses Flutter and Kotlin. A workspace-local Flutter SDK may be used
on machines where Flutter is not on `PATH`:

```powershell
cd apps/mobile
..\..\flutter\bin\flutter.bat pub get
..\..\flutter\bin\flutter.bat analyze
..\..\flutter\bin\flutter.bat test
```

For a configured Supabase session, pass runtime values through secure build
configuration rather than committing them:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
NIMMY_AI_BASE_URL
NIMMY_TIMEZONE
```

Without a cloud session Nimmy runs in local-only mode. This is an intentional,
supported mode, not a fake cloud success.

## Verification rule

The analyzer and automated tests cover the parser, confirmation gate,
idempotent tools, audit events, memory flow, and command-center smoke path.
Android notification and speech behavior still require a physical-device pass.

> Do not mark a checklist item ✅ merely because the UI exists. Mark it ✅ only
> after the actual workflow has been implemented, tested, and verified.

## Product boundary

Read [PRODUCT_SPEC.md](PRODUCT_SPEC.md) first. The remaining architecture and
acceptance documents state exactly what is implemented, what is verification
pending, and what is future.
