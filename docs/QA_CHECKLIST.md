# NIMMY — Master QA Checklist

> Every page, workflow, and phase must be tracked here.
> Status: ⬜ Not Tested | 🟡 Partial | ✅ Pass | ❌ Fail | 🚫 N/A

---

## Pages

| Page | UI | Navigation | Loading | Empty | Error | Offline | Permissions | Backend | Database | API | Security | Audit | Tests |
|------|-----|-----------|---------|-------|-------|---------|-------------|---------|----------|-----|----------|-------|-------|
| Home/Dashboard | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🚫 | ⬜ | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ |
| Voice Center | 🟡 | 🟡 | 🟡 | ⬜ | 🟡 | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Tasks | ⬜ | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ | 🚫 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Calendar | ⬜ | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Memory Vault | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🚫 | ⬜ | 🟡 | ⬜ | ⬜ | 🟡 | ⬜ |
| More | 🟡 | 🟡 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | 🚫 | ⬜ |
| Reminders | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ⬜ | ⬜ | 🟡 | ⬜ | ⬜ | 🟡 | ⬜ |
| Audit | 🟡 | 🟡 | 🟡 | 🟡 | ⬜ | 🟡 | 🚫 | ⬜ | 🟡 | ⬜ | ⬜ | ✅ | ⬜ |
| Permissions | 🟡 | 🟡 | ⬜ | ⬜ | ⬜ | 🚫 | 🟡 | 🚫 | 🚫 | 🚫 | ⬜ | 🚫 | ⬜ |
| Notes | ⬜ | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ | 🚫 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Settings | ⬜ | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ | 🚫 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Core Workflows

| Workflow | Input | Intent | Tool | Confirmation | Execution | Database | Audit | Response | Tests |
|----------|-------|--------|------|--------------|-----------|----------|-------|----------|-------|
| Create reminder (voice) | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create reminder (text) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Save memory (voice) | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Save memory (text) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edit memory | ✅ | 🚫 | 🚫 | 🚫 | ✅ | ✅ | ✅ | ✅ | ⬜ |
| Delete memory | ✅ | 🚫 | 🚫 | 🚫 | ✅ | ✅ | ✅ | ✅ | ⬜ |
| Delete reminder | ✅ | 🚫 | 🚫 | 🚫 | ✅ | ✅ | ✅ | ✅ | ⬜ |
| Cancel confirmation | ✅ | 🚫 | 🚫 | ✅ | 🚫 | 🚫 | ✅ | ✅ | ⬜ |

## Phase Verification

| Phase | Architecture | Implementation | Testing | Documentation | Verification |
|-------|-------------|---------------|---------|---------------|-------------|
| 0 — Foundation | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1 — App Shell | ✅ | ✅ | ✅ | ✅ | 🟡 (Device pass pending) |
| 2 — Auth | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 — Tasks | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 4 — Calendar | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 5 — AI Brain | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 6 — Voice | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 7 — Memory | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 8 — Recording | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 9 — Timeline | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 10 — Automation | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 11 — Messaging | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 12 — Offline/Sync | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 13 — Analytics | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 14 — Web | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 15 — Security | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 16 — Performance | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 17 — QA | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 18 — Release | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Android Test Matrix

| Condition | Tested | Device | Android Version | Result | Notes |
|-----------|--------|--------|-----------------|--------|-------|
| Screen ON | ⬜ | — | — | — | — |
| Screen OFF | ⬜ | — | — | — | — |
| App foreground | ⬜ | — | — | — | — |
| App background | ⬜ | — | — | — | — |
| App killed | ⬜ | — | — | — | — |
| Device restart | ⬜ | — | — | — | — |
| Battery saver | ⬜ | — | — | — | — |
| Low battery | ⬜ | — | — | — | — |
| Wi-Fi | ⬜ | — | — | — | — |
| Mobile data | ⬜ | — | — | — | — |
| Offline | ⬜ | — | — | — | — |
| Permission denied | ⬜ | — | — | — | — |
| Notification denied | ⬜ | — | — | — | — |
| Microphone denied | ⬜ | — | — | — | — |
| App update | ⬜ | — | — | — | — |
| Logout/login | ⬜ | — | — | — | — |
