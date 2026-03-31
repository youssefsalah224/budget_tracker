# Project Plan: Gam3ya Investment Simulator — Flutter Client (Web · iOS · Android)

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-03-31 |
| **Project Type** | Cross-platform client — Web · iOS · Android (single Flutter codebase) |
| **Client Stack** | Flutter 3.x · Dart 3.x |
| **Backend** | Existing Django REST API — `e:/projects/budget tracker django` |
| **Spec format** | Each phase → one Spec Kit spec (`/speckit.specify` → `specs/###-name/spec.md`) |
| **Reference docs** | `PRD.md` (business logic) · `plan.md` (web roadmap) |

---

## 1. Overview

The Gam3ya Investment Simulator currently runs as a Django-served single HTML page.
This plan replaces that frontend and adds a mobile presence using a single Flutter codebase
that compiles to three targets:

```
flutter_app/
│
├── flutter build web     →  Replaces templates/index.html (served via Django or CDN)
├── flutter build apk     →  Android (Play Store / sideload)
└── flutter build ipa     →  iOS (App Store / TestFlight)
```

The Flutter client is a **pure consumer** of the existing Django REST API.
No backend logic is duplicated in the client. The backend remains the single source of truth
for all simulation math, data persistence, and AI responses.

**What the user gets that the current web app cannot provide:**
- Native iOS and Android app with platform-appropriate UX
- Offline simulation viewing via local cache
- Local push notifications for payout and payment months
- Secure token storage for future multi-user support

---

## 2. Architecture

### 2.1 Layered Architecture

```
┌─────────────────────────────────────────┐
│              Screens (UI)               │  ← Flutter Widgets, GoRouter
├─────────────────────────────────────────┤
│           State / Providers             │  ← Riverpod AsyncNotifierProvider
├─────────────────────────────────────────┤
│           Service Layer                 │  ← ApiService, CacheService
├─────────────────────────────────────────┤
│           Network / Storage             │  ← Dio · SharedPreferences · flutter_secure_storage
├─────────────────────────────────────────┤
│           Django REST API               │  ← http://localhost:8000/api
└─────────────────────────────────────────┘
```

### 2.2 Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod (AsyncNotifierProvider) | Compile-safe, testable without BuildContext, handles async/loading/error states natively |
| Navigation | GoRouter | Declarative, deep-link capable, supports redirect guards for auth (Phase 7), works on web |
| HTTP client | Dio | Interceptor support for auth headers (Phase 7), built-in timeout config, response type safety |
| Charting | fl_chart | Pure Flutter (no platform channel), smooth 60 fps, LineChart supports multi-series with tooltips |
| Local storage | SharedPreferences | Simple key-value cache sufficient for simulation JSON blob |
| Secure storage | flutter_secure_storage | Keychain (iOS) / Keystore (Android) for JWT token; falls back to localStorage encryption on web |

### 2.3 Cross-Platform Behaviour Matrix

| Feature | Web | iOS | Android |
|---------|-----|-----|---------|
| Navigation | Navigation rail (wide) / bottom nav (narrow) | Bottom nav bar | Bottom nav bar |
| Push notifications | Not supported (`kIsWeb` guarded) | `flutter_local_notifications` | `flutter_local_notifications` |
| Offline cache | SessionStorage fallback | SharedPreferences | SharedPreferences |
| Secure token storage | Encrypted localStorage | Keychain | Keystore |
| Build command | `flutter build web` | `flutter build ipa` | `flutter build apk` |

---

## 3. API Contract

All API calls originate from `ApiService` (`lib/services/api_service.dart`).
Base URL is injected at build time via `--dart-define=API_BASE_URL=http://localhost:8000/api`.

| Method | Endpoint | Used in Phase | Flutter Provider |
|--------|----------|---------------|-----------------|
| GET | `/gam3as` | 2 | `gam3asProvider` |
| POST | `/gam3as` | 2 | `gam3asProvider.add()` |
| PUT | `/gam3as/{id}` | 2 | `gam3asProvider.update()` |
| DELETE | `/gam3as/{id}` | 2 | `gam3asProvider.delete()` |
| GET | `/settings` | 4 | `settingsProvider` |
| PUT | `/settings` | 4 | `settingsProvider.update()` |
| GET | `/simulate` | 1 | `simulationProvider` |
| POST | `/simulate/scenario` | 4 | `scenarioProvider.run()` |
| POST | `/chat` | 5 | `chatProvider.send()` |
| GET | `/overrides` | 6 | `overridesProvider` |
| POST | `/overrides` | 6 | `overridesProvider.add()` |
| PUT | `/overrides/{month}` | 6 | `overridesProvider.update()` |
| DELETE | `/overrides/{month}` | 6 | `overridesProvider.delete()` |
| GET | `/actuals` | 6 | `actualsProvider` |
| POST | `/actuals` | 6 | `actualsProvider.log()` |
| PUT | `/actuals/{month}` | 6 | `actualsProvider.update()` |
| POST | `/auth/register` | 7 | `authProvider.register()` |
| POST | `/auth/login` | 7 | `authProvider.login()` |
| POST | `/auth/refresh` | 7 | `authProvider.refresh()` |

---

## 4. Dependency Manifest

Full `pubspec.yaml` dependency list across all phases. Each phase introduces only the
packages marked for that phase.

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Phase 1 — Foundation
  go_router: ^14.0.0          # Declarative routing with redirect guards
  flutter_riverpod: ^2.5.0    # State management
  riverpod_annotation: ^2.3.0 # Code-gen annotations for providers
  dio: ^5.4.0                  # HTTP client with interceptors
  shared_preferences: ^2.2.0  # Local key-value cache

  # Phase 3 — Charts
  fl_chart: ^0.68.0            # Pure-Flutter charting library

  # Phase 5 — AI Chat
  # No new packages — uses Dio from Phase 1

  # Phase 7 — Auth
  flutter_secure_storage: ^9.0.0  # Keychain/Keystore JWT storage

  # Phase 8 — Offline & Notifications
  connectivity_plus: ^6.0.0        # Network status detection
  flutter_local_notifications: ^17.0.0  # Local push scheduling

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0   # Provider code generation
  build_runner: ^2.4.0
  mocktail: ^1.0.0             # Mocking for unit tests
  flutter_lints: ^4.0.0
```

---

## 5. Project File Structure

```text
flutter_app/
├── lib/
│   ├── main.dart                         # Entry point, ProviderScope, theme
│   ├── router.dart                       # GoRouter definition, redirect logic
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart         # Phase 1/3
│   │   ├── gam3as_screen.dart            # Phase 2
│   │   ├── gam3a_form_screen.dart        # Phase 2 (add/edit)
│   │   ├── scenario_screen.dart          # Phase 4
│   │   ├── chat_screen.dart              # Phase 5 (full-screen modal route)
│   │   ├── overrides_screen.dart         # Phase 6
│   │   ├── actuals_screen.dart           # Phase 6
│   │   └── auth/
│   │       ├── login_screen.dart         # Phase 7
│   │       └── register_screen.dart      # Phase 7
│   │
│   ├── widgets/
│   │   ├── kpi_card.dart                 # Phase 3
│   │   ├── simulation_chart.dart         # Phase 3 (fl_chart wrapper)
│   │   ├── monthly_table.dart            # Phase 3
│   │   ├── gam3a_card.dart               # Phase 2
│   │   ├── chat_bubble.dart              # Phase 5
│   │   ├── offline_banner.dart           # Phase 8
│   │   └── scaffold_with_nav.dart        # Phase 1 (adaptive nav shell)
│   │
│   ├── providers/
│   │   ├── simulation_provider.dart      # Phase 1
│   │   ├── gam3as_provider.dart          # Phase 2
│   │   ├── settings_provider.dart        # Phase 4
│   │   ├── scenario_provider.dart        # Phase 4
│   │   ├── chat_provider.dart            # Phase 5
│   │   ├── overrides_provider.dart       # Phase 6
│   │   ├── actuals_provider.dart         # Phase 6
│   │   └── auth_provider.dart            # Phase 7
│   │
│   ├── services/
│   │   ├── api_service.dart              # Dio client, base URL, interceptors
│   │   └── cache_service.dart            # SharedPreferences read/write helpers
│   │
│   ├── models/
│   │   ├── gam3a.dart                    # Phase 1 (fromJson/toJson)
│   │   ├── simulation_result.dart        # Phase 1
│   │   ├── monthly_row.dart              # Phase 1
│   │   ├── kpis.dart                     # Phase 1
│   │   ├── simulation_settings.dart      # Phase 4
│   │   ├── monthly_override.dart         # Phase 6
│   │   ├── monthly_actual.dart           # Phase 6
│   │   └── auth_token.dart               # Phase 7
│   │
│   └── constants/
│       ├── theme.dart                    # Design tokens, ThemeData
│       └── api_endpoints.dart            # Endpoint path constants
│
├── test/
│   ├── services/
│   │   └── api_service_test.dart
│   ├── providers/
│   │   ├── simulation_provider_test.dart
│   │   └── gam3as_provider_test.dart
│   └── widgets/
│       ├── kpi_card_test.dart
│       └── gam3a_card_test.dart
│
├── web/                                  # Auto-generated Flutter web target
├── android/                              # Auto-generated Flutter Android target
├── ios/                                  # Auto-generated Flutter iOS target
└── pubspec.yaml
```

---

## 6. Design Token Reference

All colors, typography, and spacing are defined once in `lib/constants/theme.dart`
and referenced throughout the app. No hardcoded hex values anywhere else.

| Token | Hex | Dart constant | Usage |
|-------|-----|--------------|-------|
| Background | `#1A1A2E` | `AppColors.background` | Scaffold background |
| Surface | `#16213E` | `AppColors.surface` | Cards, panels |
| Accent | `#0F3460` | `AppColors.accent` | Borders, buttons |
| Positive | `#10B981` | `AppColors.positive` | Gains, inflows, interest |
| Negative | `#E74C3C` | `AppColors.negative` | Payments, losses |
| Payout | `#F59E0B` | `AppColors.payout` | Payout month highlights |
| Text primary | `#FFFFFF` | `AppColors.textPrimary` | Headlines, values |
| Text secondary | `#94A3B8` | `AppColors.textSecondary` | Labels, captions |
| Blue | `#3B82F6` | `AppColors.blue` | Editable inputs, badges |

---

## 7. Testing Strategy

| Layer | Tool | What is tested |
|-------|------|----------------|
| Models | `flutter_test` | `fromJson` / `toJson` round-trips, null safety |
| Services | `flutter_test` + `mocktail` | `ApiService` Dio calls mocked at the HTTP adapter level |
| Providers | `flutter_test` + `ProviderContainer` | Loading, success, and error states for each provider |
| Widgets | `flutter_test` | Key widgets (`KpiCard`, `Gam3aCard`, `SimulationChart`) render correctly with mock data |
| Integration | Manual on device | Full user journeys run on a physical iOS device, Android device, and Chrome |

Each phase MUST have at least one passing unit test for any new provider or service
before the phase spec is marked complete.

---

## 8. Environment & Build

### Development
```bash
# Run on Chrome (web)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api

# Run on Android emulator
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Run on iOS simulator
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8000/api
```

### Production Build
```bash
# Web — output to build/web, serve via Django staticfiles or CDN
flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# Android APK
flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# iOS archive
flutter build ipa --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

> **Note:** Android emulator uses `10.0.2.2` to reach the host machine's `localhost`.
> iOS simulator uses `localhost` directly.

---

## 9. Phase Execution Plan

| # | Spec | Name | Status | New Packages | Key Deliverable |
|---|------|------|--------|-------------|-----------------|
| 1 | `001-flutter-foundation` | Foundation & Navigation | 🔲 Next | `go_router` `flutter_riverpod` `dio` `shared_preferences` | Project boots on all 3 targets, simulation data visible |
| 2 | `002-gam3a-manager` | Gam3a Manager | 🔲 Planned | — | Full CRUD on all platforms |
| 3 | `003-dashboard-charts` | Dashboard & Charts | 🔲 Planned | `fl_chart` | KPI cards + line chart + monthly table |
| 4 | `004-scenario-simulator` | Scenario Simulator | 🔲 Planned | — | What-if simulation without saving |
| 5 | `005-ai-chat` | AI Chat | 🔲 Planned | — | Bilingual Claude chat modal |
| 6 | `006-overrides-actuals` | Overrides & Actuals | 🔲 Planned | — | Override management + actual vs projected |
| 7 | `007-auth` | Authentication | 🔲 Planned | `flutter_secure_storage` | Login/register, per-user data |
| 8 | `008-offline-notifications` | Offline & Notifications | 🔲 Planned | `connectivity_plus` `flutter_local_notifications` | Offline cache + push reminders |

---

## Phase 1 — Foundation & Navigation
**Spec**: `specs/001-flutter-foundation/spec.md`
**Branch**: `001-flutter-foundation`
**New packages**: `go_router` · `flutter_riverpod` · `riverpod_annotation` · `dio` · `shared_preferences`

### Summary
Bootstrap the Flutter project, configure the layered architecture, connect to the Django API,
apply the design token theme, and render live simulation data on screen. This phase validates
that the Flutter client compiles and runs on all three targets and can communicate with the backend.

### Definition of Done
- [ ] `flutter run` succeeds on Chrome, Android emulator, and iOS simulator without errors
- [ ] `GET /api/simulate` response is fetched, deserialized into `SimulationResult`, and displayed
- [ ] All 3 navigation destinations are reachable
- [ ] Design tokens applied — background, surface, and accent colors match the web app
- [ ] At least one passing unit test for `SimulationProvider` (loading → success → error states)

### User Stories

#### Story 1 — View live simulation on any device (P1)
The user opens the app on web, iOS, or Android and sees the 12-month simulation data
fetched in real time from the Django backend.

**Acceptance Scenarios**:
1. **Given** the app is open and the backend is running, **When** the Dashboard screen loads, **Then** all 12 monthly rows and KPI totals are visible within 2 seconds.
2. **Given** the backend is unreachable, **When** the Dashboard attempts to load, **Then** an error widget is shown with a "Retry" button that re-triggers the API call.
3. **Given** the app is loading data, **When** the API call is in-flight, **Then** a `CircularProgressIndicator` is displayed and no partial data is shown.

#### Story 2 — Navigate between main sections (P2)
The user navigates between Dashboard, Gam3as, and Scenario using the bottom navigation bar
on mobile or the navigation rail on wide screens (web/tablet).

**Acceptance Scenarios**:
1. **Given** the app is on a mobile screen (<600px width), **When** the user taps a bottom nav item, **Then** the correct screen renders with no frame drop.
2. **Given** the app is on a wide screen (≥600px width), **When** the user clicks a navigation rail item, **Then** the correct screen renders and the selected item is visually highlighted.

### Functional Requirements
- **FR-001**: The API base URL MUST be injected via `--dart-define=API_BASE_URL` and never hardcoded.
- **FR-002**: `ApiService` MUST configure a 10-second connection timeout and a 30-second receive timeout on the Dio instance.
- **FR-003**: The app MUST use `AdaptiveScaffold` (or equivalent) to show bottom navigation on screens <600px wide and a navigation rail on screens ≥600px.
- **FR-004**: The app MUST use `ProviderScope` at the root and all state MUST be managed via Riverpod `AsyncNotifierProvider`.
- **FR-005**: `SimulationResult`, `MonthlyRow`, and `Kpis` MUST be immutable Dart model classes with `fromJson` factories and full null-safety.
- **FR-006**: All color values MUST be referenced from `AppColors` constants — no inline hex strings.
- **FR-007**: The app MUST compile with zero `flutter analyze` warnings.

### Success Criteria
- **SC-001**: Simulation data renders within 2 seconds of app open on a local network across all three platforms.
- **SC-002**: `flutter analyze` reports zero issues.
- **SC-003**: `SimulationProvider` unit tests cover loading, success, and network error states.

---

## Phase 2 — Gam3a Manager
**Spec**: `specs/002-gam3a-manager/spec.md`
**Branch**: `002-gam3a-manager`
**New packages**: none

### Summary
Full CRUD management of gam3as. The user can add, edit, and delete gam3as directly from
the app on any platform. Saving any change invalidates the simulation provider so the
Dashboard reflects updated data immediately.

### Definition of Done
- [ ] All four API endpoints (`GET POST PUT DELETE /api/gam3as`) are called correctly
- [ ] Form validation blocks submission on missing required fields
- [ ] Saving or deleting a gam3a triggers a simulation re-fetch visible on the Dashboard
- [ ] Delete requires an `AlertDialog` confirmation on all platforms
- [ ] Unit tests for `Gam3aProvider` (add, update, delete, validation error)

### User Stories

#### Story 1 — Add a new gam3a (P1)
The user taps the "+" FAB on the Gam3as screen, fills out the form, and saves. The new
gam3a appears in the list and the Dashboard simulation updates to include it.

**Acceptance Scenarios**:
1. **Given** the Gam3as screen is open, **When** the user completes all fields and taps Save, **Then** `POST /api/gam3as` is called, returns 201, and the gam3a card appears in the list.
2. **Given** the Add form is open, **When** the user taps Save with Name left empty, **Then** a red validation message appears under the Name field and no HTTP request is made.
3. **Given** a new gam3a is saved, **When** the user navigates to the Dashboard, **Then** the simulation totals reflect the new gam3a's contributions.

#### Story 2 — Edit an existing gam3a (P2)
The user taps a gam3a card, modifies a field, and saves. The change syncs to the backend
and the card updates immediately.

**Acceptance Scenarios**:
1. **Given** a gam3a card is tapped, **When** the Edit form opens, **Then** all current field values are pre-populated.
2. **Given** the Edit form is open, **When** the user changes the pot amount and saves, **Then** `PUT /api/gam3as/{id}` is called and the card shows the updated value.

#### Story 3 — Delete a gam3a (P3)
The user long-presses a card (mobile) or clicks a delete icon (web) and confirms deletion.

**Acceptance Scenarios**:
1. **Given** a gam3a card exists, **When** the user confirms the delete dialog, **Then** `DELETE /api/gam3as/{id}` is called and the card is removed from the list.
2. **Given** the delete `AlertDialog` is shown, **When** the user taps "Cancel", **Then** no request is made and the card remains.

### Functional Requirements
- **FR-001**: The Gam3as screen MUST list all gam3as with: name, total pot (EGP), monthly contribution (EGP, red), pay window ("Apr → May"), payout month (amber), and a received/pending badge.
- **FR-002**: The Add/Edit form MUST include all fields: name (text), total pot (numeric), monthly contribution (numeric), start month (dropdown), payout month (dropdown), end month (dropdown), payout received (switch).
- **FR-003**: Month dropdowns MUST display full month names (January–December) and store 1–12 integer values.
- **FR-004**: Saving (add or edit) MUST call `ref.invalidate(simulationProvider)` to trigger a Dashboard re-fetch.
- **FR-005**: Delete MUST be confirmed via `showDialog` with an `AlertDialog` containing "Delete" (destructive) and "Cancel" actions.
- **FR-006**: All API errors MUST surface as a `SnackBar` with the error message — the list state MUST NOT be mutated on failure.

### Success Criteria
- **SC-001**: Add, edit, and delete each complete in under 30 seconds of user interaction.
- **SC-002**: Form validation prevents API calls for all required-field violations.
- **SC-003**: Dashboard simulation visibly updates after any gam3a change without a manual refresh.

---

## Phase 3 — Dashboard & Charts
**Spec**: `specs/003-dashboard-charts/spec.md`
**Branch**: `003-dashboard-charts`
**New packages**: `fl_chart: ^0.68.0`

### Summary
Replace the placeholder simulation display from Phase 1 with the full production Dashboard:
four color-coded KPI cards, a multi-line `fl_chart` line chart, and a fully styled monthly
breakdown table with payout highlights and signed value coloring.

### Definition of Done
- [ ] 4 KPI cards render with correct colors and formatted EGP values
- [ ] Line chart shows 3 series, tap tooltip works, 60 fps on mid-range Android
- [ ] Monthly table scrolls through all 12 rows with correct amber/red/green styling
- [ ] Widget tests for `KpiCard`, `SimulationChart`, and `MonthlyTable`

### User Stories

#### Story 1 — See KPI summary at a glance (P1)
The user opens the Dashboard and immediately understands the financial position from
four headline cards before scrolling.

**Acceptance Scenarios**:
1. **Given** simulation data is loaded, **When** the Dashboard renders, **Then** 4 KPI cards are visible above the fold with correct labels, values, and colors: Total Invested (blue) · Total Interest (green) · Total Payments Out (red) · Final Balance (amber).
2. **Given** values are in the thousands, **When** displayed in the KPI card, **Then** they are formatted with comma separators and "EGP" suffix (e.g., "119,000 EGP").

#### Story 2 — View fund growth on a chart (P2)
The user scrolls to the chart and reads the fund trajectory across 12 months via three
color-coded lines with interactive tooltips.

**Acceptance Scenarios**:
1. **Given** the chart is rendered, **When** the user taps any data point, **Then** a tooltip appears showing the month name and the EGP value for all three series at that month.
2. **Given** the chart is rendered on web, **When** the user hovers over a data point, **Then** the tooltip appears on hover.

#### Story 3 — Review monthly breakdown (P3)
The user scrolls through the 12-row table and reads cash flows per month with visual
cues that make payout months, positive flows, and negative flows immediately legible.

**Acceptance Scenarios**:
1. **Given** the table is rendered, **When** a row is a payout month, **Then** the row background is amber (`AppColors.payout` at 20% opacity) and a "Payout" `Chip` is shown.
2. **Given** the table is rendered, **When** the closing balance for a month is negative, **Then** the closing value is rendered in `AppColors.negative`.
3. **Given** the table is rendered, **When** an inflow or interest value is positive, **Then** it is prefixed with "+" and rendered in `AppColors.positive`.

### Functional Requirements
- **FR-001**: Dashboard MUST display 4 `KpiCard` widgets: Total Invested (blue) · Total Interest (green) · Total Payments Out (red) · Final Balance (amber).
- **FR-002**: `SimulationChart` MUST use `fl_chart` `LineChart` with 3 `LineChartBarData` series: Closing Balance · Cumulative Invested · Cumulative Interest.
- **FR-003**: Chart X-axis MUST render abbreviated month names (Jan–Dec) using `SideTitles`.
- **FR-004**: Chart Y-axis values MUST be formatted as `"67K"` (divide by 1000, suffix "K") via `getTitlesWidget`.
- **FR-005**: Chart `LineTouchData` MUST be enabled; tooltip MUST show month name and formatted EGP value for all 3 series.
- **FR-006**: `MonthlyTable` MUST be a scrollable `DataTable` or `ListView` with columns: Month · Opening · Inflow · Interest · Payments Out · Closing · Cumul. Interest.
- **FR-007**: All numeric values in the table MUST be formatted with `NumberFormat('#,##0.00', 'en_US')`.

### Success Criteria
- **SC-001**: Chart maintains 60 fps during initial render on a mid-range Android device (Pixel 4a or equivalent).
- **SC-002**: All 12 table rows render and scroll without overflow on a 375px-wide screen (iPhone SE).
- **SC-003**: Widget tests confirm `KpiCard` renders the correct label, value, and color for all 4 variants.

---

## Phase 4 — Scenario Simulator
**Spec**: `specs/004-scenario-simulator/spec.md`
**Branch**: `004-scenario-simulator`
**New packages**: none

### Summary
The Scenario screen lets the user run ad-hoc "what-if" simulations by overriding the annual
rate, investment day, and adding one-time extra inflows per month. Results are shown with
the same KPI cards and chart as the Dashboard but clearly badged as simulation-only.
No saved data is modified.

### Definition of Done
- [ ] `POST /api/simulate/scenario` is called with correct body on Run tap
- [ ] Results display KPI cards and chart with amber "SIMULATION MODE" indicator
- [ ] Reset restores all inputs to the values from `GET /api/settings`
- [ ] Scenario results do not affect the Dashboard simulation state

### User Stories

#### Story 1 — Run a what-if scenario (P1)
The user adjusts the rate and investment day, taps "Run Scenario", and sees the projected
outcome under those new conditions alongside a clear simulation-mode indicator.

**Acceptance Scenarios**:
1. **Given** the Scenario screen is open, **When** the user sets rate to 22% and taps Run, **Then** `POST /api/simulate/scenario` is called with `{"annual_rate": 22.0}` and results render below the form.
2. **Given** scenario results are visible, **When** the user navigates to the Dashboard and back, **Then** the previous scenario results are still shown (state preserved for the session).
3. **Given** results are visible, **When** the user taps "Reset", **Then** all inputs revert to the values from `settingsProvider` and results are cleared.

#### Story 2 — Add one-time inflows per month (P2)
The user enters an extra deposit for a specific month to simulate receiving unexpected cash.

**Acceptance Scenarios**:
1. **Given** the scenario form is open, **When** the user enters 5,000 in the March extra inflow field and runs, **Then** the scenario request body includes `"extra_inflows": {"3": 5000.0}` and March's inflow row reflects the addition.

### Functional Requirements
- **FR-001**: Scenario screen MUST load initial rate and investment day values from `GET /api/settings` via `settingsProvider`.
- **FR-002**: Scenario screen MUST render 12 extra inflow inputs in a responsive grid (2 columns on mobile, 4 on web).
- **FR-003**: Run MUST call `POST /api/simulate/scenario` with only non-default fields included in the request body.
- **FR-004**: Results section MUST display an amber `Chip` labelled "SIMULATION MODE" above the KPI cards.
- **FR-005**: Results KPI cards MUST have an amber border to reinforce that they are not real data.
- **FR-006**: `scenarioProvider` MUST be independent of `simulationProvider` — running a scenario MUST NOT invalidate the Dashboard's cached simulation.

### Success Criteria
- **SC-001**: Scenario results render within 1 second of tapping Run on a local network.
- **SC-002**: Dashboard simulation data is unchanged after running a scenario, confirmed by navigating back.

---

## Phase 5 — AI Chat
**Spec**: `specs/005-ai-chat/spec.md`
**Branch**: `005-ai-chat`
**New packages**: none

### Summary
A full-screen modal chat interface backed by `POST /api/chat`. The assistant is Claude
(Anthropic), pre-loaded with the user's full simulation context by the backend. The UI
supports bilingual Arabic/English with automatic RTL detection, a typing indicator, and
suggestion chips on first open.

### Definition of Done
- [ ] Chat modal opens from a FAB on the Dashboard
- [ ] Messages send to `POST /api/chat` with full history
- [ ] Arabic input triggers `TextDirection.rtl` on the reply bubble
- [ ] Typing indicator shows during in-flight requests
- [ ] Suggestion chips appear only when history is empty
- [ ] Widget test for `ChatBubble` (LTR English and RTL Arabic variants)

### User Stories

#### Story 1 — Ask a financial question in English (P1)
The user opens the chat from the Dashboard FAB, types a question in English, and receives
a contextual answer grounded in their real simulation numbers within 5 seconds.

**Acceptance Scenarios**:
1. **Given** the chat screen is open, **When** the user types a message and taps Send, **Then** the message appears as a right-aligned bubble and a typing indicator (3 animated dots) appears immediately.
2. **Given** the typing indicator is visible, **When** the API response arrives, **Then** the indicator is replaced by a left-aligned assistant bubble.
3. **Given** an assistant reply contains numbers, **When** it renders, **Then** numbers appear formatted with comma separators and "EGP" suffix.

#### Story 2 — Ask a question in Arabic and receive an RTL reply (P2)
The user types in Arabic and the assistant replies in Arabic. Both message bubbles use
right-to-left text direction automatically.

**Acceptance Scenarios**:
1. **Given** the user types an Arabic message, **When** the message bubble renders, **Then** `Directionality.of(context)` resolves to `TextDirection.rtl` for that bubble.
2. **Given** the assistant reply is in Arabic, **When** the bubble renders, **Then** it also uses `TextDirection.rtl` and Arabic numerals display correctly.

#### Story 3 — Use suggestion chips on first open (P3)
On first open (no history), four suggestion chips guide the user toward useful questions.
Tapping one sends it immediately.

**Acceptance Scenarios**:
1. **Given** the chat has no message history, **When** the screen opens, **Then** 4 `ActionChip` widgets are visible below the empty message list.
2. **Given** a chip is tapped, **When** the message is sent, **Then** the chip row disappears and the tapped text appears as a user message bubble.

### Functional Requirements
- **FR-001**: The chat FAB MUST be positioned at `Alignment.bottomRight` on the Dashboard screen.
- **FR-002**: `POST /api/chat` request body MUST include `{"message": string, "history": [{"role": string, "content": string}]}`.
- **FR-003**: Arabic detection MUST use the regex `RegExp(r'[\u0600-\u06FF]')` applied to the message text.
- **FR-004**: `ChatBubble` MUST accept a `isUser` boolean and render with `CrossAxisAlignment.end` (user) or `CrossAxisAlignment.start` (assistant).
- **FR-005**: The typing indicator MUST be implemented as three dots animated with staggered `ScaleTransition` animations.
- **FR-006**: Session history MUST be stored in `chatProvider` state and cleared when the provider is disposed (app restart).
- **FR-007**: Suggestion chips: `"Which month will my balance peak?"` · `"Is this strategy profitable?"` · `"Summarize my financial position"` · `"ما هو الشهر الأفضل لي؟"`

### Success Criteria
- **SC-001**: First assistant reply arrives and renders within 5 seconds on a standard broadband connection.
- **SC-002**: Arabic reply bubbles render RTL with no text overflow or layout breakage on 375px screen width.
- **SC-003**: `ChatBubble` widget test passes for both LTR and RTL variants with mock message data.

---

## Phase 6 — Overrides & Actuals
**Spec**: `specs/006-overrides-actuals/spec.md`
**Branch**: `006-overrides-actuals`
**New packages**: none
**Backend work required**: Yes — new `MonthlyActual` model and new API endpoints for both overrides and actuals.

### Summary
Two related features delivered together:

1. **Monthly Overrides** — expose the existing `MonthlyOverride` backend model in the UI so
   users can suppress or replace calculated inflows and payments for any month.
2. **Actuals Tracking** — introduce a new `MonthlyActual` model to record what actually
   happened each month and show a dashed "Actual Balance" series on the Dashboard chart.

### Backend Changes Required (Django)
- **New endpoints**: `GET/POST /api/overrides` · `PUT/DELETE /api/overrides/{month}`
- **New model**: `MonthlyActual` (month, actual_inflow, actual_payment, actual_interest, note)
- **New endpoints**: `GET/POST /api/actuals` · `PUT /api/actuals/{month}`

### Definition of Done
- [ ] All override CRUD endpoints are wired and tested in the Django backend
- [ ] All actuals endpoints are wired and tested in the Django backend
- [ ] Override changes reflect in Dashboard simulation within one provider refresh
- [ ] Dashboard chart shows a dashed "Actual Balance" line when any `MonthlyActual` records exist
- [ ] Unit tests for `OverridesProvider` and `ActualsProvider`

### User Stories

#### Story 1 — Manage monthly overrides (P1)
The user opens the Overrides screen and suppresses a gam3a payout that was received before
the fund started by setting Month 1's custom inflow to 0.

**Acceptance Scenarios**:
1. **Given** the Overrides screen is open, **When** the user sets Month 1 custom inflow to 0.0 and saves, **Then** `POST /api/overrides` is called and the Dashboard simulation immediately shows 0 inflow for January.
2. **Given** an override exists, **When** the user deletes it, **Then** `DELETE /api/overrides/{month}` is called and the simulation reverts to the calculated value.

#### Story 2 — Log actual monthly values (P2)
After a month ends, the user logs the real inflow, payment, and interest to compare against
the projection.

**Acceptance Scenarios**:
1. **Given** the Actuals screen is open for May, **When** the user enters real values and saves, **Then** `POST /api/actuals` is called and the Dashboard chart adds a dashed "Actual Balance" line.
2. **Given** actuals exist for some months, **When** the Dashboard chart renders, **Then** the dashed actual line appears only for months that have been logged and stops at the last logged month.

### Functional Requirements
- **FR-001**: Overrides screen MUST list all existing `MonthlyOverride` records showing month, custom inflow, custom payment, and note.
- **FR-002**: Override form MUST use a month dropdown (Jan–Dec) and nullable numeric inputs for custom inflow and custom payment.
- **FR-003**: Saving an override MUST call `ref.invalidate(simulationProvider)`.
- **FR-004**: Actuals screen MUST list all 12 months; logged months show their actual values, unlogged months show "Not recorded".
- **FR-005**: `SimulationChart` MUST conditionally render a fourth `LineChartBarData` series for Actual Balance using a dashed `DashArray` pattern when `actualsProvider` has data.
- **FR-006**: The dashed Actual Balance line MUST use a distinct color (white at 70% opacity) to contrast with the three projected lines.

### Success Criteria
- **SC-001**: Override changes are reflected on the Dashboard simulation within one provider invalidation cycle (no manual refresh).
- **SC-002**: The dashed actual vs projected comparison is visually distinguishable on a 375px screen.

---

## Phase 7 — Authentication
**Spec**: `specs/007-auth/spec.md`
**Branch**: `007-auth`
**New packages**: `flutter_secure_storage: ^9.0.0`
**Backend work required**: Yes — JWT endpoints and per-user data scoping on all existing endpoints.

### Summary
Add login and registration so each user has their own isolated dataset. Uses Django's
built-in `User` model with `djangorestframework-simplejwt` for token issuance. The Flutter
client stores the access token in `flutter_secure_storage` and attaches it via a Dio
interceptor on every request.

### Backend Changes Required (Django)
- Install `djangorestframework-simplejwt`
- Add `POST /api/auth/register` · `POST /api/auth/login` · `POST /api/auth/refresh`
- Add `user` ForeignKey to `Gam3a`, `SimulationSettings`, `MonthlyOverride`, `MonthlyActual`
- Scope all existing queryset `.filter(user=request.user)`

### Definition of Done
- [ ] Register and login flows complete end-to-end on all platforms
- [ ] GoRouter redirect sends unauthenticated users to `/login`
- [ ] Dio interceptor attaches `Authorization: Bearer <token>` on every request
- [ ] Two separate user accounts see only their own data
- [ ] `flutter_secure_storage` read/write unit tested with a mock

### User Stories

#### Story 1 — Register and reach the Dashboard (P1)
A new user creates an account and is immediately taken to their own empty Dashboard.

**Acceptance Scenarios**:
1. **Given** the login screen is open, **When** the user taps "Create Account", fills in email + password, and submits, **Then** `POST /api/auth/register` is called, the JWT is stored, and GoRouter navigates to `/dashboard`.
2. **Given** two users are registered, **When** each logs in, **Then** each sees only their own gam3as and simulation data.

#### Story 2 — Stay authenticated across restarts (P2)
The user closes and reopens the app. The stored token is validated and they land on the
Dashboard without re-entering credentials.

**Acceptance Scenarios**:
1. **Given** a valid token is stored in `flutter_secure_storage`, **When** the app cold-starts, **Then** `authProvider` reads the token, the GoRouter redirect allows entry to `/dashboard`, and no login screen is shown.
2. **Given** the stored token is expired, **When** the app cold-starts, **Then** `POST /api/auth/refresh` is attempted; on failure the user is redirected to `/login`.

#### Story 3 — Log out cleanly (P3)
The user logs out and all local state and cached data is cleared.

**Acceptance Scenarios**:
1. **Given** the user is logged in, **When** they tap "Log Out" in the profile menu, **Then** the token is deleted from `flutter_secure_storage`, all Riverpod providers are invalidated, and GoRouter redirects to `/login`.

### Functional Requirements
- **FR-001**: Login and Register screens MUST validate that email is a valid format and password is ≥8 characters before submitting.
- **FR-002**: `AuthInterceptor` (Dio `InterceptorsWrapper`) MUST attach `Authorization: Bearer <token>` on every outgoing request.
- **FR-003**: On a 401 response, `AuthInterceptor` MUST attempt one token refresh via `POST /api/auth/refresh`; if refresh fails, clear the token and redirect to `/login`.
- **FR-004**: GoRouter MUST define a `redirect` callback that reads `authProvider` state and routes to `/login` when no valid token exists.
- **FR-005**: Logout MUST call `flutter_secure_storage.deleteAll()` then `ref.invalidate()` on all providers before navigating.
- **FR-006**: Password fields MUST use `obscureText: true` with a toggle visibility icon.

### Success Criteria
- **SC-001**: Two users can register and log in; each sees only their own data — confirmed by manual cross-account test.
- **SC-002**: Token refresh is invisible to the user — no logout occurs on a mid-session token expiry.
- **SC-003**: `AuthInterceptor` unit test confirms `Authorization` header is present on mocked requests.

---

## Phase 8 — Offline Support & Push Notifications
**Spec**: `specs/008-offline-notifications/spec.md`
**Branch**: `008-offline-notifications`
**New packages**: `connectivity_plus: ^6.0.0` · `flutter_local_notifications: ^17.0.0`
**Platform note**: Offline cache and push notifications apply to **iOS and Android only**. Both features are guarded by `kIsWeb` checks and silently skipped on web.

### Summary
Two reliability features delivered together:

1. **Offline cache** — the last successful `GET /api/simulate` response is persisted to
   `SharedPreferences`. On subsequent opens with no network, the cached data is shown with
   an offline banner.
2. **Local push notifications** — scheduled via `flutter_local_notifications` to remind the
   user on the 28th of the month before a payout and on the 1st of each payment month.

### Definition of Done
- [ ] Dashboard loads from `SharedPreferences` cache when network is unavailable on iOS/Android
- [ ] Offline banner appears with the timestamp of the last successful fetch
- [ ] Write operations show a `SnackBar` error when offline
- [ ] Notifications are scheduled after each simulation fetch on mobile
- [ ] Notifications fire at the correct time in an emulator test
- [ ] All offline/notification code is guarded with `if (!kIsWeb)`

### User Stories

#### Story 1 — View cached simulation while offline (P1)
The user opens the app with no network connection and sees their last known simulation data
with a clear indicator that the data may be outdated.

**Acceptance Scenarios**:
1. **Given** the app has previously fetched simulation data, **When** the user opens the app with no network, **Then** the Dashboard renders the cached data and an amber banner reads "Offline — last updated [date/time]".
2. **Given** the app is offline and the cache is empty (first launch), **When** the Dashboard loads, **Then** an error state is shown: "No data available. Connect to the internet to load your simulation."
3. **Given** the app is offline, **When** the user taps "Add Gam3a", **Then** a `SnackBar` reads "This action requires an internet connection."

#### Story 2 — Receive a reminder before a payout month (P2)
On the 28th of the month before a payout, the user gets a local notification so they can
prepare to deposit the incoming funds.

**Acceptance Scenarios**:
1. **Given** May is a payout month for Gam3a #3 (80,000 EGP), **When** it is April 28th, **Then** the device shows a notification: "Payout incoming: 80,000 EGP from Gam3a #3 arrives next month."

#### Story 3 — Receive a reminder when payments are due (P3)
On the 1st of each month with outgoing gam3a payments, the user is reminded of the total
amount owed that month.

**Acceptance Scenarios**:
1. **Given** March has 13,000 EGP in total gam3a payments, **When** it is March 1st, **Then** the device shows: "Gam3a payments due: 13,000 EGP across 2 clubs this month."

### Functional Requirements
- **FR-001**: After every successful `GET /api/simulate` call, `CacheService` MUST write the raw JSON string and the current `DateTime.now().toIso8601String()` to `SharedPreferences`.
- **FR-002**: On app start, `simulationProvider` MUST first attempt a live API call; on `DioException`, fall back to `CacheService.readSimulation()` and set a `isOffline: true` flag in state.
- **FR-003**: The offline banner MUST be a `MaterialBanner` rendered at the top of the `Dashboard` screen; it MUST display the last-updated timestamp from the cache.
- **FR-004**: All write-path provider methods (add, edit, delete, log actuals) MUST check `ConnectivityResult` before making a Dio call; if offline, throw an `OfflineException` that the UI catches and shows as a `SnackBar`.
- **FR-005**: After each simulation fetch on mobile (`!kIsWeb`), `NotificationService` MUST cancel all previously scheduled notifications and reschedule them from the new simulation data.
- **FR-006**: Payout notifications MUST be scheduled for `28th of the month prior to each payout month` at `09:00` local time.
- **FR-007**: Payment notifications MUST be scheduled for the `1st of each month with payments > 0` at `09:00` local time.
- **FR-008**: `flutter_local_notifications` initialization MUST request permissions on iOS via `requestPermissions` and on Android via the notification channel setup.

### Success Criteria
- **SC-001**: Dashboard renders cached data within 1 second on iOS and Android when the device is in airplane mode.
- **SC-002**: Payout and payment notifications fire within 1 minute of their scheduled time in an emulator test.
- **SC-003**: Zero `flutter analyze` warnings introduced in this phase.

---

## 10. Out of Scope (All Phases)

The following will not be built unless a new Spec Kit spec is written and approved:

| Item | Reason deferred |
|------|----------------|
| Real-time sync (WebSockets) | Complexity not justified for a personal finance app |
| Bank statement import | Requires third-party integration outside project scope |
| Multi-currency support | App is EGP-only by design |
| Shared group gam3a tracking (all members) | Out of scope per original PRD |
| Multi-year simulation | Deferred to a future spec |
| Desktop targets (macOS, Windows, Linux) | Web target covers desktop use cases |
| Dark/light theme toggle | Dark theme only — matches the web app |
| E2E automated testing (Appium / Patrol) | Deferred post-MVP |
