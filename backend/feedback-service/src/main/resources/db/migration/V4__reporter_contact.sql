-- Reporter contact captured at submit time (from the verified gateway
-- headers) so the notification service can send status emails without
-- reaching into auth-service data.
ALTER TABLE feedback
    ADD COLUMN reporter_name  VARCHAR(100) NULL,
    ADD COLUMN reporter_email VARCHAR(255) NULL;
