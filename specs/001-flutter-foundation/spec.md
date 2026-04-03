# Feature Specification: Flutter Foundation & Navigation

**Feature Branch**: `001-flutter-foundation`
**Created**: 2026-03-31
**Status**: Draft
**Plan reference**: `planmobile.md` § Flutter Phase F1

## Clarifications

### Session 2026-03-31

- Q: Does Phase F1 include caching the simulation result locally for offline reads, or is caching deferred to a later phase? → A: Include — wire `CacheService` now so all subsequent phases can use it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Live Simulation on Any Device (Priority: P1)

A user opens the app on web, iOS, or Android and immediately sees the 12-month
Gam3ya simulation data fetched from the live Django backend. The dashboard displays
monthly cash-flow rows and summary KPI totals without any manual action required.
The result is immediately written to local storage so subsequent launches can show
cached data while a fresh fetch is in progress.

**Why this priority**: This is the core proof-of-life for the entire Flutter client.
Without live data rendering and a shared cache layer, no subsequent phase can be
validated end-to-end.

**Independent Test**: Open the app while the Django backend is running locally.
The dashboard must show 12 rows of monthly data and 5 KPI values within 2 seconds,
with no manual interaction beyond launching the app. Stop the backend, close and
reopen the app — cached data must appear immediately.

**Acceptance Scenarios**:

1. **Given** the Django backend is running, **When** the Dashboard screen loads,
   **Then** all 12 monthly rows and 5 KPI totals render within 2 seconds.
2. **Given** a successful fetch completes, **When** the data is rendered,
   **Then** the result is persisted to local storage before the next user interaction.
3. **Given** the backend is unreachable and no cached data exists, **When** the
   Dashboard attempts to fetch data, **Then** an error message and a "Retry" button
   appear and no partial or stale data is shown.
4. **Given** the backend is unreachable but cached data exists, **When** the
   Dashboard loads, **Then** the cached simulation result is displayed with a
   visible stale-data indicator.
5. **Given** a network request is in-flight, **When** the Dashboard is visible,
   **Then** a loading indicator appears and no partial data or layout shift occurs.
6. **Given** the simulation returns all-zero values (no gam3as configured),
   **When** the Dashboard renders, **Then** zero values display gracefully with no
   layout overflow or missing widget errors.

---

### User Story 2 - Navigate Between Main Sections (Priority: P2)

A user navigates between the three main sections of the app (Dashboard, Gam3as list,
Scenario simulator) using platform-appropriate navigation controls that adapt to
screen size.

**Why this priority**: Navigation shell is required before any feature screen can be
accessed. It is a prerequisite for all subsequent phases but is not the primary value
of this phase on its own.

**Independent Test**: On a narrow screen (mobile), tap each bottom navigation item
and confirm the correct screen appears. On a wide screen (web/tablet), click each
navigation rail item and confirm the active item is highlighted.

**Acceptance Scenarios**:

1. **Given** the app runs on a screen narrower than 600px, **When** a bottom
   navigation item is tapped, **Then** the corresponding screen renders smoothly
   and the selected item is visually highlighted.
2. **Given** the app runs on a screen 600px wide or wider, **When** a navigation
   rail item is clicked, **Then** the corresponding screen renders and the item
   shows an active selected state.
3. **Given** the user is on any screen, **When** they navigate away and return
   within the same session, **Then** the previous screen state is preserved without
   triggering a new network request.

---

### Edge Cases

- What happens when the backend returns a malformed JSON response?
  The app must show the same error widget as an unreachable backend — it must not crash.
- How does the app behave when screen width changes mid-session (e.g., browser resize)?
  The navigation component must switch between rail and bottom bar without requiring
  an app restart or losing current navigation state.
- What happens if the build-time API URL variable is not provided?
  The app must surface a clear configuration error at startup rather than silently
  attempting to call an undefined URL.
- What happens if local storage is corrupt or unreadable?
  The app must discard the cached value, treat the state as empty, and attempt a
  live fetch without crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The API base URL MUST be sourced exclusively from the `API_BASE_URL`
  build-time configuration variable. No URL string MUST be hardcoded anywhere in
  the application source code.

- **FR-002**: The HTTP client MUST enforce a 10-second connection timeout and a
  30-second receive timeout on all API calls. Requests exceeding these limits MUST
  result in an observable error state, not an indefinite hang.

- **FR-003**: The app MUST render an adaptive navigation shell: a bottom navigation
  bar on screens narrower than 600 logical pixels, and a navigation rail on screens
  600 logical pixels wide or wider.

- **FR-004**: The entire widget tree MUST be wrapped in a dependency injection
  scope at the application root. All state MUST flow through asynchronous providers
  that expose distinct loading, success, and error states.

- **FR-005**: The simulation data models (SimulationResult, MonthlyRow, Kpis) MUST
  be immutable, fully null-safe, and support round-trip JSON serialization without
  data loss or type coercion errors.

- **FR-006**: All color values used in the UI MUST reference named design tokens
  defined in a single constants file. No inline color literals MUST appear in
  widget code.

- **FR-007**: The project MUST pass static analysis with zero warnings or errors
  on the initial commit and on every subsequent commit within this phase.

- **FR-008**: The three main navigation destinations MUST be: Dashboard (simulation
  overview), Gam3as (club list — stub screen in this phase), and Scenario
  (what-if simulator — stub screen in this phase).

- **FR-009**: `CacheService` MUST be implemented in Phase F1 and MUST provide
  read and write operations for the simulation result using local device storage.
  Every successful API response MUST be written to cache before returning to the
  caller. On API failure, `CacheService` MUST return the last successfully cached
  value (or null if none exists). All subsequent phases MUST use this shared
  `CacheService` for any local persistence needs.

- **FR-010**: When displaying cached data due to a failed fetch, the Dashboard MUST
  show a visible indicator that the data may not reflect the latest server state.

### Key Entities

- **SimulationResult**: Top-level API response containing a list of 12 MonthlyRow
  entries and one Kpis summary object.
- **MonthlyRow**: One month's cash-flow snapshot — month number, name, opening
  balance, inflow, interest, payments out, closing balance, cumulative invested,
  cumulative interest, payout flag, and list of payout gam3a names.
- **Kpis**: Year-end aggregates — total invested, total interest earned, total
  payments made, final account balance, and effective yield as a percentage.
- **AppColors**: Named design-token set covering background, surface, accent,
  positive (green), negative (red), payout (amber), primary text, and secondary text.
- **CacheService**: Shared local-storage abstraction that reads and writes
  serialized `SimulationResult` JSON to device-local persistent storage. Used by
  all phases that require local data persistence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Simulation data renders within 2 seconds of app launch on all three
  platforms (web, Android emulator, iOS simulator) over a local network connection.

- **SC-002**: Automated provider tests covering loading, success, error, and
  cached-fallback states for the simulation data provider pass on every run with
  no flakiness.

- **SC-003**: The app launches without runtime errors or exceptions on all three
  target platforms using the same unmodified Dart codebase.

- **SC-004**: Navigation between all three main sections completes without a
  visible frame drop or layout flash on any target platform.

- **SC-005**: Static analysis reports zero issues against the full project codebase
  at the end of this phase.

- **SC-006**: When the backend is unreachable and a prior result is cached, the
  cached data renders within 500ms of app launch with the stale-data indicator
  visible.

## Assumptions

- The Django backend (Phase B1) is already running and reachable at the URL provided
  via the build-time configuration variable during local development.
- The developer environment has the Flutter SDK, Android emulator, and iOS simulator
  (or Xcode) installed and functional before this phase begins.
- The Scenario and Gam3as navigation destinations in this phase are intentional stubs;
  full functionality is delivered in Phases F2 and F4 respectively.
- Design token color values are defined and fixed per `planmobile.md` § 3.7 and do
  not require end-user configuration or runtime theming support.
- No user authentication is required in this phase; all API requests are unauthenticated,
  matching the current B1 backend configuration.
- The simulation always covers exactly 12 calendar months for the configured year;
  no partial-year or multi-year simulation is in scope for this phase.
- `CacheService` uses `SharedPreferences` as its storage backend, which is available
  on all three target platforms (web, iOS, Android) without additional native setup.
