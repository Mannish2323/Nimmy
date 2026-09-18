# NIMMY — Screen and Navigation Map

## Current mobile routes

```text
App bootstrap
  └─ /home  (ShellRoute)
      ├─ /tasks       Coming Soon / empty state
      ├─ /calendar    Coming Soon / empty state
      ├─ /memory      Memory Vault (search, edit, delete)
      └─ /more
          ├─ /reminders   Reminder list + delete/cancel
          ├─ /audit       Action history
          ├─ /permissions Permission Center
          ├─ /notes       Coming Soon / empty state
          └─ /settings    truthful local/cloud/settings status

Root modal routes:
  /voice  Nimmy Voice Center
```

The center orb action opens `/voice`. Bottom navigation is Home, Tasks,
Calendar, Memory, and More. An unavailable feature is rendered as a clear
`COMING SOON` state rather than a dead action.

## Voice flow

```text
idle
  → listening (speech plugin permission)
  → understanding
  → confirmation sheet
  → executing
  → success or error
  → speaking (optional TTS)
  → idle
```

Every state has a visible cancel/stop path. Text input is available when speech
recognition is unavailable or the user prefers typing.

## Orb state language

The orb is a live particle widget and receives `NimmyOrbState` from the
controller. Implemented states are idle, listening, understanding, confirming,
executing, success, speaking, error, and recording. Recording is visual-only in
MVP until the production recording pipeline exists.

## Future route groups

Splash/onboarding/auth restoration, AI conversation history, task CRUD,
calendar, notes editor, recordings, timeline/“what happened?”, universal
search, projects, goals, habits, automations, message center, app launcher,
analytics, briefing, review, focus mode, profile, data export, and account
deletion are planned route groups. They must be added with real state,
permissions, errors, and audit coverage before being marked complete.

