# Feature: Feedback (Geo-tagged Civic Reports)

Citizens report city problems — potholes, water leaks, broken streetlights —
optionally pinning them to a GPS location. Admins triage them through an
audited status workflow; the community upvotes to signal priority.

## The lifecycle of one report

```
SUBMIT (citizen)            TRIAGE (admin)                COMMUNITY
POST /feedback              POST /feedback/{id}/status    POST /feedback/{id}/upvote
  status = OPEN      ──►    OPEN → IN_REVIEW → RESOLVED   1 upvote per citizen
  location (opt.)           every transition writes a      (composite PK enforces)
  RabbitMQ event:           row in feedback_status_history  counter incremented
  feedback.created          + RabbitMQ event:
                            feedback.status.changed
```

## Data model (feedback-service owns `feedbackdb`)

| Table | Purpose | Notable |
|---|---|---|
| `feedback` | The report | `location GEOGRAPHY(POINT,4326)` + GIST index; `sentiment_score/label` (reserved for sentiment-service); `upvotes` counter |
| `feedback_status_history` | Audit trail | old status, new status, who changed, when |
| `feedback_upvotes` | Who upvoted | composite PK `(feedback_id, user_id)` = one per citizen; implements `Persistable` (see polls.md for why) |
| `feedback_images` | Photo links | MinIO URLs — upload itself is future work |
| `comments` | Discussion threads | text + author + timestamp |

## The near-me query (PostGIS)

```
GET /api/v1/feedback/near-me?lat=18.5204&lng=73.8567&radiusKm=5
```

```sql
SELECT …, ST_Distance(f.location, ST_MakePoint(:lng,:lat)::geography) AS distance_meters
FROM feedback f
WHERE ST_DWithin(f.location, ST_MakePoint(:lng,:lat)::geography, :radiusMeters)
  AND f.status = COALESCE(:status, f.status::varchar)
ORDER BY distance_meters ASC
```

- `GEOGRAPHY` type = distances in **meters on the earth's surface** (not
  degrees), so `radiusKm * 1000` is a real radius.
- `ST_DWithin` uses the GIST index — fast even with many reports.
- Results come back nearest-first; the response includes `distanceMeters`.

## Status workflow rules

Allowed transitions (anything else → 409):

```
OPEN ──────► IN_REVIEW ──────► RESOLVED
  ▲              │                 │
  └──────────────┴─────────────────┘   (re-opening is allowed)
```

Every transition is recorded in `feedback_status_history`
(old → new → who → when). This table is also the data source for the
**average resolution time** on the Analytics dashboard.

## Events published (see notifications-events.md)

| Moment | Routing key | Payload highlights |
|---|---|---|
| Report submitted | `feedback.created` | id, author, title, category |
| Status changed | `feedback.status.changed` | id, title, old status, new status |

Publishing is wrapped in try/catch — a RabbitMQ outage logs a warning and
**never** fails the citizen's submission.

## Endpoints

| Method & path | Who | Purpose |
|---|---|---|
| `POST /api/v1/feedback` | citizen | Submit (title, description, category, optional lat/lng) |
| `GET /api/v1/feedback` | any | Paged list, filters: category, status |
| `GET /api/v1/feedback/near-me` | any | Radius search, nearest first |
| `GET /api/v1/feedback/{id}` | any | Detail + comments + status history |
| `POST /api/v1/feedback/{id}/upvote` | citizen | Upvote (duplicate → 409) |
| `POST /api/v1/feedback/{id}/status` | ADMIN | Transition (audited) |
| `POST /api/v1/feedback/{id}/comments` | citizen | Comment |
| `GET /api/v1/feedback/analytics/summary` | ADMIN | Counts by status/category, avg resolution hours |

Full contract: [api/feedback-openapi.yaml](../api/feedback-openapi.yaml).

## Where the code lives

| Concern | File |
|---|---|
| Endpoints | `backend/feedback-service/.../controller/FeedbackController.java` |
| Business rules + events | `backend/feedback-service/.../service/FeedbackService.java` |
| PostGIS query + resolution SQL | `backend/feedback-service/.../repository/FeedbackRepository.java` |
| Entities (incl. `Persistable` upvote) | `backend/feedback-service/.../entity/` |
| Tables (+ PostGIS extension) | `backend/feedback-service/.../db/migration/V1__create_feedback.sql` |
| Mobile: submit form with GPS | `mobile/lib/features/feedback/presentation/pages/submit_feedback_page.dart` |
| Mobile: list with filters + upvote | `mobile/lib/features/feedback/presentation/pages/feedback_list_page.dart` |
| Mobile: bloc | `mobile/lib/features/feedback/presentation/bloc/feedback_bloc.dart` |
| Admin: triage tab | `admin/lib/main.dart` (_FeedbackTab) |

## Try it

```bash
# submit (citizen token)
curl -s -X POST localhost:8080/api/v1/feedback -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"title":"Huge pothole","description":"near the station","category":"ROADS",
       "latitude":18.5290,"longitude":73.8620}'

# nearest-first within 5 km
curl -s "localhost:8080/api/v1/feedback/near-me?lat=18.5204&lng=73.8567&radiusKm=5" \
  -H "Authorization: Bearer $TOKEN"
# -> distanceMeters: 1104.0  (real PostGIS math)
```
