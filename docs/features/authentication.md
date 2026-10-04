# Feature: Authentication (email + password)

Registration takes name, email and password; the password is BCrypt-hashed
and the account is created with role CITIZEN (the register API does not
accept a role). Login verifies the hash and issues a single HS256 JWT valid
24 hours with claims `sub`, `email`, `role`, `name` — no refresh tokens, no
server session.

The API gateway validates every JWT at the edge, strips client-supplied
`X-User-*` headers and injects verified `X-User-Id/Role/Name/Email`, which
services resolve through the shared `@CurrentUser` argument resolver.
Role checks happen in the services (admin-only endpoints return 403), and
the hard identity rules live in the database: `users.role` is an
ENUM('CITIZEN','ADMIN') and email is UNIQUE. The mobile app keeps the token
in flutter_secure_storage and restores the session via `/auth/me`; the React
admin does the same in localStorage. Phone OTP, SMS, Redis and refresh-token
rotation were removed in the final architecture (preserved on `advanced`).
