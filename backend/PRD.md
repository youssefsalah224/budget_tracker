# Product Requirements Document
# Gm3ya Investment Simulator

**Version:** 1.0
**Date:** 2026-03-25
**Purpose:** Full specification to rebuild this application in any tech stack.

---

## 1. Overview

A personal finance dashboard that simulates investing **Gam3ya** (Egyptian rotating savings club) payouts into a compounding monthly investment fund. Tracks real cash flows (contributions owed, payouts received) across a 12-month period and projects fund growth with compound interest.

### What is a Gam3ya?
A Gam3ya is an informal rotating savings club common in Egypt. A group of N members each contribute a fixed amount every month. Each month, one member receives the total pot (N × monthly contribution). The user may be at any position in the rotation — they receive once and owe contributions in all other months they are active.

---

## 2. Core Concepts & Business Logic

### 2.1 Gam3a Payment Windows

Each Gam3a has:
- A **start month** — the first month the user owes a contribution in 2026
- An **end month** — the last month the user owes a contribution in 2026
- A **payout month** — the single month when the user receives the full pot

The user owes `monthly_contribution` EGP in every month from `start_month` to `end_month`, inclusive. The payout is a one-time inflow in `payout_month` (which may or may not fall within the start–end window; that is user-specific).

**Example data from real spreadsheet:**

| Gam3a | Pot (EGP) | Monthly (EGP) | Payout Month | Start Month | End Month | Received? |
|-------|-----------|---------------|-------------|------------|----------|----------|
| #1 | 18,000 | 3,000 | March (3) | April (4) | May (5) | Yes |
| #2 | 21,000 | 3,500 | April (4) | April (4) | June (6) | Yes |
| #3 | 80,000 | 10,000 | May (5) | March (3) | August (8) | No |
| #4 | 30,000 | 3,000 | January (1) | March (3) | December (12) | Yes |

### 2.2 Monthly Cash Flow Calculation

For each month (1–12), the simulator computes:

```
inflow        = sum of total_pot for all Gam3as whose payout_month == this month
payments_out  = sum of monthly_contribution for all Gam3as where start_month ≤ month ≤ end_month
```

**Interest formula (partial-month for new deposits):**
```
monthly_rate  = annual_rate / 12
day_ratio     = (31 - investment_day) / 31

pos_opening   = max(0, opening_balance)   ← no negative-balance interest
available     = pos_opening + inflow

if available <= 0:
    interest = 0
else:
    interest = (pos_opening × monthly_rate) + (inflow × monthly_rate × day_ratio)

closing_balance = opening_balance + inflow + interest - payments_out
```

**Key rules:**
- Interest is NEVER earned on negative balances
- Interest is zero when `available ≤ 0`
- Inflows earn partial-month interest based on investment day (e.g., day 20 → only 11/31 of the month left)

### 2.3 Cumulative Tracking

```
cumul_invested  += inflow (each month)
cumul_interest  += interest (each month)
total_payments  += payments_out (each month)
```

### 2.4 KPIs

```
total_invested     = cumul_invested at month 12
total_interest     = cumul_interest at month 12
total_payments_out = sum of all payments_out
final_balance      = closing_balance at month 12
effective_yield    = (total_interest / total_invested) × 100   [%]
```

### 2.5 Special Case: Gam3a #4 (Payout Already Received Before Fund Started)

Gam3a #4's payout was in January but was **not deposited into the investment fund** (received before the fund tracking period). Its January inflow must be forced to 0 via a monthly override. All other Gam3as with `payout_received = True` have their payouts included as inflows (they received within the tracked period).

---

## 3. Data Models

### 3.1 Gam3a

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| id | integer (PK) | auto | |
| name | string | required | e.g. "Gam3a #1" |
| total_pot | float | required | Full payout amount (EGP) |
| monthly_contribution | float | required | Amount owed per active month (EGP) |
| payout_month | integer 1–12 | required | Month user receives the pot |
| payout_received | boolean | false | Whether payout has been received |
| start_month | integer 1–12 | 1 | First month contributions are due |
| end_month | integer 1–12 | 12 | Last month contributions are due |
| active | boolean | true | Include in simulation |
| created_at | datetime | now | |

### 3.2 SimulationSettings

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| id | integer (PK) | auto | |
| annual_rate | float | 19.0 | Annual interest rate (%) |
| investment_day | integer | 20 | Day of month payouts are deposited |
| year | integer | 2026 | Simulation year |

### 3.3 MonthlyOverride

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| id | integer (PK) | auto | |
| month | integer 1–12 | required | Which month to override |
| custom_inflow | float | null | Force inflow to this value (null = use calculated) |
| custom_payment | float | null | Force payments to this value (null = use calculated) |
| note | string | null | Explanation |

**Seed override:** Month 1, custom_inflow = 0.0 (suppresses Gam3a #4's January payout from the fund)

---

## 4. API Specification

All endpoints return JSON. Base path: `/api`

### 4.1 Gam3a CRUD

| Method | Path | Request Body | Response |
|--------|------|-------------|----------|
| GET | /gam3as | — | Array of Gam3a objects |
| POST | /gam3as | Gam3a fields | Created Gam3a |
| PUT | /gam3as/{id} | Gam3a fields | Updated Gam3a |
| DELETE | /gam3as/{id} | — | `{ "ok": true }` |

### 4.2 Settings

| Method | Path | Request Body | Response |
|--------|------|-------------|----------|
| GET | /settings | — | SimulationSettings object |
| PUT | /settings | `{ annual_rate, investment_day, year }` | Updated settings |

### 4.3 Simulation

**GET /simulate** — Run full 12-month simulation using DB data. Returns:
```json
{
  "rows": [
    {
      "month": 1,
      "month_name": "January",
      "opening_balance": 0.0,
      "inflow": 0.0,
      "interest": 0.0,
      "payments_out": 0.0,
      "closing_balance": 0.0,
      "cumul_invested": 0.0,
      "cumul_interest": 0.0,
      "is_payout_month": false,
      "payout_gam3as": []
    }
    // ... 12 rows total
  ],
  "kpis": {
    "total_invested": 119000.0,
    "total_interest": 4920.38,
    "total_payments_out": 106500.0,
    "final_balance": 17420.38,
    "effective_yield": 4.13
  }
}
```

**POST /simulate/scenario** — Run one-off simulation without saving. Request body:
```json
{
  "annual_rate": 22.0,         // optional, overrides settings
  "investment_day": 15,        // optional, overrides settings
  "extra_inflows": { "3": 5000, "6": 10000 }  // optional, month → extra EGP
}
```
Returns same structure as GET /simulate.

### 4.4 AI Chat

**POST /chat** — Send message to Claude AI with full simulation context. Request:
```json
{
  "message": "Which month will my balance peak?",
  "history": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
```
Response:
```json
{ "reply": "Your balance peaks in May at 67,857 EGP..." }
```

---

## 5. AI Chat System Prompt Template

Built dynamically on each chat request. Inject full simulation data so Claude can answer quantitative questions accurately:

```
You are a personal finance advisor embedded in an investment tracking app.
The user is managing rotating savings clubs (Gam3as) and investing the payouts
into a compounding fund. Here is their current financial data:

SETTINGS:
- Annual interest rate: {rate}%
- Investment day: {day}th of each month
- Year: 2026

ACTIVE GAM3AS:
{json array of all gam3as with all fields}

12-MONTH SIMULATION:
{json array of monthly rows: month, month_name, opening_balance, inflow,
 interest, payments_out, closing_balance, cumul_invested, cumul_interest,
 is_payout_month, payout_gam3as}

KPIs:
- Total invested: {x} EGP
- Total interest earned: {x} EGP
- Total payments out: {x} EGP
- Final balance: {x} EGP
- Effective yield: {x}%

Answer concisely and helpfully. Detect the user's language from their message
and respond in the same language (Arabic or English). Format numbers with
commas and EGP suffix. Never make up data — only reference the numbers above.
```

**AI model:** `claude-sonnet-4-6` (or latest Claude Sonnet)
**Max tokens:** 1024
**Language detection:** automatic from user's message — respond in Arabic or English accordingly

---

## 6. Frontend Pages & Components

### 6.1 Layout

```
┌──────────────────┬──────────────────────────────────────────────────┐
│   SIDEBAR        │   MAIN CONTENT                                   │
│   (320px fixed)  │                                                  │
│                  │   [Dashboard tab] [Scenario tab]  [AI Advisor ●] │
│  Fund Settings   │                                                  │
│  ─────────────   │   Dashboard or Scenario content                  │
│  Gam3a Manager   │                                                  │
│  (list + form)   │                                                  │
│                  │                                                  │
└──────────────────┴──────────────────────────────────────────────────┘
                                              ┌──────────────────────┐
                                              │  AI CHAT DRAWER      │
                                              │  (right side, toggle)│
                                              └──────────────────────┘
```

### 6.2 Sidebar — Fund Settings

Inputs (save to `/api/settings`):
- Annual Rate (%) — number input, step 0.1
- Investment Day — number input, 1–28

### 6.3 Sidebar — Gam3a Manager

Add/Edit form fields:
- Name (text)
- Total Pot — EGP number
- Monthly Contribution — EGP number
- **Start Month** — dropdown (Jan–Dec)
- **Payout Month** — dropdown (Jan–Dec), highlighted in amber
- **End Month** — dropdown (Jan–Dec)
- Payout Already Received — checkbox

Each Gam3a card displays:
- Name
- Pot amount
- Monthly contribution (shown as negative/red)
- Pay Window: "Apr → May" format
- Payout month (amber)
- Status: Received (green) / Pending (blue)
- Edit and Delete buttons

### 6.4 Dashboard Tab

**4 KPI Cards:**
| Card | Color |
|------|-------|
| Total Capital Invested | Blue |
| Total Interest Earned | Green |
| Total Payments Out | Red |
| Final Projected Balance | Amber |

**Multi-line chart** (Recharts or equivalent):
- X axis: month abbreviations (Jan–Dec)
- Y axis: EGP values (formatted as "67K")
- 3 lines:
  - Closing Balance (blue)
  - Cumulative Invested (amber)
  - Cumulative Interest (green)
- Tooltip shows full EGP formatted values

**Monthly Breakdown Table:**

| Month | Opening | Inflow | Interest | Payments Out | Closing | Cumul. Interest |
|-------|---------|--------|----------|-------------|---------|----------------|

- Payout months: amber/gold row highlight + "Payout" badge
- Inflow values: green with `+` prefix
- Interest: green with `+` prefix
- Payments out: red with `-` prefix
- Closing balance: white (positive) / red (negative)

### 6.5 Scenario Simulator Tab

Header: "Scenario Simulator" + amber "SIMULATION MODE" badge + "Changes are not saved" note.

Controls:
- Annual Rate (%) input
- Investment Day input
- Run Scenario button

Custom One-Time Inflows grid:
- 12 small inputs, one per month (Jan–Dec)
- Styled with blue left border to indicate "editable"
- Added to the Gam3a-calculated inflows for that month

Results (shown after run):
- Same 4 KPI cards (with amber/warning border to signal simulation mode)
- Same chart

### 6.6 AI Chat Drawer

- Fixed right panel, 384px wide, slides in/out
- Header: "AI Financial Advisor" + "Powered by Claude • Arabic & English"
- Close button (×)
- Message history with bubbles:
  - User messages: right-aligned, navy background
  - Assistant messages: left-aligned, dark background with border
  - RTL direction applied automatically when Arabic is detected (`/[\u0600-\u06FF]/` regex)
- Typing indicator: 3 bouncing dots
- Suggestion chips on first load:
  - "Which month will my balance peak?"
  - "Is this strategy profitable?"
  - "Summarize my financial position"
  - "ما هو الشهر الأفضل لي؟"
- Textarea input (Shift+Enter = newline, Enter = send)
- Send button

---

## 7. Design System

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#1A1A2E` | Page background |
| Surface | `#16213E` | Cards, sidebar, panels |
| Accent | `#0F3460` | Borders, buttons, highlights |
| Positive | `#27AE60` / `#10B981` | Gains, interest, green values |
| Negative | `#E74C3C` | Payments, losses, red values |
| Payout | Amber `#F59E0B` | Payout month highlights |
| Text primary | `#FFFFFF` | Headlines, values |
| Text secondary | `#94A3B8` | Labels, captions |
| Editable input | Blue left border `#3B82F6` | Scenario inputs |

### Typography
- Font: Inter or system sans-serif
- Headlines: font-bold, white
- Labels: text-xs / text-sm, slate-400
- Values: font-bold, color-coded

### Component Styles
- Cards: rounded-xl, border with accent/30 opacity, surface background
- Inputs: surface background, accent border, white text
- Buttons: accent background, hover darkens, smooth transitions
- Scrollbar: thin (6px), accent colored, rounded
- Transitions: 300ms for drawer, smooth chart re-renders

---

## 8. Seed Data

Pre-populate DB with:

```
Settings: annual_rate=19.0, investment_day=20, year=2026

Gam3as:
  #1: pot=18000, contribution=3000, payout_month=3, payout_received=True,  start_month=4, end_month=5
  #2: pot=21000, contribution=3500, payout_month=4, payout_received=True,  start_month=4, end_month=6
  #3: pot=80000, contribution=10000, payout_month=5, payout_received=False, start_month=3, end_month=8
  #4: pot=30000, contribution=3000,  payout_month=1, payout_received=True,  start_month=3, end_month=12

Monthly Overrides:
  month=1, custom_inflow=0.0, note="G4 payout received in Jan but not deposited into this fund"
```

### Expected Simulation Output (19% rate, day 20)

| Month | Inflow | Payments | Interest | Closing |
|-------|--------|----------|----------|---------|
| Jan | 0 | 0 | 0.00 | 0.00 |
| Feb | 0 | 0 | 0.00 | 0.00 |
| Mar | 18,000 | 13,000 | 101.13 | 5,101.13 |
| Apr | 21,000 | 19,500 | 198.75 | 6,799.88 |
| May | 80,000 | 19,500 | 557.13 | 67,857.01 |
| Jun | 0 | 16,500 | 1,074.40 | 52,431.41 |
| Jul | 0 | 13,000 | 830.16 | 40,261.57 |
| Aug | 0 | 13,000 | 637.47 | 27,899.05 |
| Sep | 0 | 3,000 | 441.73 | 25,340.78 |
| Oct | 0 | 3,000 | 401.23 | 22,742.01 |
| Nov | 0 | 3,000 | 360.08 | 20,102.10 |
| Dec | 0 | 3,000 | 318.28 | 17,420.38 |

**KPIs:**
- Total Invested: 119,000 EGP
- Total Interest: 4,920.38 EGP
- Total Payments Out: 106,500 EGP
- Final Balance: 17,420.38 EGP
- Effective Yield: 4.13%

---

## 9. Environment & Dependencies

### Backend (reference: Python/FastAPI)
- REST API framework
- ORM with SQLite
- Anthropic SDK for Claude API
- CORS enabled for localhost:5173

### Frontend (reference: React/Vite)
- SPA, no server-side rendering needed
- HTTP client (axios or fetch)
- Charting library (Recharts or equivalent)
- CSS utility framework (Tailwind or equivalent)
- Proxy `/api` → `http://localhost:8000`

### Required Environment Variable
```
ANTHROPIC_API_KEY=sk-ant-...
```

---

## 10. Local Development Setup

1. Start backend on port **8000**
2. Start frontend on port **5173** (or any, with API proxy to 8000)
3. Run seed script to populate DB
4. Open browser at frontend URL

Backend API docs auto-generated at: `http://localhost:8000/docs`

---

## 11. Out of Scope

- Authentication / multi-user
- Multi-year simulation (only 2026)
- PDF export
- Mobile app
- Real-time updates (websockets)
- External bank integrations
