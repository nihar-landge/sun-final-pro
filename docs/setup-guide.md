# Local Setup Guide

Fresh machine → running stack in ~10 minutes.

## Prerequisites

| Tool | Used for |
|---|---|
| Docker Desktop | everything containerized (MySQL + 6 services + admin) |
| JDK 21 + Maven wrapper | building jars (the wrapper needs no global Maven) |
| Flutter SDK | the citizen app |
| Node 20 | admin/email dev servers (containers already bundle them) |
| kubectl + kind (optional) | the Kubernetes demonstration |

## 1. Full stack (recommended)

```bash
docker compose up -d --build          # mysql + gateway + 4 services + email + react-admin
scripts/e2e.sh localhost:8080         # 27 guarantees → all pass
open http://localhost:4173            # React admin
```

First boot applies every Flyway migration and seeds the dev admin.

## 2. Citizen app

Android emulator (10.0.2.2 = host loopback):

```bash
cd mobile && flutter run              # API_BASE_URL defaults to http://10.0.2.2:8080/api/v1
```

Physical device over USB (cleartext HTTP is enabled in the manifest):

```bash
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

## 3. Host-run services (alternative to containers)

```bash
docker compose up -d mysql            # or: infra compose — MySQL publishes 3307
cd services && ./mvnw -DskipTests package
../scripts/run-local.sh               # boots the 5 jars (DB_PORT=3307)
```

## Ports

| Port | What |
|---|---|
| 8080 | API gateway — the only published application backend |
| 8081–8084 | auth / poll / feedback / notification (internal; host-run mode only) |
| 8090 | email-service (internal) |
| 4173 | React admin (nginx) |
| 3307 | MySQL for local tooling only |
| 9090 / 3000 | Prometheus / Grafana (`--profile monitoring`) |

## Dev credentials

| What | Value |
|---|---|
| Admin | `admin@civicpulse.in` / `Admin@123` |
| MySQL root | `mysql_root_devpw` |
| MySQL app user | `feedback` / `mysql_feedback_pw` |
| Service key | `dev-service-key` |

## Troubleshooting (lessons baked into the tree)

- **Homebrew MySQL on 3306** shadows the container for host-run jars → compose
  publishes 3307 and `run-local.sh` sets `DB_PORT=3307`.
- **Access denied for 'feedback'@'localhost'** → the init script creates the
  localhost twin explicitly (MySQL 8 does not create users via GRANT).
- **Containers recreated with new IPs not picked up** → every Java service
  runs with `-Dnetworkaddress.cache.ttl=10`.
- **Android blocks plain HTTP** → `usesCleartextTraffic="true"` is set in the
  app manifest (dev only).
- **Fresh volume lost uploads** → the feedback image pre-creates and chowns
  `/app/uploads` so a new named volume inherits ownership.
- Reset everything: `docker compose down -v && docker compose up -d --build`.
