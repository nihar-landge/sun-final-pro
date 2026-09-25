# Public Feedback & Polling System

A civic engagement platform where citizens vote on live city polls and submit
geo-tagged feedback (roads, water, sanitation...) with photos, while admins
track resolution and analytics.

**CDAC Final Project — Mobile Computing** · Flutter + Spring Boot microservices
+ PostgreSQL/PostGIS + Kubernetes.

![Architecture](docs/architecture.md)

## Documentation

Everything is documented so a newcomer can understand the system without
asking anyone:

**Start here**

- [docs/project-structure.md](docs/project-structure.md) — annotated map of every folder and key file
- [docs/architecture.md](docs/architecture.md) — system diagram, request flows, design decisions
- [docs/setup-guide.md](docs/setup-guide.md) — run everything on a new machine

**Feature deep-dives** (what it does, how it works, where the code lives,
how to demo it)

| Feature | Doc |
|---|---|
| Phone OTP login, JWT, session restore | [docs/features/authentication.md](docs/features/authentication.md) |
| Polls & one-person-one-vote | [docs/features/polls.md](docs/features/polls.md) |
| Live results (WebSocket/STOMP) | [docs/features/live-results.md](docs/features/live-results.md) |
| Geo-tagged feedback, workflow, upvotes | [docs/features/feedback.md](docs/features/feedback.md) |
| Event pipeline & notifications (RabbitMQ) | [docs/features/notifications-events.md](docs/features/notifications-events.md) |
| Admin user & role management | [docs/features/user-management.md](docs/features/user-management.md) |
| Analytics dashboard | [docs/features/analytics.md](docs/features/analytics.md) |

**Reference**

- [docs/database-schema.md](docs/database-schema.md) — ERD + every table
- [docs/api/](docs/api/) — OpenAPI specs (auth, polls, feedback)
- [docs/project-plan.md](docs/project-plan.md) — 12-week roadmap and status
- Per-folder guides: [backend/README.md](backend/README.md) · [mobile/README.md](mobile/README.md) · [admin/README.md](admin/README.md) · [infra/README.md](infra/README.md) · [k8s/README.md](k8s/README.md)

## Repository layout

| Path | Contents |
|---|---|
| `backend/` | Maven multi-module: `common`, `api-gateway` (:8080), `auth-service` (:8081), `poll-service` (:8082), `feedback-service` (:8083), `notification-service` (:8084), `sentiment-service` (:8085) |
| `mobile/` | Flutter citizen app (clean architecture: core/ + features/{auth,polls,feedback}) |
| `admin/` | Flutter web admin panel (polls, feedback triage, analytics, user management) |
| `infra/` | Docker Compose for PostgreSQL+PostGIS, Redis, MinIO, RabbitMQ |
| `k8s/` | Kubernetes manifests (deployed in weeks 9-10) |
| `docs/` | Architecture, DB schema, setup guide, API specs, 12-week plan |
| `.github/workflows/ci.yml` | CI: backend tests + Flutter analyze/test |

## Current status — core features working end-to-end

1. `infra/docker-compose.yml` boots all data services (PostGIS `postgis`
   extension enabled in `feedbackdb`).
2. **auth-service**: phone-OTP login (Redis-backed codes, rate limiting,
   attempt capping), JWT access tokens (15 min) + rotating refresh tokens
   (30 days), `users` table via Flyway. Swagger UI at
   <http://localhost:8081/swagger-ui.html>. Dev admin account seeded:
   phone `9999999999`.
3. **api-gateway**: routes `/api/v1/{auth,polls,feedback}/**`, validates JWTs
   at the edge, forwards verified identity as `X-User-*` headers, and
   rate-limits OTP sends (1/s refill, burst 5 per IP → HTTP 429).
4. **poll-service**: admin poll creation, one-person-one-vote voting
   (enforced by the `poll_participation` composite PK), atomic vote counts,
   live results with a short-TTL Redis cache, early close, and **live result
   broadcasts over STOMP WebSocket** (`/ws` → `/topic/polls/{id}`).
5. **feedback-service**: geo-tagged submission (PostGIS), paged listing with
   filters, `near-me` radius query ordered by real distance, one-upvote-per-
   citizen, audited admin status workflow, comments — publishing
   `feedback.created` / `feedback.status.changed` events to RabbitMQ.
6. **notification-service**: consumes feedback events from RabbitMQ and
   serves the recent event feed (`/api/v1/notifications/recent`, admin).
7. **Analytics** (admin-only): poll participation summary and feedback
   status/category/resolution-time stats powering the admin dashboard's
   Analytics tab (KPI cards, distribution bars, live event feed).
8. **Flutter citizen app — CivicPulse** (rebranded): 5-tab navigation
   (Home / Polls / Report / Alerts / Profile), dashboard home with featured
   poll + nearby issues + own activity, Active/Upcoming/Closed poll tabs with
   result previews and countdowns, guided 5-step report wizard **with
   similar-report detection before submission**, full report detail with
   progress timeline + comments, **OpenStreetMap issue map** with
   status-colored pins, alerts feed derived from own reports + closing polls,
   Material 3 teal design system with **dark mode** and semantic status
   colors. Secure token storage + transparent refresh throughout.
9. **Flutter admin console — municipal operations dashboard** (desktop-first
   sidebar shell): Dashboard (6 KPI cards + charts + live event feed),
   **Reports triage** (searchable/filterable table, multi-select with bulk
   status updates, CSV export, right-side operation drawer with status
   dropdown, officer assignment, public/internal notes, timeline, comments),
   **Poll builder** (dynamic options, duplicate, close, results), live issue
   **map** (OSM, status-colored pins, click-to-drawer), Analytics, user
   management (admin-only), and an **Audit Log** of every status transition.
   MODERATOR role supported end-to-end (sees moderation, not users).
10. **Report photos**: citizens attach up to 3 photos in the report wizard;
    uploads go **directly to MinIO** via time-limited pre-signed URLs
    (photo bytes never touch the Java services), view URLs are minted per
    detail request, and the 3-photo cap is server-enforced (409).
11. **Observability & testing**: every service exposes Prometheus metrics
    (`/actuator/prometheus`, scraped by the compose Prometheus at :9090,
    dashboards at Grafana :3000), `scripts/e2e.sh` verifies 27 system
    guarantees in one run (also a CI job), and `scripts/load/vote.js` is a
    k6 load test asserting the blueprint's p95 < 200 ms target.
12. CI runs the backend build plus Testcontainers-PostgreSQL integration
    tests (`TEST_DOCKER=true`), the E2E suite, and Flutter analyze/test.

## Quickstart

```bash
# 1. Infrastructure (PostgreSQL+PostGIS, Redis, MinIO, RabbitMQ)
docker compose -f infra/docker-compose.yml up -d

# 2. Backend — two terminals
cd backend && ./mvnw -pl auth-service spring-boot:run
cd backend && ./mvnw -pl api-gateway spring-boot:run

# 3. Try the vertical slice (dev profile echoes the OTP in the response)
curl -s -X POST localhost:8080/api/v1/auth/otp/send \
  -H 'Content-Type: application/json' -d '{"phone":"9876543210"}'
# -> {"success":true,"data":{...,"devOtp":"123456"},...}
# In the app itself, the OTP screen shows a "Dev OTP" chip you tap to fill.
# (Logs live in Kubernetes now: kubectl logs -n feedbackapp deploy/auth-service)

# 4. Mobile app (Android emulator reaches the host via 10.0.2.2)
cd mobile && flutter run
```

Full details: [docs/setup-guide.md](docs/setup-guide.md) ·
Architecture: [docs/architecture.md](docs/architecture.md) ·
Database: [docs/database-schema.md](docs/database-schema.md) ·
12-week plan: [docs/project-plan.md](docs/project-plan.md)

## Development principles

- **Microservices data boundary** — each service owns its own database
  (`authdb`, `polldb`, `feedbackdb`); user IDs are stored without
  cross-database foreign keys.
- **Flyway owns the schema** — no JPA auto-DDL; every table change is a
  versioned migration in the owning service.
- **One person, one vote** — `poll_participation` composite primary key
  `(poll_id, user_id)` is the hard enforcement; entities use
  `Persistable.isNew()` so JPA inserts (never merges) and the PK violation
  surfaces as HTTP 409. Ballots carry no user ID so results can't be traced
  back to voters.
- **JWT at the edge** — the gateway validates tokens once and forwards
  `X-User-Id` / `X-User-Role`; downstream services trust these headers
  (network-boundary trust) via the shared `@CurrentUser` resolver.
- **Dev echo OTP** — `app.otp.dev-echo=true` returns the OTP in the API
  response so the flow works without an SMS provider. Never enable in prod.
- **Integration tests in CI** — Testcontainers-PostgreSQL tests
  (`TEST_DOCKER=true`) prove the uniqueness constraints on a real database;
  they are skipped locally on Docker Desktop builds that reject the
  Testcontainers client version (the same guarantees are verified live via
  the E2E curl flow).
