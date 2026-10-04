# DevOps Layer

Docker, GitHub Actions, Kubernetes and monitoring — how CivicPulse is built,
tested, shipped and observed.

## Docker

`docker-compose.yml` (repo root) boots the full stack:

| Service | Image | Notes |
|---|---|---|
| mysql | mysql:8.4 | 4 logical DBs created by `infra/mysql/init/01-databases.sql`; published on **3307** for tooling (a local Homebrew MySQL may hold 3306) |
| api-gateway | civicpulse/api-gateway:0.1.0 | **the only published application port (:8080)** |
| auth / poll / feedback / notification | civicpulse/*:0.1.0 | internal network only; layered-jar Dockerfiles (temurin 21 JRE, non-root user) |
| email-service | civicpulse/email-service:0.1.0 | node:20-alpine; `EMAIL_DEV_MODE=true` logs emails |
| react-admin | civicpulse/react-admin:0.1.0 | Vite build served by nginx with SPA fallback (:4173) |
| prometheus / grafana | optional `--profile monitoring` | scrape `/actuator/prometheus` on all five services |

Volumes: `mysql_data` (persists the DB), `feedback_uploads` (photos survive
restarts). The feedback image pre-creates `/app/uploads` and chowns it so a
fresh named volume inherits the right ownership.

Operational notes learned the hard way (all fixed in the tree):

- MySQL 8 does **not** create users via GRANT — the init script creates the
  `feedback@localhost` twin explicitly (host-run jars connect from 127.0.0.1,
  which never matches `@'%'`).
- Every Java service runs with `JAVA_TOOL_OPTIONS=-Dnetworkaddress.cache.ttl=10`
  — JVM DNS caches are bounded so recreated containers (new IPs) are picked up.

## CI/CD (GitHub Actions)

**ci.yml — 4 jobs on every push/PR:**

1. `services` — JDK 21, `./mvnw -B verify` with `TEST_DOCKER=true`
   (Testcontainers MySQL integration tests), surefire reports uploaded.
2. `mobile` — Flutter pub get / analyze / test.
3. `react-admin` — npm ci, Vitest, production build.
4. `email-service` — npm install + supertest suite.

**e2e.yml — on push to master (or manual):**

```
checkout → build service jars (mvnw package, skip tests)
        → docker compose up -d --build
        → wait for gateway /actuator/health (300 s budget)
        → scripts/e2e.sh localhost:8080     # 27 guarantees
        → compose logs dumped on failure
```

## Kubernetes

`k8s/base/` — flat manifests, namespace `feedbackapp`:

- namespace.yaml, configmap.yaml (service URLs, `DB_HOST`, `UPLOAD_DIR`),
  secret.yaml (JWT secret, DB credentials, shared `SERVICE_KEY` —
  placeholders only; real values live in the cluster).
- One Deployment + Service per service (auth, poll, feedback, notification,
  email) + api-gateway with an **HPA** (CPU 70 %, 1→4 replicas).
- Probes: startupProbe (5 min budget) / readiness / liveness on
  `/actuator/health`; email-service uses `/health`.
- feedback mounts an `emptyDir` at `/app/uploads`.
- Images are built locally and loaded into the cluster (e.g. kind):
  `docker build -t civicpulse/auth-service:0.1.0 services/auth-service` →
  `kind load docker-image …` → `kubectl apply -f k8s/base/`.
- Only the gateway is exposed; every other service is ClusterIP.

## Local run scripts

- `scripts/run-local.sh` — boots the five jars (host-run, `DB_PORT=3307`)
  against the compose MySQL; `stop` kills them.
- `scripts/e2e.sh <gateway>` — the 27-guarantee suite: auth (register/dup
  409/bad-token 401), one-person-one-vote (first 200, second 409),
  feedback workflow + spatial + audit, multipart photos (upload → served →
  oversized 400), notification inbox + analytics + role guards.
- `scripts/load/vote.js` — k6 load test on the vote/results path.

## Monitoring

Every service exposes `GET /actuator/prometheus` (JVM, HTTP, Hikari
metrics). The `monitoring` compose profile scrapes them into Prometheus
(`infra/monitoring/prometheus.yml`) and Grafana is provisioned with the
datasource (`:3000`, dev admin/admin). Present the monitoring as the DevOps
layer — the core application stands without it.

## Security boundary

- The gateway is the **only** published application backend; MySQL :3307 is
  published for local tooling only and never in Kubernetes.
- Committed config uses placeholders (`dev-only-secret-change-me…`,
  `mysql_feedback_pw`, `dev-service-key`); real secrets live only in the
  local environment / cluster Secrets.
- `.gitignore` excludes `.env*`, runtime uploads, node_modules, target.
