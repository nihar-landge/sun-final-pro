# Infra — Local Development Infrastructure

One `docker compose up` boots every backing service the platform needs.
No application code runs here — only data infrastructure.

```bash
docker compose -f infra/docker-compose.yml up -d
docker compose -f infra/docker-compose.yml ps    # all four should be "healthy"
```

## The stack

| Container | Image | Ports | Credentials (DEV ONLY) | Who uses it |
|---|---|---|---|---|
| `feedbackapp-postgres` | `postgis/postgis:16-3.4` | 5432 | user `feedback` / `feedback_dev_password` | all three data-owning services |
| `feedbackapp-redis` | `redis:7-alpine` (AOF on) | 6379 | none | auth (OTPs, refresh tokens), poll (results cache), gateway (rate limiter) |
| `feedbackapp-minio` | `minio/minio` | 9000 API / 9001 console | `minioadmin` / `minioadmin123` | reserved for image upload (future) |
| `feedbackapp-rabbitmq` | `rabbitmq:3.13-management` | 5672 AMQP / 15672 UI | `guest` / `guest` | feedback (publisher), notification (consumer) |

All containers share the `app-net` bridge network, have healthchecks, and
persist data in named volumes (`postgres_data`, `redis_data`, `minio_data`,
`rabbitmq_data`).

## Databases (one per microservice)

Created on **first boot only** (the entrypoint runs `postgres/init/`):

| Database | Owner service | Contents |
|---|---|---|
| `authdb` | auth-service | `users` (+ `flyway_schema_history`) |
| `polldb` | poll-service | polls, poll_options, poll_participation, ballots |
| `feedbackdb` | feedback-service | feedback, feedback_images, feedback_status_history, feedback_upvotes, comments + **PostGIS** |

- `01-databases.sql` creates `polldb` + `feedbackdb` (`authdb` comes from the
  `POSTGRES_DB` env var).
- `02-extensions.sh` enables the PostGIS extension in `feedbackdb`.
- Each service then applies its own **Flyway** migrations at startup — the
  init scripts deliberately stop at empty databases.

## Connecting from your machine

```bash
docker exec feedbackapp-postgres psql -U feedback -d authdb -c '\dt'
docker exec feedbackapp-redis redis-cli keys 'otp:*'
open http://localhost:15672        # RabbitMQ UI (guest/guest) — see queue stats
open http://localhost:9001         # MinIO console
```

Service env vars (all have dev defaults in each `application.yml`):
`DB_HOST/DB_PORT/DB_USER/DB_PASSWORD`, `REDIS_HOST/REDIS_PORT`,
`RABBITMQ_HOST/PORT/USER/PASSWORD`, `JWT_SECRET`, `OTP_DEV_ECHO`.

## Resetting

```bash
docker compose -f infra/docker-compose.yml down       # stop, keep data
docker compose -f infra/docker-compose.yml down -v    # stop + DESTROY all data
```

`down -v` also wipes the database-creation scripts' work; they re-run on the
next `up` (fresh volumes = fresh first-boot).

## Security note

Every credential here is a development placeholder (and `OTP_DEV_ECHO=true`
returns login codes in API responses). Before any real deployment: change
secrets via environment/Kubernetes secrets (see `k8s/base/secret.yaml`),
disable dev echo, and front the stack with TLS.
