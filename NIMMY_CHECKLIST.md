# 🟣 NIMMY — COMPLETE APP PAGE & WORKFLOW CHECKLIST

> **Core:** Voice-first Personal AI OS
> **Platform:** Android-first
> **Principle:** Har visible feature ya toh working ho, ya clearly **Coming Soon** ho. Fake functionality nahi.
> **Status:** ⬜ = Not Started | 🟡 = In Progress | ✅ = Complete | 🔮 = Future Phase

> **Verification snapshot (2026-09-16):** Dart analyzer, the automated
> parser/tool/widget suite, and the Android `assembleDebug` build pass. Local
> reminder + memory flows are verified in tests. Supabase authentication/cloud
> writes and physical Android behavior still require a configured backend and
> device pass.

---

# 00. 🚀 APP FOUNDATION

### Project

- [x] Flutter project
- [x] Android configuration
- [🟡] Kotlin native bridge (allow-listed source compiles in `assembleDebug`; device behavior pending)
- [x] Environment configuration
- [🟡] Supabase connection (optional adapter exists; authenticated write pending)
- [ ] Authentication
- [x] Local database/cache (Hive)
- [x] Error handling
- [ ] Logging
- [ ] Analytics architecture
- [ ] Secure storage
- [ ] App version/update system

### Global UI

- [x] Dark theme
- [x] Typography
- [x] Spacing system
- [x] Glass cards
- [x] Buttons
- [x] Bottom navigation
- [x] Bottom sheets (confirmation flow)
- [ ] Dialogs
- [ ] Toast/snackbar
- [x] Loading states (controller and voice flow)
- [x] Empty states
- [x] Error states
- [x] Offline/local-only states

---

# 01. 🌌 SPLASH SCREEN

### Page

- [ ] Nimmy logo
- [ ] Animated holographic Orb
- [ ] Loading state
- [ ] App initialization
- [ ] Session check
- [ ] Database connection check
- [ ] Route decision

### Flow

```text
Open App
 ↓
Initialize
 ↓
Check Session
 ↓
Check Local Data
 ↓
Check Configuration
 ↓
Home / Login / Onboarding
```

---

# 02. 👋 ONBOARDING

### Pages

**01 — Welcome**

- [ ] Nimmy introduction
- [ ] Orb animation

**02 — Voice**

- [ ] Explain voice-first interaction
- [ ] Voice demo

**03 — Memory**

- [ ] Explain personal memory
- [ ] User control

**04 — Tasks**

- [ ] Tasks/reminders/schedule

**05 — Privacy**

- [ ] Explain permissions
- [ ] Explain recording
- [ ] Explain memory

### Actions

- [ ] Next
- [ ] Back
- [ ] Skip
- [ ] Get Started

---

# 03. 🔐 LOGIN / ACCOUNT

### Pages

- [ ] Login
- [ ] Sign up
- [ ] Forgot password
- [ ] Email verification
- [ ] Session restoration
- [ ] Logout
- [ ] Delete account

### Check

- [ ] Invalid credentials
- [ ] Network error
- [ ] Loading state
- [ ] Successful login
- [ ] Session persistence

---

# 04. 🛡️ PERMISSION CENTER

**Important:** Permission ko feature-by-feature explain karo. Sab permissions blindly request nahi karni.

### Permissions

- [ ] Microphone
- [ ] Notifications
- [ ] Calendar
- [ ] Contacts — optional
- [ ] Location — optional
- [ ] Biometric
- [ ] Background operation where applicable
- [ ] Relevant Android permissions

### Each permission

```text
Permission
 ↓
Why needed
 ↓
Allow
 ↓
Android permission dialog
 ↓
Granted / Denied
 ↓
Status update
```

### States

- [ ] Allowed
- [ ] Denied
- [ ] Permanently denied
- [ ] Restricted
- [ ] Open Settings

---

# 05. 🏠 HOME / COMMAND CENTER

**Nimmy ka main screen.**

### UI

- [ ] Greeting
- [ ] Date
- [ ] Time
- [ ] Notification
- [ ] Profile
- [ ] Nimmy Orb
- [ ] Orb state
- [ ] Today's progress
- [ ] Top priorities
- [ ] Upcoming event
- [ ] Pending tasks
- [ ] Reminders
- [ ] Quick actions

### Quick actions

- [ ] New Task
- [ ] Reminder
- [ ] Note
- [ ] Record
- [ ] Ask Nimmy

### Working flow

```text
Home
 ↓
Ask Nimmy
 ↓
Voice/Text
 ↓
Intent
 ↓
Tool
 ↓
Confirmation
 ↓
Action
 ↓
Home updates
```

---

# 06. 🟣 NIMMY VOICE CENTER

**Ye app ka primary interaction page hai.**

### States

- [ ] Idle
- [ ] Listening
- [ ] Processing
- [ ] Thinking
- [ ] Confirmation
- [ ] Executing
- [ ] Speaking
- [ ] Success
- [ ] Error

### UI

- [ ] 3D/particle Orb
- [ ] Voice waveform
- [ ] Transcript
- [ ] Stop button
- [ ] Text fallback
- [ ] Mic permission status

### Flow

```text
Tap Nimmy
 ↓
Listening
 ↓
User speaks
 ↓
STT
 ↓
Intent
 ↓
Tool
 ↓
Confirmation
 ↓
Action
 ↓
Nimmy speaks
```

---

# 07. 🧠 AI CONVERSATION

### Page

- [ ] Conversation history
- [ ] User messages
- [ ] Nimmy responses
- [ ] Tool action cards
- [ ] Confirmation cards
- [ ] Voice response
- [ ] Text input
- [ ] Voice input
- [ ] Stop generation
- [ ] Retry

### Special states

- [ ] AI unavailable
- [ ] Timeout
- [ ] No internet
- [ ] Unknown command
- [ ] Ambiguous command

---

# 08. 🎯 TASKS

### Pages

- [ ] Task dashboard
- [ ] Today
- [ ] Upcoming
- [ ] Overdue
- [ ] Completed
- [ ] Task details
- [ ] Create task
- [ ] Edit task

### Task data

- [ ] Title
- [ ] Description
- [ ] Priority
- [ ] Date
- [ ] Time
- [ ] Duration
- [ ] Project
- [ ] Reminder
- [ ] Recurrence
- [ ] Subtasks
- [ ] Notes
- [ ] Attachments

### Task states

- [ ] Inbox
- [ ] Planned
- [ ] In Progress
- [ ] Completed
- [ ] Postponed
- [ ] Cancelled
- [ ] Overdue

---

# 09. ⏰ REMINDERS

### Pages

- [x] Reminder list
- [x] Create reminder (voice/text proposal + confirmation)
- [ ] Reminder details
- [ ] Edit
- [ ] History

### Types

- [x] One-time
- [🟡] Recurring (parser exists; notification/device verification pending)
- [ ] Deadline
- [ ] Follow-up

### MVP

**`create_reminder()` must actually work.**

### Flow

```text
Voice/Text
 ↓
CREATE_REMINDER
 ↓
Parse title/date/time
 ↓
Validate
 ↓
Confirmation
 ↓
Save DB
 ↓
Audit
 ↓
Schedule notification
 ↓
Nimmy response
```

### MVP implementation status

- [x] Save to local repository
- [x] Append proposed/confirmed/executed audit events
- [x] Attempt notification scheduling with truthful warning
- [x] Refresh UI and response
- [🟡] Authenticated Supabase write (adapter exists; configured backend pending)

---

# 10. 📅 CALENDAR

### Views

- [ ] Day
- [ ] Week
- [ ] Month
- [ ] Agenda

### Functions

- [ ] Create event
- [ ] Edit event
- [ ] Delete event
- [ ] Event details
- [ ] Conflict display
- [ ] Calendar permission

### AI

> "Nimmy, what's on my calendar tomorrow?"

→ Calendar data.

---

# 11. 📝 NOTES

### Pages

- [ ] Notes home
- [ ] Create note
- [ ] Note editor
- [ ] Note details
- [ ] Pinned notes
- [ ] Search
- [ ] Categories

### Actions

- [ ] Create
- [ ] Edit
- [ ] Delete
- [ ] Pin
- [ ] Archive
- [ ] Search

---

# 12. 🧠 MEMORY VAULT

**Nimmy ki long-term personal memory.**

### Pages

- [x] Memory home
- [x] All memories
- [ ] Personal
- [x] Preferences
- [x] Goals
- [x] Projects
- [ ] Important
- [x] Recent
- [x] Memory details

### Every memory

- [x] Content
- [x] Category
- [x] Source
- [ ] Confidence/internal metadata
- [x] Created date
- [x] Updated date
- [x] User confirmed by tool policy
- [x] Edit
- [x] Delete

### MVP

**`save_memory()` must actually work.**

---

# 13. 🧠 MEMORY CREATION FLOW

```text
User:
"Nimmy, remember this..."
        ↓
STT
        ↓
Intent Detection
        ↓
SAVE_MEMORY
        ↓
Memory Candidate
        ↓
Confirmation
        ↓
User confirms
        ↓
Supabase
        ↓
Audit Log
        ↓
Memory appears in Vault
        ↓
Nimmy confirms
```

### Checklist

- [x] Explicit memory
- [x] Confirmation
- [x] Save
- [x] Search
- [x] Edit
- [x] Delete
- [x] Audit
- [x] Source tracking

---

# 14. 🎧 RECORDINGS

### Pages

- [ ] Recording home
- [ ] Start recording
- [ ] Recording active
- [ ] Pause
- [ ] Stop
- [ ] Processing
- [ ] Recording details
- [ ] Transcript
- [ ] Summary
- [ ] Save permanently
- [ ] Delete

### States

```text
Ready
 ↓
Recording
 ↓
Paused
 ↓
Processing
 ↓
Completed
 ↓
Saved / Temporary
```

### Android

- [ ] Explicit user initiation
- [ ] Foreground service
- [ ] Visible recording indication
- [ ] Screen-off support where Android permits
- [ ] Permission handling
- [ ] Battery handling
- [ ] Stop recording reliably

---

# 15. 📝 RECORDING → AI SUMMARY

Future production workflow:

```text
Audio
 ↓
Transcription
 ↓
AI
 ↓
Summary
 ├── Key Points
 ├── Decisions
 ├── Tasks
 ├── Deadlines
 ├── People
 ├── Ideas
 └── Follow-ups
```

### Checklist

- [ ] Transcript
- [ ] Summary
- [ ] Key points
- [ ] Task extraction
- [ ] Deadline extraction
- [ ] Save as note
- [ ] User approval before important mutations

---

# 16. ⏳ 7-DAY RECORDING RETENTION

```text
Recording Created
       ↓
Temporary
       ↓
7-Day Timer
       ↓
User saves?
   ↙         ↘
YES          NO
 ↓            ↓
Retain       Delete
```

### Checklist

- [ ] `created_at`
- [ ] `expires_at`
- [ ] Temporary status
- [ ] Save permanently
- [ ] Delete immediately
- [ ] Automatic expiry job
- [ ] Audio deletion
- [ ] Temporary transcript/derived-data deletion according to policy
- [ ] UI shows expiry date

---

# 17. 🧠 "WHAT HAPPENED?" / I FORGOT

**Major Nimmy feature.**

### Page

**My Timeline**

Sources:

- [ ] Tasks
- [ ] Calendar
- [ ] Notes
- [ ] Memories
- [ ] Saved recordings
- [ ] Audit history

### Commands

> "Nimmy, what happened yesterday?"

> "What did I complete?"

> "What did I miss?"

> "What did we decide?"

### Flow

```text
Question
 ↓
Context Resolver
 ↓
Search relevant sources
 ↓
Rank results
 ↓
Generate timeline
 ↓
Nimmy answer
```

---

# 18. 🔎 UNIVERSAL SEARCH

One search across:

- [ ] Tasks
- [ ] Notes
- [ ] Memories
- [ ] Recordings
- [ ] Calendar
- [ ] Projects
- [ ] Conversations

### Future

- [ ] Semantic search
- [ ] Embeddings
- [ ] pgvector
- [ ] RAG

---

# 19. 📁 PROJECTS

### Pages

- [ ] Project list
- [ ] Project details
- [ ] Project tasks
- [ ] Project notes
- [ ] Project memories
- [ ] Project timeline
- [ ] Project progress

### Flow

```text
Project
 ↓
Tasks
 ↓
Notes
 ↓
Memory
 ↓
Calendar
```

---

# 20. 🎯 GOALS

### Pages

- [ ] Goals
- [ ] Goal details
- [ ] Milestones
- [ ] Progress

### Flow

```text
Goal
 ↓
Milestone
 ↓
Project
 ↓
Task
 ↓
Daily action
```

---

# 21. 🔁 HABITS

### Features

- [ ] Create habit
- [ ] Daily/weekly recurrence
- [ ] Completion
- [ ] Streak
- [ ] History
- [ ] Reminder

---

# 22. ⚡ AUTOMATIONS

### Page

**Automation Center**

Example:

```text
WHEN task becomes overdue
        ↓
Ask Nimmy to reschedule
```

Other future workflows:

```text
Recording ends
 ↓
Create summary
```

```text
Morning
 ↓
Daily briefing
```

```text
Temporary recording expires
 ↓
Delete
```

---

# 23. 📩 MESSAGE CENTER

### Pages

- [ ] Scheduled
- [ ] Drafts
- [ ] Sent
- [ ] Templates

### Data

- [ ] Recipient
- [ ] Platform
- [ ] Message
- [ ] Schedule
- [ ] Status

### Supported integration only.

```text
Create
 ↓
Preview
 ↓
Confirmation
 ↓
Schedule
 ↓
Supported integration
 ↓
Actual result
 ↓
Audit
```

No fake "sent successfully."

---

# 24. 📱 APP LAUNCHER

### Page

- [ ] Search apps
- [ ] App grid
- [ ] Recent apps
- [ ] Favorites

### Voice

> "Nimmy, open Telegram."

```text
Voice
 ↓
OPEN_APP
 ↓
Validate installed/supported app
 ↓
Android launch/deep link
 ↓
Open
```

---

# 25. 📊 ANALYTICS

### Pages

- [ ] Daily
- [ ] Weekly
- [ ] Monthly
- [ ] Goals
- [ ] Tasks
- [ ] Focus
- [ ] Habits

### Metrics

- [ ] Completed tasks
- [ ] Pending
- [ ] Overdue
- [ ] Postponed
- [ ] Focus sessions
- [ ] Goal progress
- [ ] Habit consistency

---

# 26. 🌅 DAILY BRIEFING

Morning:

```text
Good morning.
 ↓
Calendar
 ↓
Tasks
 ↓
Reminders
 ↓
Deadlines
 ↓
Goals
 ↓
Priorities
 ↓
AI plan
```

### Checklist

- [ ] Today's summary
- [ ] Top 3 priorities
- [ ] Calendar
- [ ] Deadlines
- [ ] Reminders
- [ ] Suggested plan

---

# 27. 🌙 DAILY REVIEW

Night:

```text
Today's data
 ↓
Completed
 ↓
Pending
 ↓
Postponed
 ↓
Important events
 ↓
Memory
 ↓
Tomorrow preparation
```

---

# 28. 🎯 FOCUS MODE

### Page

- [ ] Current task
- [ ] Timer
- [ ] Progress
- [ ] Pause
- [ ] Complete
- [ ] Session history

Voice:

> "Nimmy, start a 45 minute focus session."

---

# 29. 📜 AUDIT HISTORY

**Critical system page.**

Every meaningful AI action:

- [ ] Timestamp
- [ ] User command
- [ ] Intent
- [ ] Tool
- [ ] Action
- [ ] Result
- [ ] Confirmation
- [ ] Status

Example:

```text
12:30
User: "Remind me at 9."

Intent:
CREATE_REMINDER

Confirmation:
YES

Result:
SUCCESS
```

---

# 30. 🔐 PRIVACY CENTER

### User can see:

- [ ] Microphone
- [ ] Notifications
- [ ] Calendar
- [ ] Contacts
- [ ] Location
- [ ] Connected apps
- [ ] Memory
- [ ] Recordings

### Controls

- [ ] Enable
- [ ] Disable
- [ ] Open Android Settings
- [ ] Delete data
- [ ] Export data

---

# 31. 🔒 SECURITY

- [ ] Authentication
- [ ] Secure token storage
- [ ] Android Keystore where appropriate
- [ ] Biometric lock
- [ ] PIN
- [ ] Supabase RLS
- [ ] Input validation
- [ ] Rate limiting
- [ ] API security
- [ ] No secrets in source
- [ ] Environment variables

---

# 32. 📦 DATA & STORAGE

### Page

**Data & Storage**

- [ ] Storage usage
- [ ] Recordings
- [ ] Temporary files
- [ ] Cached data
- [ ] Sync status
- [ ] Export
- [ ] Delete account/data

---

# 33. 🔄 SYNC CENTER

```text
Local
 ↓
Offline queue
 ↓
Internet restored
 ↓
Sync
 ↓
Conflict detection
 ↓
Resolve
 ↓
Cloud
```

### Checklist

- [ ] Offline indicator
- [ ] Syncing
- [ ] Synced
- [ ] Failed
- [ ] Retry
- [ ] Conflict handling

---

# 34. 📶 OFFLINE MODE

At minimum:

- [ ] View tasks
- [ ] Create local tasks
- [ ] Notes
- [ ] Cached memories
- [ ] Local recording architecture
- [ ] Local UI
- [ ] Sync queue

AI-dependent features clearly show:

> "Nimmy AI needs an internet connection."

unless a local model is actually implemented.

---

# 35. 👤 PROFILE

- [ ] Name
- [ ] Email
- [ ] Avatar
- [ ] Timezone
- [ ] Language
- [ ] Voice
- [ ] Account
- [ ] Security

---

# 36. ⚙️ SETTINGS

### Sections

**Nimmy**

- [ ] Voice
- [ ] AI preferences
- [ ] Response style

**Notifications**

- [ ] Reminders
- [ ] Daily briefing
- [ ] Task alerts

**Memory**

- [ ] Memory settings
- [ ] Review memories
- [ ] Delete memories

**Recording**

- [ ] Retention
- [ ] Storage
- [ ] Recording settings

**Privacy**

- [ ] Permissions
- [ ] Data controls

**Appearance**

- [ ] Dark
- [ ] Light future
- [ ] Accent

**Connected Apps**

- [ ] Manage integrations

---

# 37. 🟣 NIMMY ORB DESIGN SYSTEM

Every state must be tested:

- [ ] Idle
- [ ] Listening
- [ ] Thinking
- [ ] Speaking
- [ ] Recording
- [ ] Success
- [ ] Error
- [ ] Offline
- [ ] Disabled

### Performance

- [ ] Smooth animation
- [ ] Battery conscious
- [ ] Mid-range Android tested
- [ ] No excessive GPU usage
- [ ] Reduced-motion support

---

# 38. 🧠 AI INTELLIGENCE LAYER

This is the hidden backbone.

```text
Input
 ↓
Speech/Text
 ↓
Intent
 ↓
Entity extraction
 ↓
Context
 ↓
Memory retrieval
 ↓
Knowledge routing
 ↓
Tool selection
 ↓
Validation
 ↓
Confirmation
 ↓
Execution
 ↓
Audit
 ↓
Response
 ↓
Feedback
```

### Components

- [ ] Intent Engine
- [ ] Context Engine
- [ ] Memory Engine
- [ ] Tool Router
- [ ] Tool Validator
- [ ] Confirmation Engine
- [ ] Knowledge Router
- [ ] Provenance
- [ ] Confidence
- [ ] Conflict Resolver
- [ ] Feedback
- [ ] Audit

---

# 39. 🧠 AI LEARNING SYSTEM

### Nimmy learns through:

- [ ] Explicit memories
- [ ] User corrections
- [ ] Confirmed preferences
- [ ] Repeated patterns
- [ ] Feedback
- [ ] Context

### It must NOT:

- [ ] Treat guesses as facts
- [ ] Save everything permanently
- [ ] Ignore corrections
- [ ] Override current instructions with old memories
- [ ] Claim unsupported information is verified

---

# 40. 🗃️ DATA ROUTER

Har information ko correct location par jaana chahiye.

```text
USER INPUT
    ↓
DATA ROUTER
    │
    ├── Task → Tasks
    ├── Reminder → Reminders
    ├── Event → Calendar
    ├── Note → Notes
    ├── Memory → Memory
    ├── Recording → Recordings
    ├── Message → Message Queue
    └── Audit → Audit Logs
```

---

# 41. 🔥 CRITICAL END-TO-END TESTS

Ye **green checklist** sabse important hai.

### Test 01 — Reminder

- [ ] Voice works
- [ ] STT works
- [x] Intent = CREATE_REMINDER (parser test)
- [x] Date parsed (parser test)
- [x] Time parsed (including AM/PM clarification)
- [x] Confirmation appears (controller/widget flow)
- [x] Confirm works (tool test)
- [x] Database updates (in-memory/local repository test)
- [x] Reminder scheduled attempt (scheduler test double)
- [x] Audit created (tool test)
- [x] Nimmy responds (controller flow)

### Test 02 — Memory

- [ ] Voice works
- [ ] STT works
- [x] Intent = SAVE_MEMORY (parser test)
- [x] Memory candidate generated
- [x] Confirmation appears
- [x] Save works
- [x] Database updates (local repository test)
- [x] Memory Vault updates (widget/controller flow)
- [x] Audit created
- [x] Search finds memory
- [x] Edit works
- [x] Delete works

---

# 42. 🧪 ERROR TESTING

Har important feature ke liye:

- [ ] No internet
- [ ] AI unavailable
- [ ] Database unavailable
- [ ] Permission denied
- [ ] Invalid input
- [ ] Missing time
- [ ] Missing date
- [ ] Ambiguous command
- [ ] Duplicate command
- [ ] Timeout
- [ ] User cancels
- [ ] User edits
- [ ] Tool failure

---

# 43. 📱 ANDROID REAL DEVICE TEST

Emulator enough nahi.

- [ ] Real Android phone
- [ ] Screen ON
- [ ] Screen OFF
- [ ] App foreground
- [ ] App background
- [ ] App killed
- [ ] Restart
- [ ] Battery saver
- [ ] Network OFF
- [ ] Network ON
- [ ] Permission revoked
- [ ] Notification disabled

Especially recording/voice features ko real device par test karna hoga.

---

# 44. 🚀 FUTURE — CLEARLY SEPARATED

### Phase 2+

- [ ] Full recording AI pipeline
- [ ] "What happened?"
- [ ] Advanced memory
- [ ] Semantic search
- [ ] RAG
- [ ] Smart planning
- [ ] Automation engine
- [ ] Supported integrations

### Later

- [ ] Go infrastructure
- [ ] Rust performance modules
- [ ] C++ DSP if actually required
- [ ] Knowledge graph
- [ ] Advanced agent capabilities
- [ ] Multi-device
- [ ] Wearables
- [ ] Desktop
- [ ] Advanced local AI

**UI mein future feature ko working feature ki tarah mat dikhana.**

---

# ✅ NIMMY MASTER COMPLETION CHECK

Development complete tab maana jayega jab:

- [ ] App launches
- [ ] Onboarding works
- [ ] Authentication works
- [ ] Permissions work
- [ ] Home works
- [ ] Nimmy Orb works
- [ ] Voice UI works
- [ ] STT works
- [ ] Intent works
- [ ] Tool router works
- [ ] Confirmation works
- [ ] create_reminder works
- [ ] save_memory works
- [ ] Supabase writes work
- [ ] Audit works
- [ ] Error handling works
- [ ] Offline state works
- [ ] Security works
- [ ] Real-device testing passed
- [ ] No fake functionality
- [ ] No exposed secrets

---

## 🟣 Nimmy ka ultimate workflow

```text
             👤 YOU
               ↓
        🎙️ TALK TO NIMMY
               ↓
        🧠 UNDERSTAND
               ↓
        🔎 FIND CONTEXT
               ↓
       🧠 CHECK MEMORY
               ↓
       🛠️ SELECT TOOL
               ↓
          VALIDATE
               ↓
       🔐 CONFIRM
               ↓
           EXECUTE
               ↓
        💾 DATABASE
               ↓
         📜 AUDIT LOG
               ↓
       🧠 UPDATE CONTEXT
               ↓
       🔊 NIMMY RESPONSE
               ↓
        👤 USER FEEDBACK
               ↓
       🧠 LEARN/CORRECT
```

---

> **Rule:** Is checklist mein sirf UI complete hona enough nahi — **UI + state + backend + error handling + permissions + actual action + audit** complete hone par hi ✅ lagana hai.
