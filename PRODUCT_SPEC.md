# NIMMY — PRODUCT SPECIFICATION

| Document metadata | Value |
| --- | --- |
| Document | `PRODUCT_SPEC.md` |
| Status | Canonical / Source of Truth |
| Version | 1.0.0 |
| Product | Nimmy — Voice-first Personal AI OS |
| MVP scope | Voice → Intent → Controlled Tool → Confirmation → Database → Audit → Voice Response |

## 1. Product Definition

### 1.1 Product Name

Nimmy

### 1.2 Product Category

Voice-first Personal AI Operating System.

### 1.3 Core Identity

> **AI + Memory + Tasks + Voice + Automation**

Nimmy is a personal AI assistant designed to help the user remember, organize, schedule, record, retrieve, and act on daily information through natural voice and text interaction.

Nimmy is not a generic chatbot and is not a simple to-do application. Its defining experience is a controlled action system: the user speaks naturally, Nimmy understands the intent, selects an approved tool, performs or prepares the action, records the meaningful action in an audit trail, and responds naturally.

## 2. Product Principles

### 2.1 Voice-first

Voice is the primary interaction model. Text remains available as a fallback and for precision-sensitive actions.

### 2.2 Controlled actions

The AI never receives unrestricted access to the application or database. All meaningful operations go through explicit, typed tool contracts.

### 2.3 User agency

Nimmy assists and executes according to configured permissions. It does not silently make consequential decisions on the user's behalf.

### 2.4 Confirmation for sensitive actions

Actions involving sending, sharing, deleting, or other consequential external effects require an appropriate confirmation step unless a future user-configurable policy explicitly permits otherwise.

### 2.5 Explicit memory

Memory must be explicit, searchable, editable, and deletable. Temporary conversational context is distinct from durable saved memory.

### 2.6 Privacy by default

Sensitive data is minimized, access is permissioned, and temporary recordings have an explicit retention lifecycle.

### 2.7 Offline-first product behavior

Core local functionality should continue to work when network access is unavailable. Cloud synchronization is additive rather than a prerequisite for basic task/reminder/memory usage.

### 2.8 Observable behavior

Meaningful AI actions are auditable. The system should be able to explain what it did, when it did it, and what tool/action produced the result.

### 2.9 Future vs current behavior

Implemented capabilities and future capabilities must always be clearly separated in documentation, UI, and technical design.

## 3. Core User Experience

The six canonical Nimmy commands are:

1. “Nimmy, remember this.”
2. “Nimmy, remind me.”
3. “Nimmy, schedule this.”
4. “Nimmy, record this.”
5. “Nimmy, what happened?”
6. “Nimmy, what should I do now?”

These commands define the product direction. Not every command is part of MVP implementation.

## 4. MVP Scope

### 4.1 MVP Goal

Prove the end-to-end Nimmy agent loop with two production-grade tools:

- `create_reminder(...)`
- `save_memory(...)`

### 4.2 Locked MVP Pipeline

```text
Voice Input
    ↓
Speech-to-Text / User Text
    ↓
Intent + Entity Extraction
    ↓
Controlled Tool Selection
    ↓
Tool Validation
    ↓
Confirmation
    ↓
Database Transaction
    ↓
Audit Event
    ↓
Nimmy Response / TTS
```

### 4.3 MVP Must Include

- Flutter mobile foundation
- Android/Kotlin bridge where required
- Nimmy voice/text input surface
- AI intent understanding
- Typed tool contracts
- `create_reminder`
- `save_memory`
- Confirmation UI
- Supabase/PostgreSQL persistence
- Audit history
- Nimmy response generation
- Basic Nimmy Orb state system
- Error handling
- Permission handling for microphone/notifications as required
- Basic offline local state strategy

### 4.4 MVP Explicitly Excludes

The following are not MVP requirements:

- Unsupported WhatsApp/Instagram automation
- Autonomous external actions without confirmation policy
- Advanced multi-agent architecture
- Knowledge graph
- Rust modules
- C++ modules
- Go gateway unless a measurable MVP requirement appears
- Full RAG pipeline
- Complex recommendation engine
- Always-on hidden microphone behavior
- Stealth/background recording
- Autonomous deletion of user data without the defined retention policy
- Full scheduled messaging integration

## 5. Product Architecture

```text
                    ┌─────────────────────┐
                    │       USER          │
                    │   Voice / Text      │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │   Nimmy UI Layer    │
                    │ Flutter + Orb       │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Intent / Context    │
                    │ Understanding Layer │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │   Tool Router       │
                    │ Controlled Actions  │
                    └───────┬─────┬───────┘
                            │     │
                 ┌──────────┘     └───────────┐
                 ↓                            ↓
        create_reminder(...)          save_memory(...)
                 │                            │
                 └────────────┬───────────────┘
                              ↓
                    ┌─────────────────────┐
                    │   Validation /      │
                    │   Confirmation      │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Supabase/Postgres   │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │    Audit Log        │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Nimmy Response/TTS  │
                    └─────────────────────┘
```

## 6. Technology Ownership

### Mobile

- **Flutter / Dart:** application UI and client logic
- **Kotlin:** Android-specific platform integration

### Web (future control center)

- Next.js
- TypeScript
- Tailwind CSS
- Framer Motion
- Three.js / React Three Fiber for web holographic experiences

### AI service

- Python
- FastAPI

### Database / backend foundation

- Supabase
- PostgreSQL

### Deferred technologies

- **Rust:** performance/native modules only when justified
- **C++:** low-level DSP only when justified
- **Go:** infrastructure/gateway/worker scale only when justified

No feature should be duplicated across languages without a documented reason.

## 7. Nimmy Interaction States

The Nimmy Orb is a functional state indicator, not decoration only.

### States

- `idle`
- `listening`
- `understanding`
- `thinking`
- `confirming`
- `executing`
- `success`
- `speaking`
- `error`

### Visual direction

- Dark futuristic interface
- Particle/dot holographic orb
- 3D depth where supported
- Framer Motion for transitions
- Interactive particle behavior
- Clear state differentiation
- Minimal UI around the primary action

The animation must communicate system state without becoming a distraction.

## 8. Tool Contract System

AI reasoning and application execution are separated.

The model selects a tool; the application validates and executes it.

```text
AI Model
  ↓
Structured Tool Call
  ↓
Schema Validation
  ↓
Authorization / Permission Check
  ↓
Confirmation Policy
  ↓
Application Execution
  ↓
Audit Event
```

The model must not directly execute arbitrary SQL, filesystem commands, shell commands, or unrestricted platform APIs.

## 9. Production Flow A — `create_reminder(...)`

### 9.1 User examples

- “Nimmy, remind me tomorrow at 9 AM to study Geography.”
- “Remind me in 30 minutes to call Rahul.”
- “Every Sunday at 7 PM remind me to review my week.”

### 9.2 Required extracted fields

- `id`
- `user_id`
- `text` / `title`
- `scheduled_at` or `relative_time`
- `recurrence` (optional)
- `timezone`
- `source = voice | text`
- `status`
- `created_at`

### 9.3 Tool contract

```json
{
  "name": "create_reminder",
  "description": "Create a user reminder after validating the requested time and confirmation policy.",
  "input": {
    "title": "string",
    "scheduled_at": "ISO-8601 datetime",
    "timezone": "IANA timezone",
    "recurrence": "optional structured recurrence",
    "source": "voice | text"
  }
}
```

### 9.4 Execution flow

```text
User voice
 ↓
STT
 ↓
Intent = CREATE_REMINDER
 ↓
Extract title/time/timezone/recurrence
 ↓
Validate date/time
 ↓
Show confirmation
 ↓
User confirms
 ↓
Insert reminder
 ↓
Create audit event
 ↓
Schedule notification
 ↓
Nimmy confirms
```

### 9.5 Confirmation

Example:

> “Reminder for ‘Study Geography’ tomorrow at 9:00 AM. Create it?”

After confirmation:

> “Done. I’ll remind you tomorrow at 9:00 AM.”

### 9.6 Acceptance criteria

- Relative times resolve correctly using the user's timezone.
- Ambiguous times are not silently guessed when clarification is required.
- Reminder is persisted exactly once.
- Duplicate submission can be safely detected/idempotent.
- Confirmation is recorded where required.
- Audit event is created after successful execution.
- Reminder is visible in the task/reminder UI.
- User receives appropriate notification when the reminder fires.
- Failure produces a clear, actionable error.

## 10. Production Flow B — `save_memory(...)`

### 10.1 User examples

- “Nimmy, remember this: my project demo is on Friday.”
- “Remember that I prefer dark mode.”
- “Save this as an important note.”

### 10.2 Memory model

A saved memory must be:

- Explicitly saved or otherwise clearly authorized
- Searchable
- Editable
- Deletable
- Timestamped
- Attributed to its source
- Scoped to the user

### 10.3 Tool contract

```json
{
  "name": "save_memory",
  "description": "Persist a user-approved memory in durable memory storage.",
  "input": {
    "content": "string",
    "category": "preference | goal | project | person | decision | reminder_context | note | other",
    "importance": "low | normal | high",
    "source": "voice | text | conversation",
    "source_reference": "optional string"
  }
}
```

### 10.4 Execution flow

```text
User voice
 ↓
STT
 ↓
Intent = SAVE_MEMORY
 ↓
Extract memory content/category
 ↓
Show memory preview
 ↓
User confirms
 ↓
Persist memory
 ↓
Optional embedding generation
 ↓
Create audit event
 ↓
Nimmy confirms
```

### 10.5 Acceptance criteria

- Memory is never stored for a `save_memory` request without required confirmation policy being satisfied.
- Saved memory has a stable ID.
- User can search it.
- User can edit it.
- User can delete it.
- Memory is scoped to the authenticated user.
- Source metadata is preserved.
- Audit entry is created after successful save.
- Failed saves do not produce false confirmation.

## 11. Confirmation Matrix — MVP

| Action | Confirmation | Reason |
| --- | --- | --- |
| Create reminder | Yes | Creates persistent scheduled state |
| Save memory | Yes | Creates durable personal data |
| View information | No | Read-only |
| Search saved memory | No | Read-only |
| Open normal app route | No, where platform allows | Low-risk navigation |
| Delete memory | Future / Yes | Destructive |
| Delete recording | Future / Yes | Destructive |
| Send message | Future / Yes | External side effect |
| Share content | Future / Yes | External side effect |
| Purchase/payment | Future / Strong confirmation | Financial side effect |

Confirmation policy must remain centralized and configurable rather than being hard-coded independently inside each feature.

## 12. Audit System

Every meaningful AI action must produce an audit event.

### Minimum event fields

- `id`
- `user_id`
- `action_type`
- `tool_name`
- `request_id`
- `source = voice | text | system`
- `status = proposed | confirmed | executed | failed | cancelled`
- `created_at`
- `executed_at`
- `metadata`
- `error_code` (optional)

Example:

```json
{
  "action_type": "create_reminder",
  "tool_name": "create_reminder",
  "status": "executed",
  "source": "voice"
}
```

The audit system is not a raw conversation log. It is a structured history of meaningful product actions.

## 13. Memory Architecture

Memory is divided into:

### A. Session context

Short-lived context required to understand the current interaction.

### B. Durable memory

Explicitly saved user information.

### C. Future semantic memory

Embeddings/vector search can be added later using PostgreSQL + pgvector.

The MVP does not require a full knowledge graph or autonomous memory extraction engine.

## 14. Local-first Strategy

### Local MVP data

The app should be able to maintain essential state locally.

Suggested local entities:

- Reminders
- Saved memories
- Pending actions
- Audit queue
- User preferences

### Cloud synchronization

Supabase is the cloud source for authenticated synchronized data.

```text
Local DB
   ↕
Sync Layer
   ↕
Supabase/PostgreSQL
```

Sync must be idempotent and conflict-aware.

## 15. Permission Strategy

Permissions are requested only when a feature requires them.

### MVP likely permissions

- **Microphone:** voice input
- **Notifications:** reminders

### Future permissions

- Calendar
- Contacts
- Location
- Background/foreground service capabilities
- Additional Android integrations

Every permission request must explain:

- What access is needed
- Why Nimmy needs it
- What happens if the user denies it
- How to change it later

There is no requirement or design goal to hide microphone usage.

## 16. Error Handling

Nimmy must distinguish:

### Understanding failure

> “I’m not sure what time you meant. Did you mean 9 AM or 9 PM?”

### Permission failure

> “Notifications are disabled, so I can save the reminder but I may not be able to alert you.”

### Network failure

> “I saved this locally. I’ll sync it when you’re back online.”

### Tool failure

> “I understood the reminder, but I couldn’t create it. Nothing was changed.”

### AI failure

Never claim an action occurred when the tool execution did not succeed.

## 17. Security Requirements

- Authenticated user context required for durable data access.
- Row Level Security must isolate user data.
- Service-role secrets must never be shipped in the mobile or browser client.
- API keys must be managed through environment/secrets configuration.
- Tool execution must validate authenticated ownership.
- Destructive/external actions require confirmation policies.
- Sensitive data should use least-privilege access.
- Audit records must be tamper-resistant at the application level.

## 18. Initial Database Entities

The schema may evolve, but MVP must support at least:

- `profiles`
- `devices`
- `reminders`
- `memories`
- `ai_conversations`
- `ai_messages`
- `audit_logs`
- `user_preferences`

Future entities include:

- `tasks`
- `projects`
- `calendar_events`
- `notes`
- `recordings`
- `transcripts`
- `automations`
- `scheduled_messages`
- `connected_apps`
- `memory_embeddings`

Do not create every future table merely for completeness if it does not serve an active milestone.

## 19. Screen / Navigation Map — MVP

```text
Splash
  ↓
Onboarding
  ↓
Permission Setup
  ↓
Home / Command Center
  ├── Nimmy Voice
  ├── Reminders
  ├── Memories
  ├── Activity / Audit
  └── Settings
```

### Home

- Nimmy Orb
- Today summary
- Upcoming reminder
- Quick actions
- Recent memory
- Voice trigger

### Reminder screen

- Upcoming
- Completed
- Recurring
- Create/edit reminder

### Memory screen

- Search
- Recent memories
- Categories
- Edit
- Delete

### Audit screen

- Recent actions
- Status
- Timestamp
- Tool used

### Settings

- Account
- Permissions
- Notifications
- Voice
- Privacy
- Memory controls

## 20. UI/UX Direction

### Visual language

- Dark-first
- Holographic particle/dot Nimmy Orb
- Glass-like surfaces used selectively
- Deep-space background
- Purple/indigo accent system
- High readability
- Soft motion
- Minimal chrome

### Interaction rule

The Orb communicates system state:

| State | Visual behavior |
| --- | --- |
| Idle | Calm particle breathing |
| Listening | Responsive particle motion |
| Thinking | Faster orbital motion |
| Confirming | Clear attention state |
| Executing | Active motion |
| Success | Subtle particle burst |
| Speaking | Speech-linked pulse |
| Error | Unmistakable error state |

Motion should improve understanding, not merely decorate the interface.

## 21. MVP Acceptance Test — Golden Path

The MVP is considered operational only when the following complete successfully on a real Android device/emulator.

### Test A — Reminder

1. User invokes Nimmy.
2. User says: “Remind me tomorrow at 9 AM to study Geography.”
3. STT produces usable text.
4. AI detects `create_reminder`.
5. Tool schema validates.
6. Confirmation is shown/spoken.
7. User confirms.
8. Reminder is persisted.
9. Audit event is written.
10. Nimmy responds with truthful confirmation.

### Test B — Memory

1. User invokes Nimmy.
2. User says: “Remember this: the project demo is on Friday.”
3. AI detects `save_memory`.
4. Memory payload is validated.
5. Preview/confirmation is shown.
6. User confirms.
7. Memory is persisted.
8. Audit event is written.
9. User searches for the memory.
10. Nimmy returns the saved memory.

### Negative-path tests

- User cancels confirmation.
- User denies notification permission.
- User denies microphone permission.
- Network unavailable.
- AI returns malformed tool arguments.
- Tool execution fails.
- Duplicate request arrives.
- User is unauthenticated.
- User attempts to access another user's memory.

Every negative path must fail safely and must not claim success.

## 22. Phase Roadmap

### Phase 1 — Foundation

- Flutter shell
- Kotlin bridge foundation
- Nimmy Orb
- Authentication
- Supabase setup
- Reminder + memory data models
- Basic screens
- Tool contract framework

### Phase 2 — AI Brain

- Python/FastAPI
- Intent classification
- Tool calling
- Structured outputs
- Context handling
- Response generation

### Phase 3 — Voice & Android

- Speech-to-text
- Text-to-speech
- Android permission flows
- Notifications
- Foreground-service architecture where required

### Phase 4 — Memory & Automation

- Search improvements
- Embeddings/pgvector
- Recording pipeline
- Summaries
- Automation engine
- Additional tools

### Phase 5 — Performance

Only where benchmarks justify it:

- Rust native modules
- Optimized audio/search/crypto components

### Phase 6 — Scale & Integrations

- Go infrastructure if required
- Advanced workers
- Additional integrations
- Web control center
- Analytics
- Extended multi-device support

## 23. Future Scope — Explicitly Deferred

The following are valid future directions but are not current capabilities unless separately implemented and verified:

- “Always-on” wake word behavior
- Background user-authorized recording
- Scheduled messaging
- WhatsApp integrations
- Telegram integrations
- Instagram integrations
- Calendar integrations
- Contact-aware actions
- Full recording → transcription → summary pipeline
- 7-day temporary recording lifecycle
- “I Forgot” retrieval system
- RAG / semantic memory
- Personal knowledge graph
- Autonomous multi-step agents
- Smart-home integrations
- Wearables
- Desktop assistants
- Rust/C++ native modules
- Large-scale Go worker infrastructure

Documentation and UI copy must never present deferred features as already available.

## 24. Definition of Done — MVP

Nimmy MVP is complete only when:

- The two production tools work on-device.
- Tool calls are schema-validated.
- Confirmation policy is enforced.
- Data is persisted securely for the authenticated user.
- Audit history is generated.
- Voice response is truthful to actual execution.
- Core functionality has an offline-safe failure mode.
- Permission denial is handled gracefully.
- Negative-path tests pass.
- No unsupported automation is claimed or implemented.
- The product visually communicates Nimmy's voice-first holographic identity.

## 26. Nimmy Intelligence Layer (Learning & Memory Engine)

### 26.1 Fundamental Learning Principle
> **Nimmy never automatically retrains foundation AI models on user data.**
> Nimmy's learning is strictly **personalization + memory + feedback + retrieval + provenance + correction + confidence.**

This boundary ensures the system remains predictable, auditable, safe, and privacy-preserving.

### 26.2 The 4 Learning Layers
```text
                    NIMMY LEARNING
                          │
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   User Context       Corrections       Behaviour
        │                 │                 │
        ↓                 ↓                 ↓
     Memory          Feedback Store    Preferences
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ↓
                    Better Responses
```

### 26.3 The 8 Typed Memory Classes
Memory items are strictly segregated into typed categories rather than unstructured text dumps:
1. **Profile Memory**: Core user account details, identity, and personal metadata.
2. **Preference Memory**: Ergonomic, aesthetic, and workflow preferences (e.g. "prefers concise responses", "prefers dark violet UI").
3. **Goal Memory**: Explicit user aspirations and targets (e.g. "wants to launch Nimmy in Q4").
4. **Project Memory**: System architectures, stack decisions, and project structures (e.g. "Nimmy uses 10 fixed languages").
5. **Knowledge Memory**: Factual user-provided reference data.
6. **Event Memory**: Milestone past or future occurrences.
7. **Idea Memory**: Raw concepts and creative prompts reserved for future exploration.
8. **Correction Memory**: Records of user corrections and resolved misunderstandings.

### 26.4 Memory Confidence Matrix
Every memory item holds an explicit confidence score and tier:
- **Explicit user memory** (`1.00` — Very High): User explicitly commanded "remember this".
- **User confirmed** (`0.95` — High): User confirmed an AI-suggested memory candidate.
- **Repeated consistent behavior** (`0.80` — Medium): Inferred from recurring patterns across sessions.
- **Imported trusted data** (`0.75` — Imported): Ingested from synced Google Calendar, local files, or authenticated integrations.
- **AI inference** (`0.30` — Inference): Internal AI deduction. **Crucial Rule: AI inferences are capped at 0.30 and are NEVER stored or presented as facts.**
- **Unverified assumption** (`0.10` — Unverified): Speculative context.

### 26.5 Provenance Engine ("Where did this come from?")
Every memory node tracks full provenance metadata:
```text
PROVENANCE METADATA
├── source_type: user_explicit | user_confirmed | user_correction | user_note | user_recording | calendar | task_database | connected_service | external_knowledge
├── source_id: UUID of originating record
├── source_name: Human-readable origin (e.g. "Voice Session 12", "Client Meeting Note")
├── source_url: URL for external knowledge
├── verified: Boolean
└── created_at: ISO8601 Timestamp
```

### 26.6 Non-Defensive Mistake & Correction System ("Nimmy Galat Hai")
When a user corrects Nimmy, the assistant never argues or becomes defensive:
```text
User Correction ("Nahi, maine 9 PM bola tha")
       ↓
Detect Conflict & Identify Original Record
       ↓
Mark Previous Interpretation Incorrect
       ↓
Execute Data Correction
       ↓
Emit Audit Log Entry
       ↓
Feed Correction Pattern to Learning Store
       ↓
Truthful & Concise Acknowledgement ("Understood. Corrected reminder time to 9:00 PM.")
```

### 26.7 Conflict Resolution Precedence
When stored memory contradicts current user input, Nimmy enforces a strict hierarchy:
```text
CURRENT EXPLICIT INSTRUCTION (Highest Priority — ALWAYS Wins)
          ↓
USER CONFIRMED INFORMATION
          ↓
RECENT USER INFORMATION
          ↓
SAVED MEMORY
          ↓
CONNECTED DATA
          ↓
AI INFERENCE (Lowest Priority)
```
*Old memory must never override a current explicit instruction.*

### 26.8 Memory Versioning & Evolution
When preferences or facts evolve ("I used to prefer X, but now I prefer Y"):
- The old memory is marked `status = 'superseded'`.
- A link to `superseded_by` is preserved.
- `previous_value` is retained in the history array.

### 26.9 Knowledge Source Router
Queries are partitioned based on data privacy and timeliness:
- **Personal / Account Queries** -> Local Memory Vault, Tasks, Calendar, Database.
- **Current / Real-Time Facts** -> Verified external sources and live APIs.
- **Conceptual / General Knowledge** -> Foundation AI knowledge base.

### 26.10 "What Happened?" Multi-Source Engine
When the user queries *"Nimmy, kal kya hua?"* or *"What happened today?"*, Nimmy synthesizes a chronological timeline by aggregating:
1. `tasks` (completed / created)
2. `calendar_events`
3. `notes`
4. `memories`
5. `recordings` (transcripts)
6. `audit_logs`

### 26.11 Strict Separation of Concerns (No 5x Duplication)
- A **Task** lives in `tasks`.
- A **Reminder** lives in `reminders`.
- A **Calendar Event** lives in `calendar_events`.
- A **Memory** lives in `memories`.
- An **Action Record** lives in `audit_logs`.
The Data Router routes each datum to its singular source of truth.

### 26.12 Prohibited AI Behaviors
1. ❌ Never convert an AI guess or inference into a permanent fact.
2. ❌ Never retrieve or leak deleted memory items.
3. ❌ Never allow old memory to override a current explicit user command.
4. ❌ Never save transient conversational banter as permanent memory.
5. ❌ Never claim external information is "verified" without provenance metadata.
6. ❌ Never falsely claim a failed tool action was successful.
7. ❌ Never silently transmit user data for foundation model pretraining.

## Change Control

This document is the canonical product specification.

Any future implementation plan, architecture document, prompt, or generated code that conflicts with this document must either:

1. Follow this specification; or
2. Explicitly propose a documented change to this specification before implementation.

---

**End of canonical specification.**

