# Gam3ya Investment Simulator Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-03

## Active Technologies

| Layer | Technology |
|---|---|
| Language | Dart 3.x |
| Framework | Flutter 3.x |
| State management | flutter_riverpod · riverpod_annotation |
| Routing | go_router ^14 |
| HTTP client | dio ^5.4 |
| Local storage | shared_preferences |
| Backend | Python 3.12 · Django 4.2+ · Django REST Framework |
| Testing | flutter_test · mocktail |

## Project Structure

```text
lib/
  main.dart
  app.dart
  core/
    constants/app_colors.dart
    network/dio_client.dart
    cache/cache_service.dart
    routing/app_router.dart
  features/
    simulation/domain/      # SimulationResult, MonthlyRow, Kpis
    simulation/data/        # SimulationRepository
    simulation/application/ # SimulationProvider (AsyncNotifierProvider)
    dashboard/presentation/ # DashboardScreen
    gam3as/presentation/    # Stub (Phase F2)
    scenario/presentation/  # Stub (Phase F4)
  shared/widgets/
    scaffold_with_nav.dart  # Adaptive nav shell

test/
  features/simulation/
  shared/widgets/

specs/
  001-flutter-foundation/   # plan.md, research.md, data-model.md, contracts/, quickstart.md
```

## Commands

```bash
# Run on web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api

# Run on Android emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Run on iOS simulator
flutter run -d 'iPhone 15' --dart-define=API_BASE_URL=http://localhost:8000/api

# Run tests
flutter test

# Static analysis (must be zero issues)
flutter analyze

# Build web
flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

## Code Style

- All monetary values stored as `int` (piastres ×100) — never `double` for currency
- All colors via `AppColors.*` constants — no inline `Color(0xFF...)` in widget files
- Feature modules must not import from another feature's `lib/features/X/` internals
- Cross-feature communication goes through `lib/core/` services or shared providers
- Every provider exposes `AsyncValue<T>` (loading / data / error) — no manual state booleans
- Commit messages must reference task ID: `feat(dashboard): T012 implement KPI cards`

## Recent Changes

- **001-flutter-foundation** (2026-04-03): Flutter client foundation — Riverpod, GoRouter,
  Dio, SharedPreferences, adaptive nav shell, SimulationProvider, CacheService

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
