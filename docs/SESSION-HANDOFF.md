# Session Handoff — Complete Build History, Decisions & War Stories

> **Purpose of this document:** the definitive record of how CivicPulse was
> built across AI-assisted sessions — every feature, every bug hit, the root
> cause, the fix, and how it was verified. Read this before continuing work.
> It doubles as viva preparation: each "war story" below answers a real
> "how did you tackle X?" question with evidence.

**Project:** CivicPulse — Public Feedback & Polling System (CDAC Final Project, Mobile Computing)
**Repo:** github.com/nihar-landge/sun-final-pro · branch `master`
**Scale:** ~15,600 lines hand-written code (4,675 Java main · 913 Java tests · 10,074 Dart) · 338+ files · 260 lines Flyway SQL · 18 docs
**Verification:** 35 backend unit tests + 2 gated Testcontainers integration tests + 27-check live E2E suite + 4 Dart tests + k6 load script

---

## 1. What exists today (feature inventory)

### Backend — 6 Spring Boot microservices (Maven multi-module, Java 21, Boot 3.3.5)

| Service | Port | Responsibility | Endpoints |
|---|---|---|---|
| `api-gateway` | 8080 | Routing, JWT edge validation, anti-spoofing of identity headers, CORS (single owner), Redis rate limiting on OTP, WebSocket proxy | all traffic |
| `auth-service` | 8081 | Phone OTP login (Redis, cooldown + attempt caps), HS256 JWT (15 min) + rotating refresh (30 d), user records, admin role management | 7 |
| `poll-service` | 8082 | Poll CRUD, one-person-one-vote voting, atomic counters, live results (Redis cache), STOMP WebSocket broadcasts, analytics | 7 |
| `feedback-service` | 8083 | Geo-tagged reports (PostGIS), near-me radius query, upvotes, audited status workflow, comments, photo presigning, R2/SeaweedFS storage, events, admin ops, audit trail, trend | 14 |
| `notification-service` | 8084 | RabbitMQ consumer → **persistent inbox (notificationdb)** + bounded event feed, FCM push sender, device-token registry | 6 |
| `sentiment-service` | 8085 | Stub — reserved for ONNX model (schema columns ready) | health |

**Shared `common` module:** ApiResponse envelope, ErrorCode enum + typed exceptions, FeedbackEvent contract, `@CurrentUser` argument resolver (gateway-trust model), shared GlobalExceptionHandler.

### Flutter apps
- **Citizen app** (`mobile/`) — 5 tabs: Home (greeting, featured poll, quick actions, nearby issues, own reports, **community impact card**), Polls (Active/Upcoming/Closed, preview bars, countdowns, **Poll Insights**), Report (**5-step wizard**: category → describe → **photos (max 3, direct-to-S3 upload)** → GPS/manual location → **similar-report detection within 300 m** → submit → track), Alerts (**persistent inbox**, unread badge, mark-read), Profile (theme System/Light/Dark persisted, language selector EN live / हिन्दी / मराठी scaffolded, privacy notes, **About CivicPulse screen**, sign out).
  - Report detail: photo carousel, status chip, upvote, **progress timeline from audited history**, **Official Update card (staff public note)**, **Resolved celebration card (duration + supporters)**, comments with composer, OSM mini-map.
  - Poll detail: vote form → "You already voted" card (server `hasVoted`), **LIVE badge + STOMP real-time result bars**, Poll Insights.
  - Clean Architecture per feature: domain (entities/interfaces/use cases) ← data (models, data sources, repo impls mapping exceptions→Failures) → presentation (blocs + pages). Manual DI in main.dart.
- **Admin console** (`admin/`, Flutter Web) — sidebar shell: Dashboard (6 KPIs, distribution charts, 14-day trend, live event feed), Reports triage (search/filter table, multi-select + bulk status, **CSV export**, right-side drawer: photos/status/assignment/public+internal notes/timeline/comments), Poll builder (+duplicate, close), Map (OSM pins → drawer), Analytics, Users (admin-only; moderator gating), Audit Log.

### Data layer (Docker Compose)
PostgreSQL 16 + PostGIS (4 DBs: authdb, polldb, feedbackdb, **notificationdb**) · Redis 7 (AOF) · **SeaweedFS 3.80** (S3 API :9000 — replaced MinIO, which archived its open-source distribution) · RabbitMQ 3.13 + management · Prometheus (scrapes all services) · Grafana (provisioned).

### Kubernetes (kind v1.35, cluster `civicpulse`)
6 Deployments + Services + HPA (1→4, CPU 70%) on the gateway; ConfigMap + Secret; startupProbe (5-min slow-boot grace) + readiness + liveness; JVM tuned (`MaxRAMPercentage=55`, `MaxMetaspaceSize=110m`, 460Mi limits). Data layer stays in Compose via `host.docker.internal` (documented swap point).

### Public endpoints (Cloudflare Tunnel — brickbyte.me)
- **https://api.brickbyte.me** → Kubernetes gateway (E2E 27/27 verified over public HTTPS)
- **https://photos.brickbyte.me** → reserved (routes to SeaweedFS; unused while R2 is deferred)
- `infra/cloudflare/tunnel-up.sh` — auto-restart loops for port-forward + tunnel

### CI/CD (GitHub Actions)
- `ci.yml` — backend verify (incl. Testcontainers integration tests, `TEST_DOCKER=true`), Flutter analyze/test
- `e2e.yml` — boots the whole stack on the runner, runs `scripts/e2e.sh` (27 checks), dumps logs on failure

---

## 2. The war stories — every significant bug, root cause, fix, verification

These are the viva gold. Each one was hit **in reality**, diagnosed, and fixed.

### W1. JPA `merge` silently bypassed the one-person-one-vote constraint ⭐
- **Symptom:** a citizen voted twice successfully in live E2E testing. Database showed 1 participation row but **2 ballots**.
- **Root cause:** entities with a populated `@EmbeddedId` are treated by Spring Data as *existing* → `merge()` (SELECT→UPDATE) instead of INSERT → the composite-PK constraint on `poll_participation` was never touched.
- **Fix:** `PollParticipation` and `FeedbackUpvote` implement `Persistable.isNew() == true`, forcing a real INSERT so the database constraint fires → duplicate becomes 409.
- **Verification:** Testcontainers integration test against real PostgreSQL (runs in CI); live curl re-test (second vote → 409, exactly 1 ballot).

### W2. Duplicate `Access-Control-Allow-Origin` broke every browser request
- **Symptom:** phone/Chrome app said "Could not reach the server" while curl worked fine.
- **Root cause:** both the gateway AND auth-service added CORS headers → browsers reject responses with ACAO twice. Curl never catches this; only a browser does.
- **Fix:** CORS enforced once at the gateway; per-service CORS disabled (`cors.disable()` with an explanatory comment).
- **Verification:** browser-style curl with Origin header → exactly one ACAO, on success AND error responses.

### W3. HTTP 401 returned for authorization failures
- **Symptom:** citizen hitting an admin endpoint got 401 — clients would pointlessly retry token refresh.
- **Root cause:** the shared exception handler mapped `FORBIDDEN` → 401.
- **Fix:** 403 everywhere; re-verified across all services.

### W4. Missing authorization on the users-list endpoint
- **Symptom:** E2E showed a citizen token receiving the full user list (HTTP 200).
- **Fix:** `requireAdmin()` in the controller; added "citizen blocked" E2E check (403).

### W5. RabbitMQ binding `feedback.*` silently dropped status-change events ⭐
- **Symptom:** while building the persistent inbox, notifications for status changes never appeared — and it turned out they had **never** been delivered.
- **Root cause:** topic binding `feedback.*` matches exactly one word after the dot. `feedback.created` (2 segments) routed; `feedback.status.changed` (3 segments) did not. RabbitMQ's own API confirmed `"routed": false`, publish stats 0.
- **Fix:** binding changed to `feedback.#` in both services; stale binding deleted via management API; verified `routed: true` and inbox rows appearing.

### W6. Hidden reports were still readable via direct detail access
- **Symptom:** citizen `GET /feedback/{id}` on a hidden report returned 200.
- **Fix:** `getDetail(id, viewer)` — hidden + non-staff → 404. Caught by the E2E pass, fixed, re-verified (citizen 404, admin 200).

### W7. MinIO archived its open-source distribution mid-project
- **Symptom:** after a Docker reset, `minio/minio` pulls returned *denied* and dl.min.io returned **410 Gone** ("open-source MinIO projects are archived").
- **Fix:** migrated to **SeaweedFS 3.80** (same S3 API on :9000); MinIO Java client unchanged — it's a standard S3 SigV4 client. Documented in infra/README.

### W8. Testcontainers incompatible with Docker Desktop 29.x
- **Symptom:** integration tests couldn't reach Docker ("client version 1.32 is too old. Minimum supported API version is 1.40").
- **Root cause:** Boot 3.3.5 pins Testcontainers 1.19.8 whose docker-java client uses an API version newer Docker Desktop refuses.
- **Fix:** pinned `testcontainers.version=1.21.3` in the parent POM; integration tests gated behind `TEST_DOCKER=true` locally (CI sets it — standard Docker Engine works).

### W9. Kubernetes pods OOM-killed during boot on a 3.8 GB VM ⭐
- **Symptom:** after switching storage to R2, the new feedback pod entered CrashLoopBackOff — exit code **137** (cgroup OOM). Then a rollout cascade left 10 Spring Boot JVMs booting at once and the whole fleet flapped.
- **Root cause:** 384Mi limits were tighter than boot-time RSS (heap 70% + metaspace 128m + native), and the rollout booted new+old pods simultaneously on a memory-starved VM.
- **Fix:** memory rebalanced fleet-wide (460Mi limit, `MaxRAMPercentage=55`, `MaxMetaspaceSize=110m`), **startupProbe** giving 5 minutes before liveness, **sequential boot** (scale to zero → scale up one service at a time), host-side JVMs stopped (everything runs in k8s now).
- **Lesson:** on small VMs, boot-time spikes — not steady state — are what kill pods; probe budget and memory headroom are operational necessities.

### W10. CrashLoopBackOff hides recovery — exponential backoff masks a fixed cause
- **Symptom:** after the data layer (compose) accidentally went down and came back, pods stayed stuck in backoff for many minutes.
- **Fix:** force-delete the stuck pods (`kubectl delete pods --all --force`) — the Deployment controller recreates them instantly against the now-healthy dependencies.
- **Lesson:** CrashLoopBackOff retry delays keep growing even after the root cause is fixed; force-restart after fixing the cause.

### W11. `kubectl apply -f .` reverted live patches ⭐
- **Symptom:** R2 credentials patched into the cluster kept "disappearing"; the new pod kept old env.
- **Root cause:** after patching the live ConfigMap/Secret, a later `kubectl apply -f .` (for memory limits) re-applied the **git versions** of those files, overwriting the live values. Also: files apply alphabetically, so `namespace.yaml` is last and first-time applies can race.
- **Fix:** re-patch after any apply; apply `namespace.yaml` first; store real credentials ONLY in the live cluster, git keeps placeholders.
- **Lesson:** `kubectl apply` is declarative — the file is the source of truth, not the cluster.

### W12. Wireless adb reconnects silently drop all `adb reverse` forwards
- **Symptom:** "Could not reach the server" on the phone after a reconnect.
- **Fix:** re-run `adb reverse tcp:8080 tcp:8090` after every reconnect; documented in the setup guide; later made mostly moot by the public domain.

### W13. `kubectl port-forward` and `cloudflared` die silently
- **Symptom:** api.brickbyte.me returned 502 while the cluster was healthy.
- **Fix:** `infra/cloudflare/tunnel-up.sh` — auto-restart loops for both processes; run it after every Docker restart.

### W14. Cloudflare R2 rejects Java-SDK presigned URLs (documented, deferred) ⭐
- **Symptom:** presigned PUT minted by the AWS Java SDK v2 presigner → `AccessDenied` from R2, while the **identical** presigned URL minted by Python boto3 → 200 (same credentials, bucket, key path, expiry). Verified by recomputing signatures across 8 canonical-form/secret variants.
- **Status:** reverted photo storage to SeaweedFS (fully working, E2E 27/27); findings + three candidate fixes documented in `infra/README.md` (account-scoped token, AWS SDK v1 `generatePresignedUrl`, or completing the manual SigV4 presigner that now lives in `SigV4Presigner.java` — its canonical query string needs one more pass).
- **Lesson:** S3 "compatibility" is not uniform; presigned-URL canonical forms differ between SDK generations and providers.

### W15. Minor-but-real ones
- `Mockito.doNothing()` on a non-void `RedisTemplate.delete` → use lenient mocks/verify instead.
- Maven `-pl <module>` without `-am` compiled against a stale installed `common` jar — always build with `-am` from the root.
- AWS SDK v2 presigner class names: `PutObjectPresignRequest` / `GetObjectPresignRequest` (not `PresignPutObjectRequest`) — verified against the actual jar contents.
- Duplicate ACAO wasn't the only browser-only bug class: Content-Type on presigned PUTs also interacts with SigV4 (boto3 presign + CT header → 403).
- Flutter: RadioGroup replaced per-button groupValue (v3.32+ API), unused-import churn across refactors.
- Dev OTP used to require grepping logs → now surfaced in-app as a tap-to-fill chip (dev-echo only).

---

## 3. Architecture decisions worth defending in the viva

| Decision | Why |
|---|---|
| One database per microservice, no cross-DB FKs | Service autonomy; consistency via APIs/events |
| Flyway owns every schema | No drift, reproducible migrations |
| JWT validated only at the gateway; services trust `X-User-*` headers | Single auth enforcement point; anti-spoofing via header stripping |
| Composite PK for one-person-one-vote + `Persistable` | Database-level guarantee, not app logic (see W1) |
| Anonymous ballots separate from participation | Results can never be traced to voters |
| RabbitMQ topic exchange, consumers declare topology | New consumers (sentiment, push) need zero publisher changes |
| AFTER_COMMIT broadcast for WebSocket | Subscribers never see uncommitted counts |
| Direct-to-storage photo uploads via presigned URLs | Photo bytes never transit services; scales independently |
| Persistent notification inbox in a dedicated DB | Durable history + unread state, event-sourced by design |
| SeaweedFS over MinIO | MinIO archived its OSS distribution; same S3 API, zero code change |
| kind + Cloudflare Tunnel | Public HTTPS with zero open ports and no cloud account |

---

## 4. How to run everything (post-restart runbook)

```bash
# 0. Start Docker Desktop (it has quit spontaneously on this machine — see W9/W13)
open -a Docker && sleep 60

# 1. Data layer
cd infra && docker compose up -d && cd ..

# 2. Kubernetes pods recover automatically; force-fresh if stuck in backoff
kubectl delete pods -n feedbackapp --all --force --grace-period=0

# 3. Public endpoints (idempotent, auto-restart loops)
./infra/cloudflare/tunnel-up.sh
# → https://api.brickbyte.me  (gateway)  https://photos.brickbyte.me (storage)

# 4. Verify — all 27 guarantees, over the public domain
scripts/e2e.sh api.brickbyte.me        # or: localhost:8090 via port-forward

# 5. Apps
cd mobile && flutter run --dart-define=API_BASE_URL=https://api.brickbyte.me/api/v1
cd admin  && flutter run -d chrome
```

**Log locations (services run in Kubernetes):**
`kubectl logs -n feedbackapp deploy/<service>` — there are NO host-side logs anymore.
**Redis/DB inspection:** `docker exec feedbackapp-redis redis-cli ...` / `docker exec feedbackapp-postgres psql -U feedback -d <db>`.
**RabbitMQ UI:** localhost:15672 (guest/guest) · **Grafana:** localhost:3000 (admin/admin, may need `docker start feedbackapp-grafana`).

---

## 5. Configuration & credentials map

| What | Where | Committed? |
|---|---|---|
| Dev DB creds, JWT secret, storage keys (k8s) | `k8s/base/secret.yaml` (placeholders) + live Secret (real values) | placeholders only |
| R2 endpoint (not secret) | `k8s/base/configmap.yaml` is currently reverted to SeaweedFS values; live cluster holds R2 values | no — live only |
| **R2 token** (pasted in chat) | lives only in the live Secret | ⚠️ rotate before any real use |
| Firebase client config | `mobile/android/app/google-services.json` | yes (safe by design — client key, package-name enforced) |
| FCM service-account JSON | **NOT YET PROVIDED** — Firebase console → Project settings → Service accounts → Generate new private key | must NOT be committed |
| Dev OTP echo | `OTP_DEV_ECHO` env (default true) | documented "never in prod" |

---

## 6. Remaining roadmap (precise next steps)

1. **FCM activation (blocked on you, 10 min):** download the service-account JSON, then either
   `FCM_SERVICE_ACCOUNT=/path/to/key.json` for a host run, or add it to the k8s Secret + deployment env.
   Everything else (token registry, sender, event wiring, mobile permission/deep-links) is already built.
   ⚠️ If the Android app was installed before Firebase was added, uninstall + reinstall so the google-services plugin values apply cleanly.
2. **R2 presign fix (options in infra/README):** try an *account-scoped* R2 token (bucket-scoped may be the blocker), or AWS SDK v1 `generatePresignedUrl`, or finish the manual SigV4 presigner (`SigV4Presigner.java` — its canonical query string needs the parameters included; see W14).
3. **Hindi/Marathi localization:** Flutter gen_l10n + 3 ARBs; ~15 screens of strings; the language selector UI already exists in Profile.
4. **Sentiment ONNX (optional):** user is learning mini-model training; sentiment-service + schema are ready. Model: small quantized classifier; serve via the stub or a FastAPI sidecar.
5. **Demo video + slides + user manual:** blueprint deliverables not yet produced.
6. **Ongoing:** commit early/often — the session pattern of one mega-commit early on cost history granularity later (fixed: recent work is in clean commits).

---

## 7. Viva Q&A quick answers (with evidence pointers)

- **"How do you ensure one person votes once?"** → Composite PK `(poll_id, user_id)` + `Persistable.isNew()` so JPA INSERTs (W1 — we caught a real bypass) + integration test on real PostgreSQL.
- **"How do services know who the caller is?"** → Gateway validates JWT, strips client-spoofed headers, injects verified `X-User-*`; services use `@CurrentUser` (common module auto-config).
- **"What happens if RabbitMQ is down?"** → Publishing is try/catch-wrapped (API never fails); consumers retry; inbox persists independently of push.
- **"How are photos stored?"** → Pre-signed direct-to-storage uploads (bytes never transit services), 3-photo cap server-enforced, 1-hour presigned view URLs.
- **"How did you handle an S3 provider disappearing?"** → MinIO archived upstream mid-project (W7); migrated to SeaweedFS with zero code change because storage is behind the S3 API.
- **"What did Kubernetes give you?"** → Real deployment on kind (v1.35), HPA pattern, probes tuned for slow JVM boots (startupProbe — W9), public HTTPS via Cloudflare Tunnel with zero open ports.
- **"How do you know it all still works?"** → 27-check E2E suite run against the live platform (and in CI on every push).

---

## 8. Known current limitations (honesty list)

- R2 presign from Java deferred (SeaweedFS works; see W14)
- FCM inactive until the service-account JSON is provided
- Hindi/Marathi are scaffolded, not wired
- Notification inbox caps at 50 rows per user in list responses
- Poll analytics loads all polls into memory (fine at demo scale)
- No pagination caps on some admin tables beyond size=100
- Docker Desktop on this machine is memory-tight (3.8 GB) — expect slow pod boots and occasional restarts; the runbook above handles it
- Dev OTP echo + permissive CORS + placeholder credentials = dev-only posture (prod checklist in infra/README)

---

*Last updated: end of the finalization session (commit b5184f0+). Docker Desktop was crash-prone at the end of this session — if the platform is down when you return, start from section 4.*
