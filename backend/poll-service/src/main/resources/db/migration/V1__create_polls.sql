-- Poll domain tables owned by poll-service.
-- user_id columns reference the users table in authdb logically; no cross-database
-- foreign keys exist by design (microservices data boundary).

CREATE TABLE polls (
    id           BIGSERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    start_time   TIMESTAMP NOT NULL,
    end_time     TIMESTAMP NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    created_by   BIGINT NOT NULL,          -- users.id (authdb)
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (end_time > start_time)
);

CREATE TABLE poll_options (
    id          BIGSERIAL PRIMARY KEY,
    poll_id     BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_text VARCHAR(200) NOT NULL,
    votes_count INTEGER NOT NULL DEFAULT 0
);

-- The one-person-one-vote rule is enforced by the composite primary key.
CREATE TABLE poll_participation (
    poll_id  BIGINT NOT NULL,
    user_id  BIGINT NOT NULL,              -- users.id (authdb)
    voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (poll_id, user_id)
);

-- Ballots are anonymous: no user_id, so published results cannot be traced back.
CREATE TABLE ballots (
    id       BIGSERIAL PRIMARY KEY,
    poll_id  BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id BIGINT NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_poll_options_poll ON poll_options(poll_id);
CREATE INDEX idx_ballots_poll ON ballots(poll_id);
CREATE INDEX idx_ballots_option ON ballots(option_id);
CREATE INDEX idx_participation_user ON poll_participation(user_id);
CREATE INDEX idx_polls_active ON polls(start_time, end_time);
