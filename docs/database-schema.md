# Database Schema

Three logical databases, one per owning service. PostGIS is enabled in
`feedbackdb`. Migrations are Flyway SQL files inside each service
(`src/main/resources/db/migration`).

```mermaid
erDiagram
    USERS ||--o{ POLL_PARTICIPATION : "votes in"
    USERS ||--o{ FEEDBACK : "creates"
    USERS ||--o{ FEEDBACK_UPVOTES : "upvotes"
    USERS ||--o{ COMMENTS : "writes"

    POLLS ||--o{ POLL_OPTIONS : "has"
    POLLS ||--o{ POLL_PARTICIPATION : "records participation"
    POLLS ||--o{ BALLOTS : "contains"

    FEEDBACK ||--o{ FEEDBACK_IMAGES : "has"
    FEEDBACK ||--o{ FEEDBACK_STATUS_HISTORY : "tracks"
    FEEDBACK ||--o{ FEEDBACK_UPVOTES : "receives"

    USERS {
        bigint id PK
        varchar phone UK
        varchar name
        varchar avatar_url
        varchar role
        timestamp created_at
        timestamp updated_at
    }

    POLLS {
        bigint id PK
        varchar title
        text description
        timestamp start_time
        timestamp end_time
        boolean is_anonymous
        bigint created_by "users.id (authdb)"
    }

    POLL_OPTIONS {
        bigint id PK
        bigint poll_id FK
        varchar option_text
        integer votes_count
    }

    POLL_PARTICIPATION {
        bigint poll_id PK
        bigint user_id PK "one-person-one-vote"
        timestamp voted_at
    }

    BALLOTS {
        bigint id PK
        bigint poll_id FK
        bigint option_id FK
        timestamp voted_at "anonymous - no user_id"
    }

    FEEDBACK {
        bigint id PK
        varchar title
        text description
        varchar category
        varchar status
        geography location "PostGIS point"
        bigint user_id "users.id (authdb)"
        integer upvotes
    }

    FEEDBACK_IMAGES {
        bigint id PK
        bigint feedback_id FK
        varchar image_url
        timestamp uploaded_at
    }

    FEEDBACK_STATUS_HISTORY {
        bigint id PK
        bigint feedback_id FK
        varchar old_status
        varchar new_status
        bigint changed_by
        timestamp changed_at
    }

    FEEDBACK_UPVOTES {
        bigint feedback_id PK
        bigint user_id PK
        timestamp voted_at
    }

    COMMENTS {
        bigint id PK
        bigint feedback_id FK
        bigint user_id
        text comment_text
        timestamp created_at
    }
```

## Key design decisions

1. **Composite PK on `poll_participation`** — `(poll_id, user_id)` makes a
   second vote by the same citizen physically impossible; uniqueness is
   enforced by the database, not application code.
2. **Anonymous ballots** — `ballots` has no `user_id`. The participation
   table proves *that* a user voted; ballots record *what* was counted.
   Published tallies can never be traced to a voter.
3. **PostGIS `GEOGRAPHY(POINT,4326)` + GIST index** — metro-aware distance
   queries (`ST_DWithin`) for the "issues near me" map.
4. **Status audit trail** — every transition of `feedback.status` is a row in
   `feedback_status_history` (who, when, from, to), giving the admin
   accountability trail and the data for resolution-time KPIs.
5. **No cross-database FKs** — `user_id` columns reference users logically;
   the data boundary matches the service boundary.

## Applying migrations

Each service applies its own migrations at startup (`flyway.enabled=true`):

```bash
docker compose -f infra/docker-compose.yml up -d
cd backend
./mvnw -pl auth-service spring-boot:run        # applies V1__create_users.sql to authdb
./mvnw -pl poll-service spring-boot:run        # applies V1__create_polls.sql to polldb
./mvnw -pl feedback-service spring-boot:run    # applies V1__create_feedback.sql to feedbackdb
```

Inspect with:

```bash
docker exec feedbackapp-postgres psql -U feedback -d authdb -c '\dt'
docker exec feedbackapp-postgres psql -U feedback -d feedbackdb -c '\d feedback'
```
