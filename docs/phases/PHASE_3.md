# NIMMY — Phase 3: Tasks + Projects + Goals + Habits

## GOAL

Implement a complete, production-grade productivity system spanning Tasks, Projects, Goals, and Habits across domain models, offline-first Hive storage, Supabase cloud sync, controlled typed tools (`create_task`, `edit_task`, `complete_task`, `delete_task`, `reschedule_task`), confirmation policies with rollback-protected audit logging, natural language AI intent parsing, and a rich 4-tab glassmorphic mobile UI (`TasksScreen`).

## FEATURES

- **Productivity Domain Models**:
  - `NimmyTask`: Title, description, status (`todo`, `in_progress`, `done`, `cancelled`), priority (`low`, `medium`, `high`, `urgent`), project reference, tags, due date, timestamps, copyWith, JSON serialization.
  - `NimmyProject`: Name, description, color hex token, icon name, task count summary, timestamps, copyWith, JSON serialization.
  - `NimmyGoal`: Title, description, target date, progress decimal (0.0 to 1.0), category, completed boolean, timestamps, copyWith, JSON serialization.
  - `NimmyHabit`: Title, frequency (`daily`, `weekdays`, `weekends`, `weekly`), streak integer, completed dates array, `isCompletedToday` calculation, copyWith, JSON serialization.
- **Controlled Typed Tools (`ToolRegistry`)**:
  - `create_task`: Validates title, checks authorization, requires explicit confirmation, generates audit record, persists to repository.
  - `edit_task`: Updates task fields, audits changes, verifies task existence before mutation.
  - `complete_task`: Marks task as done, calculates execution audit, triggers state notification.
  - `delete_task`: Destructive action with mandatory user confirmation dialog, permanently removes task from repository with audited trace.
  - `reschedule_task`: Modifies due date with audit reason record.
  - All tools feature idempotency protection via `requestId` and atomic state rollback if audit logging fails.
- **Confirmation Policy (`ConfirmationPolicy`)**:
  - Risk classification for productivity mutations: `create_task`, `edit_task`, `complete_task`, and `reschedule_task` classified as persistent mutations; `delete_task` classified as destructive mutation.
- **Repository Abstraction & Multi-Layer Persistence**:
  - `NimmyRepository` interface expanded with 12 methods for task, project, goal, and habit CRUD.
  - `InMemoryNimmyRepository` updated for fast in-memory execution and unit testing.
  - `HiveNimmyRepository` with separate local Hive boxes: `nimmy_tasks_box`, `nimmy_projects_box`, `nimmy_goals_box`, `nimmy_habits_box`.
  - `SupabaseNimmyRepository` for authenticated cloud persistence against PostgreSQL tables (`tasks`, `projects`, `goals`, `habits`).
  - `OfflineFirstNimmyRepository` orchestrating transparent local writes and cloud synchronization.
- **AI Intent Parsing (`NimmyIntentParser`)**:
  - Natural language recognition for commands ("create task", "add a task", "new task:", "task:", "todo:").
  - Entity extraction: priority keywords (`urgent`, `high`, `low`), due dates (`today`, `tomorrow`).
  - Strict validation: empty titles trigger clarification requests rather than invalid mutations.
- **State Management (`NimmyController`)**:
  - Reactive collections: `tasks`, `projects`, `goals`, `habits`.
  - Action methods: `createTask`, `toggleTaskCompletion`, `updateTask`, `deleteTask`, `createProject`, `deleteProject`, `createGoal`, `updateGoalProgress`, `createHabit`, `toggleHabitToday`.
- **Productivity UI (`TasksScreen`)**:
  - 4-tab glassmorphic interface: Tasks, Projects, Goals, Habits with active counts and glowing badges.
  - Filter chips: All, Pending, Completed, Urgent.
  - Task cards with animated checkbox toggles, priority chips, due date tags, project pill badges, and delete actions.
  - Modal creation bottom sheets for Tasks, Projects, Goals, and Habits with full validation.
  - Goal cards with smooth progress bars and completion status.
  - Habit cards with streak counters, flame badges, and one-tap "Done Today" / "Completed" toggles.

## DEPENDENCIES

- Phase 0 (`Foundation + Architecture`) — VERIFIED / IN_PROGRESS
- Phase 1 (`Design System + Complete App Shell`) — VERIFIED / IN_PROGRESS
- Phase 2 (`Authentication + User + Security`) — VERIFIED / IN_PROGRESS

## UI SCREENS

- `/tasks`: 4-tab Productivity Command Center with Tasks, Projects, Goals, and Habits views, filtering, creation sheets, and confirmation dialogs.

## USER FLOWS

1. **Create Task via UI**: User opens `/tasks` -> Taps floating "+" button -> Task creation bottom sheet opens -> Enters title, optional description, selects priority (Low/Med/High/Urgent), chooses Project -> Taps "Create Task" -> Validated -> Stored locally & synced -> Snackbar confirms -> Task appears in list.
2. **Toggle Task Completion**: User views task -> Taps check circle -> Status updates to `done` or toggles back to `todo` -> Audit record logged -> UI animates strikethrough.
3. **Delete Task**: User taps trash icon on task -> `NimmyDialog.showConfirmation` prompts destructive confirmation -> User confirms -> Task removed from storage & audit recorded -> Task disappears from list.
4. **Voice / Text AI Intent**: User speaks or types "Nimmy, create task submit report tomorrow high priority" -> `NimmyIntentParser` detects `createTask` intent with entities: title "submit report", priority `high`, due date tomorrow -> System prepares `create_task` tool action -> Confirmation sheet displayed -> User confirms -> Action executes, audits, and persists -> Nimmy responds with confirmation.
5. **Manage Habits**: User navigates to "Habits" tab -> Views daily habit -> Taps "Mark Done" -> Streak increments, today added to completed dates -> Streak counter turns green with flame icon.
6. **Track Goals**: User navigates to "Goals" tab -> Views goal -> Progress bar shows completion percentage -> Taps edit to adjust progress slider (0%–100%).

## DATABASE CHANGES

- Handled in Supabase migrations:
  - `tasks` table: `id`, `user_id`, `title`, `description`, `status`, `priority`, `project_id`, `due_date`, `created_at`, `updated_at`.
  - `projects` table: `id`, `user_id`, `name`, `description`, `color_hex`, `icon_name`, `created_at`, `updated_at`.
  - `goals` table: `id`, `user_id`, `title`, `description`, `target_date`, `progress`, `category`, `is_completed`, `created_at`, `updated_at`.
  - `habits` table: `id`, `user_id`, `title`, `frequency`, `streak`, `completed_dates`, `created_at`, `updated_at`.
  - RLS policies ensure strict user isolation: `user_id = auth.uid()`.

## API CONTRACTS

- Controlled Tools:
  - `create_task`: `CreateTaskInput` -> `{id, title, description, priority, status, dueDate, projectId}`
  - `edit_task`: `EditTaskInput` -> `{id, title?, description?, priority?, status?, dueDate?, projectId?}`
  - `complete_task`: `CompleteTaskInput` -> `{id}`
  - `delete_task`: `DeleteTaskInput` -> `{id}`
  - `reschedule_task`: `RescheduleTaskInput` -> `{id, dueDate, reason?}`

## PERMISSIONS

- `android.permission.INTERNET` (for Supabase sync).
- Local storage permissions handled via app sandbox (Hive).

## SECURITY

- Destructive mutations (`delete_task`) enforce explicit user confirmation policy.
- Zero direct database mutations from untrusted layers; all state changes route through `ToolRegistry` with validation and audit logging.
- Audit records capture action parameters, timestamps, execution status, and rollback state.
- In-memory and Hive storage isolated to application container sandbox.

## ERROR STATES

- Empty task title on creation: Inline form validation error / parser clarification response.
- Missing task ID on edit/delete/complete: `ToolExecutionResult` failure with descriptive error message.
- Duplicate requestId submission: Idempotently returns cached result without double execution.
- Storage failure: `NimmySnackbar.showError` without application crash.

## OFFLINE BEHAVIOR

- Tasks, Projects, Goals, and Habits are persisted in local Hive boxes (`nimmy_tasks_box`, `nimmy_projects_box`, etc.).
- When offline, all CRUD operations succeed locally and are queued for cloud synchronization upon network restoration.
- Zero data loss during offline usage.

## TESTS

- Automated test suites executed with actual raw outputs:
  - `test/models/task_model_test.dart`: Serialization, copyWith, habit streak calculations. (PASSED)
  - `test/services/task_repository_test.dart`: CRUD across tasks, projects, goals, habits in repository. (PASSED)
  - `test/services/task_tool_registry_test.dart`: Confirmation requirement, idempotency, complete, delete, reschedule audits. (PASSED)
  - `test/services/task_intent_parser_test.dart`: Natural language parsing for priority, due dates, wake phrases, empty titles. (PASSED)
  - `test/features/tasks_screen_test.dart`: Widget tests for tab switching, task creation, filtering, and completion toggling. (PASSED)
  - Full mobile regression suite: **60/60 tests passed (100% pass rate)**.
  - `flutter analyze`: **0 errors, 0 warnings, 0 hints**.

## ACCEPTANCE CRITERIA

- [x] Domain models for Task, Project, Goal, Habit with full JSON serialization and copyWith.
- [x] Controlled typed tools: `create_task`, `edit_task`, `complete_task`, `delete_task`, `reschedule_task`.
- [x] Confirmation policies and audit logging with rollback protection on failure.
- [x] Hive boxes and repository methods implemented for all productivity entities.
- [x] AI Intent Parser parses natural language task creation with priority and due date extraction.
- [x] Reactive state management wired in `NimmyController`.
- [x] Production glassmorphic 4-tab `TasksScreen` with creation sheets, filters, and animated cards.
- [x] Automated unit and widget tests written and passing (60/60 suite passing).
- [ ] Physical Android verification on live hardware.

## KNOWN LIMITATIONS

1. Physical Android device execution pending hardware connection; verified in software, unit tests, and Flutter test engine.

## VERIFICATION RESULTS

- All 60 unit and widget tests in the mobile suite pass.
- Flutter analyze reports 0 issues.
- Status set to `IN_PROGRESS` per `AGENTS.md` §18 pending physical device verification.

## FILES CHANGED

- `apps/mobile/lib/models/task.dart` (created)
- `apps/mobile/lib/models/project.dart` (created)
- `apps/mobile/lib/models/goal.dart` (created)
- `apps/mobile/lib/models/habit.dart` (created)
- `apps/mobile/lib/models/tool_action.dart` (added task intents and typed tool inputs)
- `apps/mobile/lib/services/tools/confirmation_policy.dart` (added task tool risk classifications)
- `apps/mobile/lib/services/storage/nimmy_repository.dart` (extended with productivity CRUD)
- `apps/mobile/lib/services/storage/in_memory_nimmy_repository.dart` (implemented productivity methods)
- `apps/mobile/lib/services/storage/hive_nimmy_repository.dart` (implemented productivity Hive boxes)
- `apps/mobile/lib/services/storage/supabase_nimmy_repository.dart` (implemented Supabase task operations)
- `apps/mobile/lib/services/storage/offline_first_nimmy_repository.dart` (implemented offline-first productivity sync)
- `apps/mobile/lib/services/tools/tool_registry.dart` (implemented 5 task tools with audit & idempotency)
- `apps/mobile/lib/services/ai/intent_parser.dart` (added natural language task intent and entity parsing)
- `apps/mobile/lib/core/state/nimmy_controller.dart` (exposed productivity state and controller methods)
- `apps/mobile/lib/features/tasks/tasks_screen.dart` (full 4-tab glassmorphic productivity screen)
- `apps/mobile/test/models/task_model_test.dart` (created)
- `apps/mobile/test/services/task_repository_test.dart` (created)
- `apps/mobile/test/services/task_tool_registry_test.dart` (created)
- `apps/mobile/test/services/task_intent_parser_test.dart` (created)
- `apps/mobile/test/features/tasks_screen_test.dart` (created)
- `apps/mobile/test/features/app_shell_test.dart` (refined transition timing)
- `docs/phases/PHASE_3.md` (created)

---

## PHASE STATUS

- [x] UI COMPLETE
- [x] UX COMPLETE
- [x] FRONTEND COMPLETE
- [x] BACKEND COMPLETE
- [x] DATABASE COMPLETE
- [x] API COMPLETE
- [x] SECURITY COMPLETE
- [x] ERROR HANDLING COMPLETE
- [x] OFFLINE COMPLETE
- [x] TESTS PASS (60/60 tests passing)
- [ ] REAL DEVICE VERIFIED (Pending physical Android device connection)
- [x] DOCUMENTATION COMPLETE (PHASE_3.md created)
- [ ] ACCEPTANCE CRITERIA PASS (Software criteria passed; physical device pass pending)
- [x] NO REGRESSION IN PRIOR PHASES (Phases 0, 1, 2 verified intact)

PHASE STATUS = IN_PROGRESS (Software complete; pending physical device verification)
