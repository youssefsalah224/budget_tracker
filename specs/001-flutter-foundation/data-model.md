# Data Model: Flutter Foundation & Navigation

**Phase**: 1 (design) | **Date**: 2026-04-03 | **Branch**: `001-flutter-foundation`

---

## Overview

All monetary fields are stored as **integers (piastres, ×100)** in the Flutter domain layer
per Constitution Principle IV. Conversion from the B1 API's `double` payload occurs at the
`SimulationRepository` boundary. Display formatting uses `intl.NumberFormat`.

---

## Entity: SimulationResult

**File**: `lib/features/simulation/domain/simulation_result.dart`

```dart
@immutable
class SimulationResult {
  const SimulationResult({
    required this.rows,
    required this.kpis,
  });

  final List<MonthlyRow> rows;   // Always 12 entries
  final Kpis kpis;

  factory SimulationResult.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

| Field | Dart Type | Source JSON key | Notes |
|-------|-----------|-----------------|-------|
| `rows` | `List<MonthlyRow>` | `rows` | Exactly 12 entries |
| `kpis` | `Kpis` | `kpis` | Year-end aggregates |

**Validation rules**:
- `rows.length == 12` (assert in debug mode; surface as `ParseError` in release)
- `rows` and `kpis` must be non-null

**State transitions**: None (immutable value object)

---

## Entity: MonthlyRow

**File**: `lib/features/simulation/domain/monthly_row.dart`

```dart
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

  final int month;                    // 1–12
  final String monthName;             // "January" … "December"
  final int openingBalancePiastres;   // API double × 100, rounded
  final int inflowPiastres;
  final int interestPiastres;
  final int paymentsOutPiastres;
  final int closingBalancePiastres;
  final int cumulInvestedPiastres;
  final int cumulInterestPiastres;
  final bool isPayoutMonth;
  final List<String> payoutGam3as;    // Names of gam3as paying out this month

  factory MonthlyRow.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

| Field | Dart Type | Source JSON key | Conversion |
|-------|-----------|-----------------|------------|
| `month` | `int` | `month` | Direct |
| `monthName` | `String` | `month_name` | Direct |
| `openingBalancePiastres` | `int` | `opening_balance` | `(v * 100).round()` |
| `inflowPiastres` | `int` | `inflow` | `(v * 100).round()` |
| `interestPiastres` | `int` | `interest` | `(v * 100).round()` |
| `paymentsOutPiastres` | `int` | `payments_out` | `(v * 100).round()` |
| `closingBalancePiastres` | `int` | `closing_balance` | `(v * 100).round()` |
| `cumulInvestedPiastres` | `int` | `cumul_invested` | `(v * 100).round()` |
| `cumulInterestPiastres` | `int` | `cumul_interest` | `(v * 100).round()` |
| `isPayoutMonth` | `bool` | `is_payout_month` | Direct |
| `payoutGam3as` | `List<String>` | `payout_gam3as` | Direct |

**Validation rules**:
- `month` in 1..12
- `monthName` non-empty
- All monetary int fields ≥ 0 (piastres cannot be negative for balance fields; `paymentsOut` represents magnitude)

---

## Entity: Kpis

**File**: `lib/features/simulation/domain/kpis.dart`

```dart
@immutable
class Kpis {
  const Kpis({
    required this.totalInvestedPiastres,
    required this.totalInterestPiastres,
    required this.totalPaymentsOutPiastres,
    required this.finalBalancePiastres,
    required this.effectiveYieldBps,
  });

  final int totalInvestedPiastres;     // API double × 100
  final int totalInterestPiastres;
  final int totalPaymentsOutPiastres;
  final int finalBalancePiastres;
  final int effectiveYieldBps;         // basis points: API double × 100 (4.13% → 413 bps)

  factory Kpis.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

| Field | Dart Type | Source JSON key | Conversion |
|-------|-----------|-----------------|------------|
| `totalInvestedPiastres` | `int` | `total_invested` | `(v * 100).round()` |
| `totalInterestPiastres` | `int` | `total_interest` | `(v * 100).round()` |
| `totalPaymentsOutPiastres` | `int` | `total_payments_out` | `(v * 100).round()` |
| `finalBalancePiastres` | `int` | `final_balance` | `(v * 100).round()` |
| `effectiveYieldBps` | `int` | `effective_yield` | `(v * 100).round()` |

---

## Entity: AppColors (Design Tokens)

**File**: `lib/core/constants/app_colors.dart`

```dart
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

All widget code must reference these tokens; no inline `Color(0xFF...)` literals in widget files.

---

## Service: CacheService

**File**: `lib/core/cache/cache_service.dart`

```dart
class CacheService {
  static const _kSimulationKey = 'simulation_result_v1';

  Future<void> writeSimulation(SimulationResult result) async { ... }

  /// Returns null if no cached value exists or if storage is corrupt.
  Future<SimulationResult?> readSimulation() async { ... }
}
```

| Operation | Storage key | Serialisation |
|-----------|------------|---------------|
| `writeSimulation` | `simulation_result_v1` | `json.encode(result.toJson())` via `SharedPreferences.setString` |
| `readSimulation` | `simulation_result_v1` | `SharedPreferences.getString` → `json.decode` → `SimulationResult.fromJson`; on any exception returns `null` |

**Error handling**: All `SharedPreferences` and `json` exceptions are caught; `readSimulation`
returns `null` (cache miss) instead of propagating (edge case 4 in spec).

---

## Provider: SimulationProvider

**File**: `lib/features/simulation/application/simulation_provider.dart`

```dart
@riverpod
class SimulationNotifier extends _$SimulationNotifier {
  @override
  Future<SimulationResult> build() async { ... }

  // Exposes: AsyncValue<SimulationResult> — loading / data / error
  // On success: writes to CacheService before returning
  // On error: reads CacheService; if hit, returns cached value with isStale=true flag
}
```

**State**:

| State | Condition |
|-------|-----------|
| `AsyncLoading` | Initial fetch in-flight |
| `AsyncData(result)` | Successful live fetch |
| `AsyncError(e, st)` | Network/parse error AND no cache |
| `AsyncData(cachedResult)` + `isStale = true` | Network/parse error WITH cache hit |

> `isStale` is a separate `bool` provider family that `SimulationNotifier` sets via a
> `StateProvider<bool>` flag so `DashboardScreen` can show/hide `StaleBanner` without
> coupling to `AsyncError`.

---

## Constitution Check (Post-Design)

| # | Principle | Status |
|---|-----------|--------|
| I | Cross-Platform First | ✅ All model classes are pure Dart; no platform imports |
| II | API-Driven Architecture | ✅ Domain models map 1-to-1 with `GET /api/simulate` contract |
| III | Feature-Module Structure | ✅ Domain lives in `features/simulation/domain/`; no cross-feature imports |
| IV | Financial Accuracy | ✅ All monetary fields are `int` (piastres); conversion happens at repository boundary only |
| V | Test Coverage | ✅ `fromJson`/`toJson` round-trip tests for all three models; repository mock tests planned |
