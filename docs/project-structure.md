# Project Structure

```
civicpulse/
├── docker-compose.yml        # full local stack: MySQL + 6 services + React admin
├── services/                 # Maven multi-module Spring Boot backend
│   ├── common/               #   shared ApiResponse, errors, @CurrentUser resolver
│   ├── api-gateway/          #   :8080 — JWT edge filter, routes, CORS
│   ├── auth-service/         #   :8081 — register/login (BCrypt + JWT), users, roles
│   ├── poll-service/         #   :8082 — polls, one-person-one-vote, results
│   ├── feedback-service/     #   :8083 — reports, photos, near-me, upvotes, triage
│   └── notification-service/ #   :8084 — inbox (notificationdb) + email fan-out
├── email-service/            # Node/Express: POST /api/email/report-status (no DB)
├── mobile/                   # Flutter citizen app
│   ├── lib/core/             #   api client, token store, theme, l10n (en/hi/mr)
│   └── lib/features/         #   auth · home · polls · feedback · map · alerts · profile
├── admin-react/              # React admin (Vite): dashboard, reports+drawer, map,
│                             #   polls, users, audit — Vitest + RTL
├── infra/                    # mysql/init (4 DBs + grants), monitoring/ (prometheus, grafana)
├── k8s/base/                 # namespace, configmap, secret, 6 deployments (+HPA), services
├── scripts/                  # e2e.sh (27 checks), run-local.sh, load/vote.js (k6)
├── .github/workflows/        # ci.yml (4 jobs), e2e.yml (compose + suite)
└── docs/                     # architecture, database-schema, devops, setup-guide,
                              #   features/, advanced/ (handoff + plan)
```

Key files worth reading first:

- `services/api-gateway/src/main/java/.../security/JwtAuthGlobalFilter.java` — the trust boundary
- `services/feedback-service/.../service/NotificationForwarder.java` — the after-commit chain
- `services/poll-service/src/main/resources/db/migration/V1__create_polls.sql` — the composite-PK vote rule
- `email-service/src/server.js` — the Express email contract
- `admin-react/src/pages/Reports.jsx` — the triage drawer
- `docker-compose.yml` — how everything fits together locally
