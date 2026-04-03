# Implementation Plan: Flutter Foundation & Navigation

**Branch**: `001-flutter-foundation` | **Date**: 2026-04-03 | **Spec**: `specs/001-flutter-foundation/spec.md`
**Input**: Feature specification from `/specs/001-flutter-foundation/spec.md`

---

## Summary

Establish the Flutter client foundation for the Gam3ya Investment Simulator: set up the
project scaffold (Riverpod, GoRouter, Dio, SharedPreferences), implement an adaptive
navigation shell (bottom bar ↔ rail at 600 px breakpoint), wire `SimulationProvider`
against `GET /api/simulate`, and ship `CacheService` so every subsequent phase has
read/write access to a locally-cached `SimulationResult`.

---

## Technical Context

**Language/Version**: Dart 3.x
**Primary Dependencies**: flutter_riverpod · riverpod_annotation · go_router ^14 · dio ^5.4 · shared_preferences
**Storage**: SharedPreferences (device-local; web/iOS/Android compatible)
**Testing**: flutter_test · mocktail (provider unit tests + widget tests)
**Target Platform**: Web · Android · iOS (single Dart codebase)
**Project Type**: Mobile app (cross-platform)
**Performance Goals**: Dashboard renders live data within 2 s on all three platforms; cached fallback renders within 500 ms
**Constraints**: Offline-capable (cache fallback), 10 s connection timeout / 30 s receive timeout, zero static-analysis warnings
**Scale/Scope**: 3 navigation destinations (1 live screen + 2 stubs), 1 data provider, 1 cache service

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Evidence |
|---|-----------|--------|----------|
| I | Cross-Platform First | ✅ PASS | Single Dart codebase; all chosen packages (go_router, flutter_riverpod, dio, shared_preferences) explicitly support web, iOS, and Android. No platform forks. |
| II | API-Driven Architecture | ✅ PASS | All data flows through `GET /api/simulate`. Repository layer (`SimulationRepository`) abstracts HTTP from providers and widgets. Contract documented in `contracts/simulate-get.md`. |
| III | Feature-Module Structure | ✅ PASS | Dashboard → `lib/features/dashboard/`, simulation logic → `lib/features/simulation/`, cache/http/theme → `lib/core/`. No cross-feature internal imports. |
| IV | Financial Accuracy | ⚠️ VIOLATION (justified — see Complexity Tracking) | Existing B1 API payload transmits monetary fields as JSON `number` (float). Flutter client MUST NOT persist or compute with `double`; conversion to integer (piastres × 100) applied at the repository boundary. Remediation targeted at Phase B2. |
| V | Test Coverage | ✅ PASS | Provider tests cover loading / success / error / cached-fallback states. Widget test covers Dashboard happy path. All written before implementation (TDD for provider). |

**Gate result**: PROCEED (one justified violation, tracked below)

---

## Project Structure

### Documentation (this feature)

```text
specs/001-flutter-foundation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── simulate-get.md  # GET /api/simulate contract
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── main.dart                        # App entry point, ProviderScope root
├── app.dart                         # MaterialApp.router + GoRouter config
├── core/
│   ├── constants/
│   │   └── app_colors.dart          # AppColors design tokens (no inline hex in widgets)
│   ├── network/
│   │   ├── dio_client.dart          # Dio singleton: baseUrl, timeouts, interceptors
│   │   └── app_exception.dart       # Typed error hierarchy (NetworkError, ParseError, …)
│   ├── cache/
│   │   └── cache_service.dart       # SharedPreferences read/write for SimulationResult JSON
│   └── routing/
│       └── app_router.dart          # GoRouter shell route + 3 destinations
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── kpi_card.dart
│   │   │   │   ├── monthly_row_tile.dart
│   │   │   │   └── stale_data_banner.dart
│   │   └── application/
│   │       └── (no screen-specific providers in F1; uses simulation_provider directly)
│   ├── simulation/
│   │   ├── data/
│   │   │   ├── simulation_repository.dart   # Dio call → SimulationResult
│   │   │   └── simulation_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── simulation_result.dart       # Immutable data class
│   │   │   ├── monthly_row.dart
│   │   │   └── kpis.dart
│   │   └── application/
│   │       └── simulation_provider.dart     # AsyncNotifierProvider
│   ├── gam3as/
│   │   └── presentation/
│   │       └── gam3as_screen.dart           # Stub screen (Phase F2)
│   └── scenario/
│       └── presentation/
│           └── scenario_screen.dart          # Stub screen (Phase F4)
└── shared/
    └── widgets/
        └── scaffold_with_nav.dart            # Adaptive nav shell (bottom bar ↔ rail)

test/
├── features/
│   └── simulation/
│       ├── simulation_repository_test.dart
│       └── simulation_provider_test.dart    # loading / success / error / cached-fallback
└── shared/
    └── widgets/
        └── scaffold_with_nav_test.dart       # breakpoint switching
```

**Structure Decision**: Option 3 (Mobile + API). Flutter client only — Django backend
at `api/` is already in place from Phase B1.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Principle IV — API payload uses JSON floats for monetary fields (`opening_balance`, `inflow`, etc.) | Phase B1 backend is complete and returns `double` values; F1 scope excludes backend changes | Storing as-is (`double`) violates constitution; converting at repository boundary (×100 → int piastres) preserves accuracy without requiring a B1 re-release. Remediation of the backend serialiser is scheduled for Phase B2. |
