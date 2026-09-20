# NIMMY — Master Feature Matrix

> Every feature must appear. No feature may exist only in UI without a corresponding status and evidence link.
> Status: `NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `VERIFIED`, `COMPLETE`

## Phase 0 — Foundation

| Feature | Screen | Frontend | Backend | Database | API | Permission | Confirmation | Offline | Sync | Audit | Tests | Real Device | Evidence | Status |
|---------|--------|----------|---------|----------|-----|------------|--------------|---------|------|-------|-------|-------------|----------|--------|
| Flutter project setup | — | ✅ | — | — | — | — | — | — | — | — | — | — | pubspec.yaml exists | IN_PROGRESS |
| Android config | — | ✅ | — | — | — | — | — | — | — | — | — | Pending | build.gradle.kts exists | IN_PROGRESS |
| Kotlin bridge | — | ✅ | — | — | — | — | — | — | — | — | — | Pending | nimmy_bridge.dart | IN_PROGRESS |
| Environment config | — | ✅ | — | — | — | — | — | — | — | — | — | — | app_config.dart | IN_PROGRESS |
| Local database | — | ✅ | — | ✅ | — | — | — | ✅ | — | — | ✅ | — | hive_nimmy_repository.dart | IN_PROGRESS |
| Error handling | — | ✅ | — | — | — | — | — | — | — | — | — | — | try/catch in controller | IN_PROGRESS |

## Phase 1 — Design System + App Shell

| Feature | Screen | Frontend | Backend | Database | API | Permission | Confirmation | Offline | Sync | Audit | Tests | Real Device | Evidence | Status |
|---------|--------|----------|---------|----------|-----|------------|--------------|---------|------|-------|-------|-------------|----------|--------|
| Dark theme | All | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ | Pending | app_theme.dart | VERIFIED |
| Bottom navigation | Shell | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ (1) | Pending | app_shell.dart, app_shell_test.dart | VERIFIED |
| Glass cards | Shared | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ | Pending | glass_card.dart | VERIFIED |
| NimmyDialog | Shared | ✅ | N/A | N/A | N/A | — | ✅ | ✅ | — | — | ✅ (2) | Pending | nimmy_dialog.dart, design_system_test.dart | VERIFIED |
| NimmySnackbar | Shared | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ (2) | Pending | nimmy_snackbar.dart, design_system_test.dart | VERIFIED |
| LoadingShimmer | Shared | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ (2) | Pending | loading_shimmer.dart, design_system_test.dart | VERIFIED |
| ErrorView | Shared | ✅ | N/A | N/A | N/A | — | — | ✅ | — | — | ✅ (2) | Pending | error_view.dart, design_system_test.dart | VERIFIED |
| Structured Logging | Core | ✅ | N/A | N/A | N/A | — | — | ✅ | — | ✅ | ✅ (7) | Pending | nimmy_logger.dart, nimmy_logger_test.dart | VERIFIED |
| Home screen | /home | ✅ | — | — | — | — | — | ✅ | — | — | ✅ (1) | Pending | dashboard_screen.dart, widget_test.dart | VERIFIED |
| Tasks shell route | /tasks | ✅ | — | — | — | — | — | ✅ | — | — | ✅ (1) | Pending | tasks_screen.dart, app_shell_test.dart | VERIFIED |
| Calendar shell route | /calendar | ✅ | — | — | — | — | — | ✅ | — | — | ✅ (1) | Pending | calendar_screen.dart, app_shell_test.dart | VERIFIED |
| Memory screen | /memory | ✅ | — | ✅ | — | — | — | ✅ | — | ✅ | ✅ (1) | Pending | memory_screen.dart, app_shell_test.dart | VERIFIED |
| Voice Center route | /voice | ✅ | — | — | — | Microphone | — | ✅ | — | — | ✅ (1) | Pending | voice_interaction_sheet.dart, app_shell_test.dart | VERIFIED |
| More screen | /more | ✅ | — | — | — | — | — | ✅ | — | — | ✅ (1) | Pending | more_screen.dart, app_shell_test.dart | VERIFIED |

## Phase 2 — Authentication

| Feature | Screen | Frontend | Backend | Database | API | Permission | Confirmation | Offline | Sync | Audit | Tests | Real Device | Evidence | Status |
|---------|--------|----------|---------|----------|-----|------------|--------------|---------|------|-------|-------|-------------|----------|--------|
| Sign up | — | — | — | ✅ | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| Login | — | — | — | ✅ | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| Logout | — | — | — | — | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| Password reset | — | — | — | — | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| Session restore | — | — | — | — | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| Account delete | — | — | — | — | — | — | — | — | — | — | — | — | — | NOT_STARTED |
| RLS enforcement | — | — | — | ✅ | — | — | — | — | — | — | — | — | 015_mvp_action_foundation.sql | IN_PROGRESS |

## MVP Tools (Cross-Phase)

| Feature | Screen | Frontend | Backend | Database | API | Permission | Confirmation | Offline | Sync | Audit | Tests | Real Device | Evidence | Status |
|---------|--------|----------|---------|----------|-----|------------|--------------|---------|------|-------|-------|-------------|----------|--------|
| create_reminder | Voice/Reminders | ✅ | ✅ | ✅ | — | Notification | ✅ | ✅ | Partial | ✅ | ✅ (3) | Pending | tool_registry.dart, intent_parser_test.dart | IN_PROGRESS |
| save_memory | Voice/Memory | ✅ | ✅ | ✅ | — | — | ✅ | ✅ | Partial | ✅ | ✅ (1) | Pending | tool_registry.dart | IN_PROGRESS |
| Intent parser | Voice | ✅ | — | — | — | — | — | ✅ | — | — | ✅ (5) | — | intent_parser.dart | IN_PROGRESS |
| Confirmation gate | Voice | ✅ | ✅ | — | — | — | ✅ | — | — | ✅ | ✅ | — | confirmation_policy.dart | IN_PROGRESS |
| Audit trail | Audit | ✅ | ✅ | ✅ | — | — | — | ✅ | Partial | ✅ | ✅ | — | audit_event.dart | IN_PROGRESS |

## Phase 6 — Hands-free Voice

| Feature | Screen | Frontend | Backend | Database | API | Permission | Confirmation | Offline | Sync | Audit | Tests | Real Device | Evidence | Status |
|---------|--------|----------|---------|----------|-----|------------|--------------|---------|------|-------|-------|-------------|----------|--------|
| Local wake-word event bridge | Voice | ✅ | — | — | ✅ | Microphone + notification | — | — | — | ✅ logging | ✅ analyzer + unit target | Pending | `lib/core/native/nimmy_wake_word_platform.dart`, `WakeWordRuntime.kt` | IN_PROGRESS |
| Hands-free wake → STT → controlled tool path | Voice | ✅ | ✅ existing MVP path | ✅ existing MVP path | ✅ bridge | Microphone | ✅ | Partial | Partial | ✅ | Analyzer passes; full runner timed out | Pending | `voice_screen.dart`, `wake_word_service.dart`, `nimmy_controller.dart` | IN_PROGRESS |
| Visible microphone foreground service | Android | — | — | — | ✅ | Microphone + foreground service + notification | — | — | — | ✅ structured errors | Android build/device pending | Pending | `NimmyForegroundService.kt`, `AndroidManifest.xml` | IN_PROGRESS |

> Phases 3–18 features will be added to this matrix as each phase begins.
