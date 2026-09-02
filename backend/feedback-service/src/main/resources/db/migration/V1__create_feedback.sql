-- Feedback domain tables owned by feedback-service.
-- user_id columns reference the users table in authdb logically; no cross-database
-- foreign keys exist by design (microservices data boundary).

-- The owning service ensures its own extension (idempotent).
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE feedback (
    id              BIGSERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    category        VARCHAR(50) NOT NULL,   -- ROADS, WATER, ELECTRICITY, SANITATION, TRANSPORT, OTHER
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',  -- OPEN, IN_REVIEW, RESOLVED
    location        GEOGRAPHY(POINT, 4326), -- PostGIS geo-tag
    user_id         BIGINT NOT NULL,        -- users.id (authdb)
    sentiment_score FLOAT,
    sentiment_label VARCHAR(10),            -- POSITIVE, NEGATIVE, NEUTRAL
    upvotes         INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE feedback_images (
    id          BIGSERIAL PRIMARY KEY,
    feedback_id BIGINT NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
    image_url   VARCHAR(255) NOT NULL,      -- MinIO object URL
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Audit trail for the admin status workflow.
CREATE TABLE feedback_status_history (
    id          BIGSERIAL PRIMARY KEY,
    feedback_id BIGINT NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
    old_status  VARCHAR(20),
    new_status  VARCHAR(20) NOT NULL,
    changed_by  BIGINT,                     -- users.id (authdb), nullable for system changes
    changed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- One upvote per user per feedback item.
CREATE TABLE feedback_upvotes (
    feedback_id BIGINT NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
    user_id     BIGINT NOT NULL,            -- users.id (authdb)
    voted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (feedback_id, user_id)
);

CREATE TABLE comments (
    id           BIGSERIAL PRIMARY KEY,
    feedback_id  BIGINT NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
    user_id      BIGINT NOT NULL,           -- users.id (authdb)
    comment_text TEXT NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedback_location ON feedback USING GIST(location);
CREATE INDEX idx_feedback_category ON feedback(category);
CREATE INDEX idx_feedback_status ON feedback(status);
CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_status_history_feedback ON feedback_status_history(feedback_id);
