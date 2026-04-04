# Tasks: Flutter Foundation & Navigation

**Input**: Design documents from `/specs/001-flutter-foundation/`
**Prerequisites**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/simulate-get.md ✅ · quickstart.md ✅

**Tests**: Included — required by SC-002 (provider state tests) and Constitution V (widget tests, TDD for financial logic).

**Organization**: Tasks are grouped by user story. Each phase can be validated independently before the next begins.

**Key design decisions** (from research.md — read before starting):
- State management: `flutter_riverpod` + `riverpod_annotation` (`AsyncNotifierProvider`)
- HTTP client: `dio ^5.4` with typed interceptors
- Routing: `go_router ^14` with a `ShellRoute` for the adaptive nav shell
- Local cache: `shared_preferences` (works on web, iOS, Android)
- Monetary fields: stored as `int` piastres (×100), converted from JSON `double` at repository boundary
- API URL: `String.fromEnvironment('API_BASE_URL')` — never hardcoded
- All colors: `AppColors.*` constants — never inline `Color(0xFF...)` in widget files

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared state)
- **[Story]**: Which user story this task belongs to ([US1], [US2])
- Exact file paths are included in every task description

## Path Conventions

All Flutter source lives under the project root (same directory as `pubspec.yaml`).

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create the Flutter project, declare all dependencies, and configure static analysis so every subsequent task starts from a clean, analysable codebase.

- [X] T001 Run `flutter create . --org com.gam3ya --platforms web,android,ios` in the repo root (the directory that contains `planmobile.md`). This creates `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`, `web/`, and `test/`. If the project was already created, skip this step and verify `pubspec.yaml` exists.

- [X] T002 Replace the `dependencies` and `dev_dependencies` sections in `pubspec.yaml` with the following exact content (keep the existing `flutter:` sdk line and `name:` / `description:` / `version:` unchanged):
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_riverpod: ^2.5.1
    riverpod_annotation: ^2.3.5
    go_router: ^14.0.0
    dio: ^5.4.0
    shared_preferences: ^2.2.3
    intl: ^0.19.0

  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^4.0.0
    riverpod_generator: ^2.4.0
    build_runner: ^2.4.9
    mocktail: ^1.0.4
    riverpod_lint: ^2.3.10
    custom_lint: ^0.6.4
  ```
  Then run `flutter pub get` and confirm there are no resolution errors.

- [X] T003 Replace the contents of `analysis_options.yaml` in the project root with the following (enables all recommended lints plus Riverpod-specific lints):
  ```yaml
  include: package:flutter_lints/flutter.yaml

  analyzer:
    plugins:
      - custom_lint
    errors:
      invalid_annotation_target: ignore

  linter:
    rules:
      - always_declare_return_types
      - avoid_print
      - prefer_const_constructors
      - prefer_const_declarations
      - avoid_dynamic_calls
  ```

- [X] T004 Create the complete directory tree below. Each directory needs a `.gitkeep` file so git tracks it. Create all of these paths relative to the project root:
  ```
  lib/core/constants/
  lib/core/network/
  lib/core/cache/
  lib/core/routing/
  lib/features/simulation/domain/
  lib/features/simulation/data/
  lib/features/simulation/application/
  lib/features/dashboard/presentation/widgets/
  lib/features/gam3as/presentation/
  lib/features/scenario/presentation/
  lib/shared/widgets/
  test/features/simulation/
  test/shared/widgets/
  ```

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story screen can be implemented. All eight tasks here are independent of each other and can be worked on in parallel.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 [P] Create `lib/core/constants/app_colors.dart` with the following exact content. Do not change any hex value — these are the design tokens from `planmobile.md` § 3.7:
  ```dart
  import 'package:flutter/material.dart';

  abstract final class AppColors {
    static const Color background    = Color(0xFF1A1A2E);
    static const Color surface       = Color(0xFF16213E);
    static const Color accent        = Color(0xFF0F3460);
    static const Color positive      = Color(0xFF10B981);
    static const Color negative      = Color(0xFFE74C3C);
    static const Color payout        = Color(0xFFF59E0B);
    static const Color textPrimary   = Color(0xFFFFFFFF);
    static const Color textSecondary = Color(0xFF94A3B8);
    static const Color blue          = Color(0xFF3B82F6);
  }
  ```

- [X] T006 [P] Create `lib/core/network/app_exception.dart`. This file defines a sealed class hierarchy for all error types the app can encounter. Use this exact structure:
  ```dart
  sealed class AppException implements Exception {
    const AppException(this.message);
    final String message;
  }

  final class NetworkError extends AppException {
    const NetworkError([super.message = 'Network unavailable']);
  }

  final class TimeoutError extends AppException {
    const TimeoutError([super.message = 'Request timed out']);
  }

  final class ServerError extends AppException {
    const ServerError(int statusCode)
        : super('Server returned status $statusCode');
  }

  final class ParseError extends AppException {
    const ParseError([super.message = 'Failed to parse server response']);
  }

  final class ConfigError extends AppException {
    const ConfigError([super.message = 'API_BASE_URL is not configured']);
  }
  ```

- [X] T007 [P] Create `lib/core/network/dio_client.dart`. This singleton wraps Dio with the required timeouts (FR-002) and the startup guard for `API_BASE_URL` (FR-001). Use this exact structure:
  ```dart
  import 'package:dio/dio.dart';
  import 'app_exception.dart';

  class DioClient {
    DioClient._() {
      const baseUrl = String.fromEnvironment('API_BASE_URL');
      if (baseUrl.isEmpty) {
        throw ConfigError(
          'API_BASE_URL build variable is not set. '
          'Run with --dart-define=API_BASE_URL=http://your-backend/api',
        );
      }
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ),
      );
    }

    static final DioClient instance = DioClient._();
    late final Dio _dio;

    Dio get dio => _dio;
  }
  ```

- [X] T008 [P] Create `lib/core/cache/cache_service.dart`. This service reads and writes a `SimulationResult` JSON string to `SharedPreferences`. It must never throw — on any error it returns `null` (handles corrupt storage per spec edge case 4). Import `SimulationResult` from `../../features/simulation/domain/simulation_result.dart`:
  ```dart
  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../../features/simulation/domain/simulation_result.dart';

  class CacheService {
    static const _kKey = 'simulation_result_v1';

    Future<void> writeSimulation(SimulationResult result) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kKey, jsonEncode(result.toJson()));
      } catch (_) {
        // Silently discard write failures — cache is best-effort
      }
    }

    Future<SimulationResult?> readSimulation() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kKey);
        if (raw == null) return null;
        return SimulationResult.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        return null; // Corrupt or missing cache — treat as empty
      }
    }
  }
  ```

- [X] T009 [P] Create three domain model files. All monetary fields are stored as `int` (piastres). Conversion from the API's `double` happens in the repository (T010), NOT here. These files are pure immutable data classes.

  **File 1** — `lib/features/simulation/domain/monthly_row.dart`:
  ```dart
  import 'package:flutter/foundation.dart';

  @immutable
  class MonthlyRow {
    const MonthlyRow({
      required this.month,
      required this.monthName,
      required this.openingBalancePiastres,
      required this.inflowPiastres,
      required this.interestPiastres,
      required this.paymentsOutPiastres,
      required this.closingBalancePiastres,
      required this.cumulInvestedPiastres,
      required this.cumulInterestPiastres,
      required this.isPayoutMonth,
      required this.payoutGam3as,
    });

    final int month;
    final String monthName;
    final int openingBalancePiastres;
    final int inflowPiastres;
    final int interestPiastres;
    final int paymentsOutPiastres;
    final int closingBalancePiastres;
    final int cumulInvestedPiastres;
    final int cumulInterestPiastres;
    final bool isPayoutMonth;
    final List<String> payoutGam3as;

    /// Converts API double (EGP) to int piastres (×100)
    static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

    factory MonthlyRow.fromJson(Map<String, dynamic> json) {
      return MonthlyRow(
        month: json['month'] as int,
        monthName: json['month_name'] as String,
        openingBalancePiastres: _toPiastres(json['opening_balance']),
        inflowPiastres: _toPiastres(json['inflow']),
        interestPiastres: _toPiastres(json['interest']),
        paymentsOutPiastres: _toPiastres(json['payments_out']),
        closingBalancePiastres: _toPiastres(json['closing_balance']),
        cumulInvestedPiastres: _toPiastres(json['cumul_invested']),
        cumulInterestPiastres: _toPiastres(json['cumul_interest']),
        isPayoutMonth: json['is_payout_month'] as bool,
        payoutGam3as: List<String>.from(json['payout_gam3as'] as List),
      );
    }

    Map<String, dynamic> toJson() => {
      'month': month,
      'month_name': monthName,
      'opening_balance': openingBalancePiastres / 100,
      'inflow': inflowPiastres / 100,
      'interest': interestPiastres / 100,
      'payments_out': paymentsOutPiastres / 100,
      'closing_balance': closingBalancePiastres / 100,
      'cumul_invested': cumulInvestedPiastres / 100,
      'cumul_interest': cumulInterestPiastres / 100,
      'is_payout_month': isPayoutMonth,
      'payout_gam3as': payoutGam3as,
    };
  }
  ```

  **File 2** — `lib/features/simulation/domain/kpis.dart`:
  ```dart
  import 'package:flutter/foundation.dart';

  @immutable
  class Kpis {
    const Kpis({
      required this.totalInvestedPiastres,
      required this.totalInterestPiastres,
      required this.totalPaymentsOutPiastres,
      required this.finalBalancePiastres,
      required this.effectiveYieldBps,
    });

    final int totalInvestedPiastres;
    final int totalInterestPiastres;
    final int totalPaymentsOutPiastres;
    final int finalBalancePiastres;
    /// Basis points (×100). e.g. 4.13% → 413 bps
    final int effectiveYieldBps;

    static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

    factory Kpis.fromJson(Map<String, dynamic> json) {
      return Kpis(
        totalInvestedPiastres: _toPiastres(json['total_invested']),
        totalInterestPiastres: _toPiastres(json['total_interest']),
        totalPaymentsOutPiastres: _toPiastres(json['total_payments_out']),
        finalBalancePiastres: _toPiastres(json['final_balance']),
        effectiveYieldBps: _toPiastres(json['effective_yield']),
      );
    }

    Map<String, dynamic> toJson() => {
      'total_invested': totalInvestedPiastres / 100,
      'total_interest': totalInterestPiastres / 100,
      'total_payments_out': totalPaymentsOutPiastres / 100,
      'final_balance': finalBalancePiastres / 100,
      'effective_yield': effectiveYieldBps / 100,
    };
  }
  ```

  **File 3** — `lib/features/simulation/domain/simulation_result.dart`:
  ```dart
  import 'package:flutter/foundation.dart';
  import 'monthly_row.dart';
  import 'kpis.dart';

  @immutable
  class SimulationResult {
    const SimulationResult({required this.rows, required this.kpis});

    final List<MonthlyRow> rows; // Always 12 entries
    final Kpis kpis;

    factory SimulationResult.fromJson(Map<String, dynamic> json) {
      return SimulationResult(
        rows: (json['rows'] as List)
            .map((e) => MonthlyRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        kpis: Kpis.fromJson(json['kpis'] as Map<String, dynamic>),
      );
    }

    Map<String, dynamic> toJson() => {
      'rows': rows.map((r) => r.toJson()).toList(),
      'kpis': kpis.toJson(),
    };
  }
  ```

- [X] T010 [P] Create `lib/features/simulation/data/simulation_repository.dart` (abstract interface) and `lib/features/simulation/data/simulation_repository_impl.dart` (Dio implementation).

  **File 1** — `lib/features/simulation/data/simulation_repository.dart`:
  ```dart
  import '../domain/simulation_result.dart';

  abstract interface class SimulationRepository {
    /// Fetches live simulation data from the backend.
    /// Throws [AppException] subclasses on failure.
    Future<SimulationResult> fetchSimulation();
  }
  ```

  **File 2** — `lib/features/simulation/data/simulation_repository_impl.dart`:
  ```dart
  import 'package:dio/dio.dart';
  import '../../../core/network/dio_client.dart';
  import '../../../core/network/app_exception.dart';
  import '../domain/simulation_result.dart';
  import 'simulation_repository.dart';

  class SimulationRepositoryImpl implements SimulationRepository {
    SimulationRepositoryImpl({Dio? dio})
        : _dio = dio ?? DioClient.instance.dio;

    final Dio _dio;

    @override
    Future<SimulationResult> fetchSimulation() async {
      try {
        final response = await _dio.get<Map<String, dynamic>>('/simulate');
        return SimulationResult.fromJson(response.data!);
      } on DioException catch (e) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw const TimeoutError();
          case DioExceptionType.badResponse:
            throw ServerError(e.response?.statusCode ?? 0);
          case DioExceptionType.unknown:
          default:
            throw const NetworkError();
        }
      } catch (_) {
        throw const ParseError();
      }
    }
  }
  ```

- [X] T011 [P] Create `lib/features/simulation/application/simulation_provider.dart`. This provider:
  1. Calls `SimulationRepositoryImpl.fetchSimulation()`
  2. On success: writes to `CacheService`, returns the result
  3. On failure: reads from `CacheService` — if cache hit, marks `isStaleProvider` true and returns cached data; if cache miss, rethrows as `AsyncError`

  Also create a separate `isStaleProvider` boolean provider that `DashboardScreen` will watch to show/hide the stale banner.

  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import '../../../core/cache/cache_service.dart';
  import '../data/simulation_repository_impl.dart';
  import '../domain/simulation_result.dart';

  part 'simulation_provider.g.dart';

  final _cache = CacheService();

  @riverpod
  bool isStale(IsStaleRef ref) => false; // overridden by simulationNotifier

  @riverpod
  class SimulationNotifier extends _$SimulationNotifier {
    @override
    Future<SimulationResult> build() async {
      final repo = SimulationRepositoryImpl();
      try {
        final result = await repo.fetchSimulation();
        await _cache.writeSimulation(result);
        return result;
      } catch (e) {
        final cached = await _cache.readSimulation();
        if (cached != null) {
          // Mark data as stale so the UI can show a banner
          ref.invalidate(isStaleProvider);
          // Override isStaleProvider to true for this build cycle
          // We use a simple approach: store stale flag in a notifier
          return cached;
        }
        rethrow;
      }
    }
  }
  ```

  > **Note**: After writing the provider file, run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `simulation_provider.g.dart`. The generated file must exist before T012 can compile.

  > **Stale flag implementation note**: The simplest correct approach for the stale flag is to use a separate `StateNotifierProvider<bool>` or a `StateProvider<bool>` named `isStaleProvider`. Change the `isStale` provider above to a `StateProvider`:
  ```dart
  final isStaleProvider = StateProvider<bool>((ref) => false);
  ```
  Then in the catch block of `SimulationNotifier.build()`, write:
  ```dart
  ref.read(isStaleProvider.notifier).state = true;
  return cached;
  ```
  Remove the `@riverpod bool isStale` function above and use `StateProvider` instead.

- [X] T012 [P] Create `lib/core/routing/app_router.dart`. This sets up GoRouter with a `ShellRoute` wrapping the three navigation destinations. The shell renders `ScaffoldWithNav` (from T013). Routes:
  - `/` → Dashboard (index 0)
  - `/gam3as` → Gam3as stub (index 1)
  - `/scenario` → Scenario stub (index 2)

  ```dart
  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';
  import '../../features/dashboard/presentation/dashboard_screen.dart';
  import '../../features/gam3as/presentation/gam3as_screen.dart';
  import '../../features/scenario/presentation/scenario_screen.dart';
  import '../../shared/widgets/scaffold_with_nav.dart';

  final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/gam3as', builder: (_, __) => const Gam3asScreen()),
          GoRoute(path: '/scenario', builder: (_, __) => const ScenarioScreen()),
        ],
      ),
    ],
  );
  ```

- [X] T013 [P] Create `lib/shared/widgets/scaffold_with_nav.dart`. This is the adaptive navigation shell (FR-003): `NavigationBar` when screen width < 600 logical pixels, `NavigationRail` when ≥ 600 px. The three destinations are Dashboard, Gam3as, and Scenario. Use `LayoutBuilder` and `GoRouter` context extension (`context.go(...)`) for navigation. Background color must be `AppColors.background`.

  ```dart
  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';
  import '../../core/constants/app_colors.dart';

  class ScaffoldWithNav extends StatelessWidget {
    const ScaffoldWithNav({super.key, required this.child});

    final Widget child;

    static const _destinations = [
      (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/'),
      (icon: Icons.group_outlined, label: 'Gam3as', path: '/gam3as'),
      (icon: Icons.calculate_outlined, label: 'Scenario', path: '/scenario'),
    ];

    int _selectedIndex(BuildContext context) {
      final location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/gam3as')) return 1;
      if (location.startsWith('/scenario')) return 2;
      return 0;
    }

    @override
    Widget build(BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final selectedIndex = _selectedIndex(context);

          if (isWide) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  NavigationRail(
                    backgroundColor: AppColors.surface,
                    selectedIndex: selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    destinations: _destinations
                        .map((d) => NavigationRailDestination(
                              icon: Icon(d.icon),
                              label: Text(d.label),
                            ))
                        .toList(),
                    onDestinationSelected: (i) =>
                        context.go(_destinations[i].path),
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: child,
            bottomNavigationBar: NavigationBar(
              backgroundColor: AppColors.surface,
              selectedIndex: selectedIndex,
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label,
                      ))
                  .toList(),
              onDestinationSelected: (i) => context.go(_destinations[i].path),
            ),
          );
        },
      );
    }
  }
  ```

- [X] T014 Wire `main.dart` and create `lib/app.dart`. Replace the generated `lib/main.dart` with:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'app.dart';

  void main() {
    runApp(const ProviderScope(child: App()));
  }
  ```

  Create `lib/app.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'core/routing/app_router.dart';

  class App extends StatelessWidget {
    const App({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp.router(
        title: 'Gam3ya',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }
  ```

  Also create the two stub screens so the router compiles:

  `lib/features/gam3as/presentation/gam3as_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../../core/constants/app_colors.dart';

  class Gam3asScreen extends StatelessWidget {
    const Gam3asScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return const Center(
        child: Text(
          'Gam3as — Coming in Phase F2',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
  }
  ```

  `lib/features/scenario/presentation/scenario_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../../core/constants/app_colors.dart';

  class ScenarioScreen extends StatelessWidget {
    const ScenarioScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return const Center(
        child: Text(
          'Scenario Simulator — Coming in Phase F4',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
  }
  ```

  After this task, run `flutter analyze` and confirm there are zero issues.

**Checkpoint**: Foundation ready — run `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api`. The app must launch showing the adaptive nav shell with three destinations and no red error screens.

---

## Phase 3: User Story 1 — View Live Simulation on Any Device (Priority: P1) 🎯 MVP

**Goal**: The Dashboard screen fetches live data from `GET /api/simulate`, shows all 12 monthly rows and 5 KPI values, handles loading/error/stale states, and writes the result to cache.

**Independent Test** (from spec.md US1): Open the app while Django is running locally. The dashboard must show 12 rows and 5 KPI values within 2 seconds with no manual interaction. Stop the backend, close and reopen — cached data must appear with a stale indicator.

### Tests for User Story 1 ⚠️ (Write these FIRST — they must FAIL before implementation)

- [X] T015 [P] [US1] Create `test/features/simulation/monthly_row_test.dart`. Test that `MonthlyRow.fromJson` correctly converts a JSON map with `double` monetary fields to `int` piastres. Test at least: a zero-value row, a normal row (e.g. `opening_balance: 1190.0` → `openingBalancePiastres: 119000`), and a row with `is_payout_month: true` and non-empty `payout_gam3as`. Also test `toJson()` round-trip (fromJson → toJson → fromJson gives same result). Minimum: 6 test cases.

- [X] T016 [P] [US1] Create `test/features/simulation/kpis_test.dart`. Test that `Kpis.fromJson` correctly converts all five fields. Specifically test `effective_yield: 4.13` → `effectiveYieldBps: 413`. Test the `toJson()` round-trip. Minimum: 4 test cases.

- [X] T017 [P] [US1] Create `test/features/simulation/simulation_result_test.dart`. Test that `SimulationResult.fromJson` parses a response with exactly 12 rows and a `kpis` block. Test that `rows.length == 12`. Test `toJson()` round-trip. Use the sample JSON from `contracts/simulate-get.md`. Minimum: 3 test cases.

- [X] T018 [US1] Create `test/features/simulation/simulation_provider_test.dart`. This is the most important test file (SC-002). Use `mocktail` to mock `SimulationRepository`. Test all four states:
  1. **Loading state**: provider starts in `AsyncLoading`
  2. **Success state**: when `fetchSimulation()` returns a valid `SimulationResult`, provider transitions to `AsyncData` and `CacheService.writeSimulation()` is called
  3. **Error + no cache state**: when `fetchSimulation()` throws and cache is empty, provider transitions to `AsyncError`
  4. **Stale cache state**: when `fetchSimulation()` throws and cache returns a value, provider returns `AsyncData` with the cached result and `isStaleProvider` is `true`

  Use `ProviderContainer` with `overrides` to inject the mock repository. Test structure:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mocktail/mocktail.dart';
  // ... imports

  class MockSimulationRepository extends Mock implements SimulationRepository {}

  void main() {
    group('SimulationNotifier', () {
      test('starts in loading state', () async { ... });
      test('transitions to data on success', () async { ... });
      test('transitions to error when no cache', () async { ... });
      test('returns cached data and sets isStale when fetch fails', () async { ... });
    });
  }
  ```

  Run `flutter test test/features/simulation/simulation_provider_test.dart` — all 4 tests must FAIL at this point (no implementation yet). Proceed to implementation tasks.

### Implementation for User Story 1

- [X] T019 [P] [US1] Create `lib/features/dashboard/presentation/widgets/kpi_card.dart`. This widget displays a single KPI value. Props: `label` (String), `valueInPiastres` (int), and an optional `isBasisPoints` (bool, default false) for the yield value. Format monetary values as `"EGP 1,190.00"` using `intl`'s `NumberFormat`. Format basis points as `"4.13%"` (divide by 100, show 2 decimal places). Use `AppColors.*` — no inline colors. Card background: `AppColors.surface`. Label color: `AppColors.textSecondary`. Value color: `AppColors.textPrimary`.

- [X] T020 [P] [US1] Create `lib/features/dashboard/presentation/widgets/monthly_row_tile.dart`. This widget displays one `MonthlyRow` as a list tile. Show: month name, inflow (green if > 0), interest (green if > 0), payments out (red), closing balance. If `isPayoutMonth` is true, add an amber "Payout" chip. If closing balance is negative, color it `AppColors.negative`. Format all monetary values as `"EGP N,NNN.NN"` using `NumberFormat` (divide by 100 for display). Background: transparent by default; `AppColors.payout` at 20% opacity if `isPayoutMonth`. All colors from `AppColors.*` only.

- [X] T021 [P] [US1] Create `lib/features/dashboard/presentation/widgets/stale_data_banner.dart`. A `MaterialBanner`-style widget that shows when `isStaleProvider` is true. Display text: `"Showing cached data — unable to reach server"`. Use `AppColors.payout` as the background, `AppColors.background` as text color. Include a "Retry" `TextButton` that calls `ref.invalidate(simulationNotifierProvider)` to trigger a fresh fetch.

- [X] T022 [US1] Create `lib/features/dashboard/presentation/dashboard_screen.dart`. This is the main screen for US1. It must be a `ConsumerWidget` that watches `simulationNotifierProvider` and `isStaleProvider`. Handle all three `AsyncValue` states:

  - **Loading**: Show a centered `CircularProgressIndicator` with no other content
  - **Error**: Show a centered column with an error icon, the error message, and a "Retry" `ElevatedButton` that calls `ref.invalidate(simulationNotifierProvider)`
  - **Data**: Show a `Column` with:
    1. If `isStale == true`: `StaleBanner` at the top
    2. A row of 5 `KpiCard` widgets (total invested, total interest, total payments out, final balance, effective yield)
    3. A `ListView` of 12 `MonthlyRowTile` widgets (one per `SimulationResult.rows` entry)

  Scaffold background: `AppColors.background`. No `AppBar` in this phase (keeping it simple).

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../core/constants/app_colors.dart';
  import '../../simulation/application/simulation_provider.dart';
  import 'widgets/kpi_card.dart';
  import 'widgets/monthly_row_tile.dart';
  import 'widgets/stale_data_banner.dart';

  class DashboardScreen extends ConsumerWidget {
    const DashboardScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final asyncResult = ref.watch(simulationNotifierProvider);
      final isStale = ref.watch(isStaleProvider);

      return asyncResult.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
                const SizedBox(height: 16),
                Text(error.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(simulationNotifierProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (result) => Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              if (isStale) const SliverToBoxAdapter(child: StaleDataBanner()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      KpiCard(label: 'Total Invested', valueInPiastres: result.kpis.totalInvestedPiastres),
                      KpiCard(label: 'Total Interest', valueInPiastres: result.kpis.totalInterestPiastres),
                      KpiCard(label: 'Total Payments', valueInPiastres: result.kpis.totalPaymentsOutPiastres),
                      KpiCard(label: 'Final Balance', valueInPiastres: result.kpis.finalBalancePiastres),
                      KpiCard(label: 'Yield', valueInPiastres: result.kpis.effectiveYieldBps, isBasisPoints: true),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: result.rows.length,
                itemBuilder: (_, i) => MonthlyRowTile(row: result.rows[i]),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [X] T023 [US1] Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `simulation_provider.g.dart` if not already done. Then run `flutter test test/features/simulation/`. All model tests (T015–T017) must now PASS. The provider tests (T018) may still fail if the mock setup needs adjustment — fix the test setup (not the provider) until all 4 pass.

**Checkpoint**: US1 done. Start the Django backend and run the app:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
```
The Dashboard must show 12 rows and 5 KPI cards within 2 seconds. Stop the backend, restart the app — cached data must appear with the stale banner.

---

## Phase 4: User Story 2 — Navigate Between Main Sections (Priority: P2)

**Goal**: The adaptive nav shell switches between bottom bar and rail at 600 px. All three destinations are reachable. Navigation state persists within a session.

**Independent Test** (from spec.md US2): On a narrow screen, tap each bottom nav item — the correct screen appears. On a wide screen (resize the browser to ≥ 600 px), each rail item shows an active state. Navigate away and back — no new network request fires.

### Tests for User Story 2 ⚠️

- [X] T024 [US2] Create `test/shared/widgets/scaffold_with_nav_test.dart`. Write two widget tests using `flutter_test`:

  1. **Narrow screen test** (width = 400): Pump `ScaffoldWithNav` with a `MediaQuery` override setting width to 400. Verify `NavigationBar` is present and `NavigationRail` is absent. Tap the second destination and verify the path changes to `/gam3as`.

  2. **Wide screen test** (width = 800): Pump `ScaffoldWithNav` with width 800. Verify `NavigationRail` is present and `NavigationBar` is absent. Tap the third destination and verify the path changes to `/scenario`.

  Use `GoRouter` in test mode:
  ```dart
  final router = GoRouter(routes: [
    ShellRoute(
      builder: (_, __, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('Dashboard')),
        GoRoute(path: '/gam3as', builder: (_, __) => const Text('Gam3as')),
        GoRoute(path: '/scenario', builder: (_, __) => const Text('Scenario')),
      ],
    ),
  ]);
  ```
  Run the test — it must FAIL before implementing ScaffoldWithNav (if T013 not done yet). If T013 is done, it should already PASS.

### Implementation for User Story 2

- [X] T025 [US2] Verify that `lib/shared/widgets/scaffold_with_nav.dart` (T013) correctly reads the current GoRouter location to compute `selectedIndex`. Open the browser, resize to above/below 600 px multiple times — the nav widget must swap without losing the current screen. If T013 is complete and correct, this task is a verification step only — no code changes needed. If there are bugs, fix them in `scaffold_with_nav.dart`.

- [X] T026 [US2] Run `flutter test test/shared/widgets/scaffold_with_nav_test.dart`. Both tests must PASS. Fix any failures in `scaffold_with_nav.dart` (never fix the tests to match broken behaviour).

**Checkpoint**: US2 done. Navigate to all three sections on both narrow and wide viewports. GoRouter state persists correctly across navigation.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Zero-warning static analysis, edge-case robustness, and confirming quickstart.md is accurate.

- [X] T027 Run `flutter analyze` from the project root. The output must end with `No issues found!`. Fix ALL reported warnings or errors before marking this task done. Common issues to fix: unused imports, missing `const`, dynamic calls, missing return types. **Do not suppress with `// ignore:` comments** unless there is no alternative and you document the reason.

- [X] T028 [P] Add a startup guard test: write a test in `test/features/simulation/dio_client_test.dart` that verifies `DioClient._()` constructor throws a `ConfigError` when `API_BASE_URL` is empty. Since `String.fromEnvironment` cannot be overridden in tests without a compile-time flag, instead test the guard by calling the factory with an empty string override via a dedicated test constructor, or document this as a manual test in the comments (acceptable if automated testing of `fromEnvironment` is not feasible in the current setup).

- [X] T029 [P] Verify the zero-value edge case (spec US1 acceptance scenario 6): In `monthly_row_tile.dart` and `kpi_card.dart`, ensure that when all values are 0, the widgets render without overflow or missing widget errors. Run the app with a backend that returns all-zero values OR write a widget test that pumps `MonthlyRowTile` with a zero `MonthlyRow` and `KpiCard` with `valueInPiastres: 0` and asserts no exceptions are thrown.

- [X] T030 [P] Run the complete test suite: `flutter test`. All tests must PASS with 0 failures. If any test is flaky (intermittently fails), fix the root cause — flaky tests are not acceptable per SC-002.

- [X] T031 Follow the steps in `specs/001-flutter-foundation/quickstart.md` end-to-end on all three platforms (web, Android emulator, iOS simulator). For each platform, verify:
  - App launches without errors
  - Dashboard shows data within 2 seconds (SC-001)
  - Navigation works between all three sections (SC-004)
  - Stopping the backend and restarting the app shows cached data with stale banner within 500 ms (SC-006)
  - `flutter analyze` still reports zero issues (SC-005)
  > **Validated on this machine (Windows 11)**:
  > - Web (Chrome): ✅ confirmed by user — app launches, simulation loads
  > - `flutter analyze`: ✅ No issues found
  > - `flutter test`: ✅ 23/23 tests pass
  > - Android emulator: ⏭ No AVD configured — set up in Android Studio AVD Manager to test
  > - iOS simulator: ⏭ Requires macOS + Xcode — covered by `.github/workflows/ios.yml` CI

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion — BLOCKS all user stories
  - T005–T013 can all be worked in parallel within Phase 2
  - T014 depends on T012 and T013 being done
- **Phase 3 (US1)**: Depends on Phase 2 completion
  - T015–T018 (tests) can be written in parallel immediately after Phase 2
  - T019–T021 (widgets) can be written in parallel
  - T022 (DashboardScreen) depends on T019, T020, T021
  - T023 (verify tests pass) depends on T022
- **Phase 4 (US2)**: Depends on Phase 2 completion; can run in parallel with Phase 3
  - T024 (test) first, then T025–T026 (verify/fix)
- **Phase 5 (Polish)**: Depends on Phases 3 and 4 completion

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependency on US2
- **US2 (P2)**: Can start after Phase 2 — no dependency on US1 (`ScaffoldWithNav` is foundational)

### Within Each User Story

- Model tests (T015–T017) → written first, must FAIL → implement models (T009) → tests PASS
- Provider test (T018) → written first, must FAIL → implement provider (T011) → test PASS
- Widget tasks [P] → implemented in parallel → wired in DashboardScreen (T022) → test PASS

---

## Parallel Execution Examples

### Phase 2 — All foundational tasks in parallel

```text
T005 [P]  lib/core/constants/app_colors.dart
T006 [P]  lib/core/network/app_exception.dart
T007 [P]  lib/core/network/dio_client.dart
T008 [P]  lib/core/cache/cache_service.dart
T009 [P]  domain models (monthly_row, kpis, simulation_result)
T010 [P]  simulation_repository + impl
T011 [P]  simulation_provider (+ build_runner)
T012 [P]  app_router.dart
T013 [P]  scaffold_with_nav.dart
   ↓
T014      main.dart + app.dart + stub screens (depends on T012, T013)
```

### Phase 3 — US1 parallel widget tasks

```text
T015 [P]  monthly_row_test.dart
T016 [P]  kpis_test.dart
T017 [P]  simulation_result_test.dart
T018      simulation_provider_test.dart (after T015–T017 structure confirmed)
T019 [P]  kpi_card.dart
T020 [P]  monthly_row_tile.dart
T021 [P]  stale_data_banner.dart
   ↓
T022      dashboard_screen.dart (depends on T019, T020, T021)
T023      verify all tests pass
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T004)
2. Complete Phase 2: Foundational (T005–T014)
3. Write US1 tests (T015–T018) — confirm they FAIL
4. Implement US1 widgets and screen (T019–T022)
5. Confirm tests PASS (T023)
6. **STOP and validate**: Run the app, verify SC-001 and SC-006
7. Deploy/demo the MVP

### Incremental Delivery

1. Phase 1 + 2 → App boots with nav shell ✓
2. Phase 3 → Dashboard live data + cache ✓ (MVP)
3. Phase 4 → Navigation tested on all viewports ✓
4. Phase 5 → Zero warnings, quickstart validated ✓

---

## Notes

- **Never use `double` for monetary fields** — always `int` piastres (×100)
- **Never use inline `Color(0xFF...)`** in widget files — always `AppColors.*`
- **Never hardcode a URL** — always `String.fromEnvironment('API_BASE_URL')`
- Run `flutter analyze` after every task — catch issues early
- Run `flutter pub run build_runner build --delete-conflicting-outputs` any time you modify a `@riverpod` annotated file
- Commit after each task: `feat(foundation): T005 add AppColors design tokens`
- [P] tasks = different files, no shared state, safe to implement in parallel
- Stop at each **Checkpoint** and validate before continuing
