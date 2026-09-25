# Local Setup Guide

## Prerequisites (as installed on this machine)

| Tool | Version | Used for |
|---|---|---|
| JDK | 21 (`/opt/homebrew/opt/openjdk@21`) | backend build & run |
| Maven | 3.9.x (`brew install maven`) + committed `mvnw` wrapper | backend build |
| Docker Desktop | any recent | PostgreSQL/PostGIS, Redis, MinIO, RabbitMQ |
| Flutter | stable (analyze/test green) | mobile + admin apps |
| kubectl | any recent | weeks 9-10 deployment |

## 1. Start the infrastructure

```bash
docker compose -f infra/docker-compose.yml up -d
docker compose -f infra/docker-compose.yml ps     # all four should be "healthy"
```

| Service | Endpoint | Credentials (dev only) |
|---|---|---|
| PostgreSQL + PostGIS | localhost:5432 | `feedback` / `feedback_dev_password` — dbs: `authdb`, `polldb`, `feedbackdb` |
| Redis | localhost:6379 | none |
| MinIO | localhost:9000 (API), localhost:9001 (console) | `minioadmin` / `minioadmin123` |
| RabbitMQ | localhost:5672 (AMQP), localhost:15672 (UI) | `guest` / `guest` |

## 2. Run the backend

```bash
cd backend
./mvnw -pl auth-service spring-boot:run      # terminal 1  (port 8081)
./mvnw -pl api-gateway spring-boot:run       # terminal 2  (port 8080)
# optional: stub services
./mvnw -pl poll-service spring-boot:run      # port 8082, applies poll schema
./mvnw -pl feedback-service spring-boot:run  # port 8083, applies feedback schema
```

Environment overrides (all optional in dev): `DB_HOST`, `DB_PORT`, `DB_USER`,
`DB_PASSWORD`, `REDIS_HOST`, `REDIS_PORT`, `JWT_SECRET`, `OTP_DEV_ECHO`.

## 3. Exercise the vertical slice

```bash
# Send OTP (dev profile echoes the code in devOtp)
curl -s -X POST localhost:8080/api/v1/auth/otp/send \
  -H 'Content-Type: application/json' -d '{"phone":"9876543210"}'

# Verify → tokens (replace 123456 with the echoed code)
curl -s -X POST localhost:8080/api/v1/auth/otp/verify \
  -H 'Content-Type: application/json' \
  -d '{"phone":"9876543210","code":"123456","name":"Nihar"}'

# Authenticated call through the gateway (replace $ACCESS_TOKEN)
curl -s localhost:8080/api/v1/auth/me -H "Authorization: Bearer $ACCESS_TOKEN"

# Gateway rejects protected routes without a token
curl -i localhost:8080/api/v1/polls/health   # -> 401
```

Swagger UI: <http://localhost:8081/swagger-ui.html> (auth-service direct).

## 4. Run the Flutter apps

```bash
cd mobile
flutter run                      # Android emulator: API base = http://10.0.2.2:8080
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1   # iOS simulator / web
```

Admin panel: `cd admin && flutter run -d chrome`.

## 5. Tests

```bash
cd backend && ./mvnw verify              # unit tests; add TEST_DOCKER=true for Testcontainers integration tests
cd mobile && flutter test && flutter analyze
cd admin && flutter analyze
```

Note: recent Docker Desktop versions reject the Testcontainers client
version, so the PostgreSQL integration tests are gated behind
`TEST_DOCKER=true` (CI runs them). Locally the same constraints are verified
by the live E2E curl flow in the README.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Connection refused :5432` | Docker Desktop not running, or `docker compose up` not executed |
| Flyway "Validate failed" | volume has an older schema: `docker compose ... down -v` and re-up (destroys dev data) |
| Android emulator can't reach gateway | use `http://10.0.2.2:8080` (already the default `API_BASE_URL`) |
| OTP always rate-limited | Redis cooldown is 60s per phone; `docker exec feedbackapp-redis redis-cli flushdb` to reset |
| "Could not reach the server" on the phone | re-establish `adb reverse tcp:8080 <gateway-port>` after every wireless-adb reconnect — reconnects reset all reverse forwards |
| Where are the service logs? | Services run in Kubernetes: `kubectl logs -n feedbackapp deploy/auth-service` (etc.) |
