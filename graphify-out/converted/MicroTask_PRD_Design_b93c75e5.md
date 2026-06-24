<!-- converted from MicroTask_PRD_Design.docx -->

✓ MICRO-TASK CHECKLIST
Product Requirements Document & Design Specification
Version 1.0  ·  Android App
April 2026

# 1. Product Overview
Micro-Task Checklist is a minimalist Android productivity app built on a single radical constraint: users may only commit to 3 essential tasks per day. No infinite lists. No project hierarchies. No tags. Just three things that matter today — done or not done.
The app targets the overwhelm epidemic in modern productivity tools. By enforcing scarcity of attention, it drives higher completion rates and lower daily anxiety.


## 1.1 Target Audience
- Students & professionals aged 18–35 overwhelmed by traditional to-do apps
- Users with ADHD or focus challenges seeking a structured daily ritual
- Minimalism enthusiasts who want a low-friction productivity tool
- Existing users of Todoist, Notion, TickTick who feel overwhelmed
## 1.2 Value Proposition

# 2. Feature Specification
## 2.1 Core Features (MVP)
F1 — Daily Task Slots (3 max)
- Exactly 3 task slots displayed on the home screen at all times
- Empty slots display a subtle placeholder prompt (e.g., 'What matters today?')
- Tapping an empty slot opens an inline text input — no navigation required
- Tasks are limited to 80 characters to enforce brevity
- If all 3 slots are filled, the Add button is disabled with visual feedback
F2 — Task Completion
- Single tap on a task or its checkbox marks it complete
- Completion triggers a satisfying micro-animation (check + strikethrough + color shift)
- Completed tasks remain visible (not auto-deleted) until midnight reset
- Long-press on a task opens edit/delete options via bottom sheet
F3 — Daily Reset
- At midnight local time, all tasks are automatically archived and slots cleared
- A 'Yesterday' drawer shows yesterday's completed/incomplete tasks for reference
- Users receive a daily reset notification (opt-in) at a customizable morning time
F4 — Streak & Stats
- Daily completion streak tracked (3/3 tasks = perfect day)
- Weekly completion rate shown as a simple percentage
- Simple calendar heatmap showing past 30 days of completion
- Stats screen accessible from the top bar
## 2.2 Ad Integration (Monetization)


Interstitial Ads
- Trigger point: When user opens the Stats screen
- Trigger point: When user navigates from History back to Home (max once per session)
- Frequency cap: Max 1 interstitial per 5 minutes, max 3 per day
- Use AdMob Interstitial: com.google.android.gms.ads.InterstitialAd
- Pre-load next interstitial immediately after one is dismissed
Rewarded Ads
- Unlock 'Yesterday summary' — user watches a reward ad to reveal full history beyond 1 day
- Unlock 'Theme Pack' — reward ad unlocks a premium color theme for 7 days
- Unlock 'Streak Shield' — one missed day forgiven after watching a reward ad
- UI: Clearly labeled 'Watch ad to unlock' button with play icon; never forced
- Use AdMob Rewarded: com.google.android.gms.ads.rewarded.RewardedAd
Ad Placement Rules
- NEVER show any ad during task add, edit, or complete interactions
- NEVER show interstitials on first app launch or first task creation
- Always show a loading state before presenting an interstitial to prevent blank screens
- All ad units must comply with AdMob policies; include test ad unit IDs in debug builds
## 2.3 Settings
- Daily reset time (default: midnight; customizable 10 PM–2 AM)
- Morning reminder notification time
- Theme selection (Light / Dark / Auto)
- Haptic feedback toggle
- Clear all data option
# 3. Design System
## 3.1 Design Philosophy
The app follows a Neo-Brutalist Minimal aesthetic — bold typography, high contrast, deliberate whitespace, and just enough color to signal meaning. No gradients. No drop shadows. No skeuomorphism. Every pixel earns its place.
Design inspiration: Linear.app, Raycast, Bear Notes. Clean, opinionated, fast.
## 3.2 Color Palette

## 3.3 Typography

## 3.4 Spacing & Grid
- Base unit: 8dp
- Screen horizontal margin: 24dp
- Task card padding: 20dp vertical, 16dp horizontal
- Gap between task cards: 12dp
- Bottom nav height: 64dp + system insets
- Minimum touch target: 48x48dp for all interactive elements
## 3.5 Iconography
- Icon set: Phosphor Icons (outlined style, 24dp default, 20dp in nav)
- Checkbox: Custom animated SVG — circle outline → filled checkmark
- Streak icon: Flame (Phosphor) in accent color when active
- Ad unlock icon: Play circle (Phosphor) with subtle pulse animation
# 4. Screen Designs & User Flows
## 4.1 Home Screen
The primary screen. Shows the date, the 3 task slots, a streak counter, and a bottom nav bar.


## 4.2 Add / Edit Task
- Tapping empty slot slides up an inline input field within the card (no new screen)
- Keyboard appears immediately (windowSoftInputMode: adjustResize)
- Character counter shown when > 60 characters entered (e.g., '72/80')
- Pressing Enter or 'Done' on keyboard saves the task
- Tapping outside the card cancels (with discard confirmation if text was entered)
## 4.3 Stats Screen
- Interstitial ad may fire when navigating to this screen (frequency-capped)
- Shows: current streak, longest streak, today's completion %, weekly % bar chart
- 30-day heatmap grid (5 columns x 6 rows) — color-coded by completion: 0/3=empty, 1/3=light, 2/3=medium, 3/3=accent
- 'Unlock full history' button (rewarded ad trigger)
## 4.4 History Screen
- Shows yesterday's task list by default (free)
- Older days locked behind 'Watch ad' paywall (rewarded ad)
- Each day shows a completion badge: ✓✓✓ or partial or ✗
- Interstitial may fire on back navigation from this screen (max 1 per session)
## 4.5 Settings Screen
- Theme toggle: Light / Dark / System
- Notification time picker for morning reminder
- Reset hour picker
- Haptics toggle
- 'Streak Shield' section with rewarded ad unlock
- About, Privacy Policy, Rate App links at bottom
# 5. Animations & Micro-interactions

Use Android's spring animation APIs (SpringAnimation / SpringForce) over linear interpolators wherever possible. Target 60 fps; test on low-end devices (Snapdragon 4xx series).
# 6. Technical Architecture
## 6.1 Tech Stack

## 6.2 Data Model
Task Entity
- id: Long (auto-generated)
- text: String (max 80 chars)
- isCompleted: Boolean
- slotIndex: Int (0, 1, or 2)
- createdAt: Long (epoch ms)
- completedAt: Long? (nullable)
- date: String (yyyy-MM-dd, local time — used as partition key for daily reset)
DayArchive Entity
- date: String (primary key)
- tasksCompleted: Int (0–3)
- tasksTotal: Int (0–3)
UserStats Entity
- currentStreak: Int
- longestStreak: Int
- streakShieldActive: Boolean
- lastCompletedDate: String
## 6.3 AdMob Integration Checklist
- Initialize MobileAds.initialize() in Application class, not Activity
- Use test ad unit IDs (ca-app-pub-3940256099942544/...) in all debug builds
- Preload interstitials via InterstitialAd.load() in ViewModel, not at trigger point
- Preload rewarded ads similarly; call show() only when ad.isLoaded == true
- Implement FullScreenContentCallback for all ad events (onAdDismissed, onAdFailed)
- Add <meta-data android:name='com.google.android.gms.ads.APPLICATION_ID'> to AndroidManifest.xml
- Declare INTERNET and ACCESS_NETWORK_STATE permissions in manifest
- Comply with AdMob's content policy — no misleading ad placements
- Implement frequency capping in ViewModel (SharedPreferences timestamp tracking)
# 7. Navigation Flow
App Entry → Splash (500ms, logo) → Home Screen
Home → [tap stats icon] → Stats Screen → [back] → Home (interstitial may fire on back)
Home → [bottom nav History] → History Screen → [back] → Home (interstitial may fire once/session)
Home → [bottom nav Settings] → Settings Screen → [back] → Home
Task slot (empty) → [tap] → inline edit mode → [Enter/Done] → filled slot
Task slot (filled) → [long press] → bottom sheet (Edit / Delete) → action → updated slot
Task slot → [swipe left] → delete confirmation reveal
# 8. Release Plan
## 8.1 MVP Scope (v1.0)
- 3-task home screen with add/complete/delete
- Daily midnight reset with archive
- Streak counter (current only)
- Dark/Light theme
- AdMob Interstitial (Stats screen trigger)
- AdMob Rewarded (History unlock)
- Morning reminder notification
## 8.2 v1.1 Enhancements
- 30-day heatmap in Stats
- Streak Shield rewarded ad unlock
- Theme pack rewarded unlock (3 additional palettes)
- Widget (1x1 and 2x1 home screen widget showing today's tasks)
## 8.3 v2.0 Potential Features
- Optional task categories (Work / Personal / Health) — still max 3/day
- Cloud sync via Google Sign-In (optional, not required)
- Shareable daily summary card (image export for social)
- Wear OS companion glance tile
# 9. Success Metrics

# 10. Appendix — Ad Unit ID Reference

Replace all test IDs with live AdMob ad unit IDs before publishing to the Play Store. Live IDs are generated in the AdMob console under Apps > Ad units.

Document prepared for Sai Vardhan  ·  Micro-Task Checklist v1.0  ·  Confidential
| Core Premise
If everything is a priority, nothing is. The 3-task limit forces intentional prioritization and creates a daily ritual of focus. |
| --- |
| Feature | Benefit |
| --- | --- |
| Hard 3-task limit | Forces prioritization; no more decision paralysis |
| Daily reset at midnight | Creates urgency without carrying guilt forward |
| No accounts needed | Instant start; data stays on device |
| Sub-10 second interaction | So fast, there's no excuse not to open it |
| Streak & completion stats | Gamification without the bloat |
| Ad Strategy
Ads are placed at natural friction points — never interrupting core task flow. The user experience of adding/completing tasks remains completely ad-free. |
| --- |
| Token | Hex Value | Usage |
| --- | --- | --- |
| --color-bg | #0D0D0D | App background (dark mode) |
| --color-surface | #1A1A1A | Card / task slot surface |
| --color-accent | #E94560 | CTAs, active states, streak |
| --color-accent-2 | #0F3460 | Secondary accent, headers |
| --color-text-primary | #F0F0F0 | Primary text (dark mode) |
| --color-text-secondary | #888888 | Placeholder, metadata |
| --color-success | #4CAF50 | Completed task state |
| --color-divider | #2A2A2A | Separators, outlines |
| Light bg | #F5F5F0 | Background (light mode) |
| Light surface | #FFFFFF | Card surface (light mode) |
| Role | Spec |
| --- | --- |
| Display / App Name | Space Grotesk Bold, 32sp, color-accent |
| Task Text | DM Sans Medium, 18sp, color-text-primary |
| Placeholder Text | DM Sans Regular, 16sp, color-text-secondary |
| Stat Numbers | Space Grotesk Bold, 40sp, color-accent |
| Stat Labels | DM Sans Regular, 12sp, color-text-secondary, ALL CAPS |
| Button Labels | DM Sans SemiBold, 14sp, letter-spacing 0.5 |
| Body / Meta | DM Sans Regular, 14sp, color-text-secondary |
| Component | Specification |
| --- | --- |
| Top bar | Date (DM Sans, 14sp secondary) + Streak flame counter (right) + Stats icon (right) |
| Task Slot (empty) | Dashed border card, placeholder text, tap-anywhere to add |
| Task Slot (filled) | Solid border card, task text, checkbox on left, 3-dot overflow on right |
| Task Slot (done) | Checkbox filled green, text has strikethrough + 50% opacity |
| Completion counter | '2 / 3 done' shown as accent-colored progress line at bottom of task list |
| Bottom nav | Home | History | Settings — icon + label, active state uses accent color |
| Interaction | Animation |
| --- | --- |
| Task complete | Checkbox fills (200ms ease-out) → text fades to 50% + strikethrough (150ms) → card background shifts to surface-success (100ms) |
| All 3 done | Confetti burst from bottom + subtle haptic pattern + streak counter increments with bounce |
| Task add | Card expands from dashed to solid with spring animation (300ms) |
| Task delete | Swipe-to-delete with red background reveal, spring-back if not committed |
| Daily reset | On first open after midnight: cards slide out upward sequentially (staggered 80ms), new empty slots slide in |
| Streak increment | Flame icon pulses + number counts up with roll animation |
| Navigation | Bottom nav icon scales to 1.2x on tap (spring, 150ms) |
| Slot limit reached | Disabled add button wobbles briefly (8ms × 3 oscillations) when tapped |
| Layer | Technology |
| --- | --- |
| Language | Kotlin |
| UI Framework | Jetpack Compose (Material 3 base, heavily customized) |
| Architecture | MVVM + Repository pattern |
| Local DB | Room (SQLite) — tasks, daily archives, streak data |
| DI | Hilt |
| Notifications | WorkManager + NotificationCompat |
| Ads | Google Mobile Ads SDK (AdMob) — latest stable |
| Navigation | Jetpack Navigation Compose |
| State | StateFlow + ViewModel |
| Min SDK | API 26 (Android 8.0) |
| Target SDK | API 35 |
| Metric | Target (30 days) | Measurement |
| --- | --- | --- |
| D1 Retention | > 40% | Firebase Analytics |
| D7 Retention | > 20% | Firebase Analytics |
| Daily completion rate | > 60% complete 3/3 | Room DB aggregation |
| Avg session length | < 45 seconds | Firebase Analytics |
| Rewarded ad CTR | > 8% | AdMob dashboard |
| Interstitial CTR | > 1.5% | AdMob dashboard |
| Play Store rating | > 4.3 stars | Play Console |
| Crash-free rate | > 99.5% | Firebase Crashlytics |
| Ad Type | Test Ad Unit ID |
| --- | --- |
| Interstitial (Android) | ca-app-pub-3940256099942544/1033173712 |
| Rewarded (Android) | ca-app-pub-3940256099942544/5224354917 |
| App ID (Test) | ca-app-pub-3940256099942544~3347511713 |