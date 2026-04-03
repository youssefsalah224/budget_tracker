# Gam3ya Investment Simulator — Full Project Plan
## Flutter Client (Web · iOS · Android) + Django REST API

| Field | Value |
|-------|-------|
| **Version** | 2.0 |
| **Date** | 2026-03-31 |
| **Project Type** | Cross-platform client + REST API backend |
| **Client Stack** | Flutter 3.x · Dart 3.x |
| **Backend Stack** | Python 3.12 · Django 4.2+ · Django REST Framework · SQLite |
| **AI Integration** | Anthropic Claude (`claude-sonnet-4-6`) |
| **Spec format** | Each phase → one Spec Kit spec (`/speckit.specify` → `specs/###-name/spec.md`) |
| **Backend status** | Phase B1 (core API) complete · Phase B2–B4 to be built per plan below |
| **Client status** | Not started |

---

## 1. Product Overview

### 1.1 What Is This?

A personal finance dashboard for tracking and simulating **Gam3as** — Egyptian rotating
savings clubs. In a Gam3a, N members each contribute a fixed amount every month. Each month,
one member receives the total pot (N × monthly contribution). The user logs their gam3as and
the app simulates depositing each payout into a compounding investment fund, projecting
balances, interest, and cash flows across a 12-month period.


### 1.2 Build Targets

```
┌─────────────────────────────────────────────────────────────┐
│                  Flutter Client (Dart)                      │
│                                                             │
│  flutter build web   →  Web app (replaces HTML frontend)    │
│  flutter build apk   →  Android (Play Store / sideload)     │
│  flutter build ipa   →  iOS (App Store / TestFlight)        │
└─────────────────────────────────────────────────────────────┘
                              │  HTTP/JSON
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Django REST API (Python)                       │
│              http://localhost:8000/api                      │
└─────────────────────────────────────────────────────────────┘
```

The Flutter client is a **pure consumer** of the Django API. No business logic lives in
the client. All simulation math, data persistence, and AI responses are handled by Django.

### 1.3 Core Business Logic

#### Gam3a Payment Windows
Each Gam3a has a `start_month`, `end_month`, and `payout_month` (integers 1–12).
- The user owes `monthly_contribution` EGP every month from `start_month` to `end_month` inclusive.
- The user receives `total_pot` EGP once in `payout_month`.

#### Monthly Cash Flow Formula
```
inflow       = Σ total_pot          for all Gam3as where payout_month == month
payments_out = Σ monthly_contribution  for all Gam3as where start_month ≤ month ≤ end_month
```

#### Compound Interest Formula
```
monthly_rate  = annual_rate / 12 / 100
day_ratio     = (31 - investment_day) / 31

pos_opening   = max(0, opening_balance)          ← no interest on negative balances
available     = pos_opening + inflow

interest      = 0  if available ≤ 0
              = (pos_opening × monthly_rate) + (inflow × monthly_rate × day_ratio)  otherwise

closing_balance = opening_balance + inflow + interest - payments_out
```

#### KPIs
```
total_invested     = Σ inflow       (months 1–12)
total_interest     = Σ interest     (months 1–12)
total_payments_out = Σ payments_out (months 1–12)
final_balance      = closing_balance at month 12
effective_yield    = (total_interest / total_invested) × 100  [%]
```

#### Monthly Overrides
A `MonthlyOverride` row for a given month replaces the calculated value:
- `custom_inflow` replaces the calculated inflow for that month when set.
- `custom_payment` replaces the calculated payments_out for that month when set.

---

## 2. Backend Plan

The backend is split into four backend phases (B1–B4). B1 is already implemented.
B2–B4 are required to support the full Flutter client feature set.

### Backend Phase B1 — Core API ✅ COMPLETE

#### Tech Stack

| Component | Value |
|-----------|-------|
| Language | Python 3.12 |
| Framework | Django 4.2 |
| API layer | Django REST Framework 3.14 |
| Database | SQLite (`db.sqlite3`) |
| AI | Anthropic Python SDK (`anthropic>=0.25`) |
| CORS | `django-cors-headers` |
| Env | `python-dotenv` |

#### Current `requirements.txt`
```
django>=4.2,<5.0
djangorestframework>=3.14
django-cors-headers>=4.3
anthropic>=0.25
python-dotenv>=1.0
```

#### Current `settings.py` — Key Configuration
```python
INSTALLED_APPS = [
    'django.contrib.contenttypes',
    'rest_framework',
    'corsheaders',
    'api',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
]

CORS_ALLOW_ALL_ORIGINS = True
APPEND_SLASH = False       # URLs defined without trailing slashes

REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_AUTHENTICATION_CLASSES': [],
    'DEFAULT_PERMISSION_CLASSES': [],
    'UNAUTHENTICATED_USER': None,
}

ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
```

#### Existing Data Models

**Gam3a**
| Field | Type | Default |
|-------|------|---------|
| `id` | BigAutoField PK | auto |
| `name` | CharField(100) | required |
| `total_pot` | FloatField | required |
| `monthly_contribution` | FloatField | required |
| `payout_month` | IntegerField 1–12 | required |
| `payout_received` | BooleanField | False |
| `start_month` | IntegerField 1–12 | 1 |
| `end_month` | IntegerField 1–12 | 12 |
| `active` | BooleanField | True |
| `created_at` | DateTimeField | auto_now_add |

**SimulationSettings** (always a single row, `pk=1`)
| Field | Type | Default |
|-------|------|---------|
| `id` | BigAutoField PK | auto |
| `annual_rate` | FloatField | 19.0 |
| `investment_day` | IntegerField 1–28 | 20 |
| `year` | IntegerField | 2026 |

**MonthlyOverride**
| Field | Type | Default |
|-------|------|---------|
| `id` | BigAutoField PK | auto |
| `month` | IntegerField 1–12 | required (unique) |
| `custom_inflow` | FloatField | null |
| `custom_payment` | FloatField | null |
| `note` | TextField | null |

#### Existing API Endpoints

Base path: `/api` · No trailing slashes · All responses: `application/json`

**Gam3a CRUD**
| Method | Path | Request | Response |
|--------|------|---------|----------|
| GET | `/api/gam3as` | — | `Gam3a[]` |
| POST | `/api/gam3as` | Gam3a fields | `Gam3a` 201 |
| PUT | `/api/gam3as/{id}` | Partial Gam3a fields | `Gam3a` 200 |
| DELETE | `/api/gam3as/{id}` | — | `{"ok": true}` 200 |

**Settings**
| Method | Path | Request | Response |
|--------|------|---------|----------|
| GET | `/api/settings` | — | `SimulationSettings` |
| PUT | `/api/settings` | `{annual_rate?, investment_day?, year?}` | `SimulationSettings` |

**Simulation**
| Method | Path | Request | Response |
|--------|------|---------|----------|
| GET | `/api/simulate` | — | `SimulationResult` |
| POST | `/api/simulate/scenario` | `ScenarioRequest` | `SimulationResult` |

`ScenarioRequest` body (all fields optional):
```json
{
  "annual_rate": 22.0,
  "investment_day": 15,
  "extra_inflows": { "3": 5000.0, "6": 10000.0 }
}
```

`SimulationResult` response:
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

**AI Chat**
| Method | Path | Request | Response |
|--------|------|---------|----------|
| POST | `/api/chat` | `ChatRequest` | `{"reply": string}` |

`ChatRequest` body:
```json
{
  "message": "Which month will my balance peak?",
  "history": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
```

The backend builds a system prompt with the full simulation context and calls
`claude-sonnet-4-6` (max 1024 tokens). It detects the user's language (Arabic or English)
from the message and instructs Claude to respond in the same language.

#### Seed Data (`python manage.py seed`)
```
SimulationSettings: annual_rate=19.0, investment_day=20, year=2026

Gam3a #1: pot=18,000   contribution=3,000  payout_month=3  received=True  start=4  end=5
Gam3a #2: pot=21,000   contribution=3,500  payout_month=4  received=True  start=4  end=6
Gam3a #3: pot=80,000   contribution=10,000 payout_month=5  received=False start=3  end=8
Gam3a #4: pot=30,000   contribution=3,000  payout_month=1  received=True  start=3  end=12

MonthlyOverride: month=1, custom_inflow=0.0
  (Gam3a #4 payout was received in January before the fund started — suppressed)
```

#### Expected Simulation Output (19% rate, day 20)
| Month | Inflow | Payments Out | Interest | Closing Balance |
|-------|--------|-------------|----------|-----------------|
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

KPIs: Invested 119,000 · Interest 4,920.38 · Payments 106,500 · Balance 17,420.38 · Yield 4.13%

#### Local Setup
```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed
python manage.py runserver        # → http://localhost:8000
```

---

### Backend Phase B2 — Monthly Overrides API

**Required by**: Flutter Phase 6
**Spec**: `specs/b02-overrides-api/spec.md`

The `MonthlyOverride` model already exists and is used in the simulation engine.
This phase exposes it via a REST API so the Flutter client can manage overrides.

#### New `requirements.txt` additions
No new packages required.

#### New Endpoints

| Method | Path | Request Body | Response |
|--------|------|-------------|----------|
| GET | `/api/overrides` | — | `MonthlyOverride[]` |
| POST | `/api/overrides` | `{month, custom_inflow?, custom_payment?, note?}` | `MonthlyOverride` 201 |
| PUT | `/api/overrides/{month}` | `{custom_inflow?, custom_payment?, note?}` | `MonthlyOverride` 200 |
| DELETE | `/api/overrides/{month}` | — | `{"ok": true}` 200 |

#### New Serializer (`api/serializers.py`)
```python
class MonthlyOverrideSerializer(serializers.ModelSerializer):
    class Meta:
        model = MonthlyOverride
        fields = '__all__'
        read_only_fields = ['id']
```

#### New Views (`api/views.py`)
```python
class OverrideListCreateView(APIView):
    def get(self, request):   # GET /api/overrides
    def post(self, request):  # POST /api/overrides

class OverrideDetailView(APIView):
    def put(self, request, month):     # PUT /api/overrides/{month}
    def delete(self, request, month):  # DELETE /api/overrides/{month}
```

#### URL Registration (`api/urls.py`)
```python
path('overrides', OverrideListCreateView.as_view()),
path('overrides/<int:month>', OverrideDetailView.as_view()),
```

#### Validation Rules
- `month` must be 1–12.
- `POST` returns 400 if a record for that month already exists (unique constraint).
- `PUT` / `DELETE` return 404 if no record exists for that month.
- `custom_inflow` and `custom_payment` are both nullable floats — `null` means "use calculated value".

---

### Backend Phase B3 — Actuals Tracking API

**Required by**: Flutter Phase 6
**Spec**: `specs/b03-actuals-api/spec.md`

A new model and endpoints to record what actually happened each month vs the projection.

#### New Model (`api/models.py`)
```python
class MonthlyActual(models.Model):
    month            = IntegerField(unique=True, validators=[Min(1), Max(12)])
    actual_inflow    = FloatField(default=0.0)
    actual_payment   = FloatField(default=0.0)
    actual_interest  = FloatField(default=0.0)
    note             = TextField(null=True, blank=True)
    recorded_at      = DateTimeField(auto_now=True)

    class Meta:
        ordering = ['month']
```

Run `python manage.py makemigrations && python manage.py migrate` after adding.

#### New Endpoints

| Method | Path | Request Body | Response |
|--------|------|-------------|----------|
| GET | `/api/actuals` | — | `MonthlyActual[]` |
| POST | `/api/actuals` | `{month, actual_inflow, actual_payment, actual_interest, note?}` | `MonthlyActual` 201 |
| PUT | `/api/actuals/{month}` | `{actual_inflow?, actual_payment?, actual_interest?, note?}` | `MonthlyActual` 200 |

#### New Serializer
```python
class MonthlyActualSerializer(serializers.ModelSerializer):
    class Meta:
        model = MonthlyActual
        fields = '__all__'
        read_only_fields = ['id', 'recorded_at']
```

#### Validation Rules
- `month` must be 1–12.
- `POST` returns 400 if a record for that month already exists.
- `PUT` returns 404 if no record exists for that month.
- All three numeric fields default to `0.0` if omitted on POST.

---

### Backend Phase B4 — Authentication (JWT)

**Required by**: Flutter Phase 7
**Spec**: `specs/b04-auth/spec.md`

Adds user accounts so each user has isolated data. Uses Django's built-in `User` model
with `djangorestframework-simplejwt` for stateless JWT token issuance.

#### `requirements.txt` Addition
```
djangorestframework-simplejwt>=5.3
```

#### `settings.py` Changes

Add to `INSTALLED_APPS`:
```python
'django.contrib.auth',
'django.contrib.contenttypes',   # already present
```

Add to `MIDDLEWARE`:
```python
'django.contrib.auth.middleware.AuthenticationMiddleware',
```

Update `REST_FRAMEWORK`:
```python
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

Add JWT config:
```python
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
}
```

Move `SECRET_KEY` to `.env`:
```python
SECRET_KEY = os.getenv('SECRET_KEY', 'fallback-dev-only-key')
```

#### New Auth Endpoints

| Method | Path | Request Body | Response |
|--------|------|-------------|----------|
| POST | `/api/auth/register` | `{email, password}` | `{access, refresh}` 201 |
| POST | `/api/auth/login` | `{email, password}` | `{access, refresh}` 200 |
| POST | `/api/auth/refresh` | `{refresh}` | `{access}` 200 |

Validation:
- Email: valid format, unique in `User` table.
- Password: minimum 8 characters.
- Invalid credentials: `{"detail": "Invalid email or password."}` 401.

#### Model Changes — Add `user` ForeignKey

Apply to: `Gam3a`, `SimulationSettings`, `MonthlyOverride`, `MonthlyActual`

```python
user = models.ForeignKey(
    settings.AUTH_USER_MODEL,
    on_delete=models.CASCADE,
    related_name='gam3as',   # change per model
)
```

Migration strategy: set `default=1` for existing rows (safe for single-user installs).

#### Query Scoping

Every view filters by `request.user`:
```python
Gam3a.objects.filter(user=request.user, active=True)
SimulationSettings.objects.get_or_create(user=request.user, defaults={...})
```

---

## 3. Flutter Client Architecture

### 3.1 Layered Architecture

```
┌────────────────────────────────────────────┐
│              Screens (UI)                  │  ← Flutter Widgets · GoRouter
├────────────────────────────────────────────┤
│           State / Providers                │  ← Riverpod AsyncNotifierProvider
├────────────────────────────────────────────┤
│             Service Layer                  │  ← ApiService · CacheService · NotificationService
├────────────────────────────────────────────┤
│          Network / Storage                 │  ← Dio · SharedPreferences · flutter_secure_storage
├────────────────────────────────────────────┤
│           Django REST API                  │  ← http://localhost:8000/api
└────────────────────────────────────────────┘
```

### 3.2 Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod `AsyncNotifierProvider` | Compile-safe, no `BuildContext` needed in tests, native loading/error/data states |
| Navigation | GoRouter | Declarative, deep-link capable, `redirect` guard for auth, works on web |
| HTTP client | Dio | Interceptor support for auth token, configurable timeouts, clean error handling |
| Charting | fl_chart | Pure Flutter (no platform channel), 60 fps, `LineChart` multi-series with tap tooltips |
| Local cache | SharedPreferences | Sufficient for a single simulation JSON blob |
| Secure storage | flutter_secure_storage | Keychain (iOS) / Keystore (Android) / encrypted localStorage (web) |

### 3.3 Cross-Platform Behaviour

| Feature | Web | iOS | Android |
|---------|-----|-----|---------|
| Navigation shell | Navigation rail (wide) · bottom nav (narrow) | Bottom navigation bar | Bottom navigation bar |
| Push notifications | Not supported — `kIsWeb` guarded | `flutter_local_notifications` | `flutter_local_notifications` |
| Offline cache | SharedPreferences | SharedPreferences | SharedPreferences |
| Secure token storage | Encrypted localStorage | Keychain | Keystore |

### 3.4 Full API Contract

All calls originate from `ApiService`. Base URL injected via `--dart-define=API_BASE_URL`.

| Method | Endpoint | Flutter Phase | Provider |
|--------|----------|--------------|----------|
| GET | `/api/simulate` | F1 | `simulationProvider` |
| GET | `/api/gam3as` | F2 | `gam3asProvider` |
| POST | `/api/gam3as` | F2 | `gam3asProvider.add()` |
| PUT | `/api/gam3as/{id}` | F2 | `gam3asProvider.update()` |
| DELETE | `/api/gam3as/{id}` | F2 | `gam3asProvider.delete()` |
| GET | `/api/settings` | F4 | `settingsProvider` |
| PUT | `/api/settings` | F4 | `settingsProvider.update()` |
| POST | `/api/simulate/scenario` | F4 | `scenarioProvider.run()` |
| POST | `/api/chat` | F5 | `chatProvider.send()` |
| GET | `/api/overrides` | F6 | `overridesProvider` |
| POST | `/api/overrides` | F6 | `overridesProvider.add()` |
| PUT | `/api/overrides/{month}` | F6 | `overridesProvider.update()` |
| DELETE | `/api/overrides/{month}` | F6 | `overridesProvider.delete()` |
| GET | `/api/actuals` | F6 | `actualsProvider` |
| POST | `/api/actuals` | F6 | `actualsProvider.log()` |
| PUT | `/api/actuals/{month}` | F6 | `actualsProvider.update()` |
| POST | `/api/auth/register` | F7 | `authProvider.register()` |
| POST | `/api/auth/login` | F7 | `authProvider.login()` |
| POST | `/api/auth/refresh` | F7 | `authProvider.refresh()` |

### 3.5 Dependency Manifest (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Phase F1 — Foundation
  go_router: ^14.0.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  dio: ^5.4.0
  shared_preferences: ^2.2.0

  # Phase F3 — Charts
  fl_chart: ^0.68.0

  # Phase F7 — Auth
  flutter_secure_storage: ^9.0.0

  # Phase F8 — Offline & Notifications
  connectivity_plus: ^6.0.0
  flutter_local_notifications: ^17.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  flutter_lints: ^4.0.0
```

### 3.6 Full File Structure

```text
flutter_app/
├── lib/
│   ├── main.dart                          # ProviderScope, ThemeData, runApp
│   ├── router.dart                        # GoRouter routes + auth redirect guard
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart          # F1/F3
│   │   ├── gam3as_screen.dart             # F2
│   │   ├── gam3a_form_screen.dart         # F2 — add / edit form
│   │   ├── scenario_screen.dart           # F4
│   │   ├── chat_screen.dart               # F5 — full-screen modal route
│   │   ├── overrides_screen.dart          # F6
│   │   ├── actuals_screen.dart            # F6
│   │   └── auth/
│   │       ├── login_screen.dart          # F7
│   │       └── register_screen.dart       # F7
│   │
│   ├── widgets/
│   │   ├── scaffold_with_nav.dart         # F1 — adaptive nav shell
│   │   ├── kpi_card.dart                  # F3
│   │   ├── simulation_chart.dart          # F3 — fl_chart wrapper
│   │   ├── monthly_table.dart             # F3
│   │   ├── gam3a_card.dart                # F2
│   │   ├── chat_bubble.dart               # F5
│   │   └── offline_banner.dart            # F8
│   │
│   ├── providers/
│   │   ├── simulation_provider.dart       # F1
│   │   ├── gam3as_provider.dart           # F2
│   │   ├── settings_provider.dart         # F4
│   │   ├── scenario_provider.dart         # F4
│   │   ├── chat_provider.dart             # F5
│   │   ├── overrides_provider.dart        # F6
│   │   ├── actuals_provider.dart          # F6
│   │   └── auth_provider.dart             # F7
│   │
│   ├── services/
│   │   ├── api_service.dart               # Dio client, base URL, timeouts, interceptors
│   │   ├── cache_service.dart             # SharedPreferences read/write
│   │   └── notification_service.dart      # F8 — flutter_local_notifications
│   │
│   ├── models/
│   │   ├── gam3a.dart                     # fromJson / toJson
│   │   ├── simulation_result.dart
│   │   ├── monthly_row.dart
│   │   ├── kpis.dart
│   │   ├── simulation_settings.dart
│   │   ├── monthly_override.dart          # F6
│   │   ├── monthly_actual.dart            # F6
│   │   └── auth_token.dart                # F7
│   │
│   └── constants/
│       ├── theme.dart                     # AppColors, ThemeData
│       └── api_endpoints.dart             # Endpoint path constants
│
├── test/
│   ├── services/api_service_test.dart
│   ├── providers/
│   │   ├── simulation_provider_test.dart
│   │   └── gam3as_provider_test.dart
│   └── widgets/
│       ├── kpi_card_test.dart
│       └── gam3a_card_test.dart
│
├── web/                                   # Auto-generated Flutter web target
├── android/                               # Auto-generated Flutter Android target
├── ios/                                   # Auto-generated Flutter iOS target
└── pubspec.yaml
```

### 3.7 Design Token Reference

All values defined in `lib/constants/theme.dart`. No inline hex values elsewhere.

| Token | Hex | Dart Constant | Usage |
|-------|-----|--------------|-------|
| Background | `#1A1A2E` | `AppColors.background` | Scaffold background |
| Surface | `#16213E` | `AppColors.surface` | Cards, panels |
| Accent | `#0F3460` | `AppColors.accent` | Borders, buttons |
| Positive | `#10B981` | `AppColors.positive` | Inflows, interest, gains |
| Negative | `#E74C3C` | `AppColors.negative` | Payments, losses |
| Payout | `#F59E0B` | `AppColors.payout` | Payout month highlights |
| Text Primary | `#FFFFFF` | `AppColors.textPrimary` | Headlines, values |
| Text Secondary | `#94A3B8` | `AppColors.textSecondary` | Labels, captions |
| Blue | `#3B82F6` | `AppColors.blue` | Input borders, info badges |

### 3.8 Testing Strategy

| Layer | Tool | Coverage |
|-------|------|----------|
| Models | `flutter_test` | `fromJson` / `toJson` round-trips, null safety edge cases |
| Services | `flutter_test` + `mocktail` | Dio calls mocked at HTTP adapter — success, 4xx, 5xx, timeout |
| Providers | `flutter_test` + `ProviderContainer` | loading / success / error states per provider |
| Widgets | `flutter_test` | `KpiCard`, `Gam3aCard`, `SimulationChart`, `ChatBubble` |
| Integration | Manual on device | Full journeys on physical iOS, Android, and Chrome |

Each phase MUST ship at least one passing unit test for every new provider or service.

### 3.9 Environment & Build

```bash
# Development
flutter run -d chrome   --dart-define=API_BASE_URL=http://localhost:8000/api
flutter run -d android  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
flutter run -d ios      --dart-define=API_BASE_URL=http://localhost:8000/api

# Production builds
flutter build web   --dart-define=API_BASE_URL=https://api.yourdomain.com/api
flutter build apk   --dart-define=API_BASE_URL=https://api.yourdomain.com/api
flutter build ipa   --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

> Android emulator uses `10.0.2.2` to reach the host machine's `localhost`.
> iOS simulator uses `localhost` directly.

---

## 4. Full Phase Execution Plan

| # | Spec | Name | Backend | Flutter | Status |
|---|------|------|---------|---------|--------|
| B1 | `b01-core-api` | Core Django API | ✅ Complete | — | Done |
| B2 | `b02-overrides-api` | Overrides Endpoints | New endpoints for existing model | — | 🔲 Before F6 |
| B3 | `b03-actuals-api` | Actuals API | New model + endpoints | — | 🔲 Before F6 |
| B4 | `b04-auth` | JWT Authentication | JWT + user scoping | — | 🔲 Before F7 |
| F1 | `f01-flutter-foundation` | Foundation & Navigation | None | Project boots on all 3 targets | 🔲 Next |
| F2 | `f02-gam3a-manager` | Gam3a Manager | None | Full CRUD on all platforms | 🔲 Planned |
| F3 | `f03-dashboard-charts` | Dashboard & Charts | None | KPI cards + chart + table | 🔲 Planned |
| F4 | `f04-scenario-simulator` | Scenario Simulator | None | What-if simulation | 🔲 Planned |
| F5 | `f05-ai-chat` | AI Chat | None | Bilingual Claude chat modal | 🔲 Planned |
| F6 | `f06-overrides-actuals` | Overrides & Actuals UI | Requires B2 + B3 | Override + actuals screens | 🔲 Planned |
| F7 | `f07-auth` | Authentication | Requires B4 | Login/register, per-user data | 🔲 Planned |
| F8 | `f08-offline-notifications` | Offline & Notifications | None | Offline cache + push reminders | 🔲 Planned |

---

## 5. Flutter Phase Specs

---

### Flutter Phase F1 — Foundation & Navigation
**Spec**: `specs/f01-flutter-foundation/spec.md`
**Branch**: `f01-flutter-foundation`
**Backend required**: B1 (already complete)
**New packages**: `go_router` · `flutter_riverpod` · `riverpod_annotation` · `dio` · `shared_preferences`

#### Summary
Bootstrap the Flutter project for all three targets. Configure the layered architecture
(Dio · Riverpod · GoRouter), apply the design token theme, and render live simulation data
on screen. This phase proves the client communicates with the Django backend on all three
platforms.

#### Definition of Done
- [ ] `flutter run` succeeds on Chrome, Android emulator, and iOS simulator with zero errors
- [ ] `GET /api/simulate` deserializes into `SimulationResult` and renders on screen
- [ ] All 3 navigation destinations reachable without crash
- [ ] Design tokens applied — colors match Section 3.7
- [ ] `flutter analyze` reports zero warnings
- [ ] `SimulationProvider` unit test covers loading, success, and network error states

#### User Stories

**Story 1 — View live simulation on any device (P1)**
The user opens the app on web, iOS, or Android and sees the 12-month simulation data
fetched from the live Django backend.

Acceptance Scenarios:
1. **Given** the backend is running, **When** the Dashboard loads, **Then** all 12 monthly rows and KPI totals render within 2 seconds.
2. **Given** the backend is unreachable, **When** the Dashboard loads, **Then** an error widget and "Retry" button appear.
3. **Given** a fetch is in-flight, **When** the screen is visible, **Then** a `CircularProgressIndicator` shows and no partial data renders.

**Story 2 — Navigate between main sections (P2)**
The user moves between Dashboard, Gam3as, and Scenario.

Acceptance Scenarios:
1. **Given** the app is on mobile (<600px), **When** a bottom nav item is tapped, **Then** the screen renders with no frame drop.
2. **Given** the app is on web (≥600px), **When** a navigation rail item is clicked, **Then** the screen renders and the item is visually active.

#### Functional Requirements
- **FR-001**: API base URL MUST come from `--dart-define=API_BASE_URL` — never hardcoded.
- **FR-002**: `ApiService` Dio instance MUST set 10s connection timeout and 30s receive timeout.
- **FR-003**: App MUST use adaptive navigation: `NavigationBar` on <600px, `NavigationRail` on ≥600px.
- **FR-004**: Root MUST be wrapped in `ProviderScope`; all state via `AsyncNotifierProvider`.
- **FR-005**: `SimulationResult`, `MonthlyRow`, and `Kpis` MUST be immutable with `fromJson` and full null-safety.
- **FR-006**: All colors MUST reference `AppColors` — no inline hex strings.
- **FR-007**: `flutter analyze` MUST report zero issues on initial commit.

#### Success Criteria
- **SC-001**: Simulation data renders within 2 seconds on local network on all three platforms.
- **SC-002**: `SimulationProvider` unit tests pass for loading, success, and error states.

---

### Flutter Phase F2 — Gam3a Manager
**Spec**: `specs/f02-gam3a-manager/spec.md`
**Branch**: `f02-gam3a-manager`
**Backend required**: B1 (already complete)
**New packages**: None

#### Summary
Full CRUD management of gam3as from any platform. Saving any change invalidates
`simulationProvider` so the Dashboard reflects updated projections immediately.

#### Definition of Done
- [ ] All four endpoints (`GET POST PUT DELETE /api/gam3as`) called correctly
- [ ] Form validation blocks submission on missing required fields
- [ ] Saving or deleting triggers a simulation re-fetch on the Dashboard
- [ ] Delete requires `AlertDialog` confirmation
- [ ] `Gam3aProvider` unit tests: add, update, delete, validation error

#### User Stories

**Story 1 — Add a new gam3a (P1)**

Acceptance Scenarios:
1. **Given** the form is complete, **When** Save is tapped, **Then** `POST /api/gam3as` returns 201 and the card appears.
2. **Given** Name is empty, **When** Save is tapped, **Then** a validation error shows and no request fires.
3. **Given** a gam3a is saved, **When** the user views the Dashboard, **Then** simulation totals include the new gam3a.

**Story 2 — Edit an existing gam3a (P2)**

Acceptance Scenarios:
1. **Given** a card is tapped, **When** the edit form opens, **Then** all current values are pre-populated.
2. **Given** the pot is changed and saved, **When** the form submits, **Then** `PUT /api/gam3as/{id}` is called and the card updates.

**Story 3 — Delete a gam3a (P3)**

Acceptance Scenarios:
1. **Given** the delete dialog is confirmed, **Then** `DELETE /api/gam3as/{id}` is called and the card disappears.
2. **Given** the delete dialog is shown, **When** Cancel is tapped, **Then** no request fires.

#### Functional Requirements
- **FR-001**: List MUST show: name, total pot (EGP), monthly contribution (red), pay window ("Apr → May"), payout month (amber), received/pending badge.
- **FR-002**: Form MUST include: name, total pot, monthly contribution, start month dropdown, payout month dropdown, end month dropdown, payout received switch.
- **FR-003**: Month dropdowns MUST show full month names and store integer values 1–12.
- **FR-004**: Save MUST call `ref.invalidate(simulationProvider)`.
- **FR-005**: Delete MUST use `showDialog` with destructive "Delete" and neutral "Cancel" actions.
- **FR-006**: API errors MUST surface as `SnackBar` — list state MUST NOT mutate on failure.

#### Success Criteria
- **SC-001**: Add, edit, and delete each complete in under 30 seconds of user interaction.
- **SC-002**: Form validation blocks all required-field violations before any API call.
- **SC-003**: Dashboard visibly updates after any gam3a change without a manual refresh.

---

### Flutter Phase F3 — Dashboard & Charts
**Spec**: `specs/f03-dashboard-charts/spec.md`
**Branch**: `f03-dashboard-charts`
**Backend required**: B1 (already complete)
**New packages**: `fl_chart: ^0.68.0`

#### Summary
Replace the Phase F1 placeholder with the full Dashboard: four KPI cards, a multi-line
`fl_chart` line chart, and a styled monthly breakdown table with payout highlights.

#### Definition of Done
- [ ] 4 KPI cards render with correct colors and `NumberFormat` EGP values
- [ ] Line chart shows 3 series with working tap tooltip at 60 fps on mid-range Android
- [ ] Monthly table scrolls all 12 rows with correct amber/red/green styling
- [ ] Widget tests for `KpiCard`, `SimulationChart`, and `MonthlyTable`

#### User Stories

**Story 1 — See KPI summary at a glance (P1)**

Acceptance Scenarios:
1. **Given** simulation data is loaded, **When** the Dashboard renders, **Then** 4 cards show: Total Invested (blue) · Total Interest (green) · Total Payments Out (red) · Final Balance (amber).
2. **Given** a value is in the thousands, **When** it renders in a card, **Then** it shows as "119,000 EGP".

**Story 2 — View fund growth on a chart (P2)**

Acceptance Scenarios:
1. **Given** the chart is rendered, **When** a data point is tapped, **Then** a tooltip shows the month name and EGP value for all 3 series.
2. **Given** the app is on web, **When** a data point is hovered, **Then** the same tooltip appears.

**Story 3 — Review the monthly breakdown table (P3)**

Acceptance Scenarios:
1. **Given** a row is a payout month, **When** it renders, **Then** the row background is `AppColors.payout` at 20% opacity with a "Payout" chip.
2. **Given** a closing balance is negative, **When** it renders, **Then** the value is `AppColors.negative`.
3. **Given** an inflow or interest value is positive, **When** it renders, **Then** it is prefixed "+" and colored `AppColors.positive`.

#### Functional Requirements
- **FR-001**: 4 `KpiCard` widgets: Total Invested (blue) · Total Interest (green) · Total Payments Out (red) · Final Balance (amber).
- **FR-002**: `SimulationChart` MUST use `fl_chart LineChart` with 3 `LineChartBarData` series.
- **FR-003**: X-axis MUST show abbreviated month names (Jan–Dec) via `SideTitles`.
- **FR-004**: Y-axis MUST format as "67K" (÷1000, suffix "K").
- **FR-005**: `LineTouchData` MUST show month name and formatted EGP for all 3 series on tap/hover.
- **FR-006**: Table columns: Month · Opening · Inflow · Interest · Payments Out · Closing · Cumul. Interest.
- **FR-007**: All table numbers MUST use `NumberFormat('#,##0.00', 'en_US')`.

#### Success Criteria
- **SC-001**: Chart renders at 60 fps on a mid-range Android device (Pixel 4a equivalent).
- **SC-002**: All 12 rows scroll without overflow on a 375px-wide screen (iPhone SE).
- **SC-003**: `KpiCard` widget test confirms correct label, value, and color for all 4 variants.

---

### Flutter Phase F4 — Scenario Simulator
**Spec**: `specs/f04-scenario-simulator/spec.md`
**Branch**: `f04-scenario-simulator`
**Backend required**: B1 (already complete)
**New packages**: None

#### Summary
Ad-hoc "what-if" simulation. The user overrides rate, investment day, and adds one-time
extra inflows per month. Results display with an amber "SIMULATION MODE" badge.
No saved data is modified.

#### Definition of Done
- [ ] `POST /api/simulate/scenario` called with correct body on Run tap
- [ ] Results show KPI cards + chart with amber SIMULATION MODE indicator
- [ ] Reset restores inputs to values from `GET /api/settings`
- [ ] `simulationProvider` (Dashboard) is NOT affected by running a scenario

#### User Stories

**Story 1 — Run a what-if scenario (P1)**

Acceptance Scenarios:
1. **Given** rate is changed to 22% and Run is tapped, **Then** `POST /api/simulate/scenario` fires with `{"annual_rate": 22.0}` and results render.
2. **Given** Reset is tapped, **Then** all inputs revert to `settingsProvider` values and results clear.
3. **Given** results are visible and the user visits the Dashboard, **Then** Dashboard data is unchanged.

**Story 2 — Add one-time inflows per month (P2)**

Acceptance Scenarios:
1. **Given** 5,000 is entered for March and Run is tapped, **Then** the request includes `"extra_inflows": {"3": 5000.0}` and March's inflow row reflects it.

#### Functional Requirements
- **FR-001**: Scenario screen loads initial rate/day from `settingsProvider`.
- **FR-002**: 12 extra inflow inputs in a responsive grid: 2 columns mobile, 4 columns web.
- **FR-003**: Run MUST call `POST /api/simulate/scenario` with only non-default fields.
- **FR-004**: Results MUST show an amber `Chip` labelled "SIMULATION MODE" above the KPI cards.
- **FR-005**: Results KPI cards MUST have an amber border.
- **FR-006**: `scenarioProvider` MUST be independent — MUST NOT call `ref.invalidate(simulationProvider)`.

#### Success Criteria
- **SC-001**: Results render within 1 second of Run tap on local network.
- **SC-002**: Dashboard is unchanged after running a scenario.

---

### Flutter Phase F5 — AI Chat
**Spec**: `specs/f05-ai-chat/spec.md`
**Branch**: `f05-ai-chat`
**Backend required**: B1 (already complete)
**New packages**: None

#### Summary
Full-screen modal chat backed by `POST /api/chat`. The backend provides full simulation
context to Claude. The UI handles bilingual Arabic/English with auto RTL detection,
a typing indicator, and suggestion chips on first open.

#### Definition of Done
- [ ] Chat opens from a FAB on the Dashboard
- [ ] Messages send to `POST /api/chat` with full history
- [ ] Arabic input triggers `TextDirection.rtl` on both bubbles
- [ ] Typing indicator renders during in-flight requests
- [ ] Suggestion chips show only when history is empty
- [ ] `ChatBubble` widget test passes for LTR and RTL variants

#### User Stories

**Story 1 — Ask a financial question in English (P1)**

Acceptance Scenarios:
1. **Given** a message is sent, **Then** a right-aligned user bubble appears and a 3-dot typing indicator shows.
2. **Given** the response arrives, **Then** the indicator is replaced by a left-aligned assistant bubble.
3. **Given** the reply contains numbers, **Then** they are formatted with commas and "EGP" suffix.

**Story 2 — Ask in Arabic with RTL reply (P2)**

Acceptance Scenarios:
1. **Given** an Arabic message is sent, **When** both bubbles render, **Then** they use `TextDirection.rtl` with correct layout.

**Story 3 — Use suggestion chips on first open (P3)**

Acceptance Scenarios:
1. **Given** no history exists, **When** the screen opens, **Then** 4 `ActionChip` widgets show.
2. **Given** a chip is tapped, **Then** it sends as a user message and the chip row disappears.

#### Functional Requirements
- **FR-001**: Chat FAB at `Alignment.bottomRight` on the Dashboard.
- **FR-002**: `POST /api/chat` body: `{"message": string, "history": [{"role": string, "content": string}]}`.
- **FR-003**: Arabic detection via `RegExp(r'[\u0600-\u06FF]')` on the message text.
- **FR-004**: `ChatBubble` accepts `isUser` boolean: `CrossAxisAlignment.end` (user) / `CrossAxisAlignment.start` (assistant).
- **FR-005**: Typing indicator: 3 dots with staggered `ScaleTransition` animation.
- **FR-006**: History lives in `chatProvider` state, cleared on provider disposal.
- **FR-007**: Suggestion chips: `"Which month will my balance peak?"` · `"Is this strategy profitable?"` · `"Summarize my financial position"` · `"ما هو الشهر الأفضل لي؟"`

#### Success Criteria
- **SC-001**: First reply arrives within 5 seconds on standard broadband.
- **SC-002**: Arabic bubbles render RTL with no overflow on a 375px screen.
- **SC-003**: `ChatBubble` widget test passes for both LTR and RTL variants.

---

### Flutter Phase F6 — Overrides & Actuals UI
**Spec**: `specs/f06-overrides-actuals/spec.md`
**Branch**: `f06-overrides-actuals`
**Backend required**: B2 + B3 must be complete first
**New packages**: None

#### Summary
Two screens that consume the new B2/B3 backend endpoints:
1. **Overrides screen** — CRUD for `MonthlyOverride` records.
2. **Actuals screen** — log real monthly values; Dashboard chart gains a dashed "Actual Balance" line.

#### Definition of Done
- [ ] Override CRUD wired end-to-end; Dashboard simulation updates on change
- [ ] Actuals logging screen wired end-to-end
- [ ] Dashboard chart shows dashed Actual Balance line when actuals exist
- [ ] Unit tests for `OverridesProvider` and `ActualsProvider`

#### User Stories

**Story 1 — Manage monthly overrides (P1)**

Acceptance Scenarios:
1. **Given** Month 1 custom inflow is set to 0 and saved, **Then** `POST /api/overrides` fires and the Dashboard simulation shows 0 for January.
2. **Given** an override is deleted, **Then** `DELETE /api/overrides/{month}` fires and the simulation reverts to calculated.

**Story 2 — Log actual monthly values (P2)**

Acceptance Scenarios:
1. **Given** May's actual values are entered and saved, **Then** `POST /api/actuals` fires and the Dashboard chart gains a dashed Actual Balance line.
2. **Given** actuals exist for some months, **When** the chart renders, **Then** the dashed line covers only logged months.

#### Functional Requirements
- **FR-001**: Overrides screen lists all `MonthlyOverride` records: month, custom inflow, custom payment, note.
- **FR-002**: Override form uses month dropdown (Jan–Dec) and nullable numeric inputs.
- **FR-003**: Saving an override calls `ref.invalidate(simulationProvider)`.
- **FR-004**: Actuals screen lists all 12 months — logged months show values, unlogged show "Not recorded".
- **FR-005**: `SimulationChart` conditionally renders a 4th `LineChartBarData` (dashed `dashArray`) for Actual Balance when `actualsProvider` has data.
- **FR-006**: Actual Balance line uses `Colors.white.withOpacity(0.7)` to contrast the three projected lines.

#### Success Criteria
- **SC-001**: Override changes reflect in the Dashboard within one provider invalidation cycle.
- **SC-002**: Actual vs projected is visually distinguishable on a 375px screen.

---

### Flutter Phase F7 — Authentication
**Spec**: `specs/f07-auth/spec.md`
**Branch**: `f07-auth`
**Backend required**: B4 must be complete first
**New packages**: `flutter_secure_storage: ^9.0.0`

#### Summary
Login and registration. Tokens stored in `flutter_secure_storage`. Dio `AuthInterceptor`
attaches the token on every request and handles silent refresh on 401.

#### Definition of Done
- [ ] Register and login work end-to-end on all platforms
- [ ] GoRouter `redirect` sends unauthenticated users to `/login`
- [ ] `AuthInterceptor` attaches `Authorization: Bearer` on every request
- [ ] Silent token refresh works — no logout on mid-session token expiry
- [ ] Two accounts see only their own data
- [ ] `AuthInterceptor` unit test confirms header presence on mocked requests

#### User Stories

**Story 1 — Register and reach the Dashboard (P1)**

Acceptance Scenarios:
1. **Given** the form is complete, **When** submitted, **Then** `POST /api/auth/register` returns tokens, they are stored in `flutter_secure_storage`, and GoRouter navigates to `/dashboard`.
2. **Given** two users are registered, **When** each logs in, **Then** each sees only their own data.

**Story 2 — Stay authenticated across restarts (P2)**

Acceptance Scenarios:
1. **Given** a valid token is stored, **When** the app cold-starts, **Then** the Dashboard loads without the login screen.
2. **Given** the access token is expired but refresh token is valid, **When** the app starts, **Then** `/api/auth/refresh` is called silently and the Dashboard loads.
3. **Given** both tokens are expired, **When** the app starts, **Then** the user is redirected to `/login`.

**Story 3 — Log out cleanly (P3)**

Acceptance Scenarios:
1. **Given** Log Out is tapped, **Then** `flutter_secure_storage.deleteAll()` fires, all providers are invalidated, and GoRouter redirects to `/login`.

#### Functional Requirements
- **FR-001**: Login/Register forms validate email format and password ≥8 chars before submitting.
- **FR-002**: `AuthInterceptor` attaches `Authorization: Bearer <token>` on every Dio request.
- **FR-003**: On 401, `AuthInterceptor` attempts one token refresh; on failure clears tokens and redirects to `/login`.
- **FR-004**: GoRouter `redirect` reads `authProvider` and routes to `/login` when no valid token exists.
- **FR-005**: Logout calls `flutter_secure_storage.deleteAll()` then `ref.invalidate()` on all providers.
- **FR-006**: Password fields use `obscureText: true` with a visibility toggle `IconButton`.

#### Success Criteria
- **SC-001**: Two users register and each sees only their own data.
- **SC-002**: Token refresh is invisible — no logout on mid-session expiry.
- **SC-003**: `AuthInterceptor` unit test confirms `Authorization` header on mocked requests.

---

### Flutter Phase F8 — Offline Support & Push Notifications
**Spec**: `specs/f08-offline-notifications/spec.md`
**Branch**: `f08-offline-notifications`
**Backend required**: None
**New packages**: `connectivity_plus: ^6.0.0` · `flutter_local_notifications: ^17.0.0`
**Platform note**: Both features apply to iOS and Android only. All code guarded with `if (!kIsWeb)`.

#### Summary
Two reliability features: persist the last simulation result to `SharedPreferences` for
offline viewing, and schedule local push notifications for upcoming payout and payment months.

#### Definition of Done
- [ ] Dashboard loads from cache within 1 second in airplane mode on iOS/Android
- [ ] Offline banner shows with last-updated timestamp
- [ ] Write operations blocked offline with `SnackBar` error
- [ ] Notifications scheduled after each simulation fetch on mobile
- [ ] Notifications fire at correct time in emulator test
- [ ] All offline/notification code guarded with `if (!kIsWeb)`

#### User Stories

**Story 1 — View cached simulation while offline (P1)**

Acceptance Scenarios:
1. **Given** simulation data was previously fetched, **When** the app opens offline, **Then** cached data renders with banner: "Offline — last updated [date/time]".
2. **Given** the cache is empty and the app is offline, **When** the Dashboard loads, **Then** an error state shows: "No data available. Connect to the internet to load your simulation."
3. **Given** the app is offline, **When** the user taps "Add Gam3a", **Then** a `SnackBar` reads "This action requires an internet connection."

**Story 2 — Receive a payout reminder (P2)**

Acceptance Scenarios:
1. **Given** May is a payout month (Gam3a #3, 80,000 EGP), **When** it is April 28th at 09:00, **Then** the device shows: "Payout incoming: 80,000 EGP from Gam3a #3 arrives next month."

**Story 3 — Receive a payment-due reminder (P3)**

Acceptance Scenarios:
1. **Given** March has 13,000 EGP in payments, **When** it is March 1st at 09:00, **Then** the device shows: "Gam3a payments due: 13,000 EGP across 2 clubs this month."

#### Functional Requirements
- **FR-001**: After every successful `GET /api/simulate`, `CacheService` MUST write the raw JSON string and `DateTime.now().toIso8601String()` to `SharedPreferences`.
- **FR-002**: `simulationProvider` MUST attempt a live call first; on `DioException`, fall back to `CacheService.read()` and expose `isOffline: true` in state.
- **FR-003**: Offline banner MUST be a `MaterialBanner` at the top of the Dashboard with the last-updated timestamp.
- **FR-004**: All write-path methods MUST check `ConnectivityResult` before calling Dio; if offline, show a `SnackBar` and do NOT mutate local state.
- **FR-005**: After each simulation fetch on mobile, `NotificationService` MUST cancel all scheduled notifications and reschedule from the new data.
- **FR-006**: Payout notifications MUST schedule for the **28th of the month prior** to each payout month at 09:00 local time.
- **FR-007**: Payment notifications MUST schedule for the **1st of each month** with `payments_out > 0` at 09:00 local time.
- **FR-008**: `flutter_local_notifications` MUST request iOS permissions via `requestPermissions` and configure an Android notification channel on init.

#### Success Criteria
- **SC-001**: Dashboard renders from cache within 1 second in airplane mode on iOS and Android.
- **SC-002**: Push notifications fire within 1 minute of scheduled time in emulator test.
- **SC-003**: Zero `flutter analyze` warnings introduced in this phase.

---

## 6. Out of Scope

The following will not be built unless a new Spec Kit spec is written and approved:

| Item | Reason |
|------|--------|
| Real-time sync (WebSockets) | Complexity not justified for a personal finance app |
| Bank statement / CSV import | Requires third-party integration |
| Multi-currency support | App is EGP-only by design |
| Shared group gam3a tracking | Out of scope per original PRD |
| Multi-year simulation | Deferred to a future spec |
| Desktop targets (macOS, Windows, Linux) | Web target covers desktop use cases |
| Dark/light theme toggle | Dark theme only |
| E2E automated testing (Patrol) | Deferred post-MVP |
| Password reset via email | Requires SMTP config — post-Phase-F7 add-on |
