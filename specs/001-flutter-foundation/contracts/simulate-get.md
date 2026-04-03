# Contract: GET /api/simulate

**Feature**: Flutter Foundation (F1) | **Date**: 2026-04-03
**Consumer**: `SimulationRepository` (`lib/features/simulation/data/simulation_repository_impl.dart`)
**Provider**: Django REST backend (Phase B1)

---

## Endpoint

```
GET /api/simulate
Host: {API_BASE_URL}          # injected via --dart-define=API_BASE_URL=...
Content-Type: application/json
```

No request body. No query parameters. No authentication required in Phase F1.

---

## Timeouts (FR-002)

| Timeout type | Value |
|---|---|
| Connection timeout | 10 000 ms |
| Receive timeout | 30 000 ms |

---

## Success Response — 200 OK

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
    // … 11 more entries (always 12 total)
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

### Field types (as received from API)

| JSON path | JSON type | Notes |
|-----------|-----------|-------|
| `rows[].month` | `number` (integer) | 1–12 |
| `rows[].month_name` | `string` | Full English month name |
| `rows[].opening_balance` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].inflow` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].interest` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].payments_out` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].closing_balance` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].cumul_invested` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].cumul_interest` | `number` (float) | EGP; convert to piastres ×100 |
| `rows[].is_payout_month` | `boolean` | — |
| `rows[].payout_gam3as` | `string[]` | May be empty `[]` |
| `kpis.total_invested` | `number` (float) | EGP; convert to piastres ×100 |
| `kpis.total_interest` | `number` (float) | EGP; convert to piastres ×100 |
| `kpis.total_payments_out` | `number` (float) | EGP; convert to piastres ×100 |
| `kpis.final_balance` | `number` (float) | EGP; convert to piastres ×100 |
| `kpis.effective_yield` | `number` (float) | Percentage; convert to basis points ×100 |

> **⚠ Known violation (Constitution IV)**: Monetary values are transmitted as JSON floats
> by the B1 backend. The Flutter repository layer MUST convert to integer piastres at parse
> time. Remediation of the backend serialiser is scheduled for Phase B2.

---

## Error Responses

| HTTP Status | Meaning | Flutter handling |
|---|---|---|
| 4xx / 5xx | Backend error | Map to `AppException.serverError(statusCode)` |
| Network timeout | No response within timeout windows | Map to `AppException.timeout()` |
| Connection refused / DNS failure | Backend unreachable | Map to `AppException.networkError()` |
| 200 with malformed JSON | Parse failure | Map to `AppException.parseError()` |

All error cases surface identically to the user (error widget + Retry button), per spec edge case 1.

---

## Consumer Behaviour

```
SimulationRepository.fetchSimulation()
  1. Call GET /api/simulate via DioClient
  2. On success (200):
     a. Parse response → SimulationResult (with float → int conversion)
     b. Write to CacheService
     c. Return SimulationResult
  3. On any error:
     a. Attempt CacheService.readSimulation()
     b. If cache hit: return cached SimulationResult (provider marks isStale = true)
     c. If cache miss: rethrow as AppException
```

---

## Breaking Change Policy

Per Constitution Principle II, the backend MUST version breaking endpoint changes (`/api/v1/`, `/api/v2/`).
The Flutter client MUST NOT assume field additions are breaking; it MUST ignore unknown JSON keys.
