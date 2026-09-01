# Release Notes

## v2.0.0+11 — Mita 2.0: Premium Redesign, Pomodoro & Reliability Audit

### UX & Flow Redesign
- **Instant completion + UNDO**: tapping a task completes it instantly; a 6s snackbar offers UNDO (re-reads the DB so a stale snackbar can't re-complete an undone task).
- **Merged day-progress card**: progress, streak count, and perfect-day status combined into one card; uses real task count (e.g. "4 of 4 complete!", never "4 of 3").
- **Onboarding rewrite**: 4 pages in order → Brand → Streak → Name your 3 tasks → Goals (skippable); ends with a themed notification-permission dialog. Existing users get a one-time goal prompt.
- **Splash 1.1s** with Mitzy mascot; glow-streak pill and emissive fire indicator.
- **Mitzy perfect-day celebration** card with animated confetti/check (`all_done_animation.dart`); shows on any fully completed day.
- **Goal-based personalization**: 7 goals × 5 curated tasks (`goals.dart`); Quick Picks are goal- and time-aware, cached once per day; editable via Settings → Personalize → Your Goals.
- **Wisdom Banner** (context-aware messages, streak-colored accent bar) and upcoming-events banner.

### Notification Overhaul
- **4 channels with individual toggles**: Daily Reminder, End-of-Day, Weekly Summary, Focus Complete.
- **Deep-link payloads** route notification taps to the correct tab (`tab:today`, `tab:stats`, `tab:focus`).
- **Telemetry on tap, not schedule** — engagement recorded in `_onNotificationTapped`.
- Removed redundant per-task reminders; fixed double-initialization; single themed onboarding dialog.

### Productivity & Monetization
- **Pomodoro timer** on a monotonic `Stopwatch` (no clock drift), focus-session logging to SQLite, haptics, ambient sounds (rain/forest/white noise) that pause in background; configurable durations and ready-state pre-start screen.
- **Rewarded ads** (streak freeze redemption, extra task slots) with re-entrancy guard, test/release unit IDs, and remote-config gating; **In-App Review** + rate prompt after 3 completions (delayed, single-shot).
- **Backup/Restore** now round-trips `completedAt`, `recurrence`, `recurrenceDays`.
- **Remote config** (Vercel-hosted JSON) drives ads flag, live re-theme, seasonal Mitzy Winter Arc assets, and update/event prompts.

### Reliability Audit (15 fixes)
- Notification service no longer double-initialized.
- Streak-freeze race fixed — freeze logic runs last in `loadData()`, re-checks today's tasks.
- **Atomic streak state** — single JSON blob in SharedPreferences, with self-heal on load.
- Pomodoro uses `Stopwatch` (monotonic) instead of wall clock.
- Backup import includes completion/recurrence fields.
- Quick Picks cached per day (at most one query/day).
- Onboarding order fixed + "Skip goals".
- Notification toggles cached; recurrence duplicate-check queries the DB directly.
- Date storage normalization + WAL/`Synchronous=FULL` journaling for crash resilience.

### Dependencies
- **AdMob SDK upgraded `google_mobile_ads` 5.3.1 → 9.1.0** (GMA Android SDK 25.x). 5.x is deprecated by Google (sunset Q2 2027); 9.x is the current supported major. API surface used (rewarded ads) is unchanged — verified with `flutter analyze` (0 issues) and a clean debug build.
- Added `http` for remote config.

## v1.4.0 — Streak Journey

- Revamped streak system with milestone progression path and psychological rewards
- New Streak Journey screen with detailed timeline, 14-day calendar, and trophy room
- Compact streak summary card on stats page with one-tap access to full journey
- Streak freeze (⏳): one missed day per week forgiven before streak resets
- Perfect day now requires at least 3 completed tasks (was exactly 3)
- Activity calendar: tappable month header to jump to today, improved future-day visuals