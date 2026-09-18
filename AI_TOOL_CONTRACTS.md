# NIMMY — AI Tool Contracts

Status: MVP contract; application execution is authoritative

The model or parser may propose a tool. It may not call a database, scheduler,
filesystem, shell, or Android API directly. The Dart `ToolRegistry` validates
the typed proposal and owns the side effect.

## Common envelope

```json
{
  "request_id": "uuid",
  "tool": "create_reminder",
  "source": "voice",
  "input": {},
  "original_text": "Nimmy, ..."
}
```

`request_id` is generated before confirmation and remains stable through
proposal, confirmation, execution, retry, and audit. A repeated request is
idempotent rather than creating a second record.

## `create_reminder`

### Input

```json
{
  "title": "Study Geography",
  "scheduled_at": "2030-05-18T09:00:00.000Z",
  "timezone": "Asia/Kolkata",
  "recurrence": null,
  "notes": null
}
```

Rules:

- `title` is required and trimmed.
- `scheduled_at` must be a future ISO-8601 instant.
- `timezone` must be retained even though storage normalizes the instant to
  UTC.
- An ambiguous AM/PM phrase is a clarification, not a guess.
- `recurrence` is optional and must use a recognized descriptor.
- The proposal is confirmed before persistence.

### Output

```json
{
  "success": true,
  "record_id": "uuid",
  "message": "Done. Your reminder is scheduled.",
  "warning": null,
  "was_duplicate": false
}
```

If local notification scheduling is unavailable, the record may still be saved
but `warning` must say so. The app must not claim that a notification is active.

## `save_memory`

### Input

```json
{
  "content": "I want the dashboard to remain minimal.",
  "category": "preference",
  "importance": "normal",
  "source_reference": null
}
```

Rules:

- `content` is required and trimmed.
- `category` is one of `preference`, `goal`, `project`, `person`, `decision`,
  `reminder_context`, `note`, or `other`.
- `importance` is `low`, `normal`, or `high`.
- Explicit user memory requires confirmation under the MVP policy.
- Source and timestamps are attached by the application.

### Output

```json
{
  "success": true,
  "record_id": "uuid",
  "message": "Done. I saved that to your memory.",
  "warning": null,
  "was_duplicate": false
}
```

## Audit contract

The application emits `proposed`, `confirmed`, `cancelled`, `failed`, and
`executed` events with the same `request_id`. An executed event is written only
after the corresponding record write succeeds. If the audit write fails, the
tool returns a failure and rolls back the newly-created record where possible.

## Unsupported tools

`create_task`, `create_note`, `search_memory`, recording, scheduled messaging,
app actions, planning, and automation are not executable in this MVP. Their UI
must be labeled `COMING SOON` or `NOT AVAILABLE`; no successful result may be
fabricated.

