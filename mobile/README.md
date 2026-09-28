# Mobile — Citizen App (Flutter)

The phone/web app citizens use: OTP login, vote on live polls with real-time
results, report city issues with their GPS location, upvote and comment.
Runs on Android, iOS, and Chrome (`flutter run -d chrome`).

## Dependencies and why

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (one bloc per feature) |
| `equatable` | Value equality for bloc states/entities |
| `http` | REST calls (wrapped by `ApiClient`) |
| `flutter_secure_storage` | JWT persistence — Keychain/Keystore, survives restarts |
| `geolocator` | "Use my location" in the feedback form |
| `stomp_dart_client` | WebSocket/STOMP subscription for live poll results |

## The architecture — Clean Architecture, one feature at a time

```
lib/
├── main.dart                    Entry point + manual dependency wiring
└── lib structure per feature:
    features/<name>/
    ├── domain/                  The CORE — pure Dart, no Flutter imports
    │   ├── entities/            Business objects (User, Poll, FeedbackItem)
    │   ├── repositories/        Abstract interfaces the outside world must fulfil
    │   └── usecases/            One class per user action (SendOtp, CastVote, …)
    ├── data/                    IMPLEMENTS the domain interfaces
    │   ├── models/              JSON ⇄ entity mapping (fromJson/toJson)
    │   ├── datasources/         Actual HTTP calls (via core ApiClient)
    │   └── repositories/        <Name>RepositoryImpl: calls datasource,
    │                            converts exceptions → Failures
    └── presentation/            Widgets + state
        ├── bloc/                Events in → States out; calls usecases
        └── pages/               Screens (login, poll detail, submit form, …)
```

**The dependency rule:** `presentation → domain ← data`. The domain layer
never imports Flutter or http; the UI never imports http. Swap the whole
data layer and the screens wouldn't notice.

### A concrete request: casting a vote

```
PollDetailPage (user taps Cast vote)
  → PollsBloc.add(VoteRequested(pollId, optionId))
    → CastVote usecase (domain)
      → PollRepository.vote (interface)
        → PollRepositoryImpl (data): HTTP POST via ApiClient,
           ServerException → ServerFailure
    ← PollsBloc emits VoteRecorded(poll, pollsList)
      → detail page animates result bars; list page shows VOTED chip
```

Errors never reach the UI as exceptions: the data layer throws typed
`exceptions` (network/server), repositories translate them into `Failure`
subclasses, blocs catch `Failure` and emit failure states the pages render.

## `core/` — the shared plumbing

| File | What it does |
|---|---|
| `constants/api_constants.dart` | Base URL of the gateway. Default `http://10.0.2.2:8080/api/v1` (Android emulator); override with `--dart-define=API_BASE_URL=…` |
| `network/api_client.dart` | All HTTP: attaches the stored Bearer token, **auto-refreshes once on 401 and retries**, unwraps the `ApiResponse` envelope, throws typed exceptions |
| `network/token_store.dart` | Reads/writes the JWT pair in secure storage |
| `errors/exceptions.dart` | Data-layer exceptions (Network/Server/Cache) |
| `errors/failures.dart` | Domain-layer failures (sealed) — what blocs catch |
| `themes/app_theme.dart` | Material 3 light/dark theme from one seed color |
| `l10n/` | gen_l10n ARBs (English / हिन्दी / मराठी) → generated `AppLocalizations`; language persisted by `LocaleCubit` |
| `utils/validators.dart` | Phone (10–15 digits), OTP (6 digits), name validation |

## Features

### auth
Login page (phone) → OTP verification page (code + name for first login) →
home. `AuthBloc` also restores the session on app start
(`AuthSessionRequested` → stored token → `/me`) and handles logout (revokes
the refresh token server-side, clears storage).

### polls
List page (status chips, VOTED chip, pull-to-refresh) and detail page
(RadioGroup selection → vote → animated result bars; LIVE badge; STOMP
subscription in `_connectLive` pushes `PollLiveUpdate` events so bars move
without refresh). Bloc states always carry the latest list snapshot so
voting or an error never blanks the list.

### feedback
List page (category icons, status chips, upvote buttons, status filter
chips) and submit page (category dropdown, title/description, "Use my
current location" via geolocator with manual lat/lng fallback — permission
denials degrade gracefully). Comment/detail UI is a natural next addition;
the API layer already supports it.

## Running

```bash
flutter pub get
flutter run                                        # picks a device
flutter run -d <deviceId> \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1
flutter analyze && flutter test                    # must both be green
```

Device networking cheat sheet:

| Target | API base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8080/api/v1` (default) |
| Physical phone (USB) | run `adb reverse tcp:8080 tcp:8080`, then `localhost:8080` works |
| Physical phone (WiFi adb) | same `adb reverse` trick over the wireless connection |
| Chrome / iOS simulator | `http://localhost:8080/api/v1` |

## Tests

- `test/validators_test.dart` — phone/OTP validation rules.
- Blocs and models are structured for easy test coverage
  (pure constructors + injected repositories).

## Adding a new feature (checklist)

1. `features/<name>/domain/` — entity + repository interface + usecases.
2. `features/<name>/data/` — model (JSON), remote data source (ApiClient
   calls), repository impl (exceptions → Failures).
3. `features/<name>/presentation/` — bloc (events/states/handlers) + pages.
4. Provide the bloc in `main.dart`; add navigation from `home_shell.dart`.
5. `flutter analyze && flutter test` must stay green.
