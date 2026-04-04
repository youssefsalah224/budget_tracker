# Contract: PUT /api/gam3as/{id}

**Phase**: F2 — Gam3as Management
**Direction**: Flutter client → Django backend

## Request

```
PUT /api/gam3as/{id}
Content-Type: application/json
Accept: application/json
```

Path parameter `{id}`: integer ID of the gam3a to update.

### Request Body

Same structure as POST. All fields are sent (full replacement, not partial):

```json
{
  "name": "Family Gam3a (updated)",
  "total_pot": 80000.0,
  "monthly_contribution": 10000.0,
  "payout_month": 6,
  "start_month": 3,
  "end_month": 8,
  "payout_received": true
}
```

## Success Response

**Status**: `200 OK`

```json
{
  "id": 3,
  "name": "Family Gam3a (updated)",
  "total_pot": 80000.0,
  "monthly_contribution": 10000.0,
  "payout_month": 6,
  "start_month": 3,
  "end_month": 8,
  "payout_received": true,
  "active": true,
  "created_at": "2026-01-15T10:30:00Z"
}
```

## Error Responses

| Status | Condition |
|---|---|
| `400` | Validation error |
| `404` | Gam3a with given ID does not exist |
| `500` | Backend internal error |

## Flutter Client Behaviour

- Validate all fields client-side before sending.
- On `200`: call `GamAasNotifier.update()` which reloads the list and invalidates `simulationNotifierProvider`.
- On `404`: show "Gam3a not found" error; pop the form screen.
- On `400`/`5xx`: show error message; keep form open.
