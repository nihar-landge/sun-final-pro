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
| `feedbackapp-storage` | `chrislusf/seaweedfs:3.80` | 9000 S3 API | none (S3 gateway runs unauthenticated) | feedback (photo upload) |
| `feedbackapp-rabbitmq` | `rabbitmq:3.13-management` | 5672 AMQP / 15672 UI | `guest` / `guest` | feedback (publisher), notification (consumer) |

All containers share the `app-net` bridge network, have healthchecks, and
persist data in named volumes (`postgres_data`, `redis_data`, `storage_data`,
`rabbitmq_data`, `grafana_data`).

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

## Photo storage: Cloudflare R2 (live) — SeaweedFS kept as local fallback

The platform's photo pipeline speaks S3, so storage is swappable by env.
The original R2 failure (**W14** — Java-minted presigned PUTs rejected with
`AccessDenied` while boto3-minted URLs worked) is root-caused, fixed in
`SigV4Presigner`, and **verified live on 2026-09-27**: the kind cluster now
serves photos from R2, E2E 27/27 including the photo flow.

Root cause — the manual presigner had three defects, invisible locally
because SeaweedFS's S3 gateway runs unauthenticated and never checks
signatures (R2 was the first strict validator):
- the canonical query string was **empty** — SigV4 requires every `X-Amz-*`
  param to be part of the signed canonical request
- region defaulted to `us-east-1` — R2 requires **`auto`** in the credential
  scope (now settable via `MINIO_REGION`)
- the Flutter client sends `Content-Type` on the direct PUT, but the header
  wasn't signed — R2 rejects request headers that the presign omitted

Fix verification:
- `scripts/r2-presign-vector.py` regenerates frozen-clock boto3 vectors
  (boto3 is the implementation that provably worked against R2)
- `SigV4PresignerTest` asserts byte-for-byte URL parity with those vectors
- `R2PresignLiveTest` (env-gated, skipped in CI) round-trips real R2:
  presigned PUT → statObject register → presigned GET, byte-exact
- live E2E 27/27 with photos on R2 + a manual presigned-GET fetch over the
  public internet (200, correct content-type, byte-exact)

Live-only config (never commit real values — see SESSION-HANDOFF W11):
live ConfigMap `MINIO_URL`/`MINIO_PUBLIC_URL` = R2 endpoint,
`MINIO_BUCKET=civicpulse-photos`, `MINIO_REGION=auto`; R2 keys in the live
Secret. Note the app's bucket default is `feedback-photos` — with a
bucket-scoped token the wrong name fails `bucketExists` with *Access denied*
(the non-fatal bootstrap logs one WARN).

Token notes:
- R2 tokens come from **R2 → Manage R2 API Tokens** (S3 credentials);
  Cloudflare API tokens from My Profile do not work
- Bucket-scoped tokens deny `ListBuckets` — test with `HeadBucket`

To re-run the live round-trip against any R2 account/bucket:

```bash
cd services && R2_LIVE_TEST=true \
R2_ENDPOINT=https://<account>.r2.cloudflarestorage.com \
R2_ACCESS_KEY=... R2_SECRET_KEY=... R2_BUCKET=... \
./mvnw -pl feedback-service -am test -Dtest=R2PresignLiveTest \
  -Dsurefire.failIfNoSpecifiedTests=false
```

To fall back to SeaweedFS (still running in this compose stack): restore
the four `MINIO_*` values in the live ConfigMap to the git placeholders,
put the SeaweedFS keys into the live Secret, rollout-restart
feedback-service.

## Security note

Every credential here is a development placeholder (and `OTP_DEV_ECHO=true`
returns login codes in API responses). Before any real deployment: change
secrets via environment/Kubernetes secrets (see `k8s/base/secret.yaml`),
disable dev echo, and front the stack with TLS.
