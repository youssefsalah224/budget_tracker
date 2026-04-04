# Research: Gam3as Management (002)

**Branch**: `002-gam3as-management` | **Date**: 2026-04-04

## Decision 1: Riverpod Mutation Pattern

**Decision**: `GamAasNotifier` extends `AsyncNotifier<List<Gam3a>>`. Mutation methods (`add`, `update`, `delete`) set `state = const AsyncLoading()`, call the repository, then reload the full list via `state = AsyncData(await repo.fetchAll())`. No optimistic updates.

**Rationale**: The gam3a list is small (<50 items). A full reload after every mutation is simple, predictable, and always consistent with backend state. Optimistic updates would add complexity (rollback logic, ID reconciliation) with no meaningful performance benefit at this scale.

**Alternatives considered**:
- **Optimistic update + rollback**: Rejected — adds ~100 lines of rollback logic for no perceptible UX gain.
- **StateNotifier with manual list patching**: Rejected — `AsyncNotifier` is the current Riverpod 2.x standard and is already used in F1.

---

## Decision 2: Form Screen Routing

**Decision**: The add/edit form is a separate full-screen `GoRoute` registered **outside** the `ShellRoute`, so it covers the entire screen without the bottom nav bar. Two paths:
- `/gam3as/new` — add mode, no `extra`
- `/gam3as/edit` — edit mode, `extra: Gam3a` (typed object passed via GoRouter `extra`)

**Rationale**: The form is a task-focused flow. Showing the bottom nav bar during data entry creates visual noise and accidental navigation. GoRouter `extra` is the idiomatic way to pass rich typed objects between routes without URI serialization.

**Alternatives considered**:
- **Modal bottom sheet**: Rejected — insufficient vertical space for 6+ form fields; not accessible on small screens.
- **Query parameter with ID**: Rejected — requires a provider lookup by ID inside the form; `extra` is simpler and avoids an extra async step.

---

## Decision 3: List Cache Strategy

**Decision**: Cache the `List<Gam3a>` as a JSON string in `SharedPreferences` under key `gam3as_list_v1`. On network failure, return the cached list and set `isGam3asStaleProvider = true`. After any successful mutation (add/update/delete), write the fresh list to cache.

**Rationale**: Mirrors the `CacheService` pattern from F1 (SimulationResult). Keeps the cache logic behind a service boundary and avoids duplicating SharedPreferences boilerplate in the provider.

**Alternatives considered**:
- **No cache**: Rejected — offline resilience is a spec requirement (FR-010, US1 acceptance scenario 3).
- **Hive / ObjectBox**: Rejected — over-engineered for a small list; adds a new dependency violating the "no new packages" constraint.

---

## Decision 4: Form Validation

**Decision**: Use Flutter's built-in `Form` widget with `TextFormField` and `validator` callbacks. No third-party form library.

**Rationale**: The form has ≤7 fields with straightforward validation rules (non-empty, positive number, 1–12 range, start ≤ end). The built-in `Form` + `GlobalKey<FormState>` covers all these cases without a new dependency.

**Alternatives considered**:
- **flutter_form_builder**: Rejected — adds a dependency; overkill for 7 fields.
- **reactive_forms**: Rejected — same reason.

---

## Decision 5: piastres Conversion in Gam3a Model

**Decision**: `Gam3a.fromJson` converts `total_pot` and `monthly_contribution` from JSON `double` (EGP) to `int` piastres (×100) using `.round()`. `Gam3a.toJson` converts back to `double` for the API request body. The domain model stores only `int`.

**Rationale**: Consistent with `MonthlyRow` and `Kpis` from F1. All monetary fields in the Flutter client are `int` piastres — no `double` ever enters a domain model (Constitution Principle IV).

---

## Decision 6: Delete UX

**Decision**: Tap a delete icon on the card → `showDialog` confirmation → on confirm, call `GamAasNotifier.delete(id)`. No swipe-to-dismiss (swipe gesture conflicts with horizontal scrolling on wide screens and is hard to discover).

**Rationale**: An explicit icon + dialog is accessible, discoverable on all platforms (web mouse, touch, keyboard), and prevents accidental deletion.

**Alternatives considered**:
- **Dismissible widget (swipe)**: Rejected — poor discoverability on web, conflicts with scroll on some viewports.
