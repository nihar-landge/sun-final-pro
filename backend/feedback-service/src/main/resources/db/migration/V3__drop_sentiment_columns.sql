-- Sentiment columns were never written (the sentiment-service stub was removed);
-- drop them so the schema matches the entity.
ALTER TABLE feedback DROP COLUMN IF EXISTS sentiment_score;
ALTER TABLE feedback DROP COLUMN IF EXISTS sentiment_label;
