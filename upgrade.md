# UI/UX Upgrades

## 🔴 High Priority

### Upgrade `google_mobile_ads`
- **Current version**: `5.3.1`
- **Latest version**: `9.x`
- **Why**: Old SDK versions may lose ad serving support silently. Upgrading ensures compatibility with Google's latest ad infrastructure, better fill rates, and new ad formats.
- **Risk**: Breaking changes between major versions — test ads thoroughly after upgrading.
- **How**: Update `pubspec.yaml` → `google_mobile_ads: ^9.0.0` then run `flutter pub get` and test.

---

| # | Upgrade | Files | Status | Tested |
|---|---------|-------|--------|--------|
| 1 | Stats calendar day detail popup | `stats_screen.dart` | ✅ done | ✅ |
| 2 | Home swipe-to-complete + per-task time | `home_screen.dart` | ✅ done | ✅ |
| 3 | Focus configurable timer durations + session counter | `focus_screen.dart`, `pomodoro_provider.dart` | ✅ done | ✅ |
| 4 | Empty states & micro-interactions | `home_screen.dart`, `history_screen.dart` | ✅ done | ✅ |
| 5 | Focus pre-start Ready state — preparation screen with duration/ambient selection, explicit Start button | `focus_screen.dart`, `pomodoro_provider.dart` | ✅ done | ❌ |
| 6 | Wisdom Banner — context-aware motivational messages on home screen between deadline bar and task list, with streak-colored accent bar, Perfect Day bloom, collapse when idle | `wisdom_banner.dart`, `wisdom_messages.dart`, `home_screen.dart` | ✅ done | ❌ |
| 7 | Focus screen fixes: Expanded wrapping for Spacer layout, resetToReady() after stop timer, AnimatedSwitcher fade+scale transitions, pulsing START FOCUS glow, animated blurred circle | `focus_screen.dart`, `pomodoro_provider.dart` | ✅ done | ❌ |
