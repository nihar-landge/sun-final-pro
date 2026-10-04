# CivicPulse

A civic engagement platform where citizens report local issues with photos and
location, vote in community polls, and track resolutions — while
administrators triage everything from a web dashboard.

**CDAC Final Project — Mobile Computing**
Flutter (citizen app) · React (admin) · Spring Boot microservices · MySQL ·
Node.js/Express email service · Docker / GitHub Actions / Kubernetes

> **The story:** the citizen application is developed in Flutter, the
> administration dashboard in React, and the backend as Spring Boot
> microservices — auth, polls, feedback and notifications — behind a Spring
> Cloud Gateway. Each service owns its logical MySQL database. Node.js and
> Express are used as a supporting email service. Docker, GitHub Actions and
> Kubernetes make up the DevOps layer.

## Architecture

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

Design highlights (each one explained in [docs/architecture.md](docs/architecture.md)):

- **Database-per-service** — four logical MySQL databases on one server;
  services reference each other's data by ID, never with cross-database FKs.
- **JWT at the edge** — the gateway validates the token, strips
  client-supplied `X-User-*` headers and injects verified ones. One person
  one vote and one-upvote-per-report are enforced by **composite primary
  keys**, not application code.
- **Notifications after commit** — a status change commits first; the
  notification + email happen strictly afterwards, so a notification- or
  email-service outage can never fail a report update (verified live).
- **Multipart photos on local disk** — no cloud storage in the core stack;
  files are served by feedback-service at `/uploads/**`.

## Quickstart

Prereqs: Docker Desktop, JDK 21, Flutter (for the app), Node 20 (for the
admin/email dev servers — the containers already bundle them).

```bash
# 1. Full stack: MySQL + gateway + 4 services + email + React admin
docker compose up -d --build

# 2. Wait for the gateway, then run the 27-check guarantee suite
scripts/e2e.sh localhost:8080          # → E2E: 27 passed, 0 failed

# 3. Admin dashboard
open http://localhost:4173             # admin@civicpulse.in / Admin@123

# 4. Citizen app on an emulator (10.0.2.2 = host loopback)
cd mobile && flutter run
#    …or a physical device over USB:
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Optional monitoring profile: `docker compose --profile monitoring up -d`
(Prometheus :9090, Grafana :3000, admin/admin).

Prefer host-run services? `scripts/run-local.sh` boots the five jars against
the compose MySQL (port 3307).

## Repository layout

| Path | Contents |
|---|---|
| `services/` | Maven multi-module: `common`, `api-gateway` (:8080), `auth-service` (:8081), `poll-service` (:8082), `feedback-service` (:8083), `notification-service` (:8084) |
| `email-service/` | Node.js + Express supporting email service (:8090, no database) |
| `mobile/` | Flutter citizen app (auth, home, polls, report wizard, map, alerts, profile) |
| `admin-react/` | React admin dashboard (Vite, React Router, axios, react-leaflet, Vitest) |
| `docker-compose.yml` | Full local stack — MySQL + 6 services + nginx-served admin |
| `infra/` | MySQL init script, Prometheus/Grafana config |
| `k8s/` | Kubernetes manifests (namespace, configmap, secret, deployments incl. HPA on the gateway) |
| `.github/workflows/` | `ci.yml` (4 test/build jobs) · `e2e.yml` (compose stack + 27-check suite) |
| `docs/` | Architecture, database schema, DevOps, setup guide, feature notes |
| `scripts/` | `e2e.sh` (27 guarantees), `run-local.sh`, k6 load test |

## Features

- **Auth** — email + password (BCrypt), single 24 h JWT with email claim,
  roles CITIZEN / ADMIN. Phone OTP, refresh rotation and Redis are gone.
- **Polls** — admin create/close/duplicate; one-person-one-vote enforced by
  the `poll_participation` composite PK; anonymous ballots; results refreshed
  by 5-second REST polling (WebSocket removed).
- **Reports** — geo-tagged (MySQL `POINT SRID 4326`), multipart photos served
  at `/uploads/**`, near-me radius query (`ST_Distance_Sphere`), upvotes and
  comments with composite-PK uniqueness, similar-report check in the wizard.
- **Triage** — admin status workflow (OPEN → IN_PROGRESS → RESOLVED) with
  allowed-transition validation, assignment, public/internal notes, hiding,
  and a full audit trail.
- **Notifications** — in-app inbox (unread count, mark read) owned by
  notification-service; report-status emails via the Express service
  (dev mode logs them; SMTP via env).
- **Citizen app extras** — OSM issue map + mini-map, community impact stats,
  dark mode, English / हिन्दी / मराठी.
- **Quality gates** — `mvn verify` (unit + Testcontainers MySQL), Flutter
  analyze/test, Vitest + build, supertest, and the 27-check E2E suite.

## Dev credentials (dev only)

| What | Value |
|---|---|
| Admin login | `admin@civicpulse.in` / `Admin@123` |
| MySQL root | `mysql_root_devpw` |
| MySQL app user | `feedback` / `mysql_feedback_pw` |
| Service key | `dev-service-key` |

All committed config uses placeholders; real values live only in the local
environment. See [docs/devops.md](docs/devops.md) for the security boundary.

## Documentation

- [docs/architecture.md](docs/architecture.md) — diagram, request flows, failure tolerance
- [docs/database-schema.md](docs/database-schema.md) — every table, real DDL, relationships
- [docs/devops.md](docs/devops.md) — Docker, CI/CD, Kubernetes, monitoring
- [docs/setup-guide.md](docs/setup-guide.md) — fresh-machine walkthrough
- [docs/features/](docs/features/) — per-feature notes
- [docs/advanced/](docs/advanced/) — build history and war stories (viva prep)

## Branches

- `master` — the final, demonstrable architecture (this tree).
- `advanced` — the earlier infrastructure-heavy exploration (R2 pre-signed
  uploads, Redis, WebSocket, tunnels), kept for reference; tag
  `pre-migration-mysql` marks the last commit before simplification.
