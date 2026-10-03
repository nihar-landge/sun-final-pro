-- The citizen notification inbox lives with the reports that generate it.
-- Status changes insert rows here in the same transaction (no broker needed);
-- notification-service polls unpushed rows for FCM delivery.
CREATE TABLE notification (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL,          -- recipient (users.id, logical ref)
    type        VARCHAR(40) NOT NULL,     -- REPORT_STATUS | POLL_REMINDER
    title       VARCHAR(200) NOT NULL,
    body        VARCHAR(1000) NOT NULL,
    ref_id      BIGINT,                   -- report/poll id for deep-linking
    pushed_at   TIMESTAMP,                -- FCM delivery attempted
    read_at     TIMESTAMP,                -- null = unread
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_user ON notification(user_id, created_at DESC);
CREATE INDEX idx_notification_unpushed ON notification(pushed_at) WHERE pushed_at IS NULL;

-- One FCM device token per user (notification-service reads this to push).
CREATE TABLE device_token (
    user_id     BIGINT PRIMARY KEY,
    token       TEXT NOT NULL,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
