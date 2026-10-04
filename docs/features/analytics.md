# Feature: Analytics

Admin-only endpoints power the React dashboard: `GET /feedback/analytics/
summary` (totals, by-status, by-category, average resolution hours, last
7 days), `GET /feedback/admin/trend?days=` (daily submission counts),
`GET /polls/analytics/summary` (polls, active, votes, top poll) and
`GET /feedback/admin/audit` (the transition trail). The Dashboard page
renders KPI cards and category bars straight from these endpoints; the
public `GET /feedback/community-stats` feeds the citizen home screen
without exposing user data.
