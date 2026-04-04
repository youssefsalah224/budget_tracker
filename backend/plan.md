# Gam3ya Investment Simulator — Project Plan

## Summary

A personal finance dashboard for tracking and simulating Egyptian rotating savings clubs (Gam3as).
The user logs their gam3as (rotating savings groups), and the app simulates depositing each payout
into a compounding investment fund — projecting monthly balances, interest earned, and cash flows
across a 12-month period. An embedded AI advisor (Claude) answers financial questions in Arabic or English.

The project is built in phases, each delivered as a Spec Kit spec. Phase 1 is complete.
Each subsequent phase builds on the previous one and is scoped to be independently deliverable.

**Stack:** Django · Django REST Framework · SQLite · Anthropic Claude API · Vanilla JS + Chart.js

**Full data + business logic specification:** See `PRD.md`

---

## Execution Plan

| Phase | Name | Status | Key Deliverable |
|-------|------|--------|-----------------|
| 1 | Core Foundation | ✅ Complete | Full working app matching PRD |
| 2 | Monthly Overrides UI | 🔲 Next | UI to manage simulation overrides |
| 3 | Actuals Tracking | 🔲 Planned | Log real numbers vs projected |
| 4 | Multi-year Support | 🔲 Planned | Year switching + carry-over balance |
| 5 | Authentication & Multi-user | 🔲 Planned | Login, isolated data per user |
| 6 | Export & Reminders | 🔲 Planned | PDF/CSV export + in-app monthly alerts |

### Delivery approach
Each phase from Phase 2 onward will be written as a **Spec Kit spec** before any code is written.
The spec defines the problem, goals, data model changes, API changes, and UI changes in detail.
Code is only written after the spec is reviewed and approved.

---

## Phase 1 — Core Foundation ✅ COMPLETE

Everything defined in the PRD has been implemented.

### What was built
- **Models:** `Gam3a`, `SimulationSettings`, `MonthlyOverride`
- **REST API endpoints:**
  - `GET/POST /api/gam3as` — list and create gam3as
  - `PUT/DELETE /api/gam3as/{id}` — update and delete gam3as
  - `GET/PUT /api/settings` — simulation settings
  - `GET /api/simulate` — run full 12-month simulation
  - `POST /api/simulate/scenario` — run one-off scenario without saving
  - `POST /api/chat` — AI financial advisor (Claude, bilingual Arabic/English)
- **Simulation engine:** compound interest with partial-month logic, monthly overrides support
- **Frontend:** single-file vanilla HTML/CSS/JS with Chart.js
  - Sidebar: Fund Settings + Gam3a Manager (add/edit/delete)
  - Dashboard tab: KPI cards + multi-line chart + monthly breakdown table
  - Scenario tab: custom rate/day/extra inflows + results
  - AI Chat drawer: bilingual (Arabic/English), suggestion chips, typing indicator
- **Seed data:** 4 real gam3as + Month 1 override (Gam3a #4 payout suppression)

---

## Phase 2 — Monthly Overrides UI

### Problem
The `MonthlyOverride` model exists in the backend and directly affects simulation results,
but there is no UI to manage overrides. They can only be set via the seed command or Django admin.

### Goals
- Allow the user to create, edit, and delete monthly overrides directly from the app
- Reflect override changes in the simulation instantly without a page reload

### Scope
- **Backend:** `GET/POST /api/overrides` and `PUT/DELETE /api/overrides/{month}` endpoints
- **Frontend — Sidebar section "Monthly Overrides":**
  - List all existing overrides (month, custom inflow, custom payment, note)
  - Inline add form: month dropdown, custom inflow input, custom payment input, note text
  - Edit and delete buttons per override row
  - Saving an override triggers a re-fetch of the simulation

### Out of scope
- Bulk import of overrides
- Override history / audit log

---

## Phase 3 — Actuals Tracking

### Problem
The app is 100% simulation/projection. There is no way to record what actually happened
month by month — actual deposits, actual payments made, real interest received.

### Goals
- Track real numbers alongside projected numbers
- Show a running actual balance vs simulated balance on the dashboard

### Scope
- **New model:** `MonthlyActual` — fields: month, actual_inflow, actual_payment, actual_interest, note
- **Backend:** CRUD endpoints for actuals (`/api/actuals`)
- **Frontend — Dashboard:**
  - "Mark Month" button per row in the monthly table to log actuals
  - New chart line: Actual Closing Balance (dashed, contrasted against projected)
  - KPI cards show actual totals when at least one month has been logged
- **Frontend — Sidebar:** "Actuals" section listing logged months with edit capability

### Out of scope
- Importing actuals from bank statements
- Reconciliation workflow

---

## Phase 4 — Multi-year Support

### Problem
The `year` field exists in `SimulationSettings` but the entire app is hardcoded to
12 months of a single year. Gam3as cannot span year boundaries and there is no carry-over balance.

### Goals
- Support switching between years
- Carry the December closing balance of year N as the January opening balance of year N+1
- Allow gam3as to span year boundaries

### Scope
- **Model changes:** `Gam3a` gains a `year` field (or date-based start/end instead of month integers)
- **SimulationSettings:** `year` field becomes the active year selector
- **Backend:** simulation engine handles carry-over balance from previous year's final record
- **Frontend:**
  - Year selector in Fund Settings sidebar section
  - Dashboard header shows the active year
  - Navigation arrows (← 2025 | 2026 | 2027 →) to switch years

### Out of scope
- Multi-decade projections
- Inflation adjustments

---

## Phase 5 — Authentication & Multi-user

### Problem
The app is fully single-user with no login. All data is shared — anyone with the URL
can see and modify the gam3as and settings.

### Goals
- Each user has their own isolated data (gam3as, settings, overrides, actuals)
- Secure login and session management

### Scope
- **Django auth:** built-in `User` model, login/logout/register views
- **Model changes:** `Gam3a`, `SimulationSettings`, `MonthlyOverride`, `MonthlyActual` all gain a
  `user` ForeignKey; all queries are scoped to `request.user`
- **API:** session-based auth (or JWT via `djangorestframework-simplejwt`)
- **Frontend:**
  - Login / register page (replaces the main app when not authenticated)
  - User avatar / logout button in sidebar header
  - No data leakage between users

### Out of scope
- OAuth / social login
- Admin panel for managing users (Django admin covers this)
- Password reset via email (can be added as a minor addition)

---

## Phase 6 — Export & Reminders

### Problem
There is no way to share or archive simulation results, and no proactive alerts
when a payout or payment month is approaching.

### Goals
- Let the user export their data for sharing or record-keeping
- Remind the user when action is needed (pay into a gam3a, expect a payout)

### Scope

#### Export
- **PDF export:** simulation table + KPI cards formatted as a one-page report
  (using `weasyprint` or `reportlab` on the backend; triggered via `GET /api/export/pdf`)
- **CSV export:** monthly simulation rows as a downloadable `.csv`
  (triggered via `GET /api/export/csv`)
- **Frontend:** Export dropdown button in the Dashboard toolbar

#### Reminders
- **Backend:** a management command (or Django-Q task) that checks the current month
  and sends a notification if a payout or payment is due
- **Frontend:** in-app banner at the top of the dashboard for the current month's actions
  ("You are expecting an 80,000 EGP payout this month" / "3 payments due this month: 16,500 EGP")

### Out of scope
- Email notifications (requires SMTP config — optional add-on)
- Push notifications (requires service worker)
- Slack / WhatsApp integration

---

## Deferred (Out of Scope for All Phases)

These items are explicitly excluded and should not be added without a new spec:

- Real-time updates (WebSockets)
- Mobile app (iOS / Android)
- External bank API integrations
- Multi-currency support
- Inflation-adjusted projections
- Shared gam3a groups (tracking all members, not just the user)
