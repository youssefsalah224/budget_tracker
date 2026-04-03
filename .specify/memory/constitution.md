<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0 (initial ratification from blank template)

Modified principles:
  - [PRINCIPLE_1_NAME] → I. Cross-Platform First
  - [PRINCIPLE_2_NAME] → II. API-Driven Architecture
  - [PRINCIPLE_3_NAME] → III. Feature-Module Structure
  - [PRINCIPLE_4_NAME] → IV. Financial Accuracy (NON-NEGOTIABLE)
  - [PRINCIPLE_5_NAME] → V. Test Coverage

Added sections:
  - Technology Stack (replaces [SECTION_2_NAME])
  - Development Workflow (replaces [SECTION_3_NAME])

Removed sections: none

Templates reviewed:
  - ✅ .specify/templates/plan-template.md — Constitution Check gate aligns with principles
  - ✅ .specify/templates/spec-template.md — FR/SC structure compatible with new principles
  - ✅ .specify/templates/tasks-template.md — Phase structure compatible (Mobile path applies)

Deferred TODOs:
  - TODO(RATIFICATION_DATE): Set to 2026-03-31 (first authoring date; adjust if project predates this)
-->

# Gam3ya Investment Simulator Constitution

## Core Principles

### I. Cross-Platform First

The Flutter client MUST target iOS, Android, and Web from a single Dart codebase.
No platform-specific forks or divergent UI trees are permitted.
Platform-adaptive widgets (e.g., `CupertinoWidget` vs `MaterialWidget`) MAY be used
only where OS conventions demand it; business logic MUST remain platform-agnostic.
Third-party packages MUST support all three targets before adoption; packages that
drop web or a mobile platform require explicit justification in the Complexity Tracking
table of the relevant plan.

**Rationale**: A single codebase eliminates drift between platforms, reduces maintenance
cost, and ensures consistent Gam3ya simulation behaviour regardless of device.

### II. API-Driven Architecture

The Flutter client MUST communicate with the Django REST backend exclusively via
versioned HTTP/JSON endpoints. No direct database access, embedded SQL, or shared
in-process calls are permitted in the client.

- API contracts MUST be documented in `specs/###-feature/contracts/` before
  implementation begins.
- The backend MUST version all breaking endpoint changes (`/api/v1/`, `/api/v2/`).
- The client MUST implement a repository layer that abstracts HTTP calls from
  UI widgets and business logic.

**Rationale**: Clean separation lets the backend (Django) and client (Flutter) evolve
and be tested independently. It also enables future third-party clients.

### III. Feature-Module Structure

Code MUST be organised by feature, not by technical layer.

```
lib/
  features/
    gam3ya/        # Gam3a CRUD and listing
    simulation/    # Investment projection engine
    auth/          # Login / registration
    dashboard/     # Summary screen
  core/            # Shared utilities, theme, networking, routing
```

Each feature module MUST expose its own router/navigator and MUST NOT import
directly from another feature's internal files. Cross-feature communication MUST
go through `core/` services or a shared state management layer.

**Rationale**: Feature isolation prevents coupling, makes parallel development safe,
and allows individual features to be shipped, tested, or removed independently.

### IV. Financial Accuracy (NON-NEGOTIABLE)

All monetary values MUST be stored and transmitted as integers (smallest currency unit,
e.g., piastres for EGP) or as `Decimal` (Python) / `int`-backed types (Dart). Floating-
point arithmetic (`double`, `float`) MUST NOT be used for currency storage, database
columns, or API payloads.

Gam3ya simulation calculations (payout schedule, compound-interest projection) MUST
produce deterministic results: identical inputs MUST always yield identical outputs
regardless of platform or execution order.

**Rationale**: Financial miscalculations erode user trust and can produce legally
significant errors. IEEE 754 floating-point is not suitable for monetary arithmetic.

### V. Test Coverage

- **Flutter client**: Widget tests MUST cover every screen's happy path.
  Integration tests (using `flutter_test` / `integration_test`) MUST cover the
  end-to-end Gam3a creation and simulation flow.
- **Django backend**: Unit tests MUST cover all service-layer functions.
  API endpoint tests (using DRF's `APITestCase`) MUST cover all contract endpoints.
- Tests MUST be written before implementation (TDD) for all financial calculation
  logic (Principle IV).
- CI MUST block merges when any test suite is failing.

**Rationale**: Cross-platform apps have more failure surfaces than single-platform
ones. Automated coverage is the only scalable guard against regressions across
iOS, Android, and Web.

## Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Client language | Dart | 3.x |
| Client framework | Flutter | 3.x |
| Backend language | Python | 3.12 |
| Backend framework | Django + DRF | 4.2+ |
| Database | SQLite (dev) / PostgreSQL (prod) | — |
| AI integration | Anthropic Claude | `claude-sonnet-4-6` |
| State management | Riverpod or BLoC | latest stable |
| HTTP client | `dio` or `http` package | latest stable |

Technology additions or upgrades that affect more than one layer MUST be
recorded in a plan's Complexity Tracking table and approved before adoption.

## Development Workflow

1. **Spec first**: Every feature begins with `/speckit.specify` → `spec.md`.
2. **Plan before code**: `/speckit.plan` produces `plan.md` + `contracts/` before
   any implementation task is written.
3. **Tasks gate implementation**: `/speckit.tasks` generates `tasks.md`; no code
   is written outside a tracked task.
4. **Constitution Check in every plan**: The `## Constitution Check` section of
   `plan.md` MUST explicitly verify compliance with Principles I–V before
   Phase 0 research begins.
5. **Incremental delivery**: Each user story MUST be independently deployable and
   demoed before the next story begins.
6. **Commit granularity**: One logical task per commit; commit message MUST
   reference the task ID (e.g., `feat(gam3ya): T012 implement Gam3a model`).

## Governance

This constitution supersedes all other development conventions in this repository.
Any practice that conflicts with Principles I–V is non-compliant and MUST be
remediated before the next release.

**Amendment procedure**:
1. Author a pull request that modifies this file.
2. Bump `CONSTITUTION_VERSION` following semver rules documented in the
   Sync Impact Report header.
3. Update `LAST_AMENDED_DATE` to the PR merge date.
4. Re-run `/speckit.constitution` to propagate changes to all templates.
5. All open `plan.md` files MUST re-run their Constitution Check section.

**Versioning policy**:
- MAJOR — principle removal or backward-incompatible redefinition.
- MINOR — new principle or section added.
- PATCH — wording clarification, typo fix, non-semantic refinement.

**Compliance review**: Every plan's Constitution Check gate serves as the
per-feature compliance review. A quarterly repository-wide review SHOULD
audit all active specs against the current constitution version.

**Version**: 1.0.0 | **Ratified**: 2026-03-31 | **Last Amended**: 2026-03-31
