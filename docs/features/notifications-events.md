# Feature: Notifications & email

The notification service owns `notificationdb` and the citizen inbox:
`GET /api/v1/notifications`, `GET /unread-count`, `PUT /{id}/read`,
`PUT /read-all` (plus mobile path aliases). When feedback-service commits a
status change it publishes an event consumed strictly AFTER COMMIT and
forwarded over HTTP to `POST /internal/notifications` (shared
`X-Service-Key`, not routed through the gateway). The service saves the
inbox row, then tries the Express email service (`POST /api/email/
report-status`) with a 3-second timeout.

Failure tolerance is the design point: a notification-service outage cannot
fail a report status change (live-verified — 200 in ~100 ms with the service
down), and an email failure only logs. Express renders and sends the email
via nodemailer; without SMTP configured (dev) it logs the rendered email and
returns 200. No RabbitMQ, no broker — plain REST between services.
