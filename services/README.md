# Backend — Spring Boot Microservices

Java 21 · Spring Boot 3.3 · Maven multi-module. Six modules: one shared
library (`common`) and five runnable services.

## Modules at a glance

| Module | Port | Owns | Status |
|---|---|---|---|
| `common` | — | Shared contracts (see below) | library |
| `api-gateway` | 8080 | Routing, JWT edge validation, CORS, rate limiting, WS proxy | ✅ working |
| `auth-service` | 8081 | OTP login, JWT, users, role management | ✅ working |
| `poll-service` | 8082 | Polls, one-person-one-vote, live results, STOMP | ✅ working |
| `feedback-service` | 8083 | Geo-tagged reports, workflow, upvotes, events | ✅ working |
| `notification-service` | 8084 | Consumes feedback events, recent feed | ✅ working |

## Build & run

```bash
./mvnw verify                                   # build + all unit tests
TEST_DOCKER=true ./mvnw verify                  # + Testcontainers integration tests
./mvnw -pl auth-service spring-boot:run         # run one service
java -jar auth-service/target/auth-service-0.1.0-SNAPSHOT.jar   # run the built jar
```

Every service is runnable independently but expects the infrastructure in
[../infra](../infra) (PostgreSQL, Redis, RabbitMQ) — see
[setup-guide](../docs/setup-guide.md).

## The `common` module — shared contracts

Anything two services need to agree on lives here:

- **`api/ApiResponse<T>` + `ErrorResponse`** — the `{success, data, message,
  timestamp}` envelope every endpoint returns.
- **`error/`** — `ErrorCode` enum (`OTP-429`, `POL-409`, …) and typed
  exceptions (`NotFoundException`, `ForbiddenException`, `AlreadyVotedException`…).
- **`event/FeedbackEvent`** — the RabbitMQ payload shared by
  feedback-service (publisher) and notification-service (consumer).
- **`web/`** — servlet plumbing auto-configured via
  `META-INF/spring/...AutoConfiguration.imports`:
  - `@CurrentUser GatewayUser` argument resolver — services read the caller
    from the `X-User-Id/Role/Name` headers the gateway injects (never from
    the client);
  - `GlobalExceptionHandler` — one mapping of exceptions → HTTP codes for
    every service (e.g. `FORBIDDEN` → 403, `ALREADY_VOTED` → 409).

The gateway (reactive) skips this auto-configuration — see
`CommonWebAutoConfiguration`'s `@ConditionalOnClass` guard.

## Patterns every service follows

1. **Layering**: `controller → service → repository (Spring Data)`, DTO
   records at the boundary, JPA entities inside.
2. **Flyway owns the schema** — `src/main/resources/db/migration/`, JPA runs
   with `ddl-auto: none|validate`. Never touch tables by hand.
3. **One database per service** — `authdb` / `polldb` / `feedbackdb`; other
   services' IDs are plain columns, never foreign keys across databases.
4. **Identity comes from headers** — the gateway validates JWTs and injects
   `X-User-*`; services never see tokens.
5. **Errors are typed** — throw a `common.error` exception with an
   `ErrorCode`; the shared handler turns it into the right HTTP status.
6. **Every response is `ApiResponse<T>`** — clients unwrap `data` uniformly.

## Adding a new service (checklist)

1. `mkdir my-service && cd it`, copy a `pom.xml` from `poll-service` (parent
   = services POM, add `common`).
2. Application class + `application.yml` (port, datasource if needed,
   Flyway if it owns tables).
3. If it owns tables: `src/main/resources/db/migration/V1__….sql`.
4. If clients reach it: add a route in `api-gateway/application.yml`.
5. If clients send identity to it: depend on `common` and use
   `@CurrentUser GatewayUser` — done, the resolver is auto-configured.
6. Add a `Dockerfile` (copy from any service — they're identical).
7. Add a module entry to the root `services/pom.xml`.

## Testing conventions

- **Unit tests** with Mockito for service logic — run always.
- **Testcontainers integration tests** (`@SpringBootTest` + `@ServiceConnection`
  PostgreSQL/PostGIS) for database-level guarantees — gated behind
  `TEST_DOCKER=true` because recent Docker Desktop rejects the Testcontainers
  client version; CI sets the flag.

## Docker

Each service has an identical layered-jar `Dockerfile` (build stage extracts
`dependencies/loader/snapshot-dependencies/application`; runtime copies the
layers) — rebuilds push only the thin application layer.
