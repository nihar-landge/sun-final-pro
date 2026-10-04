# Feature: Analytics Dashboard (Admin)

One screen that answers "how is the city responding?" — poll participation,
feedback load and resolution speed, and the live event stream. Every number
is served by a real SQL-backed endpoint; nothing is hard-coded or
client-computed.

## The screen

```
┌─ PARTICIPATION ────────────────────────────────────────────────┐
│ [ 3 Total polls ] [ 3 Active now ] [ 4 Total votes ]           │
│ Avg 1.3 votes/poll · top: "New public park in the ward?" (2)   │
├─ FEEDBACK STATUS ──────────────────────────────────────────────┤
│ OPEN      ██████████░░░░  1 (50%)                              │
│ IN_REVIEW ██░░░░░░░░░░░░  0 (0%)                               │
│ RESOLVED  ██████████░░░░  1 (50%)                              │
│ 2 reports · 2 in last 7 days · avg resolution 0.5 h            │
├─ FEEDBACK BY CATEGORY ─────────────────────────────────────────┤
│ ROADS ████░░░ 1 … WATER / ELECTRICITY / SANITATION / …         │
├─ LIVE EVENT FEED (RabbitMQ) ───────────────────────────────────┤
│ ● feedback.created        Stray cattle on highway     22:22:04 │
│ ● feedback.status.changed Huge pothole OPEN → IN_REVIEW 22:22   │
└────────────────────────────────────────────────────────────────┘
```

Pull-to-refresh re-reads everything. All three sections load in parallel.

## Where each number comes from

### Poll participation — `GET /api/v1/polls/analytics/summary`

Computed in `PollService.analyticsSummary()` from all polls:
total polls, active polls (derived from time windows), total votes (sum of
the atomic `votes_count` column), average votes per poll, and the top poll
by votes. Admin-only (`GatewayUser.isAdmin()`), like every analytics read.

### Feedback stats — `GET /api/v1/feedback/analytics/summary`

| Metric | Source |
|---|---|
| Counts by status (OPEN/IN_REVIEW/RESOLVED) | `COUNT` per `FeedbackStatus` via JPA specifications |
| Counts by category (ROADS/WATER/…) | `COUNT` per `FeedbackCategory` |
| **Average resolution hours** | Native SQL: average of `changed_at − created_at` over all `RESOLVED` transitions in `feedback_status_history` |
| Submitted last 7 days | `countByCreatedAtAfter(now − 7 days)` |
| Total | plain count |

The resolution-time query is the interesting one — it derives a business KPI
directly from the audited workflow history rather than a hand-maintained
field:

```sql
SELECT AVG(EXTRACT(EPOCH FROM (h.changed_at - f.created_at)) / 3600.0)
FROM feedback_status_history h
JOIN feedback f ON f.id = h.feedback_id
WHERE h.new_status = 'RESOLVED'
```

### Live event feed — `GET /api/v1/notifications/recent`

The bounded in-memory feed from notification-service (see
[notifications-events.md](notifications-events.md)). Shows the type, the
report title, the status transition (if any) and the time. It doubles as a
live monitor for the RabbitMQ pipeline — submit feedback on the phone and
watch it appear here.

Admin-only: non-admin callers get **403** at every one of these endpoints
(checked via the gateway-injected role header).

## Charts, deliberately without a chart library

The bars are `Stack` + `FractionallySizedBox` widgets colored per status —
no `fl_chart` dependency, no version churn, fully theme-aware. Each bar row
shows the absolute count and percentage share. If richer charts (time
series) arrive later, swapping in a chart package
only touches `_DistributionBars`.

## Where the code lives

| Concern | File |
|---|---|
| Poll summary endpoint | `services/poll-service/.../controller/PollController.java` + `PollService.analyticsSummary` |
| Feedback summary endpoint + SQL | `services/feedback-service/.../controller/FeedbackController.java`, `FeedbackRepository.avgResolutionHours` |
| Recent events endpoint | `services/notification-service/.../web/NotificationsController.java` |
| Dashboard UI (KPI cards, bars, feed) | `admin/lib/main.dart` (_AnalyticsTab, _KpiCard, _DistributionBars) |
| State management + API calls | `admin/lib/features/analytics/admin_analytics_bloc.dart` |

## Try it

```bash
# both summaries with an admin token
curl -s localhost:8080/api/v1/polls/analytics/summary    -H "Authorization: Bearer $ADMIN_TOKEN"
curl -s localhost:8080/api/v1/feedback/analytics/summary -H "Authorization: Bearer $ADMIN_TOKEN"

# citizen token → 403 on both (role gate)
```

Future additions that slot straight in: resolution-time trends
per category and votes-per-hour time series for live polls.
