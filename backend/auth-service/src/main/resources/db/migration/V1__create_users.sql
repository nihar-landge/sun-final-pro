-- Users owned by auth-service. Other services store user_id without a
-- cross-database foreign key (microservices data boundary).
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    phone       VARCHAR(15) UNIQUE NOT NULL,
    name        VARCHAR(100),
    avatar_url  VARCHAR(255),
    role        VARCHAR(20) NOT NULL DEFAULT 'CITIZEN', -- CITIZEN, MODERATOR, ADMIN
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role ON users(role);
