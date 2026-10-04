# System Architecture

CivicPulse is a microservices system: one API gateway, four Spring Boot
business services, one supporting Node.js/Express service, and four logical
MySQL databases — one owned per service.

## The picture

```
   Flutter Citizen App              React Admin (Vite + react-leaflet)
            └───────────────┬──────────────────┘
                            ▼
              Spring Cloud Gateway  :8080
              (JWT validation · role headers · routing · CORS)
                            │
   ┌──────────────┬─────────┴──────┬───────────────────┐
   ▼              ▼                ▼                   ▼
auth-service   poll-service   feedback-service   notification-service
  :8081         :8082            :8083                :8084
  authdb        polldb          feedbackdb          notificationdb
                                                     │ after commit
                                                     ▼
                                          Express email-service :8090
                                                     │
                                                 SMTP / dev log
```

Clients never call a service directly — the gateway is the single entry
point (and the only externally published application port).

## Service responsibilities

| Service | Owns | Responsibility |
|---|---|---|
| api-gateway | — | Single entry point: validates JWTs, strips/injects identity headers, routes, CORS |
| auth-service | authdb | Registration, login, BCrypt hashing, JWT issuance, user/role management |
| poll-service | polldb | Poll CRUD, one-person-one-vote voting, results, close, poll analytics |
| feedback-service | feedbackdb + uploads | Civic reports: geo-tagging, photos, near-me, upvotes, comments, admin triage, audit |
| notification-service | notificationdb | Citizen notification inbox; fan-out of status-change emails |
| email-service (Express) | none | One job: render + send a report-status email. No DB, no business logic |

## Trust boundary (why identity headers are safe)

```
Client ── Authorization: Bearer <jwt> ──► Gateway
                                            │ verifies HS256 signature + issuer + expiry
                                            │ strips any client-sent X-User-* headers
                                            ▼
                     injects X-User-Id / X-User-Role / X-User-Name / X-User-Email
                                            │
                                            ▼
                            services resolve @CurrentUser GatewayUser
```

A client that forges `X-User-Role: ADMIN` without a token gets 401 at the
gateway. A client that reaches a service directly cannot — in Docker only
the gateway is published, and in Kubernetes all services are ClusterIP.

## Two request flows worth knowing

**Vote (poll-service):**

```
POST /api/v1/polls/{id}/vote
  → gateway validates JWT
  → poll open check → INSERT poll_participation (composite PK)
      └── second vote violates the PK → 409 Already Voted
  → INSERT ballot (anonymous) → UPDATE poll_options.votes_count
  → response: fresh results
```

**Status change (the microservice chain):**

```
PUT /api/v1/feedback/{id}/status   (admin)
  → feedback-service: admin check → allowed transition?
    → UPDATE feedback SET status …
    → INSERT feedback_status_history        [TRANSACTION COMMITS]
  → AFTER COMMIT only: HTTP POST notification-service /internal/notifications
      → INSERT notificationdb.notifications
      → HTTP POST email-service /api/email/report-status (X-Service-Key)
          → SMTP (dev: logs the email)
```

## Failure tolerance

The report-status transaction and notification delivery are deliberately
independent:

- The event is published with `@TransactionalEventListener(AFTER_COMMIT)` —
  it runs strictly after the commit, so nothing it does can roll the update
  back.
- The HTTP call has a 3 s timeout and every failure (connection refused,
  timeout, 5xx) is caught and logged.
- Live-verified during development: with notification-service stopped, a
  status change still returned 200 in ~100 ms.
- The same contract holds one hop further: if the email service is down,
  the inbox row is already saved and the in-app notification still works.

That gives the viva line: *"notification delivery is a supporting concern,
not a critical dependency."*

## Data-ownership rule

Services reference each other's data by plain ID (user_id, poll_id,
feedback_id) — there are **no foreign keys across databases**. Composite
primary keys encode the hard business rules (one vote per poll, one upvote
per report) inside the database itself.

## What was deliberately removed

The earlier exploration carried Redis, RabbitMQ, WebSocket/STOMP, FCM push,
pre-signed cloud uploads and phone-OTP auth. The final architecture drops
them: REST polling replaces WebSockets, multipart local storage replaces
pre-signed uploads, email+password replaces OTP, and the in-app inbox
replaces push. The heavier variant is preserved on the `advanced` branch.
