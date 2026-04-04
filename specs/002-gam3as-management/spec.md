# Feature Specification: Gam3as Management

**Feature Branch**: `002-gam3as-management`
**Created**: 2026-04-04
**Status**: Draft
**Input**: User description: "Gam3as Management — users can view, add, edit and delete their Gam3as from the Flutter app, with live sync to the Django backend"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — View All Gam3as (Priority: P1)

A user opens the Gam3as section and immediately sees a list of all their registered Gam3as. Each card shows the name, monthly contribution, payout month, and whether the payout has been received. If no gam3as exist yet, a friendly empty state prompts the user to add their first one.

**Why this priority**: Without visibility into their gam3as the user cannot verify whether the simulation uses correct data. This is the essential read path that all other stories depend on.

**Independent Test**: Navigate to the Gam3as tab — a list of all registered gam3as (or an empty-state message) must appear within 2 seconds with no additional interaction.

**Acceptance Scenarios**:

1. **Given** the backend has 4 gam3as, **When** the user opens the Gam3as screen, **Then** 4 cards are displayed, each showing name, contribution, and payout month.
2. **Given** the backend has no gam3as, **When** the user opens the Gam3as screen, **Then** an empty state message and an "Add Gam3a" call-to-action are shown.
3. **Given** the user is on the Gam3as screen, **When** the backend is unreachable, **Then** previously cached gam3as remain visible with a stale banner; if no cache exists, an error message with a "Retry" button is shown.

---

### User Story 2 — Add a New Gam3a (Priority: P1)

A user taps "Add Gam3a", fills in a form (name, total pot, monthly contribution, payout month, start month, end month), and saves. The new gam3a appears immediately in the list and the Dashboard simulation refreshes automatically.

**Why this priority**: Adding gam3as is the primary write action — without it the list is read-only and users cannot set up their financial picture.

**Independent Test**: Add a gam3a named "Test" with pot 10,000, contribution 1,000, payout month 6, start month 1, end month 10 — it must appear in the list immediately after saving, and the Dashboard must reflect updated totals.

**Acceptance Scenarios**:

1. **Given** the user taps "Add Gam3a" and fills all required fields, **When** they tap "Save", **Then** the gam3a is created, appears in the list, and the dashboard simulation is refreshed.
2. **Given** the user leaves a required field empty, **When** they tap "Save", **Then** an inline validation error appears and no API call is made.
3. **Given** a month field contains a value outside 1–12, or start month > end month, **When** the user taps "Save", **Then** a validation error is shown and submission is blocked.
4. **Given** the backend returns an error on submit, **Then** an error message is shown and the form remains open with previously entered values intact.

---

### User Story 3 — Edit an Existing Gam3a (Priority: P2)

A user taps "Edit" on a gam3a card, modifies one or more fields in the same form used for adding, and saves. The updated values appear immediately in the list and the Dashboard simulation refreshes.

**Why this priority**: Real-world gam3as change — users may correct a payout month, update the pot amount, or mark the payout as received. This closes the data-accuracy loop.

**Independent Test**: Edit Gam3a #3 — change payout month from 5 to 6, save, confirm the card shows month 6 and the Dashboard totals change.

**Acceptance Scenarios**:

1. **Given** the user taps "Edit" on a card, **When** the form opens, **Then** all current values are pre-populated.
2. **Given** the user modifies fields and taps "Save", **Then** the backend is updated, the card reflects new values, and the simulation is refreshed.
3. **Given** the user taps "Cancel" or navigates back without saving, **Then** no API call is made and original values are preserved.

---

### User Story 4 — Delete a Gam3a (Priority: P2)

A user taps "Delete" on a gam3a card and confirms in a dialog. The gam3a is removed from the list and the Dashboard simulation refreshes to exclude it.

**Why this priority**: Users need to remove completed or incorrectly entered gam3as to keep the simulation accurate. A confirmation step prevents accidental deletion.

**Independent Test**: Delete Gam3a #1 — confirm — it must disappear from the list and the Dashboard must no longer include its payout in the simulation.

**Acceptance Scenarios**:

1. **Given** the user initiates delete and confirms the dialog, **Then** the gam3a is deleted from the backend and removed from the list.
2. **Given** the confirmation dialog is shown, **When** the user taps "Cancel", **Then** no deletion occurs and the gam3a remains.
3. **Given** the backend returns an error on delete, **Then** an error message is shown and the gam3a remains in the list.

---

### Edge Cases

- What happens when the user double-taps "Save"? → The Save button is disabled immediately after the first tap until the request resolves, preventing duplicate submissions.
- What happens when `payout_month` falls outside the `start_month`–`end_month` range? → The form shows a warning but does not block submission (the backend accepts this; it represents a payout that happened outside the contribution window).
- What happens when the list has 20+ gam3as? → The list is scrollable; all cards remain tappable with no layout overflow.
- What happens when `payout_received` is true on an existing gam3a? → The card shows a "Received" badge and the edit form includes a toggle to change this flag.
- What happens when the add/edit form is submitted but the network drops mid-request? → The error state is shown and the form data is not lost.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST fetch and display a scrollable list of all gam3as from the backend, sorted by payout month ascending.
- **FR-002**: Each gam3a card MUST show: name, total pot (formatted as EGP), monthly contribution (formatted as EGP), payout month name, start–end month range, and a "Received" badge when the payout has been collected.
- **FR-003**: The list MUST display an empty-state message and a prominent "Add Gam3a" button when no gam3as exist.
- **FR-004**: The app MUST provide a form for creating a new gam3a. Required inputs: name, total pot, monthly contribution, payout month, start month, end month. Optional toggle: payout received (defaults to false).
- **FR-005**: The app MUST reuse the same form for editing an existing gam3a, pre-populated with the current values.
- **FR-006**: The form MUST validate before submission: name non-empty, all numeric fields greater than zero, all month fields in range 1–12, start month ≤ end month. Errors must be shown inline next to the relevant field.
- **FR-007**: After a successful create or update, the app MUST refresh both the gam3as list and the Dashboard simulation data.
- **FR-008**: The app MUST allow deleting a gam3a after the user confirms in a dialog. After deletion the list and simulation must refresh.
- **FR-009**: All monetary values MUST be displayed as `EGP N,NNN.00` using the same formatting convention as the Dashboard.
- **FR-010**: The list MUST show a loading indicator on first load and a stale-cache banner when displaying cached data due to a network failure.
- **FR-011**: All colors MUST use `AppColors.*` tokens — no inline hex values in widget files.

### Key Entities

- **Gam3a**: A rotating savings club entry. Attributes: name (text label), total pot (lump sum received by the user in their payout month), monthly contribution (amount paid each month during active months), payout month (1–12), start month (1–12, first month of contribution), end month (1–12, last month of contribution), payout received (whether the user has already collected the pot), active (whether the gam3a is included in simulation).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The gam3a list loads and displays within 2 seconds of opening the Gam3as tab when the backend is running.
- **SC-002**: A user can complete adding a new gam3a (open form → fill fields → save) in under 60 seconds on first use.
- **SC-003**: After any create, edit, or delete action, the Dashboard simulation updates within 1 second without requiring the user to manually navigate away and back.
- **SC-004**: Form validation prevents all invalid submissions — no record with an empty name, zero amounts, or out-of-range months reaches the backend.
- **SC-005**: `flutter analyze` reports zero issues after all Phase F2 code is merged.
- **SC-006**: All new providers and widgets have at least one passing unit or widget test covering the success path and the error/empty path.

## Assumptions

- The Django backend B1 Gam3a CRUD endpoints (`GET/POST /api/gam3as`, `PUT/DELETE /api/gam3as/{id}`) are already running and return the correct JSON schema — no backend changes are required for this phase.
- Authentication is out of scope for this phase (deferred to Phase F7); the API is unauthenticated.
- Monetary inputs are entered by the user in EGP as decimal numbers; the app converts to integer piastres internally for consistency with existing display logic.
- The `active` field on a Gam3a defaults to `true` on creation and is not exposed in the form — deactivating a gam3a is out of scope for this phase.
- Pagination is not required; the number of gam3as per user is expected to be under 50.
- The existing `SimulationNotifier` from Phase F1 is invalidated after any mutation to trigger a dashboard refresh — no new simulation logic is introduced in this phase.
- The add and edit flows share a single form screen, distinguished by whether a gam3a ID is passed as a route parameter.
