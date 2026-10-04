# Database Schema

Four logical databases on **one MySQL 8.4 container** — one owned per
service. Every service applies its own **Flyway** SQL migrations at startup
(`services/*/src/main/resources/db/migration`); there is no JPA auto-DDL.

Cross-service references are plain IDs (`user_id`, `poll_id`,
`feedback_id`) — **no foreign keys across databases**. Business rules that
must never be broken are encoded as **composite primary keys**.

---

## authdb — auth-service

### users
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| email | VARCHAR(255) | NOT NULL, UNIQUE (`uq_users_email`) |
| password_hash | VARCHAR(100) | NOT NULL — BCrypt |
| name | VARCHAR(100) | NULL |
| role | ENUM('CITIZEN','ADMIN') | NOT NULL, DEFAULT 'CITIZEN' |
| created_at / updated_at | DATETIME | NOT NULL, auto |

Index: `idx_users_role`. Seed (V2): the built-in admin
`admin@civicpulse.in` (password `Admin@123`, BCrypt) — dev only.

---

## polldb — poll-service

### polls
id PK · title VARCHAR(200) NOT NULL · description TEXT ·
start_time/end_time DATETIME NOT NULL with **CHECK (end_time > start_time)** ·
is_anonymous BOOLEAN DEFAULT FALSE · created_by BIGINT (logical ref → authdb) ·
created_at. Index `idx_polls_active(start_time, end_time)`.

### poll_options
id PK · poll_id **FK → polls(id) ON DELETE CASCADE** · option_text ·
votes_count INT DEFAULT 0 (denormalized counter for fast results).

### poll_participation ⭐ one-person-one-vote
**composite PRIMARY KEY (poll_id, user_id)** · voted_at.
The database itself rejects a second vote → HTTP 409.

### ballots (anonymous)
id PK · poll_id FK CASCADE · option_id FK CASCADE · voted_at.
**No user_id** — published results cannot be traced back to voters.

---

## feedbackdb — feedback-service

### feedback (final shape; V1 + V2 + V4, sentiment dropped in V3)
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK AUTO_INCREMENT | |
| title | VARCHAR(200) NOT NULL | |
| description | TEXT | |
| category | VARCHAR(50) NOT NULL | ROADS, WATER, ELECTRICITY, … |
| status | VARCHAR(20) DEFAULT 'OPEN' | OPEN / IN_PROGRESS / RESOLVED |
| **location** | **POINT SRID 4326** | MySQL spatial; near-me uses ST_Distance_Sphere |
| user_id | BIGINT NOT NULL | reporter (logical ref → authdb) |
| upvotes | INT DEFAULT 0 | cached counter |
| assigned_to | VARCHAR(100) NULL | staff member (V2) |
| public_note / internal_note | TEXT NULL | triage notes (V2) |
| hidden | BOOLEAN DEFAULT FALSE | soft moderation (V2) |
| reporter_name / reporter_email | VARCHAR NULL | captured at submit (V4) |
| created_at / updated_at | DATETIME | auto |

Indexes: category, status, user_id, assigned_to.

### feedback_images
id PK · feedback_id FK CASCADE · image_url (relative path under `uploads/`) ·
uploaded_at.

### feedback_status_history (audit trail)
id PK · feedback_id FK CASCADE · old_status NULL · new_status · changed_by ·
changed_at.

### feedback_upvotes ⭐ one-upvote-per-citizen
**composite PRIMARY KEY (feedback_id, user_id)** · voted_at → 409 on repeat.

### comments
id PK · feedback_id FK CASCADE · user_id · comment_text · created_at.

---

## notificationdb — notification-service

### notifications
id PK · user_id (recipient) · type VARCHAR(50) · title · body ·
ref_id (the report id, for deep links) · **read_at DATETIME NULL — NULL =
unread** · created_at.
Indexes: `idx_notifications_user`, `idx_notifications_unread(user_id, read_at)`
— the unread-count query is index-covered.

---

## Relationships

Within a database (real FKs, all `ON DELETE CASCADE`):

- polls 1—N poll_options, ballots, poll_participation
- feedback 1—N feedback_images, feedback_status_history, comments, feedback_upvotes

Across databases (logical references only — draw dashed on the ERD):

- users.id → feedback.user_id, comments.user_id, notifications.user_id,
  poll_participation.user_id, polls.created_by

> **Schema evolution:** Flyway shows the history — feedback was created with
> sentiment columns (V1), they were dropped in V3 when the feature was cut,
> admin triage fields arrived in V2 and reporter contact in V4. The schema
> evolves as versioned migrations, never by hand.
