-- authdb is created by the MYSQL_DATABASE env var; these three plus grants:
CREATE DATABASE IF NOT EXISTS polldb;
CREATE DATABASE IF NOT EXISTS feedbackdb;
CREATE DATABASE IF NOT EXISTS notificationdb;

-- The services connect as user 'feedback' (created by MYSQL_USER env,
-- which only gets rights on authdb) — grant it on all four:
GRANT ALL PRIVILEGES ON polldb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON feedbackdb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON notificationdb.* TO 'feedback'@'%';
FLUSH PRIVILEGES;
