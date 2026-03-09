# Habit Tracker - Gamified Habit Tracking App

A modern, gamified habit tracker built with Flutter following Clean Architecture principles. Track your daily habits across multiple categories with beautiful Material 3 UI.

## 🎯 Features

- **Daily Progress Tracking**: Visual progress bar showing completion status
- **Category System**: Organize habits by Agua, Movimiento, Sueño, Foco, and Varios
- **Flexible Frequency**: Set habits for specific days or all days
- **Quick Actions**: Fast setup with "Everyday", "Weekdays", and "Weekends" presets
- **Persistent Storage**: All data saved locally using SharedPreferences
- **Material 3 Design**: Modern, clean UI with purple/indigo theme
- **Dark Mode Support**: Automatic theme switching based on system preferences

## 🏗️ Architecture

This app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── domain/              # Pure Dart - Business Logic
│   └── models.dart      # Entities, Enums, Repository Interface
├── infrastructure/      # External Dependencies
│   └── local_storage_repository.dart  # SharedPreferences Implementation
├── application/         # State Management
│   └── habit_provider.dart  # Provider (ChangeNotifier)
└── presentation/        # UI Layer
    ├── theme.dart       # Material 3 Theme Configuration
    ├── today_screen.dart  # Main Screen
    ├── habit_form_screen.dart  # Create/Edit Screen
    └── main.dart        # App Entry Point
```

### Layer Responsibilities

1. **Domain Layer** (`lib/domain/`):
   - Pure Dart code (no Flutter dependencies)
   - Contains business entities: `Habit`, `HabitLog`, `Frequency`
   - Defines repository contracts
   - Business logic: frequency scheduling, date matching

2. **Infrastructure Layer** (`lib/infrastructure/`):
   - Implements repository interfaces
   - Handles data persistence with SharedPreferences
   - JSON serialization/deserialization

3. **Application Layer** (`lib/application/`):
   - State management using Provider
   - Coordinates between domain and presentation
   - Calculates daily progress and statistics

4. **Presentation Layer** (`lib/presentation/`):
   - Flutter UI components
   - Screens and widgets
   - Theme configuration

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. Clone the repository:
```bash
cd /Users/jesutorr/Documents/001CodigosCursos/03ConFlutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📦 Dependencies

- **provider**: ^6.1.1 - State management
- **shared_preferences**: ^2.2.2 - Local data persistence
- **uuid**: ^4.2.2 - Unique ID generation
- **intl**: ^0.19.0 - Date formatting and localization
- **google_fonts**: ^6.1.0 - Typography (Inter font family)

## 💡 Usage

### Creating a Habit

1. Tap the "Nuevo Hábito" button
2. Enter a title for your habit
3. Select a category (Agua, Movimiento, Sueño, Foco, Varios)
4. Choose frequency:
   - **Semanal**: Select specific days of the week
   - **Manual**: Habit appears every day
5. Use quick actions for common patterns:
   - "Todos los días" - All 7 days
   - "Entre semana" - Monday to Friday
   - "Fines de semana" - Saturday and Sunday

### Completing Habits

- Tap on a habit card to mark it as complete
- Tap again to unmark
- Progress bar updates automatically
- Completed habits show strikethrough text

### Editing Habits

- Long-press on a habit card to open edit screen
- Update any field and tap "Actualizar"
- Delete option available in edit mode

## 🎨 Design System

### Categories & Colors

| Category | Icon | Color |
|----------|------|-------|
| Agua | 💧 Water Drop | Blue |
| Movimiento | 🏃 Runner | Orange |
| Sueño | 🌙 Bedtime | Purple |
| Foco | 🧠 Psychology | Green |
| Varios | 📊 Dashboard | Grey |

### Theme

- **Primary Color**: Soft Purple (#6750A4)
- **Typography**: Inter (Google Fonts)
- **Design System**: Material 3
- **Border Radius**: Consistent 12-20px rounded corners
- **Spacing**: 8px grid system

## 🔧 Technical Details

### Frequency Logic

The app uses intelligent frequency scheduling:

- **Weekly Mode**: Habits only appear on selected weekdays
- **Manual Mode**: Habits appear every day
- **Date Matching**: Uses `DateTime.weekday` (1=Monday, 7=Sunday)

### Data Persistence

All data is stored locally using SharedPreferences:
- **Habits**: Stored as JSON array under key `habits`
- **Logs**: Stored as JSON array under key `habit_logs`
- **Automatic Save**: Every create/update/delete operation

### State Management

Provider pattern with ChangeNotifier:
- Centralized state in `HabitProvider`
- Reactive UI updates
- Computed properties for progress calculation

## 📱 Screenshots

### Main Screen
- Daily progress bar with percentage
- List of today's habits
- Category badges and completion checkboxes

### Habit Form
- Text input for title
- Category selection chips
- Frequency configuration
- Quick action buttons

### Empty State
- Friendly onboarding message
- Clear call-to-action

## 🧪 Testing

To run tests (when implemented):
```bash
flutter test
```

## 🤝 Contributing

This is an educational project. Feel free to fork and modify for learning purposes.

## 📄 License

This project is created for educational purposes.

## 🎓 Learning Resources

This project demonstrates:
- Clean Architecture in Flutter
- Provider state management
- Material 3 design implementation
- Local data persistence
- Date/time handling in Dart
- Custom UI components
- Form validation

---

Built with ❤️ using Flutter
