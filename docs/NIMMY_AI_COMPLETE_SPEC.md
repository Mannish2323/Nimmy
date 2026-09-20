# NIMMY — Complete AI Stack & Tool Registry Specification

> **Status:** Design specification. Each section carries its own implementation status.
> Canonical trust-boundary rules: [`NIMMY_AI_API_TOOL_REGISTRY.md`](../NIMMY_AI_API_TOOL_REGISTRY.md)
> Database contract: [`DATABASE.md`](DATABASE.md)
> Permission matrix: [`PERMISSION_CONFIRMATION_MATRIX.md`](../PERMISSION_CONFIRMATION_MATRIX.md)

---

## Table of Contents

1. [Golden Rule](#1-golden-rule)
2. [Complete AI Stack Topology](#2-complete-ai-stack-topology)
3. [Provider-Neutral AI Interface](#3-provider-neutral-ai-interface)
4. [Voice System](#4-voice-system)
5. [Intent Engine](#5-intent-engine)
6. [Entity Extraction](#6-entity-extraction)
7. [Context Engine](#7-context-engine)
8. [Memory System](#8-memory-system)
9. [Knowledge Router](#9-knowledge-router)
10. [Safety Engine — 7 Layers](#10-safety-engine--7-layers)
11. [Tool Registry — Complete Specification](#11-tool-registry--complete-specification)
12. [Tool Executor & Audit](#12-tool-executor--audit)
13. [Risk Classification](#13-risk-classification)
14. [Android Native Bridge](#14-android-native-bridge)
15. [Database Contracts — Full Schema](#15-database-contracts--full-schema)
16. [Notification & Scheduling System](#16-notification--scheduling-system)
17. [Calendar Integration](#17-calendar-integration)
18. [Recording System](#18-recording-system)
19. [Semantic Memory & Embeddings](#19-semantic-memory--embeddings)
20. [Universal Search](#20-universal-search)
21. ["What Happened?" Timeline AI](#21-what-happened-timeline-ai)
22. [Automation Engine](#22-automation-engine)
23. [App Launcher](#23-app-launcher)
24. [Bluetooth Integration](#24-bluetooth-integration)
25. [Offline-First & Sync](#25-offline-first--sync)
26. [Learning & Correction System](#26-learning--correction-system)
27. [Error Contract — Full Classification](#27-error-contract--full-classification)
28. [Complete Command Workflow Example](#28-complete-command-workflow-example)
29. [Orb State Machine](#29-orb-state-machine)
30. [Production API Technology Map](#30-production-api-technology-map)
31. [Implementation Status per Component](#31-implementation-status-per-component)

---

## 1. Golden Rule

```text
AI CAN THINK
AI CAN PROPOSE
AI CAN SELECT A TOOL
AI CANNOT DIRECTLY EXECUTE
```

The full execution chain is always:

```text
voice/text
  -> transcript
  -> provider-neutral AI proposal (UnderstandingResponse)
  -> typed ToolProposal (request_id generated here, stable forever)
  -> proposed audit event
  -> input schema validation
  -> authorization check (user owns data, session valid)
  -> permission check (Android permission granted where needed)
  -> risk classification
  -> confirmation gate (enforced by ToolRegistry, not just button labels)
  -> confirmed audit event
  -> Tool Executor
  -> database / Android API / external API
  -> result validation (success != claimed success)
  -> executed audit event
  -> controller state refresh
  -> TTS response + Orb state update
```

The AI service receives NO database credentials, service-role keys, shell
access, arbitrary filesystem access, or unrestricted Android API access.
A model response is never evidence that an action happened.

---

## 2. Complete AI Stack Topology

```
USER (Voice / Text / UI Tap)
  |
  v
WAKE-WORD LAYER
  "Hey Nimmy" / "Nimmy"
  On-device ONNX model
  Foreground service
  |
  | WAKE_DETECTED event (metadata only, no raw audio)
  v
VOICE LAYER
  VAD -> STT -> Transcript
  Barge-in cancel
  |
  | transcript: string
  v
AI ORCHESTRATOR
  NimmyController (Dart)
  + FastAPI AI Service (future)
  |
  +---> Intent Engine          +---> Safety Engine
  |     Entity Extraction      |     Permission Check
  |     Context Engine         |     Risk Classification
  |                            |
  +-------- Memory Engine -----+
            SQL Memory | Vector Memory
            pgvector semantic search
                  |
                  v
            Knowledge Router
            Personal | Task | Calendar | Web | AI
                  |
                  v
            TOOL REGISTRY
              Schema Validation
              Authorization
              Confirmation Policy
              Idempotency (request_id)
              |
              +---> Confirmation Gate
              |
              v
           Tool Executor
              |
         +----+----+
         v         v         v
     Supabase  Android APIs  External APIs
     PostgreSQL AlarmManager  Google Cal
     Hive local FCM           OAuth
         |         |           |
         +----+----+-----------+
              |
           AUDIT LOG
              |
           TTS / ORB
```

---

## 3. Provider-Neutral AI Interface

### 3.1 AIProvider Protocol (Python / Dart)

```python
class AIProvider(Protocol):
    async def understand(
        self,
        request: UnderstandingRequest,
    ) -> UnderstandingResponse: ...
```

### 3.2 UnderstandingRequest

```json
{
  "request_id": "uuid-stable",
  "source": "voice | text",
  "transcript": "Remind me tomorrow at 8 PM to submit the project",
  "locale": "en-IN",
  "timezone": "Asia/Kolkata",
  "current_datetime_utc": "2026-09-20T16:30:00Z",
  "conversation_context": [
    { "role": "user", "content": "..." },
    { "role": "nimmy", "content": "..." }
  ],
  "retrieved_memories": [],
  "retrieved_tasks": [],
  "user_preferences": {}
}
```

Must NOT contain: database credentials, service-role key, raw audio bytes,
shell commands, arbitrary SQL, unrestricted Android API tokens.

### 3.3 UnderstandingResponse

```json
{
  "request_id": "uuid-stable",
  "reply": "Reminder kal 8 PM ko submit the project ke liye. Confirm karein?",
  "intent": "create_reminder",
  "entities": {
    "title": "Submit the project",
    "date_expression": "tomorrow",
    "time_expression": "8 PM",
    "resolved_at_utc": "2026-09-21T14:30:00Z",
    "timezone": "Asia/Kolkata"
  },
  "tool_proposals": [
    {
      "tool": "create_reminder",
      "input": {
        "title": "Submit the project",
        "scheduled_at": "2026-09-21T14:30:00Z",
        "timezone": "Asia/Kolkata",
        "recurrence": null,
        "notes": null
      }
    }
  ],
  "needs_clarification": false,
  "clarification_question": null,
  "confidence": 0.97,
  "provider": "gemini | openai | deterministic | local",
  "model": "gemini-2.0-flash | gpt-4o | null"
}
```

`confidence` is advisory only. It never bypasses validation or confirmation.

### 3.4 Supported Providers

| Provider | Text/Intent | Realtime Voice | Function Calling | Status |
|---|---|---|---|---|
| Gemini 2.0 Flash | Yes | Gemini Live API | Yes native | Future |
| OpenAI GPT-4o | Yes | OpenAI Realtime API | Yes native | Future |
| Deterministic Parser | Yes (MVP intents) | N/A | N/A | **MVP — implemented** |
| Local model | Yes (offline fallback) | N/A | N/A | Future |

Architecture must allow swapping providers without changing the tool registry,
confirmation policy, or audit system.

---

## 4. Voice System

### 4.1 Wake Word Engine

| Property | Value |
|---|---|
| Trigger phrases | "Hey Nimmy", "Nimmy" |
| Technology | openWakeWord-compatible ONNX classifier |
| Asset required | `apps/mobile/android/app/src/main/assets/wakeword/nimmy.onnx` |
| Runs on | Android foreground service (visible notification required) |
| Output to Flutter | EventChannel — metadata only, no raw audio bytes |
| Fallback | Text input / manual microphone tap |
| Current status | Service boundary implemented; ONNX model absent — WAKE_ENGINE_UNAVAILABLE reported |

Privacy rule: The wake detector has no database, network, tool, or
repository dependency. Raw microphone audio never crosses the EventChannel.

### 4.2 VAD — Voice Activity Detection

```
States:
  IDLE
  SPEECH_STARTED  (energy threshold exceeded)
  SPEECH_ACTIVE   (ongoing)
  SILENCE_DETECTED (trailing silence window)
  COMMAND_COMPLETE -> trigger STT
  TIMEOUT -> cancel, return to IDLE
```

Parameters: silence threshold 800ms default, max command duration 30s,
noise floor calibrated per session.

### 4.3 STT — Speech to Text

| Property | Value |
|---|---|
| MVP implementation | Android SpeechRecognizer via Kotlin bridge |
| Provider option A | Google on-device STT (no internet needed) |
| Provider option B | Google Cloud Speech-to-Text / OpenAI Whisper (cloud) |
| Locale | en-IN default; user-configurable |
| Output | Plain transcript string |
| Failure handling | STT_FAILED error -> text fallback offered |
| Privacy | Transcript is the only data passed upward; audio file not retained in MVP |

### 4.4 TTS — Text to Speech

| Property | Value |
|---|---|
| MVP implementation | Android TextToSpeech via Kotlin MethodChannel |
| Provider option | Google Cloud TTS / OpenAI TTS (for Nimmy voice persona) |
| Barge-in | TTS stops immediately on new wake or user tap |
| Orb sync | Orb enters SPEAKING state while TTS plays; IDLE on complete |

### 4.5 Barge-in Protocol

```
Nimmy speaking (TTS active, Orb = SPEAKING)
  -> User says "Nimmy stop" OR taps screen
  -> TTS.stop() called immediately
  -> Orb -> IDLE
  -> Wake detector resumed
  -> Partial TTS output is NOT logged as a complete response
```

### 4.6 Voice Pipeline Summary

```
WAKE_DETECTED
  -> VAD: LISTENING
  -> VAD: SPEECH_ACTIVE
  -> VAD: SILENCE_DETECTED -> COMMAND_COMPLETE
  -> STT -> transcript
  -> UnderstandingRequest -> AI Orchestrator
  -> UnderstandingResponse
  -> ToolProposal (if intent resolved)
  -> Confirmation gate
  -> Tool Executor
  -> TTS response
  -> Orb SUCCESS -> IDLE
```

---

## 5. Intent Engine

### 5.1 Purpose

Maps a natural-language transcript to a structured intent + typed tool proposal.
Must never guess when ambiguous — must ask a clarification question instead.

### 5.2 MVP Deterministic Parser

Handles a fixed set of patterns without requiring a cloud AI call:

| Pattern | Intent |
|---|---|
| "remind me ... at ... to ..." | `create_reminder` |
| "set a reminder ..." | `create_reminder` |
| "remember that ..." | `save_memory` |
| "Nimmy, note that ..." | `save_memory` |
| Unknown pattern | `unknown` -> AI fallback or clarification |

File: `apps/mobile/lib/services/ai/intent_parser.dart`

### 5.3 AI-based Intent (Future)

Full LLM intent engine with system prompt, function schemas, and conversation
history. Returns the same `UnderstandingResponse` envelope.

### 5.4 Intent Categories

```
TASK:        create_task, edit_task, complete_task, delete_task, reschedule_task
REMINDER:    create_reminder, edit_reminder, delete_reminder, snooze_reminder
NOTE:        create_note, search_notes, delete_note
MEMORY:      save_memory, search_memory, edit_memory, delete_memory
CALENDAR:    create_calendar_event, edit_calendar_event, delete_calendar_event
QUERY:       what_happened, plan_day, plan_week, search_everything
RECORDING:   start_recording, stop_recording, pause_recording, resume_recording
SYSTEM:      open_app, send_message, plan_automation
READ:        get_tasks, get_reminders, get_memories, get_calendar
UNKNOWN:     clarification required
```

---

## 6. Entity Extraction

### 6.1 Entities Extracted Per Intent

#### Reminder entities

```json
{
  "title": "Submit the project",
  "date_expression": "tomorrow",
  "time_expression": "8 PM",
  "resolved_at_utc": "2026-09-21T14:30:00Z",
  "timezone": "Asia/Kolkata",
  "recurrence": null,
  "am_pm_ambiguous": false,
  "location": null
}
```

Ambiguity rule: If AM/PM cannot be resolved from context, Nimmy asks:
"8 AM ya 8 PM?" — never guesses.

#### Task entities

```json
{
  "title": "Finish Nimmy backend",
  "priority": "high | medium | low",
  "due_date_utc": "2026-09-21T00:00:00Z",
  "project": "Nimmy",
  "assignee": null,
  "recurrence": null
}
```

#### Memory entities

```json
{
  "content": "I prefer dark mode",
  "category": "preference | goal | project | person | decision | note | other",
  "importance": "high | normal | low",
  "source": "USER_EXPLICIT | USER_CORRECTION | AI_INFERENCE"
}
```

#### Calendar entities

```json
{
  "title": "Team review meeting",
  "start_utc": "2026-09-22T10:00:00Z",
  "end_utc": "2026-09-22T11:00:00Z",
  "timezone": "Asia/Kolkata",
  "location": "Office",
  "attendees": [],
  "calendar_id": "primary"
}
```

### 6.2 Timezone Resolution Rules

1. Stored preference -> use `user.timezone`
2. Device timezone -> fallback
3. Explicit phrase ("in Mumbai time") -> override
4. All stored instants are UTC; timezone string retained for display and rescheduling

---

## 7. Context Engine

### 7.1 Purpose

Resolves ambiguous references using conversation history, recent activity, and
memory — without guessing.

### 7.2 Context Sources (in priority order)

```
1. Current message
2. Last 10 conversation turns (bounded window)
3. Recent tasks (last 24h)
4. Recent reminders (next 48h)
5. Recent memories (top 5 by recency + importance)
6. Calendar events (today + tomorrow)
7. Timeline (last "what happened" result)
```

### 7.3 Ambiguity Resolution

```
User: "Reminder laga do."
Nimmy: "Kis cheez ka reminder?"

User: "Jo kal discuss kiya tha."
Context Engine:
  -> scan conversation history for yesterday's topics
  -> scan recent notes/memories for yesterday's date
  -> find candidates
  -> if single candidate: propose with confirmation
  -> if multiple candidates: "Mere paas 2 options hain: 'Project review' ya 'Database migration'?"
  -> if no candidate: "Mujhe thoda aur detail chahiye."
```

Rule: Context Engine NEVER silently picks a candidate. Ambiguous references
always surface to the user.

---

## 8. Memory System

### 8.1 Memory Categories

| Category | Description | Example |
|---|---|---|
| `PROFILE` | Who the user is | "My name is Manish" |
| `PREFERENCE` | How user likes things | "Dark mode prefer karta hoon" |
| `GOAL` | Long-term objectives | "MBA complete karna hai 2027 tak" |
| `PROJECT` | Active projects | "Nimmy project — AI OS" |
| `KNOWLEDGE` | Factual info user shared | "Office is in Bandra West" |
| `IDEA` | Loose ideas to revisit | "Nimmy mein automation add karna hai" |
| `EVENT` | Important past events | "Client meeting happened Sept 15" |
| `CORRECTION` | User corrections to prior AI output | "Time 9 PM tha, 8 PM nahi" |

### 8.2 Memory Sources

| Source | Trust Level |
|---|---|
| `USER_EXPLICIT` | Highest |
| `USER_CONFIRMED` | High |
| `USER_CORRECTION` | High (overrides prior) |
| `USER_NOTE` | Medium-High |
| `USER_RECORDING` | Medium (needs confirmation gate) |
| `CALENDAR` | Medium |
| `TASK_DATABASE` | Medium |
| `CONNECTED_SERVICE` | Medium |
| `EXTERNAL_SOURCE` | Low |
| `AI_INFERENCE` | Lowest — never permanent without confirmation |

### 8.3 Conflict Priority

```
CURRENT USER INSTRUCTION
> USER CONFIRMED DATA
> RECENT INFORMATION (< 24h)
> SAVED MEMORY
> CONNECTED DATA
> AI INFERENCE
```

### 8.4 Memory Operations

| Operation | Tool | Confirmation | Risk Level |
|---|---|---|---|
| Save | `save_memory` | Required | `local_write` |
| Search (text) | `search_memory` | None | `read` |
| Semantic search | `search_memory_semantic` | None | `read` |
| Edit | `edit_memory` | Required | `important_write` |
| Delete | `delete_memory` | Destructive | `important_write` |
| Archive | `archive_memory` | Required | `important_write` |
| Confirm AI inference | `confirm_memory` | Required | `local_write` |

### 8.5 Correction Workflow

```
Nimmy: "Reminder set for 8 PM."
User: "No, 9 PM."

-> detect_correction intent
-> identify conflicting value (scheduled_at)
-> propose edit_reminder tool
-> confirmation: "9 PM kar doon?"
-> user confirms
-> update record
-> audit: CORRECTION event with old_value / new_value
-> save CORRECTION memory: "User prefers 9 PM for evening reminders"
-> response: "Done. 9 PM kar diya."
```

---

## 9. Knowledge Router

```
User question -> Knowledge Router
  |
  +-- Personal data?
  |     -> Memory Engine -> pgvector semantic search
  |
  +-- Task/project data?
  |     -> Task DB query
  |
  +-- Calendar data?
  |     -> Local calendar cache / Google Calendar API
  |
  +-- Current world information?
  |     -> Search provider API (web grounding)
  |
  +-- General knowledge?
  |     -> LLM directly (no tool call, no side effect)
  |
  +-- Unknown / uncertain?
        -> "Mujhe is baare mein pakki jaankari nahi hai."
           -> Do NOT hallucinate facts
```

Purpose: Reduces LLM hallucination by routing to authoritative sources
before allowing free generation.

---

## 10. Safety Engine — 7 Layers

### Layer 1 — Input Safety

Validate all incoming data before processing:

- Maximum transcript length: 2000 characters
- Strip null bytes, control characters
- Detect and block prompt injection patterns
- Reject malformed JSON in tool proposals
- Rate limiting: max 30 requests/minute per user

### Layer 2 — Intent Safety

AI output is never directly trusted:

- AI proposal must match the registered tool allow-list
- Tool name not on allow-list -> `TOOL_NOT_REGISTERED` error
- `confidence < 0.5` -> clarification required, no tool proposed
- Multi-tool proposals serialized — no parallel execution

### Layer 3 — Authorization

Per-request authorization:

```
session valid?
  -> NO: UNAUTHORIZED error
  -> YES: user_id extracted from JWT

user owns resource?
  -> reminder.user_id == session.user_id?
  -> task.user_id == session.user_id?
  -> memory.user_id == session.user_id?
  -> NO: FORBIDDEN error
```

### Layer 4 — Tool Validation

Schema validation per tool (see Tool Registry section):

```
required fields present?
types correct?
string lengths within bounds?
future datetime (for reminders)?
known enum values?
  -> any failure: TOOL_VALIDATION_FAILED
```

### Layer 5 — Confirmation Gate

```
tool.requires_confirmation == true
  -> show confirmation UI
  -> wait for explicit user action
  -> request.confirmed == true required
  -> timeout (60s) -> CONFIRMATION_TIMEOUT error
  -> user cancel -> CANCELLED audit event
```

Confirmation is enforced in `ToolRegistry.execute()`, not just the UI.
Calling `execute()` without `confirmed: true` returns `CONFIRMATION_REQUIRED`.

### Layer 6 — Execution Sandbox

AI has NO access to:

```
X  Raw SQL queries
X  Shell commands
X  Arbitrary Android Intents
X  Direct Supabase service-role key
X  Filesystem outside app sandbox
X  Other users' data
X  Background recording without foreground service
```

All Android calls go through the Kotlin MethodChannel allow-list.

### Layer 7 — Audit

Every meaningful action produces an audit trail:

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "action_type": "CREATE_REMINDER",
  "tool_name": "create_reminder",
  "request_id": "uuid-stable-across-lifecycle",
  "source": "voice | text",
  "status": "proposed | confirmed | executed | failed | cancelled",
  "metadata": {
    "title": "Submit the project",
    "scheduled_at": "2026-09-21T14:30:00Z"
  },
  "error_code": null,
  "created_at": "2026-09-20T16:30:00Z",
  "executed_at": "2026-09-20T16:30:05Z"
}
```

Excluded from audit metadata: raw audio, passwords, API keys, provider
secret prompts, unnecessary private data.

---

## 11. Tool Registry — Complete Specification

Every tool entry:

```json
{
  "name": "tool_name",
  "description": "...",
  "input_schema": {},
  "output_schema": {},
  "risk_level": "read | local_write | important_write | external | destructive",
  "requires_confirmation": true,
  "requires_auth": true,
  "android_permission": null,
  "offline_support": true,
  "audit_required": true,
  "executor": "ApplicationOwned",
  "implementation_status": "COMPLETE | IN_PROGRESS | NOT_STARTED"
}
```

---

### 11.1 REMINDER TOOLS

#### `create_reminder` — Status: COMPLETE (MVP)

Risk: `local_write` | Confirmation: required | Permission: `POST_NOTIFICATIONS`
Offline: yes | Audit: yes

Input:
```json
{
  "title": "Submit the project",
  "scheduled_at": "2026-09-21T14:30:00Z",
  "timezone": "Asia/Kolkata",
  "recurrence": null,
  "notes": null
}
```

Validation rules:
- `title`: required, trimmed, 1-500 chars
- `scheduled_at`: required, future ISO-8601 UTC instant
- `timezone`: required, valid IANA timezone
- `recurrence`: null or one of `daily | weekly | monthly | yearly | weekdays`
- Ambiguous AM/PM -> `CLARIFICATION_REQUIRED`, do not guess

Execution chain:
```
validate schema
-> authorize user session
-> check POST_NOTIFICATIONS permission (warn if missing, don't block)
-> confirmation gate
-> INSERT reminders (with request_id for idempotency)
-> schedule Android AlarmManager notification
-> write executed audit
-> return result
```

Output (success):
```json
{
  "success": true,
  "record_id": "uuid",
  "message": "Done. I'll remind you tomorrow at 8 PM.",
  "warning": null,
  "notification_scheduled": true,
  "was_duplicate": false
}
```

Output (saved but notification unavailable):
```json
{
  "success": true,
  "record_id": "uuid",
  "message": "Reminder saved.",
  "warning": "Notification schedule nahi ho saka. Permission check karein.",
  "notification_scheduled": false,
  "was_duplicate": false
}
```

Failure codes: `TITLE_REQUIRED`, `TIME_IN_PAST`, `INVALID_TIMEZONE`,
`CLARIFICATION_REQUIRED`, `DUPLICATE_REQUEST`, `PERSISTENCE_FAILED`,
`SCHEDULER_FAILED`, `CONFIRMATION_REQUIRED`, `UNAUTHORIZED`

---

#### `edit_reminder` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: required | Offline: yes

Input:
```json
{
  "reminder_id": "uuid",
  "title": "Submit the project (updated)",
  "scheduled_at": "2026-09-21T15:00:00Z",
  "timezone": "Asia/Kolkata",
  "recurrence": null,
  "notes": "Final version"
}
```

Validation: At least one field besides `reminder_id` must be present.
`scheduled_at` if provided must be future. Cancel old alarm before setting new.

---

#### `delete_reminder` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: destructive | Offline: yes

Input: `{ "reminder_id": "uuid" }`

Execution: Cancel scheduled alarm first -> soft-delete record -> audit.

---

#### `snooze_reminder` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: none (triggered from notification action)

Input: `{ "reminder_id": "uuid", "snooze_minutes": 10 }`

---

### 11.2 TASK TOOLS

#### `create_task` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: required | Offline: yes | Audit: yes

Input:
```json
{
  "title": "Finish Nimmy backend",
  "priority": "high",
  "due_date_utc": "2026-09-21T18:30:00Z",
  "timezone": "Asia/Kolkata",
  "project_id": null,
  "notes": null,
  "recurrence": null,
  "tags": []
}
```

Validation: `title` required, `priority` in `[high, medium, low]`,
`due_date_utc` must be valid ISO-8601 or null.

---

#### `edit_task` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: required

Input:
```json
{
  "task_id": "uuid",
  "title": null,
  "priority": "medium",
  "due_date_utc": null,
  "notes": null,
  "tags": null
}
```

Rule: Partial update — only provided non-null fields are modified.

---

#### `complete_task` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: none (low-risk positive action)

Input: `{ "task_id": "uuid", "completed_at_utc": "2026-09-20T12:00:00Z" }`

---

#### `delete_task` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: destructive

Input: `{ "task_id": "uuid" }`

---

#### `reschedule_task` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: required | Audit: yes (reason captured)

Input:
```json
{
  "task_id": "uuid",
  "new_due_date_utc": "2026-09-25T18:30:00Z",
  "reason": "Client requested extension"
}
```

---

### 11.3 NOTE TOOLS

#### `create_note` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: configurable | Offline: yes | Audit: yes

Input:
```json
{
  "title": null,
  "content": "Meeting notes: decided to use FastAPI for AI backend.",
  "tags": ["meeting", "architecture"],
  "linked_task_id": null,
  "linked_project_id": null
}
```

---

#### `search_notes` — Status: NOT_STARTED

Risk: `read` | Confirmation: none

Input:
```json
{
  "query": "FastAPI meeting",
  "tags": [],
  "date_from": null,
  "date_to": null,
  "limit": 10
}
```

---

#### `delete_note` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: destructive

Input: `{ "note_id": "uuid" }`

---

### 11.4 MEMORY TOOLS

#### `save_memory` — Status: COMPLETE (MVP)

Risk: `local_write` | Confirmation: required | Offline: yes | Audit: yes

Input:
```json
{
  "content": "I prefer dark mode always.",
  "category": "preference",
  "importance": "normal",
  "source_reference": null
}
```

Validation:
- `content`: required, trimmed, 1-2000 chars
- `category`: one of `preference | goal | project | person | decision | reminder_context | note | other`
- `importance`: one of `low | normal | high`
- AI inference must not become permanent memory without USER_EXPLICIT or USER_CONFIRMED source

Output (success):
```json
{
  "success": true,
  "record_id": "uuid",
  "message": "Done. I saved that to your memory.",
  "warning": null,
  "was_duplicate": false
}
```

Failure codes: `CONTENT_REQUIRED`, `INVALID_CATEGORY`, `INVALID_IMPORTANCE`,
`DUPLICATE_REQUEST`, `PERSISTENCE_FAILED`, `CONFIRMATION_REQUIRED`

---

#### `search_memory` — Status: NOT_STARTED (as AI tool; text filter in Memory UI available)

Risk: `read` | Confirmation: none | Offline: partial (no vector search offline)

Input:
```json
{
  "query": "dark mode preference",
  "category": null,
  "search_type": "text | semantic | hybrid",
  "limit": 10,
  "min_importance": null
}
```

---

#### `edit_memory` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: required

Input:
```json
{
  "memory_id": "uuid",
  "content": "I prefer dark mode, but light mode is okay outdoors.",
  "importance": "high"
}
```

Rule: Previous content preserved in history. Source updated to `USER_EXPLICIT`.

---

#### `delete_memory` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: destructive

Input: `{ "memory_id": "uuid" }`

---

#### `confirm_memory` — Status: NOT_STARTED

Promotes AI-inferred memory candidate to `USER_CONFIRMED` source.

Risk: `local_write` | Confirmation: user action itself is the confirmation

Input: `{ "memory_candidate_id": "uuid", "confirmed": true }`

---

### 11.5 CALENDAR TOOLS

#### `create_calendar_event` — Status: NOT_STARTED

Android permission required: Calendar read/write (not requested in MVP)
External auth required: Google OAuth calendar scope
Risk: `external` | Confirmation: required | Offline: queue + sync

Input:
```json
{
  "title": "Team Review Meeting",
  "start_utc": "2026-09-22T10:00:00Z",
  "end_utc": "2026-09-22T11:00:00Z",
  "timezone": "Asia/Kolkata",
  "location": "Office",
  "description": null,
  "attendees": ["rahul@example.com"],
  "calendar_id": "primary",
  "recurrence": null,
  "provider": "google"
}
```

---

#### `edit_calendar_event` — Status: NOT_STARTED

Risk: `external` | Confirmation: required

---

#### `delete_calendar_event` — Status: NOT_STARTED

Risk: `external` | Confirmation: destructive

---

### 11.6 RECORDING TOOLS

#### `start_recording` — Status: NOT_STARTED

Android requirements:
- `RECORD_AUDIO` permission (runtime, must be granted before call)
- Foreground service with `microphone` service type
- Visible persistent notification with Stop action
- `FOREGROUND_SERVICE_MICROPHONE` permission

Risk: `local_write` | Confirmation: required (user initiates explicitly)

Input:
```json
{
  "label": "Client meeting recording",
  "retention_days": 7,
  "auto_transcribe": true
}
```

Output:
```json
{
  "success": true,
  "session_id": "uuid",
  "message": "Recording started. Notification bar mein dikha raha hai."
}
```

---

#### `stop_recording` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: none (user-initiated stop)

Input: `{ "session_id": "uuid" }`

Execution chain:
```
stop audio capture
-> finalize audio file
-> update recording status: PROCESSING
-> trigger transcription pipeline
-> audit: RECORDING_STOPPED
-> show processing notification
```

---

#### `pause_recording` / `resume_recording` — Status: NOT_STARTED

Input: `{ "session_id": "uuid" }`

---

### 11.7 PLANNING TOOLS

#### `plan_day` — Status: NOT_STARTED

Risk: `read` | Confirmation: none | Audit: yes (AI generation logged)

Input:
```json
{
  "date_utc": "2026-09-21T00:00:00Z",
  "timezone": "Asia/Kolkata",
  "include_tasks": true,
  "include_reminders": true,
  "include_calendar": true,
  "include_memories": false
}
```

Execution:
```
gather tasks (due today)
-> gather reminders (scheduled today)
-> gather calendar events (today)
-> rank by priority + time
-> LLM: generate daily brief
-> return structured plan
```

---

#### `plan_week` — Status: NOT_STARTED

Similar to `plan_day` but spans 7 days.

---

### 11.8 SEARCH TOOLS

#### `search_everything` — Status: NOT_STARTED

Risk: `read` | Confirmation: none

Input:
```json
{
  "query": "project review last week",
  "search_type": "keyword | semantic | hybrid",
  "sources": ["tasks", "notes", "memories", "recordings", "calendar", "conversations"],
  "date_from": null,
  "date_to": null,
  "limit": 20
}
```

---

#### `what_happened` — Status: NOT_STARTED

Risk: `read` | Confirmation: none

Input:
```json
{
  "date_expression": "yesterday",
  "resolved_date_utc": "2026-09-19T00:00:00Z",
  "timezone": "Asia/Kolkata",
  "include_tasks": true,
  "include_calendar": true,
  "include_memories": true,
  "include_recordings": true,
  "include_audit": false
}
```

---

### 11.9 SYSTEM / ANDROID TOOLS

#### `open_app` — Status: NOT_STARTED

Risk: `local_write` | Confirmation: configurable | Android: no special permission for launcher intent

Input:
```json
{
  "app_name": "Telegram",
  "package_name": null,
  "deep_link": null
}
```

Execution:
```
resolve package_name from app_name (installed packages)
-> check if package is installed
-> getLaunchIntentForPackage()
-> if null: "Telegram installed nahi hai"
-> if found: startActivity(intent)
-> audit: APP_LAUNCHED
```

---

#### `send_message` — Status: NOT_STARTED

Risk: `external` | Confirmation: STRONG (always, no bypass) | Audit: yes

Input:
```json
{
  "platform": "whatsapp | telegram | sms",
  "recipient": "Rahul",
  "resolved_contact": "+91-XXXXXXXXXX",
  "message": "Meeting 5 PM pe hai.",
  "send_immediately": false
}
```

Rule: Never fake a send. If integration is unavailable, return
`INTEGRATION_UNAVAILABLE` clearly.

---

### 11.10 AUTOMATION TOOLS

#### `create_automation` — Status: NOT_STARTED

Risk: `important_write` | Confirmation: required

Input:
```json
{
  "name": "Overdue task reminder",
  "trigger": {
    "type": "task_overdue",
    "condition": { "overdue_by_hours": 24 }
  },
  "action": {
    "tool": "create_reminder",
    "input_template": {
      "title": "Task overdue: {{task.title}}",
      "scheduled_at": "{{now + 1h}}"
    }
  },
  "confirmation_required": true,
  "enabled": true
}
```

---

## 12. Tool Executor & Audit

### 12.1 Common Execution Pattern

```
ToolRegistry.execute(proposal, confirmed: true)
  -> load tool definition from registry
  -> validate input schema
  -> authorize user ownership
  -> check offline/online state
  -> emit PROPOSED audit event (if not already emitted)
  -> execute tool implementation
  -> on success:
       emit EXECUTED audit event
       return ToolResult(success: true, ...)
  -> on failure:
       emit FAILED audit event
       rollback any partial writes
       return ErrorResult(code, message, recovery, retryable)
```

### 12.2 Idempotency

Every tool proposal carries a stable `request_id` (UUID generated before
confirmation). Re-submitting with the same `user_id + request_id` is
idempotent — the existing record is returned, no duplicate is created.

### 12.3 Atomic Audit Contract

```
record write + executed audit event = atomic transaction
  -> if record write fails: no executed audit, return PERSISTENCE_FAILED
  -> if audit write fails after record write: rollback record, return AUDIT_FAILED
  -> partial states are never presented as success
```

---

## 13. Risk Classification

| Level | Name | Examples | Default Confirmation | Re-auth |
|---|---|---|---|---|
| 0 | `read` | get tasks, search memory, what happened | None | No |
| 1 | `local_write` | create reminder, save memory, create task, create note | Required (MVP policy) | No |
| 2 | `important_write` | edit/delete task, delete memory, edit reminder | Explicit required | No |
| 3 | `external` | send message, create calendar event, share file | Strong confirmation | Integration auth |
| 4 | `destructive` | delete account, clear all data, disconnect service | Strong + re-auth | Yes |

The model cannot lower a tool's risk level. Risk level is defined in the
registry, not in the AI response.

---

## 14. Android Native Bridge

### 14.1 Allow-listed Kotlin MethodChannel calls

| Method | Permission Required | MVP Status |
|---|---|---|
| `requestNotificationPermission` | — | Implemented |
| `scheduleReminder(id, title, triggerMs)` | `POST_NOTIFICATIONS` | Implemented |
| `cancelReminder(id)` | — | Implemented |
| `startTts(text, locale)` | — | Implemented |
| `stopTts()` | — | Implemented |
| `startWakeWordService()` | `RECORD_AUDIO` | Implemented (model missing) |
| `stopWakeWordService()` | — | Implemented |
| `getInstalledApps()` | — | NOT_STARTED |
| `launchApp(packageName)` | — | NOT_STARTED |
| `getDeviceInfo()` | — | NOT_STARTED |
| `getNetworkState()` | — | NOT_STARTED |
| `startRecordingService(sessionId)` | `RECORD_AUDIO`, `FOREGROUND_SERVICE_MICROPHONE` | NOT_STARTED |
| `stopRecordingService(sessionId)` | — | NOT_STARTED |
| `getBatteryInfo()` | — | NOT_STARTED |
| `getBluetoothDevices()` | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` | NOT_STARTED |

### 14.2 EventChannel streams

| Event | Payload | Status |
|---|---|---|
| `wake_word_event` | `{ "type": "WAKE_DETECTED" or "WAKE_ENGINE_UNAVAILABLE" }` | Implemented |
| `recording_state_event` | `{ "state": "RECORDING/PAUSED/STOPPED", "session_id": "uuid" }` | NOT_STARTED |
| `ble_device_event` | `{ "device_id": "...", "name": "...", "rssi": -70 }` | NOT_STARTED |

### 14.3 Foreground Services

| Service | Type | Notification Required | Status |
|---|---|---|---|
| Wake Word | `microphone` | Yes — "Nimmy is listening for wake word" | Implemented |
| Recording | `microphone` | Yes — "Recording in progress. Tap to stop." | NOT_STARTED |

Rule: No background microphone capture without a visible foreground
service notification and explicit user initiation.

---

## 15. Database Contracts — Full Schema

### 15.1 `users`

```sql
id           UUID PRIMARY KEY DEFAULT gen_random_uuid()
auth_id      UUID UNIQUE NOT NULL REFERENCES auth.users(id)
email        TEXT
display_name TEXT
timezone     TEXT NOT NULL DEFAULT 'UTC'
language     TEXT NOT NULL DEFAULT 'en'
created_at   TIMESTAMPTZ DEFAULT NOW()
updated_at   TIMESTAMPTZ DEFAULT NOW()
```

RLS: `auth_id = auth.uid()`

---

### 15.2 `reminders`

```sql
id                      UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id                 UUID NOT NULL REFERENCES users(id)
request_id              UUID NOT NULL UNIQUE
title                   TEXT NOT NULL
message                 TEXT
remind_at               TIMESTAMPTZ NOT NULL
timezone                TEXT NOT NULL
status                  TEXT NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending','triggered','snoozed','dismissed'))
recurrence_rule         TEXT
source                  TEXT NOT NULL DEFAULT 'text'
                          CHECK (source IN ('voice','text','system'))
notification_scheduled  BOOLEAN NOT NULL DEFAULT FALSE
created_at              TIMESTAMPTZ DEFAULT NOW()
updated_at              TIMESTAMPTZ DEFAULT NOW()
```

RLS: `user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())`

---

### 15.3 `tasks`

```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID NOT NULL REFERENCES users(id)
request_id      UUID NOT NULL UNIQUE
title           TEXT NOT NULL
priority        TEXT NOT NULL DEFAULT 'medium'
                  CHECK (priority IN ('high','medium','low'))
status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','in_progress','completed','cancelled'))
due_date_utc    TIMESTAMPTZ
timezone        TEXT NOT NULL DEFAULT 'UTC'
project_id      UUID REFERENCES projects(id)
notes           TEXT
tags            TEXT[] DEFAULT '{}'
recurrence_rule TEXT
completed_at    TIMESTAMPTZ
source          TEXT NOT NULL DEFAULT 'text'
created_at      TIMESTAMPTZ DEFAULT NOW()
updated_at      TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.4 `notes`

```sql
id            UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id       UUID NOT NULL REFERENCES users(id)
request_id    UUID NOT NULL UNIQUE
title         TEXT
content       TEXT NOT NULL
tags          TEXT[] DEFAULT '{}'
linked_task   UUID REFERENCES tasks(id)
source        TEXT NOT NULL DEFAULT 'text'
created_at    TIMESTAMPTZ DEFAULT NOW()
updated_at    TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.5 `memories`

```sql
id               UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id          UUID NOT NULL REFERENCES users(id)
request_id       UUID NOT NULL UNIQUE
content          TEXT NOT NULL
memory_type      TEXT NOT NULL DEFAULT 'other'
importance       TEXT NOT NULL DEFAULT 'normal'
                   CHECK (importance IN ('low','normal','high'))
source           TEXT NOT NULL DEFAULT 'USER_EXPLICIT'
source_reference TEXT
is_active        BOOLEAN NOT NULL DEFAULT TRUE
superseded_by    UUID REFERENCES memories(id)
created_at       TIMESTAMPTZ DEFAULT NOW()
updated_at       TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.6 `memory_embeddings`

```sql
id          UUID PRIMARY KEY DEFAULT gen_random_uuid()
memory_id   UUID NOT NULL REFERENCES memories(id)
user_id     UUID NOT NULL REFERENCES users(id)
embedding   VECTOR(768)
model_name  TEXT NOT NULL DEFAULT 'text-embedding-004'
created_at  TIMESTAMPTZ DEFAULT NOW()
```

Index: `CREATE INDEX ON memory_embeddings USING ivfflat (embedding vector_cosine_ops)`

---

### 15.7 `recordings`

```sql
id               UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id          UUID NOT NULL REFERENCES users(id)
session_id       UUID NOT NULL UNIQUE
label            TEXT
status           TEXT NOT NULL DEFAULT 'recording'
                   CHECK (status IN ('recording','paused','processing','complete','failed','deleted'))
audio_path       TEXT
duration_seconds INTEGER
file_size_bytes  BIGINT
retention_days   INTEGER NOT NULL DEFAULT 7
expires_at       TIMESTAMPTZ NOT NULL
retention_status TEXT NOT NULL DEFAULT 'temporary'
                   CHECK (retention_status IN ('temporary','saved','expired'))
created_at       TIMESTAMPTZ DEFAULT NOW()
updated_at       TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.8 `transcripts`

```sql
id            UUID PRIMARY KEY DEFAULT gen_random_uuid()
recording_id  UUID NOT NULL REFERENCES recordings(id)
user_id       UUID NOT NULL REFERENCES users(id)
full_text     TEXT NOT NULL
segments      JSONB
summary       TEXT
key_points    TEXT[]
decisions     TEXT[]
action_items  JSONB
follow_ups    TEXT[]
model_used    TEXT
created_at    TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.9 `audit_logs`

```sql
id           UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id      UUID NOT NULL REFERENCES users(id)
action_type  TEXT NOT NULL
tool_name    TEXT
request_id   UUID NOT NULL
source       TEXT NOT NULL DEFAULT 'text'
status       TEXT NOT NULL
               CHECK (status IN ('proposed','confirmed','executed','failed','cancelled'))
metadata     JSONB
error_code   TEXT
created_at   TIMESTAMPTZ DEFAULT NOW()
executed_at  TIMESTAMPTZ
```

No UPDATE or DELETE policy on audit_logs. Append-only.

---

### 15.10 `user_preferences`

```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id             UUID NOT NULL UNIQUE REFERENCES users(id)
timezone            TEXT NOT NULL DEFAULT 'UTC'
language            TEXT NOT NULL DEFAULT 'en'
tts_enabled         BOOLEAN DEFAULT TRUE
voice_source        TEXT DEFAULT 'android'
notification_sound  BOOLEAN DEFAULT TRUE
reduced_motion      BOOLEAN DEFAULT FALSE
confirmation_policy JSONB
created_at          TIMESTAMPTZ DEFAULT NOW()
updated_at          TIMESTAMPTZ DEFAULT NOW()
```

---

### 15.11 Future tables (designed, not MVP)

```
projects, project_members
task_subtasks
calendar_events, calendar_sync_tokens
automations, automation_executions
connected_apps, oauth_tokens
ai_conversations, ai_messages
scheduled_messages
feedback_corrections
```

---

## 16. Notification & Scheduling System

### 16.1 Local Reminder Scheduling

```
create_reminder tool executed
  -> INSERT reminders record
  -> Kotlin MethodChannel: scheduleReminder(id, title, triggerMs)
  -> AlarmManager.setExactAndAllowWhileIdle() or setAlarmClock()
  -> BroadcastReceiver fires at triggerMs
  -> NotificationManager.notify()
  -> UPDATE reminders SET status = 'triggered', notification_scheduled = true
```

Battery / Doze handling: `setAlarmClock()` bypasses Doze for
user-facing reminders. `setExactAndAllowWhileIdle()` for lower-priority.

Notification channel: `nimmy_reminders` — importance HIGH, sound enabled.

### 16.2 Firebase Cloud Messaging (server-push)

Used for: cross-device sync notifications, server-triggered alerts.
NOT a replacement for local scheduled reminders.

```
Supabase Edge Function -> FCM
  -> data payload: { type, id, title }
  -> app: show local notification from data payload
```

Android 13+ notification permission: requested at Permission Center before
scheduling any reminder.

### 16.3 WorkManager (Future)

For background sync tasks, recording cleanup, embedding generation, and
periodic digest generation.

---

## 17. Calendar Integration

### 17.1 Google Calendar OAuth Scope

```
https://www.googleapis.com/auth/calendar.events
```

Requested only when user enables Calendar integration (not in MVP).

### 17.2 API Operations

```
GET    /calendars/{calendarId}/events        list events
POST   /calendars/{calendarId}/events        create_calendar_event
PUT    /calendars/{calendarId}/events/{id}   edit_calendar_event
DELETE /calendars/{calendarId}/events/{id}   delete_calendar_event
```

### 17.3 Offline Handling

Calendar events cached in local SQLite on last successful sync.
Mutations queued in offline mutation queue when offline.
On reconnect: sync queue applied, conflicts detected by `etag` / `updated` field.

---

## 18. Recording System

### 18.1 Lifecycle States

```
READY -> RECORDING -> PAUSED -> RECORDING -> PROCESSING -> COMPLETE -> TEMPORARY | SAVED
                                                                  |
                                                               FAILED
```

### 18.2 Recording Processing Pipeline

```
AUDIO FILE
  -> STT (transcription — Whisper or Google STT)
  -> SEGMENTATION (by speaker if diarization available)
  -> SUMMARY (LLM)
  -> KEY POINTS (LLM extraction)
  -> DECISIONS (LLM extraction)
  -> ACTION ITEMS (LLM extraction — proposed tasks, NOT auto-created)
  -> FOLLOW-UPS (LLM extraction)
  -> USER REVIEW SCREEN
    -> User confirms which action items to create as create_task()
    -> User confirms which notes to save
    -> User confirms which memories to save_memory()
  -> SAVE
```

Rule: AI never auto-creates tasks or memories from recording without
the user's explicit confirmation per item.

### 18.3 Retention Policy

- Default retention: 7 days (`expires_at = created_at + 7 days`)
- On expiry: audio file deleted from Supabase Storage AND transcript soft-deleted
- Deletion is verified against storage, not just a hidden flag
- User can promote to `SAVED` (permanent) before expiry

---

## 19. Semantic Memory & Embeddings

### 19.1 Architecture

```
User saves memory
  -> content embedded: Embedding Model -> vector[768]
  -> stored: memory_embeddings (pgvector)

User asks: "Mujhe kaisa interface pasand hai?"
  -> query embedded -> vector[768]
  -> pgvector: similarity search (cosine, top-k=5)
  -> retrieve relevant memories
  -> inject into AI context
  -> AI responds with personal context
```

### 19.2 Embedding Model

| Option | Dimensions | Offline | Status |
|---|---|---|---|
| Google `text-embedding-004` | 768 | No | Preferred |
| OpenAI `text-embedding-3-small` | 1536 | No | Alternative |
| On-device model | Variable | Yes | Future |

### 19.3 Vector Search Query

```sql
SELECT m.id, m.content, m.memory_type,
       1 - (e.embedding <=> $query_vector) AS similarity
FROM memories m
JOIN memory_embeddings e ON e.memory_id = m.id
WHERE m.user_id = $user_id AND m.is_active = true
ORDER BY e.embedding <=> $query_vector
LIMIT 5;
```

---

## 20. Universal Search

### 20.1 Two-Pass Search

```
Pass 1 — Keyword Search (fast, offline-capable)
  -> FTS on tasks.title, notes.content, memories.content
  -> filter by date, type, tags

Pass 2 — Semantic Search (online, pgvector)
  -> embed query
  -> search memory_embeddings, note_embeddings
  -> merge + deduplicate results

Result fusion -> rank by relevance + recency -> return top N
```

### 20.2 Search Sources

```
tasks        -> title, notes, tags
notes        -> title, content, tags
memories     -> content, category
recordings   -> label
transcripts  -> full_text, summary, key_points
calendar     -> title, location
conversations -> recent AI messages
```

---

## 21. "What Happened?" Timeline AI

### 21.1 Query Resolution

```
"What happened yesterday?"
  -> resolved_date_utc: 2026-09-19T00:00:00Z to 2026-09-19T23:59:59Z (Asia/Kolkata)

-> parallel queries:
    tasks completed / created / updated (that day)
    reminders triggered (that day)
    calendar events (that day)
    notes created (that day)
    memories saved (that day)
    recordings created (that day)
    audit_log summary (significant actions that day)

-> merge all results -> rank by time
-> LLM: generate natural-language summary

-> return:
  { "date": "...", "summary": "...", "timeline": [...], "highlights": [...] }
```

### 21.2 Relevance Ranking

Items ranked by: explicit user actions > AI-confirmed data > scheduled events > system events.

---

## 22. Automation Engine

### 22.1 Automation Components

```
TRIGGER types:
  task_overdue        (task.due_date < NOW AND status = 'pending')
  reminder_triggered  (reminder fired)
  time_of_day         (cron-style)
  voice_command       ("Nimmy, every morning brief me")
  calendar_event_start / end
  location_based      (future, requires location permission)

CONDITION:
  field comparisons, boolean AND/OR

ACTION:
  any read-risk or local_write tool
  (external tools require explicit extra confirmation)

CONFIRMATION POLICY:
  automation-generated actions follow same risk rules
  Level 2+ always prompts user before executing
```

### 22.2 Automation Execution

```
Trigger fires
  -> evaluate conditions
  -> build ToolProposal from action template
  -> check confirmation policy:
      if requires_confirmation: push notification -> user confirms in-app
      if automatic: execute directly (only read/local_write Level 1)
  -> execute via Tool Executor (same pipeline as manual tools)
  -> audit: AUTOMATION_EXECUTED (links to automation_id)
  -> on failure: notify user + log failure, do NOT retry silently
```

---

## 23. App Launcher

### 23.1 Resolution Algorithm

```
"Open Telegram"
  -> app_name = "Telegram"
  -> query installed packages: PackageManager.getInstalledApplications()
  -> fuzzy match app_name -> package_name = "org.telegram.messenger"
  -> getLaunchIntentForPackage("org.telegram.messenger")
  -> if null: "Telegram installed nahi hai. Play Store par search karoon?"
  -> if found: context.startActivity(intent)
  -> audit: OPEN_APP(package_name, source)
```

### 23.2 Limitations

Nimmy cannot control other apps internally (no Accessibility Service in MVP).
It can only launch them. In-app automation requires Android Accessibility Service
— document this clearly, never fake control.

---

## 24. Bluetooth Integration

### 24.1 Permissions (Android 12+)

```
BLUETOOTH_SCAN    — required for discovery
BLUETOOTH_CONNECT — required for connection
```

### 24.2 Capability Detection

```
Connect does NOT equal controllable.
-> after connection: query GATT services
-> identify supported Bluetooth profile:
    HFP (hands-free)
    A2DP (audio)
    HID (keyboard/mouse)
    Custom GATT service
-> only offer operations supported by detected profile
-> never claim control of unsupported profile
```

### 24.3 Supported Operations per Profile

| Profile | Nimmy Operations |
|---|---|
| HFP | Answer/reject call (via Android API) |
| A2DP | Play/pause via Android MediaSession |
| Custom GATT | Read/write GATT characteristics (after service discovery only) |

---

## 25. Offline-First & Sync

### 25.1 Local Storage (Hive)

```
nimmy_reminders_v1  -> full reminder records
nimmy_tasks_v1      -> full task records
nimmy_notes_v1      -> full note records
nimmy_memories_v1   -> full memory records (no embeddings offline)
nimmy_audit_v1      -> local audit trail
nimmy_settings_v1   -> user preferences
nimmy_offline_queue -> pending mutations
```

### 25.2 Offline Mutation Queue

```json
{
  "queue_id": "uuid",
  "operation": "CREATE | UPDATE | DELETE",
  "tool": "create_reminder",
  "record_id": "uuid",
  "request_id": "uuid",
  "payload": {},
  "created_at": "...",
  "retry_count": 0,
  "status": "pending | syncing | synced | failed"
}
```

### 25.3 Sync Flow

```
LOCAL WRITE (offline or online)
  -> write to Hive immediately (user sees it)
  -> enqueue to offline_queue

ONLINE detected
  -> process queue in order
  -> for each: attempt Supabase upsert (using request_id idempotency)
  -> on success: mark synced, remove from queue
  -> on conflict: apply deterministic resolution
  -> on failure after 3 retries: mark failed, notify user

CONFLICT RESOLUTION:
  -> CURRENT USER INSTRUCTION wins
  -> else: latest updated_at wins
  -> preserve both versions for user review if irreconcilable
```

### 25.4 UI States

```
OFFLINE      -> banner: "Offline — changes will sync when connected"
SYNCING      -> spinner: "Syncing..."
SYNCED       -> brief confirmation: "All changes saved"
SYNC_FAILED  -> warning: "Sync failed. [Retry] [Details]"
```

No silent data loss. User always knows sync status.

---

## 26. Learning & Correction System

### 26.1 What "Learning" Means in Nimmy

```
NOT: retraining the foundation model on private user data.

YES: storing user corrections, preferences, and feedback in Memory Engine
     -> retrieving them in future AI context
     -> personalizing responses through memory retrieval, not model weights
```

### 26.2 Feedback Loop

```
AI proposes -> User confirms or corrects
  -> confirmed: positive signal logged in audit
  -> corrected: CORRECTION memory saved (old_value, new_value, context)
  -> future requests: correction memories injected into AI context
  -> AI learns to not make same mistake in this user's context
```

### 26.3 Correction Example in Full

```
User: "Remind me at 8 PM."
Nimmy: "Reminder set for 8 PM."
User: "No. 9 PM."

-> detect: intent = edit_reminder (correction)
-> find recent reminder matching context
-> propose edit_reminder(reminder_id, scheduled_at: 9 PM resolved)
-> show: "9 PM kar doon? [Yes] [No]"
-> User: Yes
-> edit_reminder executes
-> audit: CORRECTION event { old: "8 PM", new: "9 PM" }
-> save_memory({
    content: "User prefers 9 PM for evening reminders",
    category: "preference",
    source: "USER_CORRECTION",
    importance: "high"
  })
-> TTS: "Done. 9 PM kar diya."
```

---

## 27. Error Contract — Full Classification

All errors return:

```json
{
  "success": false,
  "code": "ERROR_CODE",
  "message": "Human-readable message in user's language",
  "recovery": "What the user can do next",
  "retryable": true,
  "request_id": "uuid"
}
```

### Full Error Code List

| Code | Meaning | Retryable |
|---|---|---|
| `TITLE_REQUIRED` | Tool input missing required title | No |
| `TIME_IN_PAST` | scheduled_at is in the past | No |
| `INVALID_TIMEZONE` | Unrecognized IANA timezone | No |
| `CLARIFICATION_REQUIRED` | Ambiguous input (AM/PM, multiple candidates) | No |
| `TOOL_NOT_REGISTERED` | AI proposed a tool not in the allow-list | No |
| `TOOL_VALIDATION_FAILED` | Schema validation failure | No |
| `CONFIRMATION_REQUIRED` | Tool called without confirmed flag | No |
| `CONFIRMATION_TIMEOUT` | User did not confirm within 60s | Yes |
| `DUPLICATE_REQUEST` | Same request_id already executed | No |
| `UNAUTHORIZED` | Session invalid or expired | Yes after re-auth |
| `FORBIDDEN` | User does not own this resource | No |
| `PERMISSION_DENIED` | Android permission not granted | No — open settings |
| `OFFLINE` | Action requires network, offline mode active | Yes when online |
| `PERSISTENCE_FAILED` | Database write error | Yes (with backoff) |
| `SCHEDULER_FAILED` | AlarmManager failed (record still saved, warning) | Partial |
| `AUDIT_FAILED` | Audit write failed after record write (record rolled back) | — |
| `PROVIDER_TIMEOUT` | AI provider did not respond in time | Yes |
| `PROVIDER_UNAVAILABLE` | AI provider unreachable | Yes |
| `INTEGRATION_UNAVAILABLE` | OAuth/external integration not configured | No |
| `INTEGRATION_AUTH_FAILED` | OAuth token expired or revoked | Yes after re-auth |
| `TOOL_EXEC_FAILED` | Executor encountered unexpected error | Yes |
| `ANDROID_BRIDGE_ERROR` | Kotlin MethodChannel call failed | Conditional |
| `RECORDING_PERMISSION_DENIED` | RECORD_AUDIO not granted | No — open settings |
| `RECORDING_SERVICE_FAILED` | Foreground service could not start | Conditional |
| `UNKNOWN_ERROR` | Unexpected system error | Yes |

Every error code has a user-facing recovery path. No error leaves the user
in a dead end.

---

## 28. Complete Command Workflow Example

Command: "Hey Nimmy, kal 8 baje Rahul ko call karne ka reminder laga."

```
Step 1   Wake engine: WAKE_DETECTED
         Orb -> LISTENING

Step 2   VAD: SPEECH_ACTIVE -> SILENCE -> COMMAND_COMPLETE

Step 3   STT: "kal 8 baje Rahul ko call karne ka reminder laga"

Step 4   AI Orchestrator -> UnderstandingRequest
         context: timezone=Asia/Kolkata, current_time=2026-09-20T21:59

Step 5   AI -> UnderstandingResponse
         intent: create_reminder
         entities: {
           title: "Rahul ko call karna",
           date_expression: "kal",
           time_expression: "8 baje",
           am_pm_ambiguous: TRUE
         }
         clarification_question: "8 AM ya 8 PM?"

Step 6   Orb -> THINKING
         TTS: "8 AM ya 8 PM?"

Step 7   User: "8 PM"
         STT: "8 PM"
         resolve: scheduled_at = 2026-09-21T14:30:00Z (8 PM IST = 14:30 UTC)

Step 8   Safety Engine:
         session valid
         request_id generated: uuid-xyz
         title within bounds
         scheduled_at is future
         risk_level: local_write
         confirmation required

Step 9   Confirmation UI:
         "Reminder: Rahul ko call karna
          Kal — 21 Sep 2026, 8:00 PM
          [Confirm] [Cancel] [Edit]"

Step 10  User taps Confirm
         Orb -> EXECUTING

Step 11  ToolRegistry.execute(confirmed: true)
         -> PROPOSED audit written
         -> CONFIRMED audit written
         -> INSERT reminders (request_id: uuid-xyz)
         -> Kotlin: scheduleReminder(uuid-xyz, "Rahul ko call karna", 1758461400000)
         -> AlarmManager.setAlarmClock() success
         -> UPDATE reminders SET notification_scheduled = true
         -> EXECUTED audit written

Step 12  ToolResult:
         { success: true, record_id: "...", notification_scheduled: true }

Step 13  Orb -> SUCCESS
         TTS: "Done. Kal 8 PM ko Rahul ko call karne ka reminder set kar diya."

Step 14  Orb -> IDLE
         Wake detector resumed
```

---

## 29. Orb State Machine

```
States:
  IDLE       - Listening for wake word, minimal animation
  LISTENING  - VAD active, user speaking, pulse animation
  THINKING   - AI processing, spin/wave animation
  SPEAKING   - TTS playing, wave animation synced to audio
  EXECUTING  - Tool running, progress ring
  SUCCESS    - Tool completed successfully, checkmark burst
  ERROR      - Tool failed, error pulse
  RECORDING  - Active recording session, red pulse
  OFFLINE    - No network, muted animation

Transitions:
  IDLE -> LISTENING:  wake detected OR user taps mic
  LISTENING -> THINKING: COMMAND_COMPLETE
  THINKING -> SPEAKING: clarification or response ready
  THINKING -> EXECUTING: tool confirmed and executing
  EXECUTING -> SUCCESS: tool executed successfully
  EXECUTING -> ERROR: tool failed
  SUCCESS -> IDLE: after 2 seconds
  ERROR -> IDLE: after 3 seconds (error message shown)
  any -> IDLE: user says "Nimmy stop" or taps cancel
  any -> OFFLINE: network lost
  OFFLINE -> IDLE: network restored
  IDLE -> RECORDING: start_recording executed
  RECORDING -> THINKING: stop_recording, processing begins
```

Rule: Orb NEVER shows SUCCESS when the underlying operation failed.
Orb state is driven by actual system state, not by UI convenience.

---

## 30. Production API Technology Map

| Layer | Technology | Provider | Status |
|---|---|---|---|
| Main AI reasoning | Gemini 2.0 Flash / GPT-4o | Google / OpenAI | Future |
| Deterministic parser | Custom Dart parser | Internal | MVP — implemented |
| Realtime voice | Gemini Live API / OpenAI Realtime | Google / OpenAI | Future |
| STT | Android SpeechRecognizer (MVP) | Android | MVP partial |
| TTS | Android TextToSpeech (MVP) | Android | MVP partial |
| Wake word | openWakeWord ONNX model | On-device | Model missing |
| VAD | Android / provider | Android | Partial |
| Embeddings | text-embedding-004 | Google | Future |
| Vector search | pgvector on PostgreSQL | Supabase | Future |
| Database | PostgreSQL | Supabase | MVP partial |
| Local storage | Hive (Flutter) | Internal | MVP implemented |
| Auth | Supabase Auth (JWT + RLS) | Supabase | MVP partial |
| Storage | Supabase Storage | Supabase | Future (recording) |
| Notifications (local) | AlarmManager + NotificationManager | Android | MVP implemented |
| Notifications (push) | Firebase Cloud Messaging | Firebase | Future |
| Background tasks | WorkManager | Android | Future |
| Calendar | Google Calendar API v3 | Google | Future |
| AI backend | Python FastAPI | Internal | Future boundary |
| Web | Next.js + TypeScript | Internal | Future |
| Recording transcription | Whisper API / Google STT | Cloud | Future |
| Automation engine | WorkManager + Supabase Edge | Internal | Future |
| App launcher | Android PackageManager + Intent | Android | Future |
| Bluetooth | Android BluetoothManager | Android | Future |

---

## 31. Implementation Status per Component

| Component | Status | Evidence Required Before COMPLETE |
|---|---|---|
| Wake word service boundary | IN_PROGRESS | Physical device test + false-positive/negative measurement |
| Wake word ONNX model | **BLOCKED** | Model training, evaluation, asset file |
| VAD | IN_PROGRESS | Device test under noise conditions |
| STT (Android) | IN_PROGRESS | Device test, locale accuracy |
| TTS (Android) | IN_PROGRESS | Device test, barge-in verification |
| Intent parser (deterministic) | IN_PROGRESS | Unit tests + real device verified |
| `create_reminder` | IN_PROGRESS | Unit tests + device + notification verification |
| `save_memory` | IN_PROGRESS | Unit tests + device verification |
| AI orchestrator (LLM) | NOT_STARTED | Provider contract + tool calling + integration tests |
| Context engine | NOT_STARTED | Conversation history test, ambiguity resolution test |
| Memory semantic search | NOT_STARTED | pgvector deployed, embedding pipeline, search quality test |
| `create_task` | NOT_STARTED | All gates per AGENTS.md section 4 |
| `create_note` | NOT_STARTED | All gates |
| `search_everything` | NOT_STARTED | All gates |
| `plan_day` | NOT_STARTED | All gates |
| `what_happened` | NOT_STARTED | All gates |
| Recording system | NOT_STARTED | Foreground service + audio lifecycle + physical device |
| Calendar integration | NOT_STARTED | OAuth + API + offline queue + conflict resolution |
| Automation engine | NOT_STARTED | Trigger/condition/action pipeline + test |
| App launcher | NOT_STARTED | Package resolution + intent test |
| Bluetooth | NOT_STARTED | Profile detection + capability guard |
| Offline sync | IN_PROGRESS | Queue + conflict test + reconnect scenario |
| Web control center | NOT_STARTED | All gates |
| Security (RLS full) | IN_PROGRESS | Negative test: cross-user, invalid token, RLS bypass |
| Supabase auth (live) | IN_PROGRESS | Sign-in/out device test + RLS verification |

---

*Last updated: 2026-09-20 | Maintained per AGENTS.md Section 19*
*Status values: NOT_STARTED / IN_PROGRESS / BLOCKED / VERIFIED / COMPLETE*
