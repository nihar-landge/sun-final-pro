# Feature: Push Notifications (FCM)

True push to the citizen's phone — "Your report has been resolved 🎉" arriving
even when the app is closed. Built on Firebase Cloud Messaging, wired into the
existing RabbitMQ event pipeline.

## The flow

```
REPORT STATUS CHANGE (admin triage)
        │
        ▼
feedback-service publishes feedback.status.changed  ──►  RabbitMQ
                                                            │
notification-service consumes the event                     │
        │                                                   │
        ├─ TokenRegistryService.tokenFor(authorUserId)      │
        │        └─ Redis: fcm:token:{userId}               │
        ▼                                                   │
FCM HTTP v1 API  ──────────────────────────────────────────►┘
        │  (OAuth2: service-account JWT → access token)
        ▼
Citizen's phone: system notification
   tap → deep-link into the report detail screen
```

## What was added where

| Piece | File / endpoint |
|---|---|
| Token registry (Redis, 60-day TTL) | `notification-service/.../web/TokenRegistryService.java` |
| Registration endpoint | `POST /api/v1/notifications/register-token` (JWT required) |
| FCM HTTP v1 sender (OAuth2 JWT → access token, no Admin SDK) | `notification-service/.../push/FcmSender.java` |
| Event → push wiring | `notification-service/.../messaging/FeedbackEventListener.java` |
| App side: permission, token, foreground banner, tap deep-link | `mobile/lib/core/notifications/push_service.dart` |
| Firebase project config | `mobile/android/app/google-services.json` |

## Design decisions worth knowing

- **No Admin SDK** — the FCM sender signs a service-account JWT with the
  jjwt library the platform already carries, exchanges it at
  `oauth2.googleapis.com/token`, and calls the FCM v1 REST API. Lighter
  image, same official flow. Gotcha: the `aud` claim must be a plain string
  (`.audience().single(...)`) — jjwt's `.add()` emits a JSON array, which
  Google rejects ("Failed audience check"; see SESSION-HANDOFF W16).
- **Graceful when unconfigured** — without the service-account file, pushes
  are skipped with a log line; token registration and the whole Alerts
  system keep working.
- **Pushes target the report AUTHOR** — the event already carries
  `userId`; the token lookup fails closed (no token → skip, never crash).
- **Token rotation** — the app re-registers on FCM token refresh; stale
  tokens expire from Redis after 60 days.
- **Tap routing** — payload carries `reportId` (or `pollId`); tapping opens
  the detail screen via a global navigator key, including cold-start.

## The one manual step (per environment)

The backend cannot send until it has a **service-account private key**:

1. Get the JSON — Firebase console → your project → ⚙ Project settings →
   **Service accounts** → **Generate new private key**, or without the console:
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account=<sa>@<project>.iam.gserviceaccount.com --project=<project>
   ```
2. Verify it before wiring anything (mints a real OAuth token; the send test
   is skipped unless `FCM_TEST_DEVICE_TOKEN` is also set):
   ```bash
   FCM_LIVE_TEST=true FCM_SERVICE_ACCOUNT=/path/to/service-account.json \
     ./mvnw -pl notification-service -am test -Dtest=FcmSenderLiveTest
   ```
3. Point notification-service at it — **host run:**
   ```bash
   FCM_SERVICE_ACCOUNT=/path/to/service-account.json java -jar notification-service.jar
   ```
   **Kubernetes** — the manifest mounts the *optional* `fcm-service-account`
   secret at `/etc/fcm/service-account.json`; the pod boots with push disabled
   while the secret is absent:
   ```bash
   kubectl -n feedbackapp create secret generic fcm-service-account \
     --from-file=service-account.json=/path/to/service-account.json \
     --dry-run=client -o yaml | kubectl apply -f -     # idempotent — safe to re-run
   kubectl apply -f k8s/base/notification-service.yaml
   kubectl -n feedbackapp rollout restart deploy/notification-service
   ```

The JSON is a private key — it goes into the cluster Secret (or a local path),
never into git. Without it everything works except the actual send — by design.

**Status (2026-09-28):** credentials minted; the sender is verified against
Google's real OAuth2 endpoint (`FcmSenderLiveTest`: 2 pass / 1 skip). The first
live run caught the `aud`-array bug — see SESSION-HANDOFF W16. Cluster secret
wiring is the remaining step.

## Verify

```bash
# 1. register a token (as the citizen)
curl -X POST localhost:8090/api/v1/notifications/register-token \
  -H "Authorization: Bearer $CITIZEN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"token":"test-token"}'

# 2. it lands in Redis keyed by user id
docker exec feedbackapp-redis redis-cli get "fcm:token:2"
# -> "test-token"

# 3. transition the citizen's report (admin) → event → push attempt
#    (with service account configured: notification arrives on the phone)
```
