# System Architecture

## Overview

```mermaid
flowchart TD
    subgraph Clients
        A[Flutter Mobile App]
        B[Flutter Web Admin]
    end

    subgraph API Layer
        C[API Gateway :8080<br/>Spring Cloud Gateway]
    end

    subgraph Core Services
        D[Auth Service :8081]
        E[Poll Service :8082]
        F[Feedback Service :8083]
        G[Notification Service :8084]
        H[Sentiment Service :8085]
    end

    subgraph Data Layer
        I[(authdb)]
        J[(polldb)]
        K[(feedbackdb<br/>+ PostGIS)]
        L[(Redis)]
        M[(MinIO)]
        N[(RabbitMQ)]
    end

    A --> C
    B --> C
    C --> D
    C --> E
    C --> F
    D --> I
    D --> L
    E --> J
    E --> L
    F --> K
    F --> M
    G --> N
    H --> N
```

## Vertical slice (current)

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant GW as API Gateway :8080
    participant Auth as Auth Service :8081
    participant R as Redis
    participant DB as authdb (Flyway)

    App->>GW: POST /api/v1/auth/otp/send {phone}
    GW->>Auth: route (public path)
    Auth->>R: SET otp:phone (TTL 5m) + cooldown marker
    Auth-->>GW: ApiResponse{devOtp}
    GW-->>App: 200 (dev echo)
    App->>GW: POST /api/v1/auth/otp/verify {phone, code, name}
    GW->>Auth: route
    Auth->>R: compare + delete key
    Auth->>DB: upsert users row
    Auth-->>GW: JWT access + refresh token
    GW-->>App: TokenResponse
    App->>GW: GET /api/v1/auth/me (Bearer)
    GW->>GW: validate JWT, add X-User-* headers
    GW->>Auth: forward
    Auth-->>App: 200 user profile
```

## Gateway edge security

- Public paths: `/api/v1/auth/otp/**`, `/api/v1/auth/token/refresh`,
  `/actuator/**`, API docs. Everything else requires a valid Bearer JWT.
- The filter strips any client-supplied `X-User-*` header, validates the JWT
  (same HS256 secret as auth-service), then injects `X-User-Id`,
  `X-User-Role`, `X-User-Name` before routing downstream.

## Data ownership

| Service | Database | Tables |
|---|---|---|
| auth-service | `authdb` | `users` |
| poll-service | `polldb` | `polls`, `poll_options`, `poll_participation`, `ballots` |
| feedback-service | `feedbackdb` | `feedback`, `feedback_images`, `feedback_status_history`, `feedback_upvotes`, `comments` |

Cross-service references use bare `user_id` columns — no cross-database
foreign keys. Consistency comes from service APIs, not joins.

## One-person-one-vote enforcement

`poll_participation` uses composite PK `(poll_id, user_id)`; a second vote
violates the primary key inside the same transaction as the ballot insert,
so duplicates are impossible even under concurrency. Ballots are anonymous.

## Future phases

- **Async** (done for feedback): feedback-service publishes
  `feedback.created` / `feedback.status.changed` to the
  `feedbackapp.events` topic exchange; notification-service consumes them
  and exposes `/api/v1/notifications/recent` (admin). Sentiment scoring and
  FCM push will consume the same events.
- **Real-time** (done for polls): STOMP WebSocket at `/ws` (routed by the
  gateway with `ws://` scheme, public handshake). Vote transactions publish
  an AFTER_COMMIT event that broadcasts fresh results to
  `/topic/polls/{id}` — clients update without polling.
- **Scale** (weeks 9-10): Kubernetes HPA, Prometheus/Grafana, Loki logging
  (see `k8s/` for the manifest pattern).
