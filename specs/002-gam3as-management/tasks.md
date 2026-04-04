# Tasks: Gam3as Management

**Input**: Design documents from `/specs/002-gam3as-management/`
**Prerequisites**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · contracts/ ✅ · quickstart.md ✅

**Tests**: Included — required by Constitution V (TDD for financial model logic, provider state tests, widget tests).

**Organization**: Tasks are grouped by user story. Each phase is independently testable.

**Key design decisions** (from research.md — read before starting):
- Mutation pattern: `GamAasNotifier` (AsyncNotifier) → full list reload after every add/update/delete
- Form routing: full-screen GoRoute **outside** the ShellRoute; edit mode via `GoRouter` `extra: Gam3a`
- Cache: `SharedPreferences` key `gam3as_list_v1`, same pattern as F1 `CacheService`
- Validation: built-in `Form` + `TextFormField` validators — no new packages
- Money conversion: JSON `double` (EGP) → `int` piastres (×100) via `.round()` in `Gam3a.fromJson`
- Delete UX: delete icon on card → `showDialog` confirmation → `notifier.delete(id)`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared state)
- **[Story]**: Which user story this task belongs to ([US1]–[US4])
- Exact file paths are included in every task description

## Path Conventions

All Flutter source lives under the project root (same directory as `pubspec.yaml`).

---

## Phase 1: Setup

**Purpose**: Create the directory tree for F2 so every subsequent task has a valid target path.

- [X] T001 Create the following directories (add `.gitkeep` to each so git tracks them). All paths are relative to the project root:
  ```
  lib/features/gam3as/domain/
  lib/features/gam3as/data/
  lib/features/gam3as/application/
  lib/features/gam3as/presentation/widgets/
  test/features/gam3as/
  ```

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain model, repository, provider, and router wiring that MUST exist before any screen can compile.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Create `lib/features/gam3as/domain/gam3a.dart`. This is the immutable domain model. Monetary fields are stored as `int` piastres (×100); conversion happens here in `fromJson` via `.round()`, never in the UI. Use this exact structure:
  ```dart
  import 'package:flutter/foundation.dart';

  @immutable
  class Gam3a {
    const Gam3a({
      required this.id,
      required this.name,
      required this.totalPotPiastres,
      required this.monthlyContributionPiastres,
      required this.payoutMonth,
      required this.startMonth,
      required this.endMonth,
      required this.payoutReceived,
      required this.active,
      required this.createdAt,
    });

    final int id;
    final String name;
    final int totalPotPiastres;
    final int monthlyContributionPiastres;
    final int payoutMonth;
    final int startMonth;
    final int endMonth;
    final bool payoutReceived;
    final bool active;
    final DateTime createdAt;

    static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

    factory Gam3a.fromJson(Map<String, dynamic> json) {
      return Gam3a(
        id: json['id'] as int,
        name: json['name'] as String,
        totalPotPiastres: _toPiastres(json['total_pot']),
        monthlyContributionPiastres: _toPiastres(json['monthly_contribution']),
        payoutMonth: json['payout_month'] as int,
        startMonth: json['start_month'] as int,
        endMonth: json['end_month'] as int,
        payoutReceived: json['payout_received'] as bool,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    }

    /// toJson is used for POST/PUT request bodies — omits id, active, createdAt
    Map<String, dynamic> toJson() => {
      'name': name,
      'total_pot': totalPotPiastres / 100,
      'monthly_contribution': monthlyContributionPiastres / 100,
      'payout_month': payoutMonth,
      'start_month': startMonth,
      'end_month': endMonth,
      'payout_received': payoutReceived,
    };
  }
  ```

- [X] T003 [P] Create `lib/features/gam3as/data/gam3a_repository.dart` (abstract interface):
  ```dart
  import '../domain/gam3a.dart';

  abstract interface class Gam3aRepository {
    Future<List<Gam3a>> fetchAll();
    Future<Gam3a> create(Gam3a gam3a);
    Future<Gam3a> update(Gam3a gam3a);
    Future<void> delete(int id);
  }
  ```

- [X] T004 [P] Create `lib/features/gam3as/data/gam3a_repository_impl.dart`. This is the Dio implementation. It calls `/gam3as` (relative to `DioClient.instance.dio` base URL). On success it parses `Gam3a.fromJson`. On `DioException` it rethrows as the appropriate `AppException` subclass (same switch pattern as `SimulationRepositoryImpl`):
  ```dart
  import 'package:dio/dio.dart';
  import '../../../core/network/app_exception.dart';
  import '../../../core/network/dio_client.dart';
  import '../domain/gam3a.dart';
  import 'gam3a_repository.dart';

  class Gam3aRepositoryImpl implements Gam3aRepository {
    Gam3aRepositoryImpl({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

    final Dio _dio;

    @override
    Future<List<Gam3a>> fetchAll() async {
      try {
        final response = await _dio.get<List<dynamic>>('/gam3as');
        return (response.data!)
            .map((e) => Gam3a.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.payoutMonth.compareTo(b.payoutMonth));
      } on DioException catch (e) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw const TimeoutError();
          case DioExceptionType.badResponse:
            throw ServerError(e.response?.statusCode ?? 0);
          default:
            throw const NetworkError();
        }
      } catch (_) {
        throw const ParseError();
      }
    }

    @override
    Future<Gam3a> create(Gam3a gam3a) async {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/gam3as',
          data: gam3a.toJson(),
        );
        return Gam3a.fromJson(response.data!);
      } on DioException catch (e) {
        throw ServerError(e.response?.statusCode ?? 0);
      } catch (_) {
        throw const ParseError();
      }
    }

    @override
    Future<Gam3a> update(Gam3a gam3a) async {
      try {
        final response = await _dio.put<Map<String, dynamic>>(
          '/gam3as/${gam3a.id}',
          data: gam3a.toJson(),
        );
        return Gam3a.fromJson(response.data!);
      } on DioException catch (e) {
        throw ServerError(e.response?.statusCode ?? 0);
      } catch (_) {
        throw const ParseError();
      }
    }

    @override
    Future<void> delete(int id) async {
      try {
        await _dio.delete<Map<String, dynamic>>('/gam3as/$id');
      } on DioException catch (e) {
        throw ServerError(e.response?.statusCode ?? 0);
      } catch (_) {
        throw const NetworkError();
      }
    }
  }
  ```

- [X] T005 [P] Create `lib/features/gam3as/application/gam3as_provider.dart`. This provider:
  1. Fetches the full list via `GamAaRepositoryImpl.fetchAll()`
  2. On success: writes to SharedPreferences under `gam3as_list_v1`, returns list sorted by `payoutMonth`
  3. On failure: reads from cache — if cache hit marks `isGam3asStaleProvider = true`; if miss rethrows
  4. Mutation methods (`add`, `update`, `delete`) set loading → call repo → reload list → write cache → invalidate `simulationNotifierProvider`

  ```dart
  import 'dart:convert';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../../simulation/application/simulation_provider.dart';
  import '../data/gam3a_repository_impl.dart';
  import '../domain/gam3a.dart';

  part 'gam3as_provider.g.dart';

  const _kCacheKey = 'gam3as_list_v1';

  final StateProvider<bool> isGam3asStaleProvider =
      StateProvider<bool>((ref) => false);

  @riverpod
  class GamAasNotifier extends _$GamAasNotifier {
    late final GamAaRepositoryImpl _repo;

    @override
    Future<List<Gam3a>> build() async {
      _repo = GamAaRepositoryImpl();
      ref.read(isGam3asStaleProvider.notifier).state = false;
      try {
        final list = await _repo.fetchAll();
        await _writeCache(list);
        return list;
      } catch (_) {
        final cached = await _readCache();
        if (cached != null) {
          ref.read(isGam3asStaleProvider.notifier).state = true;
          return cached;
        }
        rethrow;
      }
    }

    Future<void> add(Gam3a gam3a) async {
      state = const AsyncLoading();
      try {
        await _repo.create(gam3a);
        final fresh = await _repo.fetchAll();
        await _writeCache(fresh);
        state = AsyncData(fresh);
        ref.invalidate(simulationNotifierProvider);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    }

    Future<void> update(Gam3a gam3a) async {
      state = const AsyncLoading();
      try {
        await _repo.update(gam3a);
        final fresh = await _repo.fetchAll();
        await _writeCache(fresh);
        state = AsyncData(fresh);
        ref.invalidate(simulationNotifierProvider);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    }

    Future<void> delete(int id) async {
      state = const AsyncLoading();
      try {
        await _repo.delete(id);
        final fresh = await _repo.fetchAll();
        await _writeCache(fresh);
        state = AsyncData(fresh);
        ref.invalidate(simulationNotifierProvider);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    }

    Future<void> _writeCache(List<Gam3a> list) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _kCacheKey,
          jsonEncode(list.map((g) => _fullJson(g)).toList()),
        );
      } catch (_) {}
    }

    Future<List<Gam3a>?> _readCache() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kCacheKey);
        if (raw == null) return null;
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => Gam3a.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return null;
      }
    }

    /// Full JSON including id, active, created_at — used only for cache read/write
    Map<String, dynamic> _fullJson(Gam3a g) => {
      'id': g.id,
      ...g.toJson(),
      'active': g.active,
      'created_at': g.createdAt.toIso8601String(),
    };
  }
  ```

  After writing this file, run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `gam3as_provider.g.dart`.

- [X] T006 Run `flutter pub run build_runner build --delete-conflicting-outputs` from the project root. Confirm `lib/features/gam3as/application/gam3as_provider.g.dart` is created with no errors. This file must exist before T007 and any screen can compile.

- [X] T007 Update `lib/core/routing/app_router.dart` to add two full-screen routes **outside** the `ShellRoute` (so they have no bottom nav bar). Import `Gam3aFormScreen` from `../../features/gam3as/presentation/gam3a_form_screen.dart`. The `Gam3a` extra is nullable — `null` means add mode, non-null means edit mode:
  ```dart
  // Add these two GoRoute entries as siblings of the ShellRoute (not inside it):
  GoRoute(
    path: '/gam3as/new',
    builder: (context, state) => const Gam3aFormScreen(existing: null),
  ),
  GoRoute(
    path: '/gam3as/edit',
    builder: (context, state) =>
        Gam3aFormScreen(existing: state.extra as Gam3a?),
  ),
  ```
  Create a stub `Gam3aFormScreen` (just a `Scaffold` with a centered "Form Coming Soon" text) in `lib/features/gam3as/presentation/gam3a_form_screen.dart` so the router compiles:
  ```dart
  import 'package:flutter/material.dart';
  import '../domain/gam3a.dart';
  import '../../../core/constants/app_colors.dart';

  class Gam3aFormScreen extends StatelessWidget {
    const Gam3aFormScreen({super.key, required this.existing});
    final Gam3a? existing;

    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Form — Coming Soon', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
  }
  ```
  Run `flutter analyze` — zero issues required before proceeding.

**Checkpoint**: Foundation ready — run `flutter analyze`. Zero issues. All files compile.

---

## Phase 3: User Story 1 — View All Gam3as (Priority: P1) 🎯 MVP

**Goal**: The Gam3as tab shows a live-fetched list of all gam3as (or empty state), with loading/error/stale states handled.

**Independent Test**: Open the app → tap Gam3as tab → 4 seed gam3as appear within 2 seconds. Stop backend → reopen app → cached list + stale banner.

### Tests for User Story 1 ⚠️ (Write FIRST — must FAIL before implementation)

- [X] T008 [P] [US1] Create `test/features/gam3as/gam3a_test.dart`. Test `Gam3a.fromJson` and `toJson` round-trips. Required test cases (minimum 6):
  1. Converts `total_pot: 80000.0` → `totalPotPiastres: 8000000`
  2. Converts `monthly_contribution: 10000.0` → `monthlyContributionPiastres: 1000000`
  3. Parses all required fields correctly (name, months, booleans, createdAt)
  4. `payoutReceived: true` round-trips correctly
  5. `toJson` emits `total_pot` as double (piastres ÷ 100) and omits `id`, `active`, `created_at`
  6. `fromJson → toJson → fromJson` gives an equivalent `Gam3a` (round-trip equivalence)

  Use this sample JSON (from `contracts/gam3as-get.md`):
  ```dart
  final sampleJson = {
    'id': 3,
    'name': 'Family Gam3a',
    'total_pot': 80000.0,
    'monthly_contribution': 10000.0,
    'payout_month': 5,
    'start_month': 3,
    'end_month': 8,
    'payout_received': false,
    'active': true,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
  ```

- [X] T009 [P] [US1] Create `test/features/gam3as/gam3as_provider_test.dart`. Use `mocktail` to mock `GamAaRepository`. Test 4 states for `GamAasNotifier`:
  1. **Loading**: provider starts as `AsyncLoading`
  2. **Success**: `fetchAll()` returns list → provider transitions to `AsyncData` with sorted list
  3. **Error + no cache**: `fetchAll()` throws and cache empty → provider transitions to `AsyncError`
  4. **Stale cache**: `fetchAll()` throws but cache has data → provider returns `AsyncData` + `isGam3asStaleProvider == true`

  ```dart
  class MockGam3aRepository extends Mock implements Gam3aRepository {}
  ```
  Use `ProviderContainer` with `overrides` to inject the mock. Run `flutter test test/features/gam3as/gam3a_test.dart` — expect failures (no implementation yet).

### Implementation for User Story 1

- [X] T010 [P] [US1] Create `lib/features/gam3as/presentation/widgets/empty_gam3as_view.dart`. A centered `Column` with an icon, message text `"No Gam3as yet"`, and an `ElevatedButton` labelled `"Add your first Gam3a"` that calls `context.push('/gam3as/new')`. All colors from `AppColors.*`.

- [X] T011 [P] [US1] Create `lib/features/gam3as/presentation/widgets/gam3a_card.dart`. Display-only card for now (edit/delete added in US3/US4). Shows:
  - **Name** (bold, `AppColors.textPrimary`)
  - **Total pot** formatted as `"EGP N,NNN.00"` using `intl` `NumberFormat` (divide piastres by 100)
  - **Monthly contribution** formatted as `"EGP N,NNN.00"`
  - **Payout month** as month name (use `DateFormat('MMMM').format(DateTime(2026, payoutMonth))`)
  - **Range**: `"Month startMonth – endMonth"` (e.g., `"Month 3 – 8"`)
  - **"Received" badge** (amber chip) if `payoutReceived == true`

  Card background: `AppColors.surface`. Rounded corners (8 px). Margin: 8 px horizontal + 4 px vertical. All colors from `AppColors.*`.

- [X] T012 [US1] Replace the stub content in `lib/features/gam3as/presentation/gam3as_screen.dart` with the full list screen. This `ConsumerWidget` watches `gamAasNotifierProvider` and `isGam3asStaleProvider`. Handle all `AsyncValue` states:
  - **Loading**: centered `CircularProgressIndicator`
  - **Error**: centered column with error icon, message text, "Retry" `ElevatedButton` calling `ref.invalidate(gamAasNotifierProvider)`
  - **Data (empty list)**: `EmptyGam3asView()`
  - **Data (non-empty)**: `ListView.builder` of `Gam3aCard` widgets, preceded by `StaleDataBanner`-style banner if `isGam3asStale == true`

  Include a `FloatingActionButton` with `Icons.add` that calls `context.push('/gam3as/new')`.

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/constants/app_colors.dart';
  import '../application/gam3as_provider.dart';
  import 'widgets/gam3a_card.dart';
  import 'widgets/empty_gam3as_view.dart';

  class Gam3asScreen extends ConsumerWidget {
    const Gam3asScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final async = ref.watch(gamAasNotifierProvider);
      final isStale = ref.watch(isGam3asStaleProvider);

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/gam3as/new'),
          child: const Icon(Icons.add),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
                const SizedBox(height: 16),
                Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(gamAasNotifierProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (list) {
            if (list.isEmpty) return const EmptyGam3asView();
            return Column(
              children: [
                if (isStale)
                  MaterialBanner(
                    backgroundColor: AppColors.payout,
                    content: const Text('Showing cached data — unable to reach server',
                        style: TextStyle(color: AppColors.background)),
                    actions: [
                      TextButton(
                        onPressed: () => ref.invalidate(gamAasNotifierProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => Gam3aCard(gam3a: list[i]),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }
  ```

- [X] T013 [US1] Run `flutter test test/features/gam3as/gam3a_test.dart` and `flutter test test/features/gam3as/gam3as_provider_test.dart`. The model tests (T008) must PASS. Fix the provider test setup (T009) if needed — all 4 provider state tests must PASS. Then run `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api` and verify the Gam3as tab shows the list.

**Checkpoint**: US1 done. Gam3as list is live and shows empty state, error, and stale cache correctly.

---

## Phase 4: User Story 2 — Add a New Gam3a (Priority: P1)

**Goal**: The "+" FAB opens a validated form; submitting creates a new gam3a and refreshes the list and Dashboard.

**Independent Test**: Tap "+", fill all 6 fields, tap Save — gam3a appears in the list; navigate to Dashboard — simulation totals updated.

### Tests for User Story 2 ⚠️

- [X] T014 [US2] Add mutation test cases to `test/features/gam3as/gam3as_provider_test.dart`:
  5. **add() success**: mock `create()` returns a new `Gam3a`; after `notifier.add()`, provider state is `AsyncData` with the updated list
  6. **add() network error**: mock `create()` throws `NetworkError`; after `notifier.add()`, provider state is `AsyncError`

  Run — these tests must FAIL before T015 is implemented.

### Implementation for User Story 2

- [X] T015 [US2] Replace the stub body of `lib/features/gam3as/presentation/gam3a_form_screen.dart` with a full `StatefulWidget` form. This screen handles both add mode (`existing == null`) and edit mode (`existing != null` — pre-populates fields). For this task, implement add mode only:

  - `AppBar` title: `"Add Gam3a"` (add mode) or `"Edit Gam3a"` (edit mode — leave for T018)
  - `Form` with a `GlobalKey<FormState>` and these `TextFormField` inputs:
    - **Name** (text, required, max 100 chars)
    - **Total pot (EGP)** (decimal number, required, > 0)
    - **Monthly contribution (EGP)** (decimal number, required, > 0)
    - **Payout month** (integer 1–12, required)
    - **Start month** (integer 1–12, required)
    - **End month** (integer 1–12, required; cross-field validator: start ≤ end)
  - `SwitchListTile` for **Payout received** (bool, defaults to false)
  - **Save** `ElevatedButton`:
    1. Calls `_formKey.currentState!.validate()` — if false, stops
    2. Sets a local `bool _saving = true` to disable the button (prevents double-submit)
    3. Builds a `Gam3a` with dummy `id: 0`, `active: true`, `createdAt: DateTime.now()`; monetary fields converted from typed EGP to piastres (×100 rounded)
    4. Calls `await ref.read(gamAasNotifierProvider.notifier).add(gam3a)`
    5. On success: `context.pop()`
    6. On error: shows a `SnackBar` with the error message; re-enables Save button

  Background color: `AppColors.background`. Input decoration: `AppColors.blue` border focus color. All colors from `AppColors.*`.

- [X] T016 [US2] Verify the full add flow:
  1. Run `flutter analyze` — zero issues
  2. In the app: tap "+" FAB on Gam3as screen → form opens full-screen (no bottom nav bar)
  3. Try submitting an empty form — validation errors appear inline
  4. Fill all fields → Save → new gam3a appears in the list
  5. Navigate to Dashboard — simulation KPIs reflect the new gam3a
  6. Run all tests: `flutter test` — all pass

**Checkpoint**: US2 done. Users can add gam3as; the Dashboard auto-refreshes.

---

## Phase 5: User Story 3 — Edit an Existing Gam3a (Priority: P2)

**Goal**: Tapping the edit icon on a card opens the form pre-populated with current values; saving updates the record and refreshes data.

**Independent Test**: Edit gam3a #3 — change payout month from 5 to 6 — Save — card shows month 6 and Dashboard updates.

### Tests for User Story 3 ⚠️

- [X] T017 [P] [US3] Add mutation test cases to `test/features/gam3as/gam3as_provider_test.dart`:
  7. **update() success**: mock `update()` returns updated `Gam3a`; after `notifier.update()`, provider state is `AsyncData` with updated list
  8. **update() network error**: mock `update()` throws `ServerError(404)`; provider state becomes `AsyncError`

### Implementation for User Story 3

- [X] T018 [US3] Extend `lib/features/gam3as/presentation/gam3a_form_screen.dart` to support edit mode. In `initState`, if `widget.existing != null`, initialize all `TextEditingController`s with current values (convert piastres to EGP string: `(piastres / 100).toStringAsFixed(2)`). Change the Save button to call `notifier.update(gam3a)` (with the original `id`, `active`, `createdAt`) instead of `notifier.add()` when in edit mode. Change `AppBar` title to `"Edit Gam3a"` for edit mode.

- [X] T019 [US3] Add an edit icon button to `lib/features/gam3as/presentation/widgets/gam3a_card.dart`. Tapping it calls `context.push('/gam3as/edit', extra: gam3a)`. Place the icon in the card's `trailing` or in a row of action buttons at the card bottom. Icon: `Icons.edit_outlined`, color: `AppColors.blue`.

**Checkpoint**: US3 done. Edit pre-populates form, saves correctly, and refreshes data.

---

## Phase 6: User Story 4 — Delete a Gam3a (Priority: P2)

**Goal**: Tapping the delete icon shows a confirmation dialog; confirming removes the gam3a and refreshes the Dashboard.

**Independent Test**: Delete gam3a #1 — confirm — it disappears from the list — Dashboard simulation excludes it.

### Tests for User Story 4 ⚠️

- [X] T020 [P] [US4] Add mutation test cases to `test/features/gam3as/gam3as_provider_test.dart`:
  9. **delete() success**: mock `delete()` completes; after `notifier.delete(id)`, provider state is `AsyncData` with the item removed
  10. **delete() server error**: mock `delete()` throws `ServerError(500)`; provider state becomes `AsyncError`

### Implementation for User Story 4

- [X] T021 [US4] Add a delete icon button to `lib/features/gam3as/presentation/widgets/gam3a_card.dart` (alongside the edit icon from T019). On tap, show a `showDialog` with:
  - Title: `"Delete Gam3a?"`
  - Content: `"Remove "${gam3a.name}"? This cannot be undone."`
  - Actions: `TextButton("Cancel")` (pops dialog) and `ElevatedButton("Delete", style: red)` (calls `notifier.delete(gam3a.id)` then pops dialog on success; shows `SnackBar` on error)

  Icon: `Icons.delete_outline`, color: `AppColors.negative`.

- [X] T022 [US4] Verify the full delete flow:
  1. In the app: tap delete on any card → confirmation dialog appears
  2. Tap **Cancel** — dialog dismisses, card remains
  3. Tap delete again → **Delete** — card disappears, Dashboard refreshes
  4. Run `flutter test` — all 10 provider tests pass

**Checkpoint**: All 4 user stories complete. Full CRUD is functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T023 [P] Create `test/features/gam3as/gam3a_card_test.dart`. Write widget tests using `flutter_test`:
  1. **Normal card**: pump `Gam3aCard` with a seed gam3a — verify name, formatted pot, contribution, month name are visible
  2. **Payout badge**: pump with `payoutReceived: true` — verify "Received" chip/badge is present
  3. **Edit icon present**: verify `Icons.edit_outlined` is found
  4. **Delete icon present**: verify `Icons.delete_outline` is found
  5. **Zero monetary values**: pump with `totalPotPiastres: 0`, `monthlyContributionPiastres: 0` — no RenderFlex overflow or exceptions

- [X] T024 [P] Run `flutter analyze` from the project root. Output must end with `No issues found!`. Fix ALL warnings or errors before marking done. Do not use `// ignore:` comments unless no alternative exists.

- [X] T025 Run `flutter test` from the project root. All tests (original 23 from F1 + new F2 tests) must pass with 0 failures. Fix any failures in implementation code (never weaken tests).

- [ ] T026 Follow all 6 integration scenarios in `specs/002-gam3as-management/quickstart.md`:
  - SC-001: list loads within 2 s
  - SC-003: Dashboard updates within 1 s after add/edit/delete
  - Empty state scenario
  - Edit with pre-population scenario
  - Delete with cancel and confirm
  - Offline / stale cache scenario

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user stories
  - T002–T005 can all be worked in parallel within Phase 2
  - T006 (build_runner) depends on T005
  - T007 (router update) depends on T002 (Gam3aFormScreen stub imports Gam3a)
- **Phase 3 (US1)**: Depends on Phase 2 completion
  - T008, T009 (tests) and T010, T011 (widgets) can all be worked in parallel
  - T012 (screen) depends on T010 and T011
  - T013 (verify) depends on T012
- **Phase 4 (US2)**: Depends on Phase 3 completion (reuses GamAasNotifier from Phase 2)
  - T014 (test) can be written in parallel with T015 (form)
  - T016 (verify) depends on T015
- **Phase 5 (US3)**: Depends on Phase 4 (form screen already exists)
  - T017 (test) and T018 (form extension) can be worked in parallel
  - T019 (edit icon) depends on T018
- **Phase 6 (US4)**: Depends on Phase 3 (card widget) and Phase 2 (provider delete method)
  - T020 (test) and T021 (delete icon) can be worked in parallel
- **Phase 7 (Polish)**: Depends on Phases 3–6 completion

### Parallel Execution Examples

```text
Phase 2 — all foundational tasks in parallel:
T002 [P]  lib/features/gam3as/domain/gam3a.dart
T003 [P]  lib/features/gam3as/data/gam3a_repository.dart
T004 [P]  lib/features/gam3as/data/gam3a_repository_impl.dart
T005 [P]  lib/features/gam3as/application/gam3as_provider.dart
   ↓
T006      build_runner (depends on T005)
T007      app_router.dart (depends on T002 for Gam3a import)

Phase 3 — US1 parallel:
T008 [P]  test/features/gam3as/gam3a_test.dart
T009 [P]  test/features/gam3as/gam3as_provider_test.dart
T010 [P]  presentation/widgets/empty_gam3as_view.dart
T011 [P]  presentation/widgets/gam3a_card.dart
   ↓
T012      presentation/gam3as_screen.dart (depends on T010, T011)
T013      verify tests pass (depends on T012)
```

---

## Implementation Strategy

### MVP First (US1 + US2 — P1 stories only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T007)
3. Write US1 tests (T008–T009) — confirm they FAIL
4. Implement US1 (T010–T012) — confirm tests PASS (T013)
5. Write US2 test (T014) — confirm it FAILS
6. Implement US2 (T015–T016) — confirm test PASSES
7. **STOP and validate**: Run app, add a gam3a, verify Dashboard refreshes
8. Demo MVP

### Incremental Delivery

1. Phase 1 + 2 → Foundation compiles, router ready ✓
2. Phase 3 → Gam3as list live ✓ (MVP read)
3. Phase 4 → Add gam3as ✓ (MVP write)
4. Phase 5 → Edit gam3as ✓
5. Phase 6 → Delete gam3as ✓
6. Phase 7 → Zero warnings, all tests green ✓

---

## Notes

- **Never use `double` for monetary fields** — always `int` piastres (×100)
- **Never use inline `Color(0xFF...)`** — always `AppColors.*`
- **Never hardcode a URL** — always `DioClient.instance.dio` (base URL from `--dart-define`)
- Run `flutter analyze` after every task — catch issues early
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after any `@riverpod` change
- Commit after each task: `feat(gam3as): T010 add empty state widget`
- [P] tasks = different files, no shared state, safe to implement in parallel
- Stop at each **Checkpoint** and validate before continuing
