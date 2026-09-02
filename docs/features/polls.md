# Feature: Polls (One-Person-One-Vote + Live Results)

Admins publish polls; citizens vote once; everyone watches the results move
in real time. The flagship guarantee: **one person, one vote — enforced by
the database, not by application code.**

## The voting transaction (the heart of the feature)

```
POST /api/v1/polls/{id}/vote {optionId}
            │
            ▼
┌─ PollService.castVote ─ @Transactional ─────────────────────────────┐
│ 1. poll exists and status == ACTIVE        (else 409)               │
│ 2. option belongs to this poll             (else 404)               │
│ 3. INSERT poll_participation(pollId,userId)← composite PRIMARY KEY │
│    → duplicate = PK violation = AlreadyVotedException (409)        │
│ 4. INSERT ballot(pollId, optionId)   ← no user id: anonymous       │
│ 5. UPDATE poll_options SET votes_count = votes_count + 1  (atomic) │
│ 6. DELETE Redis cache poll:results:{id}                            │
│ 7. publish VoteCommittedEvent (broadcast fires AFTER commit)       │
└────────────────────────────────────────────────────────────────────┘
            │
            ▼
   response = fresh results with hasVoted=true
```

Steps 3–5 are one database transaction: a crash between them can't produce a
counted ballot without participation, or vice versa.

### Why `Persistable` matters (a real bug we hit)

Spring Data treats entities with a populated `@EmbeddedId` as *existing* and
issues an UPDATE (merge) instead of INSERT — which would **silently bypass
the composite PK** and let the same person vote twice (we reproduced exactly
that before the fix). `PollParticipation` and `FeedbackUpvote` therefore
implement `Persistable.isNew() == true`, forcing a real INSERT so the
database constraint is the guarantee. The integration test
(`PollVoteIntegrationTest`, runs in CI) proves a second vote throws even
against real PostgreSQL.

## Anonymity design

- `poll_participation` proves **that** you voted (your user id is here).
- `ballots` records **what** was counted — with **no user id**.
- Published results can therefore never be traced back to a voter.

## Status model (no status column)

A poll's status is derived from its time window:

| Status | Condition |
|---|---|
| SCHEDULED | `now < start_time` |
| ACTIVE | `start_time ≤ now < end_time` |
| CLOSED | `now ≥ end_time` (or closed early by an admin) |

## Live results

- Results are read through a 3-second-TTL Redis cache (`poll:results:{id}`),
  invalidated on every vote.
- Every committed vote also **broadcasts** the fresh results to WebSocket
  subscribers on `/topic/polls/{id}` (see [live-results.md](live-results.md)).
- `hasVoted` is computed **per caller** from `poll_participation` and overlaid
  after the shared cache is read — the cache stays user-neutral.

## Endpoints

| Method & path | Who | Purpose |
|---|---|---|
| `POST /api/v1/polls` | ADMIN | Create (validates end > start, ≥2 distinct options) |
| `GET /api/v1/polls?status=active` | any | List (active/closed/scheduled/all) |
| `GET /api/v1/polls/{id}` | any | Details + results (+ `hasVoted` when identified) |
| `GET /api/v1/polls/{id}/results` | any | Results only |
| `POST /api/v1/polls/{id}/vote` | citizen | Cast one vote → 200 with results, 409 if already voted / closed |
| `POST /api/v1/polls/{id}/close` | ADMIN | End the poll now |
| `GET /api/v1/polls/analytics/summary` | ADMIN | Participation KPIs |

Errors: `POL-409` already voted · `RES-409` poll not open · `AUT-403` not an
admin · full contract in [api/polls-openapi.yaml](../api/polls-openapi.yaml).

## Where the code lives

| Concern | File |
|---|---|
| Endpoints | `backend/poll-service/.../controller/PollController.java` |
| Voting transaction | `backend/poll-service/.../service/PollService.java` |
| Entities (incl. composite PK) | `backend/poll-service/.../entity/` |
| Atomic vote counter | `backend/poll-service/.../repository/PollOptionRepository.java` |
| WebSocket broadcast | `backend/poll-service/.../service/VoteBroadcastListener.java` |
| Table definitions | `backend/poll-service/.../db/migration/V1__create_polls.sql` |
| Mobile: list + detail + live bars | `mobile/lib/features/polls/presentation/pages/` |
| Mobile: voting bloc | `mobile/lib/features/polls/presentation/bloc/polls_bloc.dart` |
| Admin: create/close polls | `admin/lib/features/polls/admin_polls_bloc.dart` + `admin/lib/main.dart` (_PollsTab) |

## The mobile UX (worth knowing)

- The detail page shows the vote form only if the poll is active **and**
  `hasVoted == false`; otherwise a "You already voted" card plus live results.
- The list carries a **VOTED** chip on polls you've participated in.
- Every bloc state carries the last list snapshot, so voting or an error never
  blanks the list (a bug we fixed — see git history).
- Radio selection → **Cast vote** → bars animate to the new percentages
  (server-confirmed, then kept in sync by WebSocket pushes).
