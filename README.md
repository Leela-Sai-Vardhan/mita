# Mita 🎯

> Focus on what matters. Three tasks, one day.

[![Flutter](https://img.shields.io/badge/Flutter-3.2%2B-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**By: [Leela Sai Vardhan](https://github.com/Leela-Sai-Vardhan)**

---

## 📱 Overview

Mita is a minimalist task management app that follows a simple philosophy: **focus on three tasks per day**. Built with Flutter, it features local SQLite storage, scheduled notifications, home screen widget, and beautiful animations.

The goal is to combat productivity anxiety by limiting daily tasks to just three high-priority items.

---

## 🎯 Key Features

| Feature | Description |
|---------|-------------|
| **3-Task Daily Limit** | Maximum 3 active tasks per day to prevent overwhelm |
| **📅 Daily Reset** | Tasks automatically reset each day for fresh focus |
| **🔔 Smart Notifications** | Scheduled reminders at chosen times |
| **🏠 Home Widget** | View today's tasks directly from Android home screen |
| **📊 Statistics** | Track completed tasks over time |
| **💾 Offline-First** | All data stored locally - no internet required |
| **🎨 Beautiful UI** | Glass morphism design with smooth animations |

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.2+ |
| **Language** | Dart |
| **State Management** | Provider |
| **Local Database** | SQLite (sqflite) |
| **Notifications** | flutter_local_notifications |
| **Animations** | flutter_animate |
| **Home Widget** | home_widget package |
| **Fonts** | Google Fonts (Inter) |

---

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   └── theme.dart           # App theme & colors
├── data/
│   ├── database_helper.dart  # SQLite operations
│   └── models/
│       └── task_model.dart  # Task entity
├── screens/
│   ├── home_screen.dart     # Main task list
│   ├── history_screen.dart  # Past tasks archive
│   ├── stats_screen.dart    # Statistics view
│   └── settings_screen.dart # App settings
├── services/
│   ├── notification_service.dart
│   ├── backup_service.dart
│   └── json_storage_service.dart
├── providers/
│   └── task_provider.dart   # State management
└── widgets/
    └── common_widgets.dart  # Reusable components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.2+
- Android SDK for home widget

### Installation

```bash
# Clone the repository
git clone https://github.com/Leela-Sai-Vardhan/mita.git
cd mita

# Get dependencies
flutter pub get

# Build and run
flutter run
```

### Building Home Widget

```bash
# Generate widget assets
flutter pub run home_widget:generate
```

---

## 🎨 Design Highlights

- **Glass Morphism**: Frosted glass effects on cards
- **Dark Theme**: Easy on the eyes, modern look
- **Micro-animations**: Smooth transitions and feedback
- **Minimal UI**: No clutter, just tasks

---

## 🔧 Key Implementation Details

### SQLite Schema

```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  status TEXT DEFAULT 'pending',
  notify_time TEXT
);
```

### Notification Scheduling

```dart
// Schedule daily reminder
flutterLocalNotificationsPlugin.zonedSchedule(
  0,
  'Mita',
  'You have ${pendingTasks} tasks remaining today!',
  scheduledTime,
  NotificationDetails(...),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
);
```

---

## 🤔 Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| **Limiting to 3 tasks** | Hard-coded validation at UI level - disable add button when 3 exist |
| **Home widget updates** | Used SharedPreferences + Android broadcast for cross-process communication |
| **Notification permissions** | Added runtime permission request with graceful fallback |
| **Data backup** | Implemented JSON export/import for local backup |

---

## 📈 What I Learned

- **SQLite in Flutter**: Complex queries, transactions, migrations
- **Provider pattern**: Simple state management for small apps
- **Android widgets**: Native widget development with platform channels
- **Notification scheduling**: Exact alarms and battery optimization handling
- **Minimalist UX**: Designing for focus, not feature density

---

## 🔜 Future Enhancements

- [ ] iOS support
- [ ] Cloud sync (Supabase/Firebase)
- [ ] Tags and categories
- [ ] Recurring tasks
- [ ] Focus mode (Pomodoro)

---

## 📱 Screenshots

*(Add your app screenshots in a /screenshots folder)*

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👤 Author

**Leela Sai Vardhan**
- GitHub: [@Leela-Sai-Vardhan](https://github.com/Leela-Sai-Vardhan)
- Email: leelasaisvardhan@gmail.com

---

*Less is more. Focus on three.* 🧘‍♂️