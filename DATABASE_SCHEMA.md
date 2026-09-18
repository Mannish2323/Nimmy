# NIMMY — Database Schema Contract

Status: MVP persistence contract

## 1. Migration order

The repository contains legacy product tables in migrations `001`–`014`. The
canonical MVP action migration is `015_mvp_action_foundation.sql`; it extends
the legacy `users`, `reminders`, and `memories` tables and adds the append-only
audit and preference tables. Migration numbers must remain unique.

## 2. MVP cloud entities

### `users` (legacy profile source)

`id UUID`, `auth_id UUID`, `email`, `display_name`, `timezone`, `language`,
`created_at`, and `updated_at`. `auth_id` is matched to `auth.uid()` by RLS.
The canonical `profiles` view exposes the product vocabulary without creating
a second profile record.

### `reminders`

| Column | Type | Contract |
| --- | --- | --- |
| `id` | UUID | Stable record ID. |
| `user_id` | UUID | References `users.id`; RLS-owned. |
| `request_id` | UUID | Idempotency key, unique per user. |
| `title` | text | Required, trimmed. |
| `message` | text | Optional notes. |
| `remind_at` | timestamptz | Stored in UTC. |
| `timezone` | text | IANA timezone used for interpretation. |
| `status` | legacy enum | `pending`, `triggered`, `snoozed`, `dismissed`; client maps terminal states. |
| `recurrence_rule` | text | Optional MVP recurrence descriptor. |
| `source` | text | `voice`, `text`, or `system`. |
| `notification_scheduled` | boolean | True only after the scheduler accepts it. |
| `created_at`, `updated_at` | timestamptz | Auditability and sync. |

### `memories`

The legacy table remains the storage table. MVP adds `request_id` and
`source_reference` and uses the existing `memory_type`, `source`, `content`,
`importance`, `is_active`, `created_at`, and `updated_at` columns.

`request_id` is the idempotency key. `memory_type` maps to the typed client
categories: `preference`, `goal`, `project`, `person`, `decision`,
`reminder_context`, `note`, and `other`. `source` records provenance and is
never treated as model retraining.

### `audit_logs`

Append-only, user-scoped action history:

```text
id, user_id, action_type, tool_name, request_id,
source, status, metadata, error_code, created_at, executed_at
```

`status` is `proposed`, `confirmed`, `executed`, `failed`, or `cancelled`.
Authenticated clients have insert/select access for their own rows; no update
or delete policy is created.

### `user_preferences`

One row per user for timezone, language, voice/notification flags, reduced
motion, and a future confirmation-policy JSON object.

## 3. Local storage

The default repository uses Hive boxes:

```text
nimmy_reminders_v1
nimmy_memories_v1
nimmy_audit_v1
```

Values are JSON snapshots of the typed Dart models. `InMemoryNimmyRepository`
is used only by tests and previews.

## 4. Security rules

- Every cloud query filters by the authenticated profile ID.
- RLS is enabled for users, reminders, memories, audit logs, preferences, and
  device sessions.
- `owns_nimmy_user(user_id)` is a security-definer predicate restricted to the
  authenticated role.
- Service-role credentials are server-only and are not required by the mobile
  app.
- Client writes use UUIDs and `request_id` uniqueness to avoid duplicate
  actions after retries.

## 5. Future entities

Projects, tasks, calendar events, notes, recordings, transcripts,
conversations, automations, scheduled messages, devices, embeddings, and
feedback/corrections already have design space or legacy migrations, but are
not claimed as MVP workflows until their tool, permission, error, and audit
contracts are implemented and tested.

