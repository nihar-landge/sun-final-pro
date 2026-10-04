-- authdb is created by the MYSQL_DATABASE env var; these three plus grants:
CREATE DATABASE IF NOT EXISTS polldb;
CREATE DATABASE IF NOT EXISTS feedbackdb;
CREATE DATABASE IF NOT EXISTS notificationdb;

-- The services connect as user 'feedback' (created by MYSQL_USER env as
-- 'feedback'@'%', which only gets rights on authdb) — grant it on all four.
-- The 'localhost' twin exists because connections from host-run services
-- (mvn spring-boot:run / java -jar) arrive from 127.0.0.1 and never match '%'.
GRANT ALL PRIVILEGES ON polldb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON feedbackdb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON notificationdb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON authdb.* TO 'feedback'@'%';
GRANT ALL PRIVILEGES ON polldb.* TO 'feedback'@'localhost';
GRANT ALL PRIVILEGES ON feedbackdb.* TO 'feedback'@'localhost';
GRANT ALL PRIVILEGES ON notificationdb.* TO 'feedback'@'localhost';
GRANT ALL PRIVILEGES ON authdb.* TO 'feedback'@'localhost';
FLUSH PRIVILEGES;
