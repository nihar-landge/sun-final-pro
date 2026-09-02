# Feature: Authentication (Phone OTP + JWT)

Login without passwords: a citizen enters a phone number, receives a 6-digit
code, and gets a JWT session. Admins log in exactly the same way — the only
difference is the role stored on their user record.

## The flow

```
Phone app                    Gateway :8080                auth-service :8081         Redis        authdb
   │  POST /auth/otp/send        │                              │                     │              │
   ├────────────────────────────>│  (rate limit: 1/s, burst 5)  │                     │              │
   │                             ├─────────────────────────────>│ SET otp:98765… (5m) │              │
   │                             │                              ├────────────────────>│              │
   │<── {devOtp: "123456"} ──────│<── dev echo (no real SMS) ───┤ [DEV SMS] to log    │              │
   │                             │                              │                     │              │
   │  POST /auth/otp/verify      │                              │                     │              │
   ├────────────────────────────>├─────────────────────────────>│ compare + delete key│              │
   │                             │                              ├────────────────────>│              │
   │                             │                              ├── upsert user ─────────────────────>│
   │<── accessToken + refreshToken ─────────────────────────────┤ SET refresh:{token} │              │
   │                             │                              │   (30 days)         │              │
   │                             │                              │                     │              │
   │  GET /auth/me  (Bearer JWT) │                              │                     │              │
   ├────────────────────────────>│ validate JWT, inject X-User-*│                     │              │
   │                             ├─────────────────────────────>│ look up profile ───────────────────>│
   │<── user profile ────────────│<─────────────────────────────┤                     │              │
```

## Key rules

| Rule | Where enforced | Detail |
|---|---|---|
| OTP is 6 digits, lives 5 minutes | `OtpService` | Redis key `otp:{phone}`, TTL `otp.ttl` |
| Max 1 send per 60s per phone | `OtpService.sendOtp` | Redis `setIfAbsent` on `otp:rl:{phone}` |
| Max 5 wrong attempts | `OtpService.verifyOtp` | Counter `otp:att:{phone}`; hitting the cap revokes the OTP |
| One person, one account | `users.phone UNIQUE` | Register-on-first-login: first verify creates the record |
| Access token 15 min | `app.jwt.access-ttl` | HS256, claims: sub(userId), phone, role, name |
| Refresh token 30 days, rotating | `AuthService` | Random 48-byte token in Redis; **used = deleted**, replay → 401 |
| Roles | `users.role` | CITIZEN (default) / MODERATOR / ADMIN |
| Dev echo | `app.otp.dev-echo` | Returns the OTP in the API response. **Never enable in prod** |

## Where the code lives

| Concern | File |
|---|---|
| Endpoints | `backend/auth-service/.../controller/AuthController.java` |
| OTP lifecycle | `backend/auth-service/.../service/OtpService.java` |
| Login + token issue/rotation | `backend/auth-service/.../service/AuthService.java` |
| JWT sign/verify | `backend/auth-service/.../security/JwtTokenProvider.java` |
| SMS abstraction (dev = log) | `backend/auth-service/.../service/SmsSender.java` + `LoggingSmsSender.java` |
| Gateway validation + identity headers | `backend/api-gateway/.../security/JwtAuthGlobalFilter.java` |
| Seeded dev admin (9999999999) | `backend/auth-service/.../db/migration/V2__seed_admin.sql` |
| Mobile: login pages + session restore | `mobile/lib/features/auth/presentation/pages/` + `presentation/bloc/auth_bloc.dart` |
| Mobile: secure token storage | `mobile/lib/core/network/token_store.dart` |
| Admin panel login (role-gated) | `admin/lib/features/auth/admin_auth_bloc.dart` |

## The gateway's job (why services stay simple)

`JwtAuthGlobalFilter` runs before routing:

1. Public paths (`/api/v1/auth/otp/**`, `/auth/token/refresh`, `/ws/**`,
   actuator, docs) pass through.
2. Everything else needs `Authorization: Bearer <JWT>` — invalid/expired → 401 JSON.
3. It **strips** any client-supplied `X-User-Id/Role/Name` (no spoofing), then
   **injects** the verified ones from the JWT claims.
4. Services read identity with `@CurrentUser GatewayUser` (from the shared
   `common` module) — no JWT parsing downstream.

## Session persistence in the apps

- Tokens are stored in platform **secure storage** (`TokenStore` in mobile,
  `AdminApiClient` in admin).
- On app start the mobile app fires `AuthSessionRequested` → reads the stored
  access token → calls `/me` → lands inside the app (no re-login).
- Any 401 triggers **one transparent refresh** (`/auth/token/refresh`) and a
  retry; if that fails the session is cleared and the user sees the login page.

## Try it

```bash
curl -s -X POST localhost:8080/api/v1/auth/otp/send \
  -H 'Content-Type: application/json' -d '{"phone":"9876543210"}'
# -> devOtp in the response (dev mode) or: grep "DEV SMS" /tmp/auth-service.log

curl -s -X POST localhost:8080/api/v1/auth/otp/verify \
  -H 'Content-Type: application/json' \
  -d '{"phone":"9876543210","code":"<otp>","name":"Nihar"}'
# -> accessToken + refreshToken + user

curl -s localhost:8080/api/v1/auth/me -H "Authorization: Bearer <accessToken>"
```

Error codes you can hit: `OTP-401` (wrong/expired), `OTP-429` (cooldown or too
many attempts), `AUT-401` (bad token). Full contract:
[api/auth-openapi.yaml](../api/auth-openapi.yaml).
