# Data Model: Gam3as Management (002)

**Branch**: `002-gam3as-management` | **Date**: 2026-04-04

## Entity: Gam3a

Represents a single rotating savings club (Gam3a) that the user participates in.

### Fields

| Field | Dart Type | JSON Key | JSON Type | Notes |
|---|---|---|---|---|
| `id` | `int` | `id` | `int` | Backend-assigned primary key; absent on create |
| `name` | `String` | `name` | `string` | Human label, max 100 chars, required |
| `totalPotPiastres` | `int` | `total_pot` | `double` (EGP) | Converted ×100 at repository boundary |
| `monthlyContributionPiastres` | `int` | `monthly_contribution` | `double` (EGP) | Converted ×100 at repository boundary |
| `payoutMonth` | `int` | `payout_month` | `int` | 1–12, month user receives the pot |
| `startMonth` | `int` | `start_month` | `int` | 1–12, first month of contribution |
| `endMonth` | `int` | `end_month` | `int` | 1–12, last month of contribution |
| `payoutReceived` | `bool` | `payout_received` | `bool` | Whether the user has collected the pot |
| `active` | `bool` | `active` | `bool` | Included in simulation when true |
| `createdAt` | `DateTime` | `created_at` | `string` (ISO-8601) | Backend-assigned; read-only in client |

### Constraints (enforced client-side before POST/PUT)

- `name`: non-empty string
- `totalPotPiastres`: > 0
- `monthlyContributionPiastres`: > 0
- `payoutMonth`, `startMonth`, `endMonth`: each in range 1–12
- `startMonth` ≤ `endMonth`

### JSON Example (backend response)

```json
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
```

### Dart Representation (domain model)

```dart
// After fromJson conversion:
Gam3a(
  id: 3,
  name: 'Family Gam3a',
  totalPotPiastres: 8000000,          // 80000.0 × 100
  monthlyContributionPiastres: 1000000, // 10000.0 × 100
  payoutMonth: 5,
  startMonth: 3,
  endMonth: 8,
  payoutReceived: false,
  active: true,
  createdAt: DateTime.parse('2026-01-15T10:30:00Z'),
)
```

### toJson (for POST/PUT request body)

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
Note: `id`, `active`, and `created_at` are omitted from create/update payloads.

---

## State: GamAasNotifier

The Riverpod provider exposes `AsyncValue<List<Gam3a>>`.

| State | When |
|---|---|
| `AsyncLoading()` | Initial fetch or after a mutation begins |
| `AsyncData(list)` | Fetch succeeded; `list` sorted by `payoutMonth` ascending |
| `AsyncError(e, st)` | Fetch failed and no cache exists |
| `AsyncData(cachedList)` + `isGam3asStale == true` | Fetch failed but cache hit |

### Mutations (methods on GamAasNotifier)

| Method | HTTP | Behaviour |
|---|---|---|
| `add(Gam3a)` | `POST /api/gam3as` | Sets loading → calls API → reloads list → writes cache |
| `update(Gam3a)` | `PUT /api/gam3as/{id}` | Sets loading → calls API → reloads list → writes cache |
| `delete(int id)` | `DELETE /api/gam3as/{id}` | Sets loading → calls API → reloads list → writes cache |

After any successful mutation, `simulationNotifierProvider` is also invalidated so the Dashboard refreshes automatically.

---

## Cache

| Key | Value | Written | Read |
|---|---|---|---|
| `gam3as_list_v1` | JSON-encoded `List<Gam3a>` | After every successful fetch or mutation | On fetch failure, before throwing |
