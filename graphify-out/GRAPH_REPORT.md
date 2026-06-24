# Graph Report - mita  (2026-06-24)

## Corpus Check
- 66 files · ~91,723 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1248 nodes · 2172 edges · 97 communities (70 shown, 27 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 53 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c38bae30`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_App Entry & Navigation|App Entry & Navigation]]
- [[_COMMUNITY_UI Theme & Typography|UI Theme & Typography]]
- [[_COMMUNITY_Task Data Layer|Task Data Layer]]
- [[_COMMUNITY_Streak & Milestones|Streak & Milestones]]
- [[_COMMUNITY_Home Screen Layout|Home Screen Layout]]
- [[_COMMUNITY_Stats Screen Tabs|Stats Screen Tabs]]
- [[_COMMUNITY_Focus Session Timer|Focus Session Timer]]
- [[_COMMUNITY_Focus UI & Controls|Focus UI & Controls]]
- [[_COMMUNITY_Onboarding Flow|Onboarding Flow]]
- [[_COMMUNITY_Settings & Services|Settings & Services]]
- [[_COMMUNITY_Notification & Backup|Notification & Backup]]
- [[_COMMUNITY_Wisdom Banner Widget|Wisdom Banner Widget]]
- [[_COMMUNITY_History Screen|History Screen]]
- [[_COMMUNITY_Stats Provider|Stats Provider]]
- [[_COMMUNITY_Stats Detail Charts|Stats Detail Charts]]
- [[_COMMUNITY_Pomodoro Timer Service|Pomodoro Timer Service]]
- [[_COMMUNITY_Stats Overview Tab|Stats Overview Tab]]
- [[_COMMUNITY_Graphify Tools|Graphify Tools]]
- [[_COMMUNITY_Ambient Sound|Ambient Sound]]
- [[_COMMUNITY_Task Provider Logic|Task Provider Logic]]
- [[_COMMUNITY_Streak Dashboard Widget|Streak Dashboard Widget]]
- [[_COMMUNITY_Stat Card Widget|Stat Card Widget]]
- [[_COMMUNITY_Google Ads Integration|Google Ads Integration]]
- [[_COMMUNITY_Streak Calendar Widget|Streak Calendar Widget]]
- [[_COMMUNITY_Streak Indicator Widget|Streak Indicator Widget]]
- [[_COMMUNITY_Milestone Badge Widget|Milestone Badge Widget]]
- [[_COMMUNITY_Pomodoro Overlay Widget|Pomodoro Overlay Widget]]
- [[_COMMUNITY_Pomodoro Ambient Toggle|Pomodoro Ambient Toggle]]
- [[_COMMUNITY_Stats Focus Tab|Stats Focus Tab]]
- [[_COMMUNITY_Stats Tasks Tab|Stats Tasks Tab]]
- [[_COMMUNITY_Streak Ring Painter|Streak Ring Painter]]
- [[_COMMUNITY_Backup & JSON Storage|Backup & JSON Storage]]
- [[_COMMUNITY_Constants & Storage Keys|Constants & Storage Keys]]
- [[_COMMUNITY_History Detail Screen|History Detail Screen]]
- [[_COMMUNITY_Release & Distribution|Release & Distribution]]
- [[_COMMUNITY_Privacy & Licensing|Privacy & Licensing]]
- [[_COMMUNITY_Development Config|Development Config]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]
- [[_COMMUNITY_Community 84|Community 84]]
- [[_COMMUNITY_Community 85|Community 85]]
- [[_COMMUNITY_Community 86|Community 86]]
- [[_COMMUNITY_Community 87|Community 87]]
- [[_COMMUNITY_Community 88|Community 88]]
- [[_COMMUNITY_Community 89|Community 89]]
- [[_COMMUNITY_Community 90|Community 90]]
- [[_COMMUNITY_Community 91|Community 91]]
- [[_COMMUNITY_Community 94|Community 94]]
- [[_COMMUNITY_Community 95|Community 95]]
- [[_COMMUNITY_Community 96|Community 96]]
- [[_COMMUNITY_Community 97|Community 97]]
- [[_COMMUNITY_Community 98|Community 98]]

## God Nodes (most connected - your core abstractions)
1. `../../providers/task_provider.dart` - 64 edges
2. `package:flutter/material.dart` - 58 edges
3. `screens/home_screen.dart` - 57 edges
4. `../../core/theme.dart` - 47 edges
5. `package:google_fonts/google_fonts.dart` - 46 edges
6. `screens/stats_screen.dart` - 45 edges
7. `history_detail_screen.dart` - 28 edges
8. `Mita App` - 23 edges
9. `package:provider/provider.dart` - 22 edges
10. `../../core/streak_milestones.dart` - 20 edges

## Surprising Connections (you probably didn't know these)
- `Mita App` --conceptually_related_to--> `Mita App Icon (root)`  [INFERRED]
  opencode_context.md → iocn.png
- `Mita App Icon (root)` --semantically_similar_to--> `Android Launcher Icon (mdpi)`  [INFERRED] [semantically similar]
  iocn.png → android/app/src/main/res/mipmap-mdpi/ic_launcher.png
- `Mita App Icon (root)` --semantically_similar_to--> `Android Launcher Icon (hdpi)`  [INFERRED] [semantically similar]
  iocn.png → android/app/src/main/res/mipmap-hdpi/ic_launcher.png
- `Mita App Icon (root)` --semantically_similar_to--> `Android Launcher Icon (xhdpi)`  [INFERRED] [semantically similar]
  iocn.png → android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
- `Mita App Icon (root)` --semantically_similar_to--> `Android Launcher Icon (xxhdpi)`  [INFERRED] [semantically similar]
  iocn.png → android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png

## Hyperedges (group relationships)
- **Mita Documentation Set** — app_icon_prompt_md, microtask_app_design_preview_html, opencode_context_md, play_console_guide_md, privacy_policy_md, readme_md, upgrade_md [EXTRACTED 1.00]
- **Mita Design System** — neo_brutalist_design, design_color_tokens, space_grotesk_font [EXTRACTED 1.00]
- **Mita Core Architecture** — local_data_architecture, notification_system, provider_state_management, three_task_focus_philosophy [INFERRED 0.85]
- **Android App Icon Density Set** — ic_launcher_mdpi, ic_launcher_hdpi, ic_launcher_xhdpi, ic_launcher_xxhdpi, ic_launcher_xxxhdpi [EXTRACTED 1.00]
- **Mita App Icon Assets** — iocn_png, ic_launcher_mdpi, ic_launcher_hdpi, ic_launcher_xhdpi, ic_launcher_xxhdpi, ic_launcher_xxxhdpi, app_icon_prompt [INFERRED 0.95]
- **Task Persistence Flow** — task_model_dart, database_helper_dart, task_provider_dart [INFERRED 0.95]
- **Android Home Widget Integration** — homewidgetprovider_kt, task_provider_dart, generatedpluginregistrant_java [INFERRED 0.95]
- **Hybrid Task State Synchronization and Backup Flow** — screens_home_screen, screens_settings_screen, services_json_storage_service, services_backup_service [INFERRED 0.85]
- **Mita Main Tabbed Interface and Core Navigation Shell** — screens_home_screen, screens_history_screen, screens_stats_screen, screens_settings_screen [INFERRED 0.95]
- **Minimalist and Privacy-Centric Architecture** — readme_md, privacy_policy, pubspec_yaml, mita_local_storage, mita_three_task_limit [INFERRED 0.95]
- **Google Play Store Release & Monetization Ecosystem** — play_console_guide, privacy_policy, mita_admob_integration [EXTRACTED 1.00]

## Communities (97 total, 27 thin omitted)

### Community 0 - "App Entry & Navigation"
Cohesion: 0.08
Nodes (47): AnimatedBuilder, build, _buildAmbientSection, _buildDurationChip, _buildHeader, _buildReadyContent, _buildRunningContent, _buildSessionHistory (+39 more)

### Community 1 - "UI Theme & Typography"
Cohesion: 0.06
Nodes (74): _computeAvgTimeToComplete, _computeBestFocusDay, _computeDeepQuick, _computeFocusStreak, _computeInterruptions, _computeTaskStats, DateTime, _loadStreakPrefs (+66 more)

### Community 2 - "Task Data Layer"
Cohesion: 0.09
Nodes (41): AdMob Monetization, Analysis Options Config, Android Manifest, Android Mipmap Drawable Resource, App Icon Design Prompt, Data Privacy & GDPR Compliance, Density Bucket hdpi (1.5x), Density Bucket mdpi (1x) (+33 more)

### Community 3 - "Streak & Milestones"
Cohesion: 0.10
Nodes (46): ../core/wisdom_messages.dart, AnimatedContainer, build, _buildAddButton, _buildDeadlineBar, _buildEmptySlot, _buildProgressIndicator, _buildRecurrenceChip (+38 more)

### Community 4 - "Home Screen Layout"
Cohesion: 0.05
Nodes (42): 10. Important Links, 1. App Information, 2. Store Listing, 3. Store Text, 4. Content Rating, 5. Privacy Policy, 6. Ad Policy (AdMob), 7. Build & Release (+34 more)

### Community 5 - "Stats Screen Tabs"
Cohesion: 0.05
Nodes (37): 10.1 Questions, 10.2 Response Time, 10. Contact Information, 11.1 Ad Categories, 11.2 Ad Frequency, 11. Ad-Related Information, 12.1 Google Play Requirements, 12.2 GDPR (+29 more)

### Community 6 - "Focus Session Timer"
Cohesion: 0.11
Nodes (40): build, _buildCalendarDay, _buildCalendarGrid, _buildCalendarHeader, _buildFullStats, _buildLegend, _buildStreakCard, _buildStreakSummaryCard (+32 more)

### Community 7 - "Focus UI & Controls"
Cohesion: 0.12
Nodes (36): AdService, build, dispose, FadeTransition, goToTab, HistoryScreen, HomeScreen, initState (+28 more)

### Community 8 - "Onboarding Flow"
Cohesion: 0.08
Nodes (31): 10. Appendix — Ad Unit ID Reference, 1.1 Target Audience, 1.2 Value Proposition, 1. Product Overview, 2.1 Core Features (MVP), 2.2 Ad Integration (Monetization), 2.3 Settings, 2. Feature Specification (+23 more)

### Community 9 - "Settings & Services"
Cohesion: 0.10
Nodes (30): configure, dispose, NotificationService, _onStateChange, pause, pauseFocus, PomodoroProvider, _reloadSessionCount (+22 more)

### Community 10 - "Notification & Backup"
Cohesion: 0.13
Nodes (27): build, _buildSectionTitle, _buildVersionRow, Container, _exportData, GestureDetector, Icon, _importData (+19 more)

### Community 11 - "Wisdom Banner Widget"
Cohesion: 0.08
Nodes (23): 👤 Author, Building Home Widget, 🤔 Challenges & Solutions, code:block1 (lib/), code:bash (# Clone the repository), code:bash (# Generate widget assets), code:dart (// Schedule daily reminder), 🎨 Design Highlights (+15 more)

### Community 12 - "History Screen"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 13 - "Stats Provider"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 14 - "Stats Detail Charts"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 15 - "Pomodoro Timer Service"
Cohesion: 0.13
Nodes (14): build, _buildHeroSection, _buildMilestoneNode, _buildMilestoneTimeline, _buildRecentActivity, _buildTrophyRoom, Column, Icon (+6 more)

### Community 16 - "Stats Overview Tab"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 17 - "Graphify Tools"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 18 - "Ambient Sound"
Cohesion: 0.12
Nodes (20): target_ndk_api, assets, ar, cc, ld, android, c_compiler, link_mode_preference (+12 more)

### Community 19 - "Task Provider Logic"
Cohesion: 0.13
Nodes (20): close, COUNT, _createDB, DatabaseHelper, date, DateTime, Exception, focus_sessions (+12 more)

### Community 20 - "Streak Dashboard Widget"
Cohesion: 0.11
Nodes (39): build, _buildDaySummary, _buildProductivityInsight, _buildSummaryItem, _buildTaskCard, _buildTimeRow, _calculateAverageDuration, Column (+31 more)

### Community 21 - "Stat Card Widget"
Cohesion: 0.23
Nodes (14): build, _buildProgressRing, Column, Container, Expanded, Icon, paint, _ProgressRingPainter (+6 more)

### Community 22 - "Google Ads Integration"
Cohesion: 0.11
Nodes (18): AndroidManifest.xml, backup_service.dart (NEW), Changes Made, database_helper.dart, history_detail_screen.dart, history_detail_screen.dart (NEW), history_screen.dart, home_screen.dart (+10 more)

### Community 23 - "Streak Calendar Widget"
Cohesion: 0.13
Nodes (19): ../../core/theme.dart, AppTheme, customSnackBar, getStreakColor, ScaleTransition, SizedBox, SnackBar, ThemeData (+11 more)

### Community 24 - "Streak Indicator Widget"
Cohesion: 0.27
Nodes (11): Mita OpenCode Context & Session Roadmap, Inexact Zoned Schedule Alarm & Battery Optimization Bypass, Samsung Task Visibility SQLite & JSON Hybrid Sync, Swipe-to-Delete Dismissible Tasks with Active SnackBar Undo, Timezone-Agnostic Date Normalization Rule, History Detail Screen, Home Screen, Settings Screen (+3 more)

### Community 25 - "Milestone Badge Widget"
Cohesion: 0.20
Nodes (10): App Overview, Current Work, Instructions, Mita - OpenCode Context, Notes, Notes, Phase 20 Enhancements (v1.2.0+6) - Universal Android Compatibility & Reliability, Remaining Issues (+2 more)

### Community 26 - "Pomodoro Overlay Widget"
Cohesion: 0.39
Nodes (7): configVersion, flutterRoot, flutterVersion, generator, generatorVersion, packages, pubCache

### Community 27 - "Pomodoro Ambient Toggle"
Cohesion: 0.48
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 28 - "Stats Focus Tab"
Cohesion: 0.48
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 29 - "Stats Tasks Tab"
Cohesion: 0.48
Nodes (5): build_end, build_start, code_assets, data_assets, dependencies

### Community 30 - "Streak Ring Painter"
Cohesion: 0.33
Nodes (3): AGENTS.md Context, graphify, Workflow: graphify

### Community 31 - "Backup & JSON Storage"
Cohesion: 0.47
Nodes (4): format-version, native-assets, format-version, native-assets

### Community 32 - "Constants & Storage Keys"
Cohesion: 0.33
Nodes (5): build, OnboardingPage, Padding, SizedBox, Spacer

### Community 34 - "Release & Distribution"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 36 - "Development Config"
Cohesion: 0.60
Nodes (3): copyWith, FocusSession, _normalizeDateToString

### Community 37 - "Community 37"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 38 - "Community 38"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 39 - "Community 39"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 40 - "Community 40"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 41 - "Community 41"
Cohesion: 0.60
Nodes (3): assets_for_linking, status, timestamp

### Community 42 - "Community 42"
Cohesion: 0.60
Nodes (3): configVersion, packages, roots

### Community 43 - "Community 43"
Cohesion: 0.60
Nodes (3): copyWith, _normalizeDateToString, Task

### Community 44 - "Community 44"
Cohesion: 0.40
Nodes (5): Changes Made, notification_service.dart, stats_screen.dart, task_provider.dart, Widget Integration

### Community 45 - "Community 45"
Cohesion: 0.50
Nodes (5): App Neo-Brutalist Design Preview Mockup, History Screen, Stats Screen, Ad Service Stub, Common Widgets

### Community 58 - "Community 58"
Cohesion: 0.50
Nodes (4): App Icon Design Prompt for Mita, App Icon Generation Prompt, Prompt, Splash Screen

### Community 64 - "Community 64"
Cohesion: 1.00
Nodes (3): Graphify Agent Knowledge Graph Tool, Graphify Rules, Graphify Workflow

### Community 80 - "Community 80"
Cohesion: 0.36
Nodes (8): build, Container, GestureDetector, RewardButton, Row, SizedBox, StatCard, StatRow

### Community 81 - "Community 81"
Cohesion: 0.24
Nodes (12): ../../core/streak_milestones.dart, getProgressToNextMilestone, getStreakMessage, getStreakTitle, isMilestoneDay, Milestone, StreakMilestones, build (+4 more)

### Community 82 - "Community 82"
Cohesion: 0.06
Nodes (30): AnimatedBuilder, build, Color, Container, dispose, ImageFiltered, initState, _LogoIcon (+22 more)

### Community 83 - "Community 83"
Cohesion: 0.43
Nodes (7): build, Column, Container, _dateKey, SizedBox, StreakCalendar, ../widgets/streak_calendar.dart

### Community 84 - "Community 84"
Cohesion: 0.07
Nodes (28): build, _buildCalendarDay, _buildCalendarGrid, _buildCalendarHeader, _buildHeroRow, _buildLegend, _buildStreakSummaryCard, _buildWeekLabels (+20 more)

### Community 85 - "Community 85"
Cohesion: 0.40
Nodes (4): AnimatedContainer, build, ExpandingDots, Row

### Community 87 - "Community 87"
Cohesion: 0.15
Nodes (20): _PluginRegistrant, register, package:flutter_local_notifications_linux/flutter_local_notifications_linux.dart, package:path_provider_android/path_provider_android.dart, package:path_provider_foundation/path_provider_foundation.dart, package:path_provider_linux/path_provider_linux.dart, package:path_provider_windows/path_provider_windows.dart, package:shared_preferences_android/shared_preferences_android.dart (+12 more)

### Community 88 - "Community 88"
Cohesion: 0.09
Nodes (21): BarChartGroupData, BarTooltipItem, _breakdownItem, build, _buildBarChart, _buildSessionBreakdown, _buildSessionQuality, _buildStatCardsRow1 (+13 more)

### Community 89 - "Community 89"
Cohesion: 0.09
Nodes (21): build, _buildInsightCard, _buildLineChart, _buildStatCardsRow1, _buildStatCardsRow2, _buildTimeToCompleteCard, Column, Container (+13 more)

### Community 90 - "Community 90"
Cohesion: 0.12
Nodes (16): build, dispose, goToTab, HistoryScreen, HomeScreen, initState, MainNavigation, MainNavigationState (+8 more)

### Community 91 - "Community 91"
Cohesion: 0.40
Nodes (4): build, Expanded, SizedBox, StatCard

### Community 94 - "Community 94"
Cohesion: 0.40
Nodes (4): WisdomMessage, WisdomMessages, streak_milestones.dart, theme.dart

### Community 95 - "Community 95"
Cohesion: 0.29
Nodes (6): AnimatedSwitcher, build, _buildContent, Container, FadeTransition, WisdomBanner

### Community 96 - "Community 96"
Cohesion: 0.24
Nodes (10): ../../core/constants/storage_keys.dart, build, FadeTransition, initState, Scaffold, SizedBox, SplashScreen, _SplashScreenState (+2 more)

### Community 97 - "Community 97"
Cohesion: 0.20
Nodes (10): OnboardingPageData, build, _cycleTrack, IconButton, PomodoroAmbientToggle, _PomodoroAmbientToggleState, paint, shouldRepaint (+2 more)

## Knowledge Gaps
- **419 isolated node(s):** `@opencode-ai/plugin`, `PageRouteBuilder`, `FadeTransition`, `screens/onboarding/onboarding_screen.dart`, `screens/navigation_shell.dart` (+414 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **27 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 97` to `App Entry & Navigation`, `UI Theme & Typography`, `Streak & Milestones`, `Focus Session Timer`, `Focus UI & Controls`, `Settings & Services`, `Notification & Backup`, `Pomodoro Timer Service`, `Streak Dashboard Widget`, `Stat Card Widget`, `Streak Calendar Widget`, `Constants & Storage Keys`, `Community 80`, `Community 81`, `Community 82`, `Community 83`, `Community 84`, `Community 85`, `Community 88`, `Community 89`, `Community 90`, `Community 91`, `Community 94`, `Community 95`, `Community 96`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Why does `package:google_fonts/google_fonts.dart` connect `Streak Calendar Widget` to `App Entry & Navigation`, `Streak & Milestones`, `Focus Session Timer`, `Focus UI & Controls`, `Notification & Backup`, `Pomodoro Timer Service`, `Streak Dashboard Widget`, `Stat Card Widget`, `Constants & Storage Keys`, `Community 80`, `Community 81`, `Community 82`, `Community 83`, `Community 84`, `Community 88`, `Community 89`, `Community 90`, `Community 91`, `Community 94`, `Community 96`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Why does `../../core/theme.dart` connect `Streak Calendar Widget` to `App Entry & Navigation`, `Streak & Milestones`, `Focus Session Timer`, `Focus UI & Controls`, `Notification & Backup`, `Pomodoro Timer Service`, `Streak Dashboard Widget`, `Stat Card Widget`, `Constants & Storage Keys`, `Community 80`, `Community 81`, `Community 82`, `Community 83`, `Community 84`, `Community 88`, `Community 89`, `Community 90`, `Community 91`, `Community 95`, `Community 96`, `Community 97`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **What connects `@opencode-ai/plugin`, `PageRouteBuilder`, `FadeTransition` to the rest of the system?**
  _426 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Entry & Navigation` be split into smaller, more focused modules?**
  _Cohesion score 0.08295625942684766 - nodes in this community are weakly interconnected._
- **Should `UI Theme & Typography` be split into smaller, more focused modules?**
  _Cohesion score 0.06050420168067227 - nodes in this community are weakly interconnected._
- **Should `Task Data Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.08973172987974098 - nodes in this community are weakly interconnected._