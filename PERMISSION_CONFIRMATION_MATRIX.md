# NIMMY — Permission and Confirmation Matrix

## 1. Permission policy

Nimmy requests a permission only when the user starts the feature that needs
it. The explanation appears before the Android dialog and the settings screen
shows the current state and a path to Android Settings.

| Capability | Android permission | MVP status | User-facing behavior |
| --- | --- | --- | --- |
| Voice input | `RECORD_AUDIO` | Implemented | Ask on voice start; text fallback remains available. |
| Reminder notifications | `POST_NOTIFICATIONS` (Android 13+) | Implemented | Request from Permission Center; the saved reminder warns if Android notification access is unavailable. |
| Calendar | calendar permissions | Coming soon | Do not request in MVP. |
| Contacts | contacts permissions | Coming soon | Do not request in MVP. |
| Location | location permissions | Coming soon | Do not request in MVP. |
| Biometric lock | biometric APIs | Future | Do not show as enabled until implemented. |
| Background recording | foreground service/microphone | Future | No hidden or passive recording. |

The manifest contains only permissions needed for current voice and reminder
behavior plus Android notification receivers. No service-role or hidden access
is granted.

## 2. Confirmation policy

| Action | Confirmation | Current behavior |
| --- | --- | --- |
| Read/search/view | No | Direct when a reader exists. |
| Create reminder | Yes | Preview sheet, then `create_reminder`. |
| Save memory | Yes | Preview sheet, then `save_memory`. |
| Edit/delete memory | Yes/destructive | Manual vault action is explicit and audited. |
| Cancel reminder | Yes/destructive | Manual delete cancels its local notification first. |
| External message/share | Strong confirmation | Future; no fake send. |
| Purchase/payment/delete all | Strong confirmation | Future; unavailable. |

Confirmation is enforced in `ToolRegistry`, not only in button labels. Calling
an executable tool without `confirmed: true` returns a refusal and does not
write a record.

## 3. Recording rule

Microphone use must be visible and user-initiated. The MVP voice feature uses
speech recognition for a command; it is not a recording daemon. Production
recording requires an Android foreground service, persistent notification,
pause/stop controls, explicit retention UI, and physical-device verification.
