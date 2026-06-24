# Graph Report - D:\Mita\mita  (2026-06-23)

## Corpus Check
- 77 files · ~87,769 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 628 nodes · 750 edges · 37 communities (30 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

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
- [[_COMMUNITY_History Detail Screen|History Detail Screen]]

## God Nodes (most connected - your core abstractions)
1. `Mita App` - 37 edges
2. `package:flutter/material.dart` - 33 edges
3. `../../core/theme.dart` - 24 edges
4. `package:google_fonts/google_fonts.dart` - 24 edges
5. `package:provider/provider.dart` - 9 edges
6. `../../providers/task_provider.dart` - 9 edges
7. `../data/database_helper.dart` - 7 edges
8. `package:shared_preferences/shared_preferences.dart` - 7 edges
9. `../data/models/task_model.dart` - 7 edges
10. `../../core/streak_milestones.dart` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Mita App` --uses--> `Google Mobile Ads (AdMob)`  [EXTRACTED]
  README.md → pubspec.yaml
- `Mita App` --uses--> `SharedPreferences`  [EXTRACTED]
  README.md → pubspec.yaml
- `Mita App` --uses--> `In-App Update`  [EXTRACTED]
  README.md → pubspec.yaml
- `Mita App` --has_feature--> `Streak System`  [INFERRED]
  README.md → RELEASE_NOTES.md
- `Mita App` --has_feature--> `Weekly Summary`  [EXTRACTED]
  README.md → opencode_context.md

## Communities (37 total, 7 thin omitted)

### Community 0 - "App Entry & Navigation"
Cohesion: 0.05
Nodes (40): AppTheme, getStreakColor, WisdomMessage, WisdomMessages, OnboardingPageData, AnimatedContainer, build, ExpandingDots (+32 more)

### Community 1 - "UI Theme & Typography"
Cohesion: 0.05
Nodes (42): ../../core/streak_milestones.dart, ../../core/theme.dart, build, _buildHeroSection, _buildMilestoneNode, _buildMilestoneTimeline, _buildRecentActivity, _buildTrophyRoom (+34 more)

### Community 2 - "Task Data Layer"
Cohesion: 0.06
Nodes (41): AdMob Interstitial, AdMob Rewarded, App Branding, Calendar Heatmap, Dark Theme, Dart Language, Data Backup/Restore, Database Schema Auto-Healing (+33 more)

### Community 3 - "Streak & Milestones"
Cohesion: 0.05
Nodes (37): build, _buildDaySummary, _buildProductivityInsight, _buildSummaryItem, _buildTaskCard, _buildTimeRow, _calculateAverageDuration, Column (+29 more)

### Community 4 - "Home Screen Layout"
Cohesion: 0.06
Nodes (35): ../core/wisdom_messages.dart, build, _buildActiveTimerBar, _buildAddButton, _buildDeadlineBar, _buildEmptySlot, _buildProgressIndicator, _buildRecurrenceChip (+27 more)

### Community 5 - "Stats Screen Tabs"
Cohesion: 0.06
Nodes (34): _adjustToValidDay, _checkRevertStreak, _checkStreakFreeze, clearMilestoneCelebration, DateTime, _formatDate, _getDateKey, _getIsoWeek (+26 more)

### Community 6 - "Focus Session Timer"
Cohesion: 0.07
Nodes (29): AnimatedBuilder, build, Color, Container, dispose, ImageFiltered, initState, _LogoIcon (+21 more)

### Community 7 - "Focus UI & Controls"
Cohesion: 0.07
Nodes (29): build, _buildSectionTitle, _buildVersionRow, Container, _exportData, GestureDetector, Icon, _importData (+21 more)

### Community 8 - "Onboarding Flow"
Cohesion: 0.07
Nodes (28): build, _buildCalendarDay, _buildCalendarGrid, _buildCalendarHeader, _buildHeroRow, _buildLegend, _buildStreakSummaryCard, _buildWeekLabels (+20 more)

### Community 9 - "Settings & Services"
Cohesion: 0.07
Nodes (27): AdService, build, FadeTransition, main, MaterialApp, MaterialPageRoute, MitaApp, NotificationService (+19 more)

### Community 10 - "Notification & Backup"
Cohesion: 0.07
Nodes (27): build, _buildAmbientSection, _buildDurationChip, _buildHeader, _buildReadyContent, _buildRunningContent, _buildSessionHistory, _buildSoundButton (+19 more)

### Community 11 - "Wisdom Banner Widget"
Cohesion: 0.07
Nodes (24): dispose, NotificationService, _onStateChange, pause, PomodoroProvider, resetToReady, resume, skipBreak (+16 more)

### Community 12 - "History Screen"
Cohesion: 0.09
Nodes (21): BarChartGroupData, BarTooltipItem, _breakdownItem, build, _buildBarChart, _buildSessionBreakdown, _buildSessionQuality, _buildStatCardsRow1 (+13 more)

### Community 13 - "Stats Provider"
Cohesion: 0.10
Nodes (20): build, _buildInsightCard, _buildLineChart, _buildStatCardsRow1, _buildStatCardsRow2, _buildTimeToCompleteCard, Column, Container (+12 more)

### Community 14 - "Stats Detail Charts"
Cohesion: 0.10
Nodes (18): close, COUNT, _createDB, DatabaseHelper, date, Exception, focus_sessions, _getColumnType (+10 more)

### Community 15 - "Pomodoro Timer Service"
Cohesion: 0.11
Nodes (17): AdService, Function, _loadRewardedAd, _initNotifications, _initTimezone, _loadNotificationTime, NotificationDetails, NotificationService (+9 more)

### Community 16 - "Stats Overview Tab"
Cohesion: 0.11
Nodes (17): build, dispose, goToTab, HistoryScreen, HomeScreen, initState, MainNavigation, MainNavigationState (+9 more)

### Community 17 - "Graphify Tools"
Cohesion: 0.11
Nodes (17): build, dispose, Icon, initState, paint, PomodoroAmbientToggle, PomodoroOverlay, _PomodoroOverlayState (+9 more)

### Community 18 - "Ambient Sound"
Cohesion: 0.23
Nodes (10): BackupService, JsonStorageService, dart:convert, dart:io, ../data/database_helper.dart, ../data/models/task_model.dart, package:file_picker/file_picker.dart, package:path_provider/path_provider.dart (+2 more)

### Community 19 - "Task Provider Logic"
Cohesion: 0.18
Nodes (10): ../../core/constants/storage_keys.dart, build, FadeTransition, initState, Scaffold, SizedBox, SplashScreen, _SplashScreenState (+2 more)

### Community 20 - "Streak Dashboard Widget"
Cohesion: 0.18
Nodes (10): _computeAvgTimeToComplete, _computeBestFocusDay, _computeDeepQuick, _computeFocusStreak, _computeInterruptions, _computeTaskStats, DateTime, _loadStreakPrefs (+2 more)

### Community 21 - "Stat Card Widget"
Cohesion: 0.25
Nodes (7): AnimatedBuilder, build, dispose, initState, PulsingCta, _PulsingCtaState, package:flutter/services.dart

### Community 22 - "Google Ads Integration"
Cohesion: 0.29
Nodes (6): getProgressToNextMilestone, getStreakMessage, getStreakTitle, isMilestoneDay, Milestone, StreakMilestones

### Community 23 - "Streak Calendar Widget"
Cohesion: 0.29
Nodes (6): build, _cycleTrack, IconButton, PomodoroAmbientToggle, _PomodoroAmbientToggleState, ../services/ambient_sound_service.dart

### Community 25 - "Milestone Badge Widget"
Cohesion: 0.50
Nodes (3): copyWith, FocusSession, _normalizeDateToString

### Community 26 - "Pomodoro Overlay Widget"
Cohesion: 0.50
Nodes (3): copyWith, _normalizeDateToString, Task

## Knowledge Gaps
- **513 isolated node(s):** `$schema`, `plugin`, `@opencode-ai/plugin`, `java.configuration.updateBuildConfiguration`, `MainActivity` (+508 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `App Entry & Navigation` to `UI Theme & Typography`, `Streak & Milestones`, `Home Screen Layout`, `Stats Screen Tabs`, `Focus Session Timer`, `Focus UI & Controls`, `Onboarding Flow`, `Settings & Services`, `Notification & Backup`, `Wisdom Banner Widget`, `History Screen`, `Stats Provider`, `Stats Overview Tab`, `Graphify Tools`, `Task Provider Logic`, `Streak Dashboard Widget`, `Stat Card Widget`, `Streak Calendar Widget`?**
  _High betweenness centrality (0.281) - this node is a cross-community bridge._
- **Why does `../../core/theme.dart` connect `UI Theme & Typography` to `App Entry & Navigation`, `Streak & Milestones`, `Home Screen Layout`, `Focus Session Timer`, `Focus UI & Controls`, `Onboarding Flow`, `Settings & Services`, `Notification & Backup`, `History Screen`, `Stats Provider`, `Stats Overview Tab`, `Graphify Tools`, `Task Provider Logic`, `Stat Card Widget`?**
  _High betweenness centrality (0.126) - this node is a cross-community bridge._
- **Why does `package:google_fonts/google_fonts.dart` connect `App Entry & Navigation` to `UI Theme & Typography`, `Streak & Milestones`, `Home Screen Layout`, `Focus Session Timer`, `Focus UI & Controls`, `Onboarding Flow`, `Settings & Services`, `Notification & Backup`, `History Screen`, `Stats Provider`, `Stats Overview Tab`, `Graphify Tools`, `Task Provider Logic`, `Stat Card Widget`?**
  _High betweenness centrality (0.116) - this node is a cross-community bridge._
- **What connects `$schema`, `plugin`, `@opencode-ai/plugin` to the rest of the system?**
  _513 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Entry & Navigation` be split into smaller, more focused modules?**
  _Cohesion score 0.045068027210884355 - nodes in this community are weakly interconnected._
- **Should `UI Theme & Typography` be split into smaller, more focused modules?**
  _Cohesion score 0.04625346901017576 - nodes in this community are weakly interconnected._
- **Should `Task Data Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.06219512195121951 - nodes in this community are weakly interconnected._