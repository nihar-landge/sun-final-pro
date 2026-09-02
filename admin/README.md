# Admin — Web Admin Panel (Flutter Web)

The back-office for the platform: triage citizen reports, manage polls, watch
analytics, and manage user roles. Runs in Chrome (`flutter run -d chrome`) or
any browser via `flutter build web`.

## Screens

| Tab | What the admin does there |
|---|---|
| **Polls** | List all polls with status + vote counts; **New poll** (title, description, dynamic option rows — published as ACTIVE starting now for 7 days); **Close** an active poll |
| **Feedback** | Triage list with status filter chips (All/Open/In review); per-item menu: Mark in review / Mark resolved / Re-open. Transitions are server-validated and audited |
| **Analytics** | KPI cards (polls, votes, totals), feedback status/category distribution bars, average resolution hours, and the live RabbitMQ event feed |
| **Users** | Search by name/phone, filter by role, change any user's role (Citizen/Moderator/Admin). Your own row is locked — the server rejects self-demotion |

Login is the same OTP flow as citizens, but after sign-in the app calls
`/auth/me` and shows **"access denied"** unless the role is ADMIN. The dev
admin account is phone `9999999999` (seeded by Flyway migration `V2`).

## Structure

```
lib/
├── main.dart                       App entry, providers, login gate,
│                                   dashboard shell (4 tabs) + all tab UIs
├── core/
│   └── api_client.dart             AdminApiClient: token persistence
│                                   (secure storage), auto-refresh on 401,
│                                   ApiResponse unwrapping, typed errors
└── features/                       One bloc per dashboard tab
    ├── auth/admin_auth_bloc.dart       OTP login, /me role gate, logout
    ├── polls/admin_polls_bloc.dart     list / create / close polls
    ├── feedback/admin_feedback_bloc.dart  triage list + status changes
    ├── analytics/admin_analytics_bloc.dart  poll + feedback summaries,
    │                                       recent events (3 parallel calls)
    └── users/admin_users_bloc.dart     user search + role transitions
```

Every bloc follows the same shape: sealed `Event` classes → sealed `State`
classes (Loading / Loaded / Message / Failure) → handlers calling
`AdminApiClient.request()`. Failures surface as snackbars via the bloc
listener in each tab.

## Running

```bash
flutter pub get
flutter run -d chrome            # or: flutter build web && serve build/web
flutter analyze                  # must be green
```

API base URL defaults to `http://localhost:8080/api/v1`; override with
`--dart-define=API_BASE_URL=…` when the gateway runs elsewhere.

## Notes

- Sessions persist in secure storage with transparent token refresh, same as
  the citizen app.
- The panel is a **single-window app** — the tab bar keeps all four blocs
  alive, so switching tabs never refetches unless you explicitly refresh.
- Custom distribution bars in the Analytics tab are deliberately dependency-
  free (Stack + FractionallySizedBox) — no chart package to maintain.
