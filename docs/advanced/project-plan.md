# 12-Week Implementation Plan

Baseline of what exists after the foundation phase, then the phased roadmap.

## Phase 0 — Foundation (done)

- [x] Monorepo: Maven multi-module services, Flutter mobile + web admin
- [x] Docker Compose infra (PostgreSQL+PostGIS, Redis, SeaweedFS, RabbitMQ)
- [x] Flyway schemas for all three databases
- [x] auth-service: OTP + JWT + refresh rotation, unit-tested
- [x] api-gateway: routing, edge JWT validation, CORS
- [x] CI workflow, k8s manifest pattern, docs

## Phase 1 — Core features (weeks 3-4)

- [ ] poll-service: poll CRUD (admin), vote casting (transactional
  participation + ballot insert), results endpoint with Redis caching
- [ ] feedback-service: submit/list feedback (category, text), status
  workflow endpoints for admins
- [ ] mobile: poll list/detail/vote screens with bloc; feedback submit form
- [ ] admin: login via auth-service, poll management screens
- [ ] integration tests against Testcontainers PostgreSQL

## Phase 2 — Rich features (weeks 5-6)

- [ ] WebSocket (STOMP) live poll results; Redis pub/sub fan-out
- [x] Geo-tagging: PostGIS `ST_DWithin` "issues near me"; image upload via
  pre-signed URLs (Cloudflare R2 live / SeaweedFS local)
- [ ] notification-service: consume events, push/in-app notifications
- [ ] community upvoting with `feedback_upvotes` PK enforcement

## Phase 3 — Analytics & admin (weeks 7-8)

- [ ] Admin analytics dashboard: polls participation, feedback resolution
  times (Flutter web + charts)
- [ ] Advanced search/filter/pagination for feedback list
- [ ] Moderator role flows (status transitions audited in
  `feedback_status_history`)

## Phase 4 — DevOps hardening (weeks 9-10)

- [ ] Build/push service images from the committed Dockerfiles
- [ ] Deploy `k8s/` manifests (add feedback/poll deployments following the
  auth-service pattern), HPA 2→10 on gateway+services
- [ ] Prometheus + Grafana (Micrometer endpoints), Loki logging
- [ ] GitHub Actions: docker build/push jobs, staging deploy

## Phase 5 — Scale & finalize (weeks 11-12)

- [ ] Load testing with k6 (vote path, p95 < 200 ms target)
- [ ] Query/index tuning; read-replica notes
- [ ] Security review: secrets management, JWT RS256 upgrade path,
  penetration checklist
- [ ] Documentation polish, demo video, presentation

## Success metrics (from blueprint)

| Metric | Target |
|---|---|
| API response time | < 200 ms (p95) |
| Vote processing | < 100 ms |
| WebSocket connection success | > 99.5% |
| System uptime | > 99.9% |
