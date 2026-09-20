# NIMMY — AI API and Tool Registry Contract

Status: canonical production boundary for the current MVP and future extensions.

This document separates what is implemented from what is designed. A model may
understand a request and propose a typed tool. Only the application executor may
validate, authorize, confirm, execute, persist, schedule, or audit a side effect.

## 1. Non-negotiable trust boundary

```text
voice/text
  → transcript
  → provider-neutral AI proposal
  → typed tool registry
  → schema validation
  → authorization and permission checks
  → confirmation policy
  → controlled executor
  → database / Android / external API
  → audit
  → response / TTS
```

The AI service must not receive database credentials, service-role keys, shell
access, arbitrary filesystem access, or unrestricted Android access. A model
response is never evidence that an action happened.

## 2. Provider-neutral AI interface

The application-facing contract is provider-neutral. OpenAI, Gemini, a local
model, or a deterministic parser may implement the understanding boundary, but
all providers return the same proposal shape.

```python
class AIProvider(Protocol):
    async def understand(
        self,
        request: UnderstandingRequest,
    ) -> UnderstandingResponse: ...
```

`UnderstandingRequest` contains a user-scoped request ID, source (`voice` or
`text`), transcript, locale/timezone, bounded conversation context, and only the
retrieval results explicitly selected by the application. It must not contain
secrets or unrestricted database access.

`UnderstandingResponse` contains:

```json
{
  "request_id": "uuid",
  "reply": "string",
  "intent": "create_reminder",
  "entities": {},
  "tool_proposals": [],
  "needs_clarification": false,
  "clarification_question": null,
  "confidence": 0.0,
  "provider": "deterministic|openai|gemini|local",
  "model": "string|null"
}
```

Confidence is advisory only. It never bypasses validation or confirmation.

## 3. Common tool proposal envelope

```json
{
  "request_id": "uuid",
  "tool": "create_reminder",
  "source": "voice",
  "input": {},
  "original_text": "Remind me tomorrow at 8 PM to submit the project",
  "requires_confirmation": true
}
```

The request ID is stable across proposal, confirmation, retry, execution, and
audit. Repeated execution with the same user and request ID is idempotent.

## 4. Registry metadata

Every registered tool declares:

| Field | Meaning |
|---|---|
| `name` | Stable allow-listed name |
| `input_schema` | Typed validation schema |
| `risk_level` | `read`, `local_write`, `important_write`, `external`, or `destructive` |
| `requires_confirmation` | Confirmation policy result, not model choice |
| `requires_auth` | User/session authorization requirement |
| `offline_support` | Whether local execution is supported |
| `audit_required` | Whether a lifecycle audit is mandatory |
| `executor` | Application-owned implementation |

## 5. Executable MVP tools

### `create_reminder`

Input: trimmed title, future UTC instant, IANA timezone, optional recurrence,
optional notes, and stable request ID.

Risk: `local_write`. Confirmation: required by current MVP policy. Execution:
validate → authorize user ownership → confirm → persist → schedule local alarm
if supported → write executed audit → return truthful result.

The response must distinguish “record saved” from “notification scheduled”. A
scheduler failure cannot be reported as a successful notification.

### `save_memory`

Input: trimmed content, typed category, importance, provenance, and request ID.

Risk: `local_write`. Confirmation: required for durable memory. AI inference may
produce a candidate, but it cannot silently become permanent memory.

Execution: validate → confirm → persist with source/timestamps → audit → return
the record ID. Correction and supersession history are future memory-phase work.

## 6. Designed, not executable yet

The following names are reserved but must not return successful execution in the
current MVP:

`create_task`, `edit_task`, `complete_task`, `delete_task`, `reschedule_task`,
`create_note`, `search_memory` as an AI mutation workflow, calendar operations,
recording operations, messaging, app actions, Bluetooth, planning, automation,
and external knowledge actions.

Until each has schema validation, authorization, permissions, confirmation,
executor, audit, error recovery, tests, and applicable device/integration proof,
the service must return an explicit unavailable/clarification response rather
than a fabricated success.

## 7. Risk policy

| Level | Examples | Default |
|---|---|---|
| Read | retrieve a saved reminder or memory | no confirmation, still authorized and audited where meaningful |
| Local write | create reminder or memory | confirmation in current MVP |
| Important write | edit/delete durable data | explicit confirmation |
| External | send/share/calendar mutation | explicit confirmation plus integration authorization |
| Destructive | account/data deletion or disconnect | strong confirmation and re-authentication |

The model cannot lower a tool's risk level.

## 8. Error contract

All provider and executor failures map to a stable error envelope:

```json
{
  "success": false,
  "code": "TOOL_VALIDATION_FAILED",
  "message": "The reminder time is in the past.",
  "recovery": "Edit the time or cancel the request.",
  "retryable": false,
  "request_id": "uuid"
}
```

Required classes include invalid input, provider timeout, unavailable provider,
clarification required, unauthorized, permission denied, offline, tool
validation failure, confirmation timeout, executor failure, persistence failure,
and audit failure. No error path may return a success message.

## 9. Audit lifecycle

Meaningful actions use the same request ID for `proposed`, `confirmed`,
`cancelled`, `failed`, and `executed` events. An executed event is emitted only
after the corresponding durable write succeeds. Retries must be idempotent.
Raw audio, secrets, provider keys, and unnecessary private prompts are excluded
from audit metadata.

## 10. Current implementation map

| Boundary | Current implementation | Status |
|---|---|---|
| Deterministic intent parsing | `apps/mobile/lib/services/ai/intent_parser.dart` | Implemented for MVP intents |
| Typed registry and execution | `apps/mobile/lib/services/tools/tool_registry.dart` | Implemented for `create_reminder` and `save_memory` |
| Confirmation and controller workflow | `apps/mobile/lib/core/state/nimmy_controller.dart` | Implemented; tests/device proof remain incomplete |
| Local persistence | Hive repository | Implemented local path |
| Optional cloud mirror | Offline-first Supabase repository | Implemented boundary; auth/RLS/live verification incomplete |
| FastAPI AI service | `services/ai-brain` | Partial/future boundary; must remain proposal-only |
| Wake/STT/TTS | Flutter + Kotlin bridge | Partial; trained wake model and physical-device proof missing |

## 11. Production gates before expanding scope

Do not add a new AI tool because a model can describe it. Add it only after the
tool contract, permission matrix, database/API contract, failure recovery,
offline/sync behavior, audit behavior, automated tests, and real integration or
device evidence exist. Until then it remains `NOT_STARTED`, `IN_PROGRESS`, or
`BLOCKED` in the feature matrix.
