# Quickstart: Flutter Foundation & Navigation

**Branch**: `001-flutter-foundation` | **Date**: 2026-04-03

---

## Prerequisites

| Tool | Minimum version | Check |
|---|---|---|
| Flutter SDK | 3.x | `flutter --version` |
| Dart SDK | 3.x | `dart --version` |
| Android emulator | API 29+ | Android Studio AVD Manager |
| iOS Simulator | iOS 16+ | Xcode → Simulator app |
| Chrome | Any stable | `google-chrome --version` |
| Django backend (B1) | Running on port 8000 | `python manage.py runserver` |

---

## 1. Clone & Install

```bash
# If not already cloned
git clone <repo-url>
cd budget-tracker\ mobile

git checkout 001-flutter-foundation

flutter pub get
```

---

## 2. Run the App

### Web (Chrome)
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api
```

### Android Emulator
```bash
# Android emulator uses 10.0.2.2 to reach the host machine's localhost
flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### iOS Simulator
```bash
flutter run -d iPhone\ 15 \
  --dart-define=API_BASE_URL=http://localhost:8000/api
```

> **Required**: `API_BASE_URL` must always be supplied. If omitted, the app will
> throw a `StateError` at startup with a descriptive message (FR-001, edge case 3).

---

## 3. Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/features/simulation/simulation_provider_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 4. Static Analysis

```bash
flutter analyze
# Expected: No issues found!
```

Zero warnings are required before committing (FR-007, SC-005).

---

## 5. Build for Production

```bash
# Web
flutter build web \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# Android APK
flutter build apk \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# iOS (requires Xcode on macOS)
flutter build ipa \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

---

## 6. Project Layout (Quick Reference)

```
lib/
  main.dart                  # Entry point — ProviderScope wraps app
  app.dart                   # MaterialApp.router, GoRouter config
  core/
    constants/app_colors.dart  # AppColors design tokens
    network/dio_client.dart    # Configured Dio instance
    cache/cache_service.dart   # SharedPreferences wrapper
    routing/app_router.dart    # GoRouter with ShellRoute
  features/
    simulation/domain/         # SimulationResult, MonthlyRow, Kpis (immutable)
    simulation/data/           # SimulationRepository (HTTP + cache logic)
    simulation/application/    # SimulationProvider (AsyncNotifierProvider)
    dashboard/presentation/    # DashboardScreen, KpiCard, MonthlyRowTile
    gam3as/presentation/       # Stub screen
    scenario/presentation/     # Stub screen
  shared/widgets/
    scaffold_with_nav.dart     # Adaptive nav (bottom bar < 600 px, rail ≥ 600 px)
```

---

## 7. Common Issues

| Symptom | Likely cause | Fix |
|---|---|---|
| `StateError: API_BASE_URL is not set` | Missing `--dart-define` | Add `--dart-define=API_BASE_URL=...` to run command |
| Dashboard shows error widget immediately | Django backend not running | `cd api && python manage.py runserver` |
| Dashboard shows stale banner | Backend unreachable, using cache | Expected behaviour — restart backend and pull to refresh |
| Android can't reach backend | Wrong host IP | Use `10.0.2.2` not `localhost` for Android emulator |
| `flutter pub get` fails | Outdated Flutter SDK | Run `flutter upgrade` |
| Zero monetary values displayed | No gam3as configured in backend | Add at least one gam3a via the Django admin or API |
