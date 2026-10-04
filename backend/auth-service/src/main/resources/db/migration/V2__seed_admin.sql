-- Dev seed: the built-in admin account (email/password login).
-- Password: Admin@123 (BCrypt) — dev only; override the row in real deployments.
INSERT INTO users (email, password_hash, name, role)
VALUES ('admin@civicpulse.in', '$2a$10$TLHvrYz2r71Lgdu6Qqo3f.5yk7UHLhH3CYpedKQT6KliuYoJDdFae', 'City Admin', 'ADMIN')
ON DUPLICATE KEY UPDATE email = email;
