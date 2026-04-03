# Research: Flutter Foundation & Navigation

**Phase**: 0 (pre-design) | **Date**: 2026-04-03 | **Branch**: `001-flutter-foundation`

All NEEDS CLARIFICATION items from Technical Context are resolved below.

---

## 1. State Management: Riverpod vs BLoC

**Decision**: Riverpod (`flutter_riverpod` + `riverpod_annotation`)

**Rationale**:
- `AsyncNotifierProvider` natively exposes `AsyncValue<T>` — loading / data / error states
  map 1-to-1 with the spec's required UI states (FR-004).
- No `BuildContext` required in providers; providers can be instantiated and tested in plain
  Dart unit tests without a widget tree (critical for SC-002).
- Code generation via `riverpod_annotation` reduces boilerplate and prevents common mistakes
  (missing `override`, stale `ProviderRef`).
- Aligns with planmobile.md § 3.5 explicit technology decision.

**Alternatives considered**:
- BLoC: more boilerplate, requires `BuildContext` via `BlocProvider.of` in some patterns;
  rejected because Riverpod's `AsyncValue` eliminates explicit loading/error state machines.
- `Provider` (original): deprecated for new projects; no async-first API.

---

## 2. HTTP Client: dio vs http package

**Decision**: `dio ^5.4` with a single `DioClient` singleton

**Rationale**:
- Built-in timeout configuration (`connectTimeout`, `receiveTimeout`) satisfies FR-002
  without additional middleware.
- `DioException` typed error hierarchy makes error mapping to `AppException` straightforward.
- Interceptor API allows uniform error logging and future auth-header injection (Phase F5)
  without modifying call sites.
- Aligns with planmobile.md § F1 package list.

**Alternatives considered**:
- `http` package: minimal surface area, but timeout handling requires manual `Future.timeout`
  wrapping at each call site; no interceptor layer; rejected for maintainability reasons.

---

## 3. Routing: GoRouter vs Navigator 2.0 direct

**Decision**: `go_router ^14` with a `ShellRoute` wrapping the adaptive nav scaffold

**Rationale**:
- `ShellRoute` cleanly separates the persistent nav shell from leaf screens, which is
  exactly the adaptive-nav pattern required (FR-003).
- Deep-link URL scheme works identically on web and mobile without platform-specific code
  (Principle I compliance).
- GoRouter's declarative `routes` list is static-analysis friendly; no string-based
  `pushNamed` calls needed.

**Alternatives considered**:
- Raw `Navigator` / `Router` API: requires manual shell state management; error-prone
  for the breakpoint-responsive shell scenario; rejected.
- `auto_route`: code-generation heavy; adds a dependency with no benefit over GoRouter
  for 3-destination apps; rejected.

---

## 4. SharedPreferences: web compatibility

**Decision**: `shared_preferences ^2.x` (platform-native on mobile; `window.localStorage` on web)

**Rationale**:
- Single API across all three platforms with no native setup beyond adding the package.
- `getString` / `setString` is sufficient for a single `SimulationResult` JSON blob (FR-009).
- No size concerns: a 12-row simulation result serialises to < 5 KB.

**Alternatives considered**:
- `hive` / `isar`: overkill for a single key-value pair; adds native build complexity.
- `flutter_secure_storage`: not needed — simulation cache is not a secret credential.

---

## 5. Adaptive Navigation Pattern

**Decision**: `LayoutBuilder` + `NavigationBar` (< 600 px) / `NavigationRail` (≥ 600 px) inside `ScaffoldWithNav`, driven by a `ShellRoute`

**Rationale**:
- Material 3 `NavigationBar` and `NavigationRail` share the same destination model;
  switching at runtime (browser resize) requires only a `LayoutBuilder` rebuild with no
  state loss (FR-003 + edge case 2 in spec).
- GoRouter's `ShellRoute` manages the index/page state independently of the nav widget,
  so resizing never triggers a new network request (Acceptance Scenario 3 of US-2).
- This pattern is the canonical Material You adaptive layout recommendation.

**Alternatives considered**:
- Separate routes for mobile/desktop: loses shared screen state on resize.
- `NavigationDrawer` for wide screens: not appropriate for a 3-destination app.

---

## 6. Float → Integer Boundary Conversion (Constitution IV Remediation)

**Decision**: Convert monetary API fields to integer piastres (×100) at the repository
boundary; store as `int` in domain models; format for display via `intl` package

**Rationale**:
- The B1 API returns `double` JSON values. The Flutter domain layer must not propagate
  `double` for monetary fields to honour Principle IV.
- Multiplying by 100 and rounding at parse time (`(value * 100).round()`) is deterministic
  and lossless for values with at most 2 decimal places (EGP piastres).
- `effective_yield` is a percentage (not monetary); stored as `int` basis points (×100).

**Impact**: `SimulationRepository` performs the conversion. Domain models carry `int`.
Display layer formats via `NumberFormat` (e.g., `"EGP 1,190.00"` from `119000` piastres).

---

## 7. Build-Time API URL Configuration

**Decision**: `String.fromEnvironment('API_BASE_URL')` with a startup guard in `DioClient`

**Rationale**:
- `--dart-define=API_BASE_URL=...` is the Flutter-idiomatic way to inject build-time config
  (FR-001). Values are compiled in and not readable at runtime from source.
- Startup guard: if `API_BASE_URL` is empty, `DioClient` constructor throws a
  `StateError` with a human-readable message before any request is attempted (edge case 3).

---

## 8. Zero-Warning Static Analysis Baseline

**Decision**: `flutter analyze` with project-default `analysis_options.yaml` (all lints enabled)

**Rationale**:
- FR-007 / SC-005 mandate zero analysis warnings from the first commit.
- No custom lint suppressions (`// ignore:`) are allowed without a documented reason.
- `riverpod_lint` will be added to catch common Riverpod misuse patterns at analysis time.
