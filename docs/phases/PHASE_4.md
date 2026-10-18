# NIMMY — PHASE 4: Calendar + Reminders + Scheduling

## 1. GOAL
Deliver a production-ready, voice-aware scheduling and calendar system for Nimmy. The system manages calendar events and time-based reminders through typed controlled tools, multi-layer persistence (local in-memory, Hive key-value boxes, Supabase PostgreSQL with RLS, and an offline-first resilient sync repository), explicit risk-classified user confirmations, audit trails with state rollback on failure, natural language scheduling intent parsing, and a glassmorphic calendar and agenda interface.

---

## 2. FEATURES
- **Calendar Event Domain Model**: `NimmyCalendarEvent` supporting meetings, deadlines, reminders, personal events, and AI-scheduled slots with ISO8601 UTC timestamps, location/meeting URL, attendee metadata, recurrence rules, and relational task links.
- **Controlled Calendar & Reminder Tools**:
  - `create_calendar_event`: Requires user confirmation; validates non-empty title and chronological validity (`endTime > startTime`); prevents duplicate submissions via `requestId` idempotency check; logs executed audit event with rollback on persistence failure.
  - `edit_calendar_event`: Modifies title, time window, location, description, or attendees of an existing calendar event; logs executed audit.
  - `reschedule_calendar_event`: Updates `startTime` and `endTime` with optional user-supplied or AI-inferred reason; preserves audit trail.
  - `delete_calendar_event`: Classified as destructive risk; prompts for user confirmation; executes clean removal and audit event.
  - `reschedule_reminder`: Modifies reminder schedule timestamp, cancels prior native alarm, reschedules alarm notification, updates repository, and audits the change with rollback protection.
  - `delete_reminder`: Classified as destructive risk; prompts for confirmation; cancels active alarm notification and removes reminder from persistent storage.
- **Multi-Layer Persistence**:
  - `NimmyRepository` interface extended with calendar event CRUD: `listCalendarEvents`, `findCalendarEventById`, `saveCalendarEvent`, `deleteCalendarEvent`, `listCalendarEventsForRange`.
  - `InMemoryNimmyRepository`: Thread-safe in-memory cache for ultra-fast unit testing.
  - `HiveNimmyRepository`: Local disk storage using encrypted/secure Hive box `nimmy_calendar_events_v1`.
  - `SupabaseNimmyRepository`: Cloud PostgreSQL mirror mapped to the `calendar_events` table with RLS policy enforcement.
  - `OfflineFirstNimmyRepository`: Optimistic local write, queued mutation sync on reconnect, and best-effort remote replication.
- **AI Intent Parsing**:
  - `IntentParser` detects scheduling phrases ("schedule meeting with...", "schedule dentist appointment today at 4pm", "calendar: tax deadline tomorrow at 5pm", "add event...", "new event...").
  - Date and time entity extraction for relative and absolute targets ("today", "tomorrow", "at 3pm", "at 10:30am").
  - Categorizes event type automatically (`meeting`, `deadline`, `personal`).
  - Returns clarification requests when an event title is missing or ambiguous.
- **Glassmorphic Calendar & Agenda Screen**:
  - Month/Year headline with today quick navigation.
  - 14-day interactive date strip with day-of-week, day numbers, and indicator dots for scheduled items.
  - View mode selector: "Agenda" and "Timeline".
  - Unified date agenda aggregating Calendar Events, Reminders, and Due Tasks.
  - Production `_CreateEventSheet` with date picker, start/end time pickers, all-day toggle, event type selector, and validation snackbars.
  - Destructive action confirmation dialogs (`NimmyDialog.showConfirmation`) before deleting events or reminders.
- **Reminders Screen Modernization**:
  - Removed "Coming Soon" placeholder on reminder rescheduling.
  - Integrated interactive `showDatePicker` and `showTimePicker` flow calling `controller.rescheduleReminder`.

---

## 3. DEPENDENCIES
- `provider: ^6.1.2` (reactive state distribution)
- `intl: ^0.19.0` (locale-aware date/time formatting)
- `uuid: ^4.5.1` (RFC-4122 v4 unique ID generation)
- `hive: ^2.2.3` / `hive_flutter: ^1.1.0` (local persistent key-value storage)
- `supabase_flutter: ^2.8.3` (cloud database & RLS)
- Native Android bridge: `NimmyNativeBridge` (AlarmManager scheduling and cancelation)

---

## 4. UI SCREENS
- **`CalendarScreen`** (`apps/mobile/lib/features/calendar/calendar_screen.dart`):
  - Month/Year dynamic header and 'Schedule event' action button.
  - 14-day horizontal scrolling date selector with active date highlight.
  - View switcher (Agenda vs. Timeline).
  - Selected date summary bar with item count badge.
  - Agenda list with dedicated sections: Events (`_AgendaEventCard`), Reminders (`_AgendaReminderCard`), and Tasks Due (`_AgendaTaskCard`).
  - Empty state (`NimmyEmptyState`) with quick "Schedule Event" action when no items exist for the date.
  - `_CreateEventSheet` modal bottom sheet with full validation and custom `Switch.adaptive` for all-day toggle.
- **`RemindersScreen`** (`apps/mobile/lib/features/reminders/reminders_screen.dart`):
  - Interactive reminder item cards with status badges.
  - Real date/time rescheduling sheet triggering `controller.rescheduleReminder`.

---

## 5. USER FLOWS
1. **Natural Language Voice / Text Scheduling**:
   - User: *"Nimmy, schedule Product Roadmap Review tomorrow at 10am"*
   - IntentParser resolves `NimmyIntent.createCalendarEvent` with `CreateCalendarEventInput(title: "Product Roadmap Review", startTime: tomorrow 10:00)`.
   - Tool proposal presented with risk classification requiring confirmation.
   - User confirms: `ToolRegistry.execute(proposal, confirmed: true)` runs.
   - Event saved to local repository + queued for cloud sync; audit log recorded; UI notifies user.
2. **Direct In-App Event Scheduling**:
   - User taps "+" button on `CalendarScreen`.
   - `_CreateEventSheet` opens with initial date set to currently selected day.
   - User enters title, picks start time & end time, selects event type (`meeting`), taps "Schedule Event".
   - `NimmyController.createCalendarEvent` executes tool proposal; event added to date's agenda; success snackbar displayed.
3. **Rescheduling Reminders**:
   - User taps "Reschedule" on a reminder card.
   - Interactive date and time pickers open; user picks new time.
   - `controller.rescheduleReminder` cancels prior alarm, schedules new alarm via native bridge, updates storage, logs audit, and updates UI state.

---

## 6. DATABASE CHANGES
- Uses Supabase migration `004_calendar_events.sql`:
  - Table: `calendar_events` (`id UUID PK`, `user_id UUID FK`, `title TEXT`, `description TEXT`, `start_time TIMESTAMPTZ`, `end_time TIMESTAMPTZ`, `is_all_day BOOLEAN`, `location TEXT`, `event_type TEXT`, `status TEXT`, `recurrence_rule TEXT`, `task_id UUID FK`, `ai_scheduled BOOLEAN`, `metadata JSONB`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`).
  - Row Level Security (RLS) enabled: user can only SELECT, INSERT, UPDATE, DELETE rows where `auth.uid() = user_id`.
  - Indexes on `(user_id, start_time)` and `(user_id, status)`.
- Uses Supabase migration `011_reminders.sql`:
  - Foreign key links from `reminders` to `calendar_events(id)`.

---

## 7. API CONTRACTS
### Tool Registry
```dart
// create_calendar_event
ToolProposal(
  intent: NimmyIntent.createCalendarEvent,
  toolName: 'create_calendar_event',
  input: CreateCalendarEventInput(
    title: String,
    startTime: DateTime,
    endTime: DateTime,
    isAllDay: bool,
    eventType: EventType,
    description: String?,
    location: String?,
  ),
);

// reschedule_reminder
ToolProposal(
  intent: NimmyIntent.rescheduleReminder,
  toolName: 'reschedule_reminder',
  input: RescheduleReminderInput(
    id: String,
    scheduledAt: DateTime,
    reason: String?,
  ),
);
```

---

## 8. PERMISSIONS
- `android.permission.SCHEDULE_EXACT_ALARM`: For alarm notification scheduling via AlarmManager.
- `android.permission.POST_NOTIFICATIONS`: For displaying triggered reminder notifications.
- Audio and speech permissions handled in Phase 6.

---

## 9. SECURITY
- **RLS Enforcement**: Supabase repository binds all calendar queries to authenticated `auth.uid()`.
- **Zero Raw Tokens**: Logger sanitizes all payload metadata, stripping sensitive fields.
- **Rollback on Audit Failure**: If writing the audit log fails, the persisted calendar event or rescheduled reminder is rolled back to prevent unaudited mutations.
- **Idempotency Protection**: Duplicate `requestId` submissions return early with `wasDuplicate: true` and existing record ID.

---

## 10. ERROR STATES
- **Empty Title**: Returns validation error / clarification prompt asking user what event to schedule.
- **Invalid Date Range**: Rejects events where `endTime <= startTime`.
- **Reminder Not Found**: Returns explicit `ToolExecutionResult(success: false, message: 'Reminder not found.')`.
- **Storage Disconnected**: Graceful fallback to offline local cache with queued mutations.

---

## 11. OFFLINE BEHAVIOR
- Calendar events and reminders are persisted locally in Hive boxes (`nimmy_calendar_events_v1`, `nimmy_reminders_v1`).
- Mutations made offline are stored in the local mutation queue and dispatched when online connectivity is restored.
- All agenda queries operate directly on local storage, providing instantaneous offline load times with zero network dependency.

---

## 12. TESTS WITH ACTUAL OUTPUT
All automated tests pass cleanly with 0 failures across the entire test suite:

```text
& "c:\Users\ADMIN\Downloads\Nimmy\flutter\bin\flutter.bat" test
00:18 +35: test/services/calendar_intent_parser_test.dart: parses schedule meeting with tomorrow at 3pm
00:18 +36: test/services/calendar_intent_parser_test.dart: parses schedule dentist appointment today at 4pm
00:18 +37: test/services/calendar_intent_parser_test.dart: parses calendar: prefix and deadline keyword
00:18 +38: test/services/calendar_intent_parser_test.dart: parses add event command with simple time
00:18 +39: test/services/calendar_intent_parser_test.dart: handles wake word with schedule command
00:18 +40: test/services/calendar_intent_parser_test.dart: returns clarification on empty schedule command
00:18 +41: test/services/calendar_repository_test.dart: saves, lists, and retrieves calendar events
00:18 +42: test/services/calendar_repository_test.dart: deletes calendar events cleanly
00:18 +43: test/services/calendar_repository_test.dart: filters events by date range correctly
00:19 +44: test/services/calendar_tool_registry_test.dart: create_calendar_event requires confirmation
00:19 +45: test/services/calendar_tool_registry_test.dart: edit_calendar_event updates event and writes audit
00:19 +46: test/services/calendar_tool_registry_test.dart: reschedule_calendar_event updates time and writes audit with reason
00:19 +47: test/services/calendar_tool_registry_test.dart: delete_calendar_event removes event and writes audit
00:19 +48: test/services/calendar_tool_registry_test.dart: reschedule_reminder updates scheduledAt and schedules notification
00:19 +49: test/services/calendar_tool_registry_test.dart: delete_reminder removes reminder and cancels notification
00:30 +81: All tests passed!
```

Static analysis output:
```text
& "c:\Users\ADMIN\Downloads\Nimmy\flutter\bin\flutter.bat" analyze
Analyzing mobile...
No issues found! (ran in 11.9s)
```

---

## 13. ACCEPTANCE CRITERIA
- [x] Calendar event domain model matches Supabase `calendar_events` schema.
- [x] Multi-layer repository (In-Memory, Hive, Supabase, Offline-First) implements calendar event CRUD.
- [x] Controlled tools created with validation, confirmation policy, idempotency, and audit trails.
- [x] Reminder rescheduling and deletion supported with native alarm scheduling and cancelation.
- [x] Natural language intent parser extracts date, time, title, and event types for calendar commands.
- [x] Production glassmorphic CalendarScreen built with date strip, agenda views, and creation sheet.
- [x] All "Coming soon" stubs removed; real mutations wired up with error handling and snackbars.
- [x] 100% of unit, integration, and UI widget tests pass (81/81 tests passing).
- [x] Flutter analyze reports 0 errors, 0 warnings, and 0 linter hints.

---

## 14. KNOWN LIMITATIONS
- Physical Android alarm delivery verification depends on a connected hardware device or running emulator. Automated native bridge unit mocks verify correct method channel parameters.
- Recurring calendar event expansion on infinite horizons is capped to 1-year window queries.

---

## 15. VERIFICATION RESULTS
- Build: Android and Flutter compile cleanly with zero errors.
- Unit Tests: 81 passed, 0 failed, 0 skipped.
- Static Analysis: 0 issues found.
- Prior Phase Regression: Phase 0, 1, 2, and 3 tests re-run and passing.

---

## 16. FILES CHANGED
- `apps/mobile/lib/models/calendar_event.dart` (created)
- `apps/mobile/lib/models/tool_action.dart` (updated)
- `apps/mobile/lib/services/tools/confirmation_policy.dart` (updated)
- `apps/mobile/lib/services/storage/nimmy_repository.dart` (updated)
- `apps/mobile/lib/services/storage/in_memory_nimmy_repository.dart` (updated)
- `apps/mobile/lib/services/storage/hive_nimmy_repository.dart` (updated)
- `apps/mobile/lib/services/storage/supabase_nimmy_repository.dart` (updated)
- `apps/mobile/lib/services/storage/offline_first_nimmy_repository.dart` (updated)
- `apps/mobile/lib/services/tools/tool_registry.dart` (updated)
- `apps/mobile/lib/services/ai/intent_parser.dart` (updated)
- `apps/mobile/lib/core/state/nimmy_controller.dart` (updated)
- `apps/mobile/lib/features/calendar/calendar_screen.dart` (created/updated)
- `apps/mobile/lib/features/reminders/reminders_screen.dart` (updated)
- `apps/mobile/test/models/calendar_event_test.dart` (created)
- `apps/mobile/test/services/calendar_repository_test.dart` (created)
- `apps/mobile/test/services/calendar_tool_registry_test.dart` (created)
- `apps/mobile/test/services/calendar_intent_parser_test.dart` (created)
- `apps/mobile/test/features/calendar_screen_test.dart` (created)
- `apps/mobile/test/features/app_shell_test.dart` (updated)
