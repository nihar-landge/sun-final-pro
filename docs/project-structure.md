# Project Structure — Annotated Map

Every folder and key file in this repository, with a one-line explanation.
Read this top-to-bottom and you'll know what lives where.

```
feedbackapp/                        ← repo root (this project)
│
├── README.md                       Start here: what the project is + quickstart
├── .gitignore                      Java/Flutter/IDE/env exclusions
├── .github/workflows/ci.yml        CI: backend tests + Flutter analyze/test on every push/PR
│
├── docs/                           All human documentation
│   ├── project-structure.md        ← YOU ARE HERE (this file)
│   ├── architecture.md             System diagram, request flows, design decisions
│   ├── database-schema.md          ERD + explanation of every table
│   ├── setup-guide.md              How to run everything on a new machine
│   ├── project-plan.md             12-week roadmap + what's done
│   ├── features/                   One deep-dive per product feature
│   │   ├── authentication.md       Phone OTP login, JWT, session restore
│   │   ├── polls.md                Creating polls, one-person-one-vote, results
│   │   ├── live-results.md         WebSocket push of results
│   │   ├── feedback.md             Geo-tagged reports, upvotes, admin workflow
│   │   ├── notifications-events.md RabbitMQ event pipeline
│   │   ├── user-management.md      Admin role management
│   │   └── analytics.md            Dashboard numbers and where they come from
│   └── api/                        OpenAPI 3.0 specs (importable into Swagger UI)
│       ├── auth-openapi.yaml       Auth service contract
│       ├── polls-openapi.yaml      Poll service contract
│       └── feedback-openapi.yaml   Feedback service contract
│
├── backend/                        Spring Boot microservices (Maven multi-module)
│   ├── pom.xml                     Parent POM: Java 21, Boot 3.3, shared versions
│   ├── mvnw, .mvn/                 Maven wrapper (build without installing Maven)
│   │
│   ├── common/                     Shared library used by every service (NOT runnable)
│   │   └── src/main/java/.../common/
│   │       ├── api/                ApiResponse<T> + ErrorResponse — the response envelope
│   │       │                       every endpoint returns: {success, data, message, timestamp}
│   │       ├── domain/UserRoles    Role constants: CITIZEN, MODERATOR, ADMIN
│   │       ├── error/              ErrorCode enum + typed exceptions
│   │       │                       (NotFoundException, ForbiddenException, …)
│   │       ├── event/FeedbackEvent The RabbitMQ event contract shared by
│   │       │                       publisher (feedback-svc) and consumer (notification-svc)
│   │       └── web/                Auto-configured servlet plumbing:
│   │                           · @CurrentUser argument resolver (reads X-User-* headers)
│   │                           · GlobalExceptionHandler (maps exceptions → HTTP codes)
│   │                           Registered via META-INF/spring/…AutoConfiguration.imports
│   │
│   ├── api-gateway/  :8080         The single entry point for all clients
│   │   ├── security/JwtAuthGlobalFilter.java   Validates JWTs, strips client-sent
│   │   │                                       X-User-* headers, injects verified ones
│   │   ├── config/RateLimiterConfig.java       Redis rate limiter key (client IP)
│   │   └── application.yml                     Routes: /api/v1/{auth,polls,feedback,
│   │                                           notifications}/** + /ws/** (WebSocket)
│   │
│   ├── auth-service/ :8081         Phone OTP login, JWT, user records, role management
│   │   ├── controller/AuthController.java      /otp/send /otp/verify /token/refresh
│   │   │                                       /logout /me
│   │   ├── controller/AdminUserController.java /admin/users (list/search + role change)
│   │   ├── service/OtpService.java             Redis OTP lifecycle: keys, TTL, attempts
│   │   ├── service/AuthService.java            Login, token issue/rotation, upsert
│   │   ├── service/AdminUserService.java       User listing/search + role transitions
│   │   ├── security/JwtTokenProvider.java      HS256 sign/verify (secret shared w/ gateway)
│   │   ├── security/JwtAuthenticationFilter.java  Per-request JWT validation
│   │   ├── entity/User.java                    users table (phone, name, role)
│   │   ├── service/SmsSender.java + LoggingSmsSender.java  Pluggable SMS; dev logs OTP
│   │   └── resources/db/migration/             V1 users table, V2 seed admin (9999999999)
│   │
│   ├── poll-service/ :8082         Polls: creation, one-person-one-vote, live results
│   │   ├── controller/PollController.java      CRUD, /vote, /close, /results, /analytics
│   │   ├── service/PollService.java            The voting transaction (see features/polls.md)
│   │   ├── service/VoteBroadcastListener.java  AFTER_COMMIT → WebSocket broadcast
│   │   ├── config/WebSocketConfig.java         STOMP endpoint /ws, broker /topic
│   │   ├── entity/                             Poll, PollOption, PollParticipation
│   │   │                                       (composite PK = one vote), Ballot (anonymous)
│   │   └── resources/db/migration/V1__create_polls.sql
│   │
│   ├── feedback-service/ :8083     Geo-tagged civic reports + workflow
│   │   ├── controller/FeedbackController.java  submit/list/near-me/upvote/status/comments
│   │   ├── service/FeedbackService.java        Business rules + RabbitMQ publishing
│   │   ├── config/RabbitMqConfig.java          Declares exchange + queue (publisher side)
│   │   ├── entity/                             Feedback (PostGIS point), Upvote (composite
│   │   │                                       PK), StatusHistory, Comment, Images
│   │   └── resources/db/migration/V1__create_feedback.sql  (+ PostGIS extension)
│   │
│   ├── notification-service/ :8084 Consumes feedback events from RabbitMQ
│   │   ├── messaging/FeedbackEventListener.java  @RabbitListener — parses + stores events
│   │   ├── web/NotificationStore.java            Bounded in-memory feed (last 100)
│   │   ├── web/NotificationsController.java      GET /api/v1/notifications/recent (admin)
│   │   └── config/RabbitMqConfig.java            Same topology as publisher side
│   │
│   ├── sentiment-service/ :8085    Placeholder stub — ONNX sentiment scoring is future work
│   │
│   └── */Dockerfile                Layered-jar build for each service (temurin 21)
│
├── mobile/                         Flutter CITIZEN app (Android/iOS/Web)
│   ├── pubspec.yaml                Deps: bloc, http, secure storage, geolocator, stomp
│   └── lib/
│       ├── main.dart               App entry + manual dependency wiring + bloc providers
│       ├── core/                   Cross-feature building blocks
│       │   ├── constants/api_constants.dart    Gateway base URL (dart-define overridable)
│       │   ├── network/api_client.dart         HTTP + auth header + auto token refresh
│       │   ├── network/token_store.dart        JWT persistence (flutter_secure_storage)
│       │   ├── errors/                         Exceptions (data layer) → Failures (domain)
│       │   ├── themes/app_theme.dart           Material 3 theme
│       │   └── utils/validators.dart           Phone/OTP/name validation
│       └── features/               One folder per feature, Clean Architecture:
│           ├── auth/               data (models, datasource, repo impl)
│           │                       domain (entities, repo interface, usecases)
│           │                       presentation (bloc + pages: login, OTP, profile)
│           ├── polls/              Same layering; bloc + list + detail (live results)
│           ├── feedback/           Same layering; list + submit form (GPS location)
│           └── home_shell.dart     Bottom navigation (Polls / Feedback / Profile)
│
├── admin/                          Flutter WEB admin panel
│   └── lib/
│       ├── main.dart               Login gate + 4-tab dashboard (Polls/Feedback/
│       │                           Analytics/Users) + all tab UIs
│       ├── core/api_client.dart    HTTP client with token persistence + refresh
│       └── features/               One bloc per tab: auth, polls, feedback,
│                                   analytics, users
│
├── infra/                          Local development infrastructure
│   ├── docker-compose.yml          PostgreSQL+PostGIS, Redis, MinIO, RabbitMQ
│   └── postgres/init/              First-boot scripts: create 3 databases + PostGIS
│
├── k8s/                            Kubernetes manifests (pattern for weeks 9-10)
│   └── base/                       namespace, config, secret, gateway + auth
│                                   Deployment/Service/HPA
│
└── docs/api/*.yaml                 Import into Swagger Editor to explore the API
```

## The five-second mental model

```
Phone app ─┐
           ├─→ api-gateway :8080 ──→ auth-service  :8081 ──→ authdb (PostgreSQL)
Web admin ─┘        │                 poll-service  :8082 ──→ polldb (PostgreSQL)
                    │                 feedback-svc  :8083 ──→ feedbackdb (PostgreSQL+PostGIS)
                    │                 notification  :8084 ←── RabbitMQ events ←── feedback-svc
                    └─ ws:// ───────→ poll-service (STOMP live results)
                            Redis   ←── OTP codes, sessions, results cache (all services)
```

- Clients only ever talk to **:8080**. Services trust the identity headers
  the gateway injects after JWT validation.
- Each service owns **its own database**; there are no cross-database joins.
- **Flyway** owns every schema — no auto-DDL anywhere.
- Everything a client receives is wrapped in
  `{success, data, message, timestamp}` (see `common/api/ApiResponse.java`).

## Where to go next

- Running it all: [setup-guide.md](setup-guide.md)
- How a specific feature works: [features/](features/) folder
- Database details: [database-schema.md](database-schema.md)
- Want to add a new service or Flutter feature? See [backend/README.md](../backend/README.md) and [mobile/README.md](../mobile/README.md)
