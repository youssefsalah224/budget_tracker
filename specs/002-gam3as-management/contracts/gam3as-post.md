# Contract: POST /api/gam3as

**Phase**: F2 — Gam3as Management
**Direction**: Flutter client → Django backend

## Request

```
POST /api/gam3as
Content-Type: application/json
Accept: application/json
```

### Request Body

```json
{
  "name": "Family Gam3a",
  "total_pot": 80000.0,
  "monthly_contribution": 10000.0,
  "payout_month": 5,
  "start_month": 3,
  "end_month": 8,
  "payout_received": false
}
```

| Field | Required | Notes |
|---|---|---|
| `name` | ✅ | Non-empty string, max 100 chars |
| `total_pot` | ✅ | Positive float (EGP). Client converts from int piastres ÷ 100 |
| `monthly_contribution` | ✅ | Positive float (EGP). Client converts from int piastres ÷ 100 |
| `payout_month` | ✅ | Integer 1–12 |
| `start_month` | ✅ | Integer 1–12; `start_month ≤ end_month` enforced client-side |
| `end_month` | ✅ | Integer 1–12 |
| `payout_received` | ✅ | Boolean; defaults to `false` in form |

Fields `id`, `active`, `created_at` are NOT sent — the backend assigns them.

## Success Response

**Status**: `201 Created`

```json
{
  "id": 5,
  "name": "Family Gam3a",
  "total_pot": 80000.0,
  "monthly_contribution": 10000.0,
  "payout_month": 5,
  "start_month": 3,
  "end_month": 8,
  "payout_received": false,
  "active": true,
  "created_at": "2026-04-04T12:00:00Z"
}
```

## Error Responses

| Status | Condition |
|---|---|
| `400` | Validation error (missing field, wrong type) |
| `500` | Backend internal error |

## Flutter Client Behaviour

- Validate all fields client-side before sending (FR-006) — no request made if validation fails.
- On `201`: call `GamAasNotifier.add()` which reloads the list and invalidates `simulationNotifierProvider`.
- On `400`/`5xx`: show error message; keep form open with entered values.
- Disable Save button from first tap until response arrives (prevents double-submit).
