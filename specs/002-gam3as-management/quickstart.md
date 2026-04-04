# Quickstart: Gam3as Management (F2)

**Branch**: `002-gam3as-management` | **Date**: 2026-04-04

---

## Prerequisites

| Tool | Check |
|---|---|
| Flutter 3.x | `flutter --version` |
| Django B1 backend running on port 8000 | `python manage.py runserver` |
| At least one gam3a in the backend (seed data) | `python manage.py seed` |

---

## 1. Run the App

```bash
# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api

# Android emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Navigate to the **Gam3as** tab in the bottom nav bar.

---

## 2. Key Integration Scenarios

### SC-001 — List loads within 2 s

1. Start the backend (`python manage.py runserver`)
2. Open the app → tap **Gam3as** tab
3. Four seed gam3as must appear within 2 seconds

### SC-003 — Dashboard refreshes after mutation

1. Open **Gam3as** tab → tap the **+** button
2. Fill in: name `"Test"`, pot `10000`, contribution `1000`, payout month `6`, start `1`, end `10`
3. Tap **Save**
4. Navigate to **Dashboard** — totals must reflect the new gam3a without navigating away and back

### Offline / stale cache

1. Stop the Django backend
2. Close and reopen the app
3. **Gam3as** tab must show cached list with a stale banner
4. If no previous cache: error screen with **Retry** button

### Empty state

1. Delete all gam3as via Django admin or API
2. Open the app → tap **Gam3as**
3. An empty-state message and **"Add your first Gam3a"** button must appear

### Edit with pre-population

1. Tap the edit icon on any card
2. The form must open with all current values pre-filled
3. Change payout month → Save → card and simulation must update

### Delete with confirmation

1. Tap the delete icon on a card
2. A confirmation dialog must appear
3. Tap **Cancel** — gam3a remains
4. Tap delete icon again → **Confirm** — gam3a disappears and Dashboard updates

---

## 3. Run Tests

```bash
# All tests (must all pass)
flutter test

# F2-specific tests only
flutter test test/features/gam3as/

# With coverage
flutter test --coverage
```

---

## 4. Static Analysis

```bash
flutter analyze
# Expected: No issues found!
```

---

## 5. Regenerate build_runner output (after any @riverpod change)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 6. File Map

| File | Purpose |
|---|---|
| `lib/features/gam3as/domain/gam3a.dart` | Immutable model, fromJson/toJson |
| `lib/features/gam3as/data/gam3a_repository.dart` | Abstract interface |
| `lib/features/gam3as/data/gam3a_repository_impl.dart` | Dio HTTP calls |
| `lib/features/gam3as/application/gam3as_provider.dart` | AsyncNotifier + add/update/delete |
| `lib/features/gam3as/presentation/gam3as_screen.dart` | List screen |
| `lib/features/gam3as/presentation/gam3a_form_screen.dart` | Add/edit form |
| `lib/features/gam3as/presentation/widgets/gam3a_card.dart` | Card widget |
| `lib/features/gam3as/presentation/widgets/empty_gam3as_view.dart` | Empty state |
| `lib/core/routing/app_router.dart` | Updated: /gam3as/new, /gam3as/edit |
| `test/features/gam3as/gam3a_test.dart` | Model round-trip tests |
| `test/features/gam3as/gam3as_provider_test.dart` | Provider state tests |
| `test/features/gam3as/gam3a_card_test.dart` | Widget tests |

---

## 7. Common Issues

| Symptom | Likely cause | Fix |
|---|---|---|
| Gam3as list shows error immediately | Backend not running | `python manage.py runserver` |
| `GamAasNotifier` type error after build_runner | Stale `.g.dart` | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Form Save button stays disabled | Previous request still pending | Wait for response or restart app |
| Dashboard doesn't update after add | `simulationNotifierProvider` not invalidated | Check `GamAasNotifier` mutation methods call `ref.invalidate(simulationNotifierProvider)` |
| "No gam3as" empty state always shown | Seed data missing | `python manage.py seed` |
