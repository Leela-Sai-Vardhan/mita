# Release Notes

## v2.0.1+12 — Winter Arc: Lock-In Season

### Winter Arc Campaign
- **Seasonal campaign (Sep 1 – Feb 28)**: Home card tracking "Day X of 181" with phases (Lock In → Deep Winter → Final Stretch), locked-in-day counter, badge ladder (7/21/50/100/150/200), and rotating daily motivation. Collapsed by default; tap the card for the full arc sheet, tap the chevron to expand the contract in place.
- **Personal contract of 3 non-negotiables** (new `ArcRoutines` engine): pick from the trend's most-cited binary habits (train, 10k steps, read 10 pages, meditate…), goal-tagged and time-bucketed. Completing them counts as locked in; suggestions adapt to the time of day and your goals. Contract resets each September; catalog remotely tunable via config.
- **Seasonal Mitzy art + animations**: cozy/frosty/scarf variants with the designed 3s breathing float on splash + rate dialog; snowfall layer on the Winter Arc card.

### Streak System (major fix)
- **Snapchat-style expiry**: a day only counts as missed after it fully ends — opening the app mid-day can never consume the weekly freeze or reset the streak (the old logic reset streaks on app reopens). First missed week spends the freeze and preserves the streak; a later missed week resets.
- **Animated streak flame** (Lottie) replaces the static 🔥 in the home pill, streak dashboard, journey ring, and stats overview.

### Celebrations
- **All-done celebration** rebuilt with a confetti Lottie at 2x bursting out of the card; dismissible (X), and dismissal persists per day (no re-trigger on tab switches or restarts).
- Celebration now fires at a perfect day (3 core tasks) even when extra tasks are still open.

### Monetization (fairer gating)
- **Rewarded-ad gate on contract/suggestion adds**: tasks beyond the core 3 consume an extension slot and require a watched ad — same rule everywhere (extra-task button, Winter Arc chips, arc sheet suggestions). Ads remotely disabled → free.
- **History unlock** now requires a rewarded ad ("Watch ad to unlock 7 more days").

### Fixes
- Force-update trap eliminated: the 999999 sentinel in remote config trapped every build in a non-dismissable dialog; force-update now requires a genuinely newer build (guard + 7 regression tests).
- Winter Arc season fixed Dec 1 → Sep 1 across app defaults, remote config, and the live site.

### Infrastructure
- Remote config pipeline: repo source of truth (`web-config/`) + JSON Schema + GitHub Actions validation + auto-deploy to the app-config site; `daily_message` and `routines` overrides documented.
- Privacy policy updated (local-only storage, Winter Arc data, optional rewarded ads, anonymous config download) — effective Sep 4, 2026.
- Tests: 19 → 84.

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