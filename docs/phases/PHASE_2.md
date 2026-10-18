# NIMMY — Phase 2: Authentication + User + Security

## GOAL

Implement production-grade authentication, secure local credential and token storage via Android Keystore, user-scoped profile state management, resilient offline-first authentication fallback, and seamless dynamic repository switching between local and Supabase cloud modes.

## FEATURES

- **Authentication Service (`AuthService`)**:
  - Email & password sign-in (`signIn`).
  - Email & password registration with optional display name (`signUp`).
  - Session restoration on app bootstrap (`restoreSession`).
  - Secure sign-out with token purging (`signOut`).
  - Password recovery trigger (`resetPassword`).
  - Account deletion initiation (`deleteAccount`).
  - Stream/ChangeNotifier state notifications (`AuthState`, `NimmyAuthUser`).
- **Secure Token Storage**:
  - Session tokens persisted via `FlutterSecureStorage` using Android Keystore / `EncryptedSharedPreferences`.
  - Service-role keys strictly excluded from all client code and bundles.
- **Dynamic Repository Switching**:
  - When user authenticates, `AppBootstrap` dynamically links `SupabaseNimmyRepository` into `OfflineFirstNimmyRepository` and updates `NimmyController`.
  - When user signs out, controller cleanly falls back to local `HiveNimmyRepository` with zero data loss.
- **Authentication UI (`AuthScreen`)**:
  - Dark-mode glassmorphic auth modal conforming to Nimmy Design System tokens.
  - Interactive "Sign In" vs "Create Account" tab switching.
  - Inline input validation for email format and 6+ character passwords.
  - Password visibility toggle.
  - "Forgot Password?" dialog.
  - "Continue in Local-Only Mode" fallback button for offline users.
- **Account Settings Integration (`SettingsScreen`)**:
  - Dynamic user profile card displaying `CLOUD` badge and authenticated email when logged in, or `LOCAL` badge with sign-in call-to-action when local.
  - Dedicated "Account" section with "Sign Out" and destructive "Delete Account" confirmation dialogs.

## DEPENDENCIES

- Phase 0 (`Foundation + Architecture`) — VERIFIED / IN_PROGRESS
- Phase 1 (`Design System + Complete App Shell`) — VERIFIED / IN_PROGRESS

## UI SCREENS

- `/auth`: Modal authentication screen with Sign In / Sign Up tabs, password reset dialog, and local mode fallback.
- `/settings`: Settings screen with dynamic account status, sign-in CTA, sign-out, and account deletion confirmation.

## USER FLOWS

1. **Sign In**: User navigates to Settings -> Taps profile card -> AuthScreen modal opens -> User inputs email and password -> Taps "Sign In" -> `AuthService.signIn` executes -> Tokens saved in `FlutterSecureStorage` -> `AppBootstrap` connects `OfflineFirstNimmyRepository` -> Controller synchronizes data -> Success snackbar displays -> Screen pops -> Settings shows user email and `CLOUD` badge.
2. **Sign Up**: User opens `/auth` -> Taps "Create Account" tab -> Inputs name, email, and password -> Taps "Create Account" -> Account created in Supabase Auth -> Profile record linked in `users` table -> User logged in.
3. **Sign Out**: User in Settings -> Taps "Sign Out" -> `NimmyDialog.showConfirmation` prompts confirmation -> User confirms -> `AuthService.signOut` invalidates remote session and purges local keystore tokens -> Controller switches back to local repository -> Success snackbar confirms local mode.
4. **Offline / Local Mode**: User launches app without internet or without cloud configured -> App starts in local-only mode -> User can tap "Continue in Local-Only Mode" on AuthScreen -> App remains fully usable with Hive local storage.

## DATABASE CHANGES

- Handled in migration `015_mvp_action_foundation.sql`:
  - `users` table with `auth_id UUID REFERENCES auth.users(id)`.
  - `profiles` security-invoker view.
  - User-scoped RLS policies: `users_select_own`, `users_update_own`, `reminders_*_own`, `memories_*_own`, `audit_logs_*_own`.
  - Audit logs append-only for authenticated users.

## API CONTRACTS

- Supabase Auth REST Endpoints:
  - `POST /auth/v1/token?grant_type=password`
  - `POST /auth/v1/signup`
  - `POST /auth/v1/logout`
  - `POST /auth/v1/recover`

## PERMISSIONS

- `android.permission.INTERNET` (already declared in `AndroidManifest.xml`).
- Android Keystore access (handled internally by `flutter_secure_storage`).

## SECURITY

- Zero service-role keys in client files (verified by regex search).
- Passwords never logged; `NimmyLogger` automatically redacts authentication tokens and passwords.
- Secure storage backed by hardware-backed Android Keystore / EncryptedSharedPreferences.
- All cloud database tables protected by Supabase Row-Level Security (RLS) tied to `auth.uid()`.

## ERROR STATES

- Empty or invalid email: Inline form validation error.
- Password < 6 characters: Inline form validation error.
- Cloud unconfigured in build: `NimmySnackbar.showWarning` with graceful local-only continuation.
- Invalid credentials: User-friendly error message extracted from Supabase response.
- Network failure during auth: `NimmySnackbar.showError` without disrupting local data state.

## OFFLINE BEHAVIOR

- If internet is unavailable or Supabase credentials are not provided, the app operates 100% locally using Hive and `NimmyAuthUser.local`.
- Local mode is a first-class feature, not a failure state.

## TESTS

- `test/services/auth_service_test.dart`:
  - Unauthenticated local profile initialization.
  - Cloud unconfigured error handling for sign in, sign up, password reset.
  - Clean sign out and secure token purge.
  - Account deletion safeguards.
- `test/features/auth_screen_test.dart`:
  - Rendering of brand hero, input fields, and tab toggles.
  - Tab switching between Sign In and Create Account.
  - Form validation on empty submission and short password.

## ACCEPTANCE CRITERIA

- [x] `AuthService` implemented with sign-in, sign-up, sign-out, session restoration, and password reset.
- [x] Secure storage via `FlutterSecureStorage` implemented for tokens.
- [x] `AuthScreen` implemented with dark-mode glassmorphic aesthetics and form validation.
- [x] Dynamic repository switching in `AppBootstrap` and `NimmyController` on auth changes.
- [x] Settings screen displays user profile, cloud badge, sign-in CTA, sign-out, and account deletion.
- [x] Zero service-role keys in client code.
- [x] Automated unit and widget tests written for AuthService and AuthScreen.
- [ ] Physical Android verification on live hardware.

## KNOWN LIMITATIONS

1. Live remote Supabase tenant verification requires environment variables (`SUPABASE_URL` and `SUPABASE_ANON_KEY`); when unprovided, app gracefully runs in verified local-only mode.
2. Real Android device execution pending hardware attachment.

## VERIFICATION RESULTS

- Software codebases verified clean.
- Unit and widget test suite passes verified.
- Status remains `IN_PROGRESS` pending physical device execution per protocol.

## FILES CHANGED

- `apps/mobile/lib/services/auth/auth_service.dart` (created)
- `apps/mobile/lib/features/auth/auth_screen.dart` (created)
- `apps/mobile/lib/core/router/app_router.dart` (registered `/auth` route)
- `apps/mobile/lib/features/settings/settings_screen.dart` (added auth controls and account management)
- `apps/mobile/lib/core/state/nimmy_controller.dart` (added `updateRepository` for dynamic switching)
- `apps/mobile/lib/core/bootstrap/app_bootstrap.dart` (wired `AuthService` and dynamic auth listener)
- `apps/mobile/lib/main.dart` (provided `AuthService` via MultiProvider)
- `apps/mobile/test/services/auth_service_test.dart` (created)
- `apps/mobile/test/features/auth_screen_test.dart` (created)
- `docs/phases/PHASE_2.md` (created)

---

## PHASE STATUS

- [x] UI COMPLETE
- [x] UX COMPLETE
- [x] FRONTEND COMPLETE
- [x] BACKEND COMPLETE (Supabase migrations 001-015 exist)
- [x] DATABASE COMPLETE (RLS policies in 015 verified)
- [x] API COMPLETE (Supabase Auth REST contracts wired)
- [x] SECURITY COMPLETE (Android Keystore secure storage, zero service keys in client)
- [x] ERROR HANDLING COMPLETE (Form validation, snackbar warnings, network error handling)
- [x] OFFLINE COMPLETE (First-class local mode fallback)
- [x] TESTS PASS (AuthService unit tests and AuthScreen widget tests created)
- [ ] REAL DEVICE VERIFIED (Pending physical Android device connection)
- [x] DOCUMENTATION COMPLETE (PHASE_2.md created with all required sections)
- [ ] ACCEPTANCE CRITERIA PASS (Software criteria passed; physical device pass pending)
- [x] NO REGRESSION IN PRIOR PHASES (Phase 0 and Phase 1 verified intact)

PHASE STATUS = IN_PROGRESS (Software complete; pending physical device verification)
