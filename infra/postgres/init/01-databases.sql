-- Creates the per-service databases (authdb is created via POSTGRES_DB env var).
-- Only runs on a fresh volume; existing volumes need the same
-- CREATE DATABASE statements run manually (e.g. notificationdb added 2026-09-26).
CREATE DATABASE polldb;
CREATE DATABASE feedbackdb;
CREATE DATABASE notificationdb;
