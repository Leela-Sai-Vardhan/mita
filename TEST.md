# Mita v2.0.0+11 — Manual Test Plan

Pre-testing audit completed (all 15 issues fixed). This file documents **what was updated** and **what to test**. Build the AAB, install, and work through the checklist below — mark each box done as you verify.

---

## 1. What Was Updated (Summary)

### 1.1 Flow & UX Redesign (Mita 2.0)
- **Instant completion + UNDO**: Tapping a task completes it instantly; a 6s snackbar offers "UNDO".
- **Merged day-progress card**: Progress, streak count, and perfect-day status combined into one card.
- **Banner gating**: Wisdom/motivational banner only shows when there are uncompleted tasks.
- **Onboarding rewrite**: 4 pages now in order → Brand → Streak → **Name your 3 tasks** → **Goals (skippable)**. Ends with a themed notification-permission dialog.
- **Splash 1.1s** with Mitzy mascot.
- **Mitzy perfect-day celebration card** with animated confetti/check animation (`all_done_animation.dart`).
- **Goal-based personalization**: 7 goals × 5 curated tasks (`goals.dart`). Existing users get a one-time goal prompt on app open; editable anytime via **Settings → Personalize → Your Goals**.

### 1.2 Notification Overhaul
- Per-channel preferences: Daily Reminder, End-of-Day, Weekly Summary, Focus Complete (4 toggles in Settings).
- Deep-link payloads route taps to the correct tab (`tab:today`, `tab:stats`, `...`).
- Removed redundant per-task reminders.
- **Telemetry on tap, not on schedule** — notification engagement recorded in `_onNotificationTapped`.
- Onboarding now shows a themed "Enable Reminders" dialog (no double initialization).

### 1.3 Productivity & Data
- **Rewarded ads** for streak freeze (`ad_service.dart`); **In-App Review** + rate prompt after 3 completions (delayed, single-shot).
- **Pomodoro timer** on a monotonic `Stopwatch` (no clock drift), focus-session logging to DB, haptics, ambient sounds (rain/forest/white noise) with lifecycle pause.
- **Backup/Restore** now round-trips `completedAt`, `recurrence`, `recurrenceDays`.
- **Quick Picks** are geo/time-aware and cached once per day (`home_screen.dart`).
- **Streak engine**: atomic `streak_state` JSON blob in SharedPreferences (no partial writes), freeze logic runs after all data loads, recurrence duplicate-check queries the DB directly.
- **Home Widget** sync, weekly summary on Monday, EOD update before 10 PM.

### 1.4 Reliability Fixes (Audit, 15 items)
| # | Sev | Fix |
|---|-----|-----|
| 1 | 🔴 | Notification service no longer double-initialized (added `requestPermission()`) |
| 2 | 🔴 | Streak-freeze race condition fixed — runs last in `loadData()`, re-checks today's tasks |
| 3 | 🔴 | Streak writes now atomic (single JSON blob via `_writeStreakState()`) |
| 4 | 🟠 | Notification telemetry recorded on tap, not on schedule |
| 5 | 🟠 | Pomodoro timer uses `Stopwatch` (monotonic) instead of wall clock |
| 6 | 🟠 | Backup import includes `completedAt`, `recurrence`, `recurrenceDays` |
| 7 | 🟠 | Quick Picks cached per day — `getAllTasks()` runs at most once/day |
| 8 | 🟡 | Onboarding order fixed (Name Tasks before Goals) + "Skip goals" |
| 9 | 🟡 | Notification toggles cached in Settings (no repeat prefs reads) |
| 10 | 🟡 | Recurrence duplicate check queries DB, not in-memory list |
| 11 | 🟡 | Telemetry `last_updated` captured at flush start |
| 12 | 🟡 | Date storage normalization verified (already in `Task.toMap()`) |
| 13 | 🟢 | Ambient sound pauses on app background (lifecycle observer) |
| 14 | 🟢 | Duplicate `@override` verified absent |
| 15 | 🟢 | Quick Pick time-bucket logic sanity-checked |

### 1.5 Follow-Up Fixes (Post-Audit, from on-device testing)
- **Ads audit (3 fixes)** in `ad_service.dart` + consumers:
  - `INTERNET` + `ACCESS_NETWORK_STATE` added to main `AndroidManifest.xml` (release builds had no network → ads never loaded)
  - `showRewardedAd()` now returns `Future<bool>` — no stuck "Loading ad…" dialog if the ad closes early / fails
  - Debug builds use the Google **test** rewarded unit; `kDebugMode` guard added
  - Plus `_rewardedFlowActive` re-entrancy guard (prevents double reward on double-tap) in home + history screens
- **UNDO bug fixed**: `toggleTask()` re-reads the task from the DB (`getTaskSafe`) so the snackbar's stale closure can't re-complete an undone task
- **Day-progress counter fixed**: "X of 3 complete!" hardcoded the `3` → now uses the real task count ("4 of 4 complete!", no mismatch when extended tasks exist)
- **All-Done celebration gate fixed**: now shows on **any** fully completed day (was `length <= 3`, so extended days got no celebration)
- **Streak self-heal on load**: if the atomic `streak_state` blob lost today's perfect day but legacy keys prove it, the earned streak is restored (fixes "Streak: 0 days" sitting below the All-Done circle right after earning `+1 to the streak`). `_checkRevertStreak()` now trusts in-memory atomic state instead of stale legacy keys.

### 1.6 Existing Behavior Preserved (Regression Watch)
- Streak milestones (15), streak freeze/unfreeze, streak journey screen, weekly summary, history, stats tabs, focus session graphs, battery-optimization dialog.

---

## 2. Test Checklist

> Suggested order: **P0 → P1 → P2 → P3**. Test on a physical Android device (13+ recommended) with notifications enabled.

### P0 — Onboarding & Core Path
- [ ] Fresh install → onboarding shows **Brand → Streak → Name 3 tasks → Goals (skippable)** in that order
- [ ] Typing on "Name your 3 tasks" does **not** overflow with keyboard open (scrollable)
- [ ] Completing onboarding shows themed "Stay on track — Enable Reminders" dialog; taps Enable → OS permission dialog, Not now → skips
- [ ] After onboarding → home: enter your 3 tasks, complete all → **All-Done animation plays**, streak=1, Perfect Day card shows
- [ ] Existing user (v1.x data) opens app → **one-time goal prompt** appears once, never again
- [ ] Goal prompt → pick ≤3 goals → Quick Picks reflect goal-matched tasks; **Settings → Personalize → Your Goals** edits them
- [ ] Complete a task → **UNDO snackbar** (6s) → undo restores task, streak unchanged, no telemetry double-count
- [ ] Add an extra task (rewarded ad) → day-progress shows real counts e.g. "4 of 4 complete!" — never "X of 3"
- [ ] Complete a perfect day → streak pill (`🔥 N / Current Streak`), the `+1 to the streak` banner, and the All-Done "Streak: N days" all show the **same** number

### P0 — Notifications
- [ ] Daily Reminder set → app killed → notification fires at set time; tap opens **Today**
- [ ] End-of-Day toggle ON → 10 PM update fires; toggle OFF → no notification
- [ ] Weekly Summary toggle ON → Monday notification; tap opens **Stats**
- [ ] Focus Complete → finish a Pomodoro → "Pomodoro Complete!" fires; tap opens Focus
- [ ] No duplicate/colliding End-of-Day notifications (channel collision bug fixed)

### P1 — Streak & Milestones
- [ ] 3 consecutive perfect days → streak grows, milestone dialog at 3/7/14/… (15 milestones)
- [ ] Miss a day → streak **freezes** (⏳ shown), no lost streak
- [ ] Freeze: watch rewarded ad → streak preserved; next perfect day unfreezes → streak continues
- [ ] App closed at midnight → reopened next day → freeze state correct (no stale tasks)
- [ ] Best streak updates correctly; streak history graph in Journey screen correct

### P1 — Pomodoro & Focus
- [ ] Start 25-min focus → timer counts down accurately
- [ ] Background the app for 1 min → foreground → **no drift** (Stopwatch)
- [ ] Pause/resume works; break mode triggers at completion with notification
- [ ] Ambient sound plays (rain/forest/white noise); volume works; **pauses when app goes background**, resumes on return
- [ ] Completed focus session recorded in Stats → Focus tab (time by day/week, avg duration)
- [ ] Interruptions + skip break behave without crash

### P1 — Backup / Data Integrity
- [ ] Export JSON → wipe app data → restore → all tasks, streak, best streak, settings return
- [ ] Restored recurring tasks keep their recurrence rules; completed tasks keep completion dates
- [ ] Import corrupted/invalid JSON → graceful error, no crash

### P2 — Tasks & Recurrence
- [ ] Recurring daily task completed → auto-created for tomorrow; **no duplicate** after app restart
- [ ] Weekdays/weekends/specific-days recurrence work correctly
- [ ] Deadline + extend ("Add 1 more day") works on history screen
- [ ] Delete task works; History screen shows unique days & tasks
- [ ] Home Widget shows streak + progress; updates after toggling a task

### P2 — Settings & Reviews
- [ ] 4 notification toggles persist across app restarts
- [ ] Battery optimization dialog → "Open Settings" → return to app → no crash
- [ ] Rate prompt triggers after 3 completions + 7 days (mitzy_rate.png dialog); In-App Review appears (native)
- [ ] Goals editor: save/not-now both work; Quick Picks update immediately

### P3 — Polish & Edge
- [ ] Dark theme consistent across all screens (bg `#0D0D0D`, accent `#E94560`)
- [ ] Splash shows Mitzy for ~1.1s then transitions cleanly
- [ ] History Detail screen opens from History; stats charts render
- [ ] Rotate device / small screen → no overflow errors anywhere
- [ ] Offline launch works fully (all data local)
- [ ] Pocket-encyclopedia check: no console errors in `flutter analyze` (currently 0 issues)

---

## 3. Previously Reported Issue — RESOLVED
- **"Numbers below tasks when completing"** → root-caused and fixed on device. Two real defects were rendering wrong numbers on the home screen:
  1. **"4 of 3 complete!"** — the day-progress label hardcoded `3`, so once an extended/extra task was added and completed, the first number exceeded the second. Verified live: `4 of 3 complete!` → now `4 of 4 complete!` (`home_screen.dart`).
  2. **"Streak: 0 days"** below the All-Done celebration circle right after completing a perfect day — the atomically-written `streak_state` blob had been clobbered (legacy keys still held `streak: 1, lastPerfectDay: today`), so the earned streak was dropped on load. Added self-healing migration in `_loadStreakState()`; verified live: pill `🔥 1 / Current Streak`, All-Done `Streak: 1 days`.

---

## 4. Release Checklist
- [ ] All P0 + P1 items pass
- [ ] `flutter analyze` → 0 issues
- [ ] Version bumped to `2.0.0+11` in `pubspec.yaml` + `theme.dart` `appVersion`
- [ ] Build AAB (`flutter build appbundle --release`)
- [ ] Upload to Play Store, submit for review