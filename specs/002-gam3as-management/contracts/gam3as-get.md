# Contract: GET /api/gam3as

**Phase**: F2 — Gam3as Management
**Direction**: Flutter client → Django backend

## Request

```
GET /api/gam3as
Accept: application/json
```

No query parameters. No request body.

## Success Response

**Status**: `200 OK`

```json
[
  {
    "id": 1,
    "name": "Work Gam3a",
    "total_pot": 18000.0,
    "monthly_contribution": 3000.0,
    "payout_month": 3,
    "start_month": 4,
    "end_month": 5,
    "payout_received": true,
    "active": true,
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": 3,
    "name": "Family Gam3a",
    "total_pot": 80000.0,
    "monthly_contribution": 10000.0,
    "payout_month": 5,
    "start_month": 3,
    "end_month": 8,
    "payout_received": false,
    "active": true,
    "created_at": "2026-01-15T10:30:00Z"
  }
]
```

**Empty list** (no gam3as): `200 OK` with body `[]`

## Error Responses

| Status | Condition |
|---|---|
| `500` | Backend internal error |

## Flutter Client Behaviour

- On `200`: parse `List<Gam3a>` via `Gam3a.fromJson`, sort by `payoutMonth` ascending, update provider state to `AsyncData`.
- On network error or timeout: read from cache; if cache hit → `AsyncData` + `isGam3asStale = true`; if no cache → `AsyncError`.
