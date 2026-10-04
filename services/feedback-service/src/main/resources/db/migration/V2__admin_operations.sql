ALTER TABLE feedback
    ADD COLUMN assigned_to VARCHAR(100) NULL,
    ADD COLUMN public_note TEXT NULL,
    ADD COLUMN internal_note TEXT NULL,
    ADD COLUMN hidden BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_feedback_assigned ON feedback(assigned_to);
