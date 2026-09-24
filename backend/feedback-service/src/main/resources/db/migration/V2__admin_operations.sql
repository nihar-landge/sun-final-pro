-- Phase 2 admin operations: assignment, notes and moderation.
ALTER TABLE feedback ADD COLUMN assigned_to VARCHAR(100);
ALTER TABLE feedback ADD COLUMN public_note TEXT;
ALTER TABLE feedback ADD COLUMN internal_note TEXT;
ALTER TABLE feedback ADD COLUMN hidden BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_feedback_assigned ON feedback(assigned_to) WHERE assigned_to IS NOT NULL;
