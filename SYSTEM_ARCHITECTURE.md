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
  → repository transaction
  → native Android notification (reminders)
  → executed audit event
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
| Cloud | Supabase client + RLS | Optional mirror for an authenticated user. |

The AI boundary receives no database credentials, service-role key, shell
access, filesystem access, or unrestricted Android API access.

## 4. Local-first behavior

Hive is the immediate source for the user experience. If Supabase is configured
and an authenticated session exists, `OfflineFirstNimmyRepository` mirrors the
same records to Supabase on a best-effort basis. Cloud failures keep the local
action visible and produce a warning rather than a false cloud-success claim.

The current MVP sync is an idempotent mirror based on stable record IDs and
`request_id`. A durable deletion outbox and conflict-resolution UI are Phase 2
work; until then, cloud sync is clearly presented as optional.

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
