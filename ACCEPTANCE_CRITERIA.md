# NIMMY — MVP Acceptance Criteria

## A. Reminder vertical slice

Given a future clock and the text or transcript:

`Nimmy, remind me tomorrow at 9 AM to study Geography.`

the system must:

1. produce intent `createReminder` and a title equivalent to `Study Geography`;
2. resolve tomorrow and 9 AM without guessing an ambiguous meridiem;
3. show a confirmation proposal before persistence;
4. refuse direct tool execution when confirmation is false;
5. write exactly one reminder for the stable `request_id` after confirmation;
6. attempt local notification scheduling and expose a warning if unavailable;
7. append proposed, confirmed, and executed audit states;
8. refresh the reminder list and return a truthful success message;
9. return an actionable clarification for missing/invalid/future time;
10. return the existing record rather than duplicating it on retry.

## B. Memory vertical slice

Given:

`Nimmy, remember this: I want my dashboard to remain minimal.`

the system must:

1. produce intent `saveMemory` and category `preference`;
2. show the memory candidate and require confirmation;
3. persist one searchable, timestamped, user-scoped memory;
4. append proposed, confirmed, and executed audit states;
5. show it in Memory Vault;
6. allow explicit edit and delete with audit entries;
7. never report saved when persistence fails.

## C. Safety and privacy

- No tool can mutate storage without the confirmation gate.
- No hidden microphone, passive recording, or unsupported social-media send is
  exposed as working.
- No service-role key is bundled in client code.
- Permission requests explain purpose and keep a text fallback.
- Audit rows include request ID, tool, status, source, and timestamp.

## D. Offline behavior

- App bootstrap can initialize local storage without Supabase configuration.
- Reminder and memory reads/writes remain visible locally when cloud setup is
  absent or unavailable.
- Cloud availability is shown as configuration/session state, not assumed.
- AI-dependent capabilities that are not local must say that they are
  unavailable rather than returning fabricated data.

## E. Verification evidence

The repository currently has automated coverage for parser edge cases,
confirmation refusal, idempotent tool execution, audit writes, memory save,
and a real command-center widget smoke test. Run the Flutter analyzer and test
suite before marking a checklist item complete. Physical Android verification
remains a release gate and cannot be inferred from a passing host test.

