# Todo-Alarming-App

An offline Flutter task management and alarming app built with Material 3. It allows users to schedule time-critical tasks with precise offline alarms, audio alerts, and persistent local storage.

## Features

- **Offline-First**: Uses local storage (`shared_preferences`) for fast and reliable persistence without requiring network connectivity.
- **Accurate Alarms**: Integrates `flutter_local_notifications` with exact alarm scheduling (`SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`).
- **Sound Alerts**: Custom alarm ringtone playback via `audioplayers` that loops until acknowledged or silenced.
- **Task Management**: Create, edit, toggle completion, and delete tasks with date and time pickers.
- **Modern UI**: Clean Material 3 design supporting both light and dark themes.

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.13.4)
- Android SDK (API 34+ recommended) or iOS development environment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/eyosiyas12345/Todo-Alarming-App.git
cd Todo-Alarming-App
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running Tests

```bash
flutter test
```
