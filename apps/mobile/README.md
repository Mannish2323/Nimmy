# Nimmy mobile

Flutter Android-first client for the Nimmy MVP vertical slice.

## Working MVP flow

- Open the Command Center and tap the Nimmy orb.
- Speak or type a reminder or explicit `remember this` command.
- Review the generated proposal.
- Confirm or cancel it.
- Inspect the persisted result in Reminders/Memory and Activity.

The app uses Hive locally by default. If `SUPABASE_URL` and
`SUPABASE_ANON_KEY` are configured and a user is authenticated, the bootstrap
adds an optional Supabase mirror. No cloud success is shown without a real
authenticated session.

## Commands

From this directory:

```powershell
..\..\flutter\bin\flutter.bat pub get
..\..\flutter\bin\flutter.bat analyze
..\..\flutter\bin\flutter.bat test
```

The mobile app intentionally exposes `COMING SOON` states for features whose
backend, permissions, and Android behavior are not implemented yet.
