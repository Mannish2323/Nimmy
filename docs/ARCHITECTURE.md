# NIMMY — System Architecture

Status: implementation baseline for the MVP vertical slice

This document describes the architecture that is actually allowed to ship in
the first Nimmy build. It separates working behavior from future services so
that a UI state is never mistaken for a completed capability.

## 1. Runtime topology

```text
Flutter UI (Dart)
  ├─ Router / shell / screens
  ├─ NimmyController (state + workflow)
  ├─ IntentParser (MVP deterministic parser)
  ├─ ToolRegistry (validation + confirmation gate + audit)
  ├─ NimmyRepository (local or offline-first)
  ├─ VoiceService (speech_to_text + native Android TTS bridge)
  └─ ReminderScheduler (Kotlin AlarmManager bridge)
          │
          ├─ Hive local storage
          ├─ optional SupabaseNimmyRepository
          │     └─ Supabase Auth/Postgres/RLS
          └─ Kotlin MethodChannel (allow-listed Android actions)
```

The Python FastAPI AI service is an optional future boundary. The MVP parser
must continue to work without a network or an LLM. A configured AI endpoint is
never allowed to bypass the Dart tool registry.

## 2. Canonical action pipeline

```text
voice or text
  → transcript
  → intent + entities
  → ToolProposal(request_id)
  → proposed audit event
  → confirmation UI
  → confirmed audit event
  → ToolRegistry validation
  → repository record persistence (initial commit boundary)
  → native Android notification scheduling (for reminders)
      • if accepted: update notification_scheduled = true in repository
      • if unavailable or denied: attach warning to result, keep reminder saved
  → executed audit event (atomic commit boundary; audit failure rolls back record and cancels notification)
  → controller refresh
  → text response + optional TTS
```

`create_reminder` and `save_memory` are the only executable AI tools in MVP.
The application, not the model, owns authorization, validation, persistence,
notification scheduling, and audit writes.

## 3. Ownership and trust boundaries

| Boundary | Owner | Rule |
| --- | --- | --- |
| UI state | `NimmyController` | UI renders state; it does not write storage directly. |
| Intent | `NimmyIntentParser` / future AI service | Produces a typed proposal only. |
| Confirmation | `ConfirmationPolicy` + controller | Durable memory and reminders require confirmation. |
| Execution | `ToolRegistry` | Allow-listed tools, validation, idempotency, audit. |
| Data | `NimmyRepository` | User-scoped records only. |
| Android platform | Kotlin bridge | Only allow-listed low-risk calls; no hidden capture. |
| Cloud | Supabase client + RLS | Required cloud persistence and synchronization for authenticated users. |

The AI boundary receives no database credentials, service-role key, shell
access, filesystem access, or unrestricted Android API access.

## 4. Persistence and offline-first architecture

Supabase PostgreSQL with user-scoped Row Level Security (RLS) is the canonical
production persistence layer for NIMMY, verified against SQL migrations
001–015 and authenticated user profiles. Local Hive storage serves as the
immediate UI backing store and offline-first cache via `OfflineFirstNimmyRepository`.

When connected and authenticated, writes and audit events synchronize to Supabase
under RLS isolation. In offline or unauthenticated mode, records are persisted
locally in Hive and flagged with a clear sync warning until cloud synchronization
can be established. Offline mutation reconciliation and multi-device conflict
resolution are formally verified against Supabase RLS policies.

## 5. Android responsibilities

Kotlin owns only Android-specific capabilities that Flutter cannot safely own:

- app/deep-link launch checks;
- device information needed by the UI;
- user-confirmed inexact reminder alarms and notification delivery;
- spoken responses through Android `TextToSpeech`;
- future platform integrations behind an explicit allow-list.

Microphone use is initiated by the visible voice screen and uses the speech
plugin. The MVP does not register a recording foreground service and does not
capture audio in the background. Full recording requires a separate Android
foreground-service design, notification, retention policy, and device tests.

## 6. Configuration

Runtime values are injected through `--dart-define` or a secure build system:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
NIMMY_AI_BASE_URL
NIMMY_TIMEZONE
```

No service-role key or provider secret belongs in Flutter, Kotlin, or the web
bundle. Missing configuration is a supported local-only mode.

## 7. Deferred services

Next.js, FastAPI, Go, Rust, C++, pgvector, RAG, messaging integrations,
recording transcription, knowledge graph, and autonomous agents are future
boundaries. They may be added only behind the same typed tools, permissions,
confirmation policy, and audit contract.
