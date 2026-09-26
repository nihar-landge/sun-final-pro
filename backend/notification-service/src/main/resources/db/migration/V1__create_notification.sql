-- Persistent notification inbox (owned by notification-service).
CREATE TABLE notification (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL,          -- recipient (users.id in authdb, logical ref)
    type        VARCHAR(40) NOT NULL,     -- REPORT_STATUS | POLL_REMINDER | ...
    title       VARCHAR(200) NOT NULL,
    body        VARCHAR(1000) NOT NULL,
    ref_id      BIGINT,                   -- report/poll id for deep-linking
    read_at     TIMESTAMP,                -- null = unread
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_user ON notification(user_id, created_at DESC);
CREATE INDEX idx_notification_unread ON notification(user_id) WHERE read_at IS NULL;
