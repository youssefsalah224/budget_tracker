# Contract: DELETE /api/gam3as/{id}

**Phase**: F2 — Gam3as Management
**Direction**: Flutter client → Django backend

## Request

```
DELETE /api/gam3as/{id}
Accept: application/json
```

Path parameter `{id}`: integer ID of the gam3a to delete. No request body.

## Success Response

**Status**: `200 OK`

```json
{ "ok": true }
```

## Error Responses

| Status | Condition |
|---|---|
| `404` | Gam3a with given ID does not exist |
| `500` | Backend internal error |

## Flutter Client Behaviour

- User must confirm via a dialog before the DELETE request is sent.
- On `200`: call `GamAasNotifier.delete(id)` which reloads the list and invalidates `simulationNotifierProvider`.
- On `404`: show "Gam3a not found" error; remove from local list anyway (it's gone on the backend).
- On `5xx`: show error message; gam3a remains in the list.
