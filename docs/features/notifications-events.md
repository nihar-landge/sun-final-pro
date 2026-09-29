# Feature: Event Pipeline & Notifications (RabbitMQ)

When something happens in feedback-land, other services find out through a
message broker instead of direct calls. Today notification-service consumes
those events and exposes an admin feed; tomorrow the same pipeline feeds
push notifications.

## Topology

```
feedback-service                          RabbitMQ                     notification-service
────────────────                          ────────                     ─────────────────────
FeedbackService.publishEvent ──────────►  topic exchange               @RabbitListener on queue
  routing key = event type                "feedbackapp.events"         "notifications.feedback"
                                          │                                  │
                                          │  binding: feedback.* ────────────┘
                                          │    (any routing key starting
                                          │     with "feedback.")
```

- **Exchange**: `feedbackapp.events` (topic, durable).
- **Queue**: `notifications.feedback` (durable), bound with `feedback.*`.
- **Both sides declare the topology** — the queue exists no matter which
  service boots first (idempotent declarations).

## The event contract

Shared Java record in the `common` module
(`common/event/FeedbackEvent.java`) so publisher and consumer can't drift:

```java
record FeedbackEvent(
    String type,        // "feedback.created" | "feedback.status.changed"
    Long feedbackId,
    Long userId,        // the report's author — a push notification target later
    String title,
    String category,
    String oldStatus,   // status.changed only
    String newStatus,   // status.changed only
    Instant occurredAt)
```

Wires are JSON strings: publisher serializes with Jackson, consumer parses
with Jackson into the shared record.

## Publishing rules (feedback-service)

| Moment | Routing key |
|---|---|
| `FeedbackService.submit` | `feedback.created` |
| `FeedbackService.transitionStatus` | `feedback.status.changed` |

`publishEvent` is wrapped in try/catch and logs a warning on failure —
**a broker outage must never fail the citizen's API call**.

## Consuming rules (notification-service)

- `FeedbackEventListener` receives the JSON, parses, stores, logs.
- A malformed payload is **logged and dropped**, never requeued forever.
- `NotificationStore` keeps the **last 100 events, newest first**, in memory
  (a bounded `ArrayDeque`; unit-tested). A database table replaces it when
  durable history is needed.

## Reading the feed

```
GET /api/v1/notifications/recent     (ADMIN only — 403 otherwise)
→ ApiResponse<FeedbackEvent[]>
```

Routed by the gateway to notification-service :8084. Identity comes from the
gateway's `X-User-Role` header; the controller rejects non-admins.

## Verify the pipeline end-to-end

```bash
# 1. submit feedback (citizen token) → publishes feedback.created
# 2. read the feed (admin token)
curl -s localhost:8080/api/v1/notifications/recent -H "Authorization: Bearer $ADMIN_TOKEN"
# -> feedback.created | Stray cattle on highway

# 3. broker-side truth (management plugin):
curl -s -u guest:guest localhost:15672/api/queues/%2F/notifications.feedback
# -> consumers: 1, message_stats.deliver_get >= 1
```

## Future consumers (why this design pays off)

- **Push notifications (FCM)**: listens to `feedback.status.changed` and
  notifies the report's author that their issue moved ("Your report was
  resolved!"). The author's `userId` is already in the event.
- Neither consumer requires any change to feedback-service — new queues bind
  to the same exchange.
