#!/bin/bash
# Runs once on first container start (after 01-databases.sql).
# Enables the PostGIS extension in feedbackdb (geo-tagged feedback queries).
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d feedbackdb <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS postgis;
EOSQL

echo "Extensions enabled."
