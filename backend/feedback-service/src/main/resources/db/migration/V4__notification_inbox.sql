CREATE TABLE IF NOT EXISTS notification (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    type        VARCHAR(40) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        VARCHAR(1000) NOT NULL,
    ref_id      BIGINT NULL,
    pushed_at   DATETIME NULL,
    read_at     DATETIME NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_user ON notification(user_id, created_at);

CREATE TABLE IF NOT EXISTS device_token (
    user_id    BIGINT PRIMARY KEY,
    token      TEXT NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
