CREATE TABLE polls (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    start_time   DATETIME NOT NULL,
    end_time     DATETIME NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    created_by   BIGINT NOT NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_poll_dates CHECK (end_time > start_time)
);

CREATE TABLE poll_options (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    poll_id     BIGINT NOT NULL,
    option_text VARCHAR(200) NOT NULL,
    votes_count INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_poll_options_poll FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE
);

-- The one-person-one-vote rule is enforced by the composite primary key.
CREATE TABLE poll_participation (
    poll_id  BIGINT NOT NULL,
    user_id  BIGINT NOT NULL,
    voted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (poll_id, user_id)
);

-- Ballots are anonymous: no user_id, so published results cannot be traced back.
CREATE TABLE ballots (
    id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    poll_id   BIGINT NOT NULL,
    option_id BIGINT NOT NULL,
    voted_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ballots_poll FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE,
    CONSTRAINT fk_ballots_option FOREIGN KEY (option_id) REFERENCES poll_options(id) ON DELETE CASCADE
);

CREATE INDEX idx_poll_options_poll ON poll_options(poll_id);
CREATE INDEX idx_ballots_poll ON ballots(poll_id);
CREATE INDEX idx_ballots_option ON ballots(option_id);
CREATE INDEX idx_participation_user ON poll_participation(user_id);
CREATE INDEX idx_polls_active ON polls(start_time, end_time);
