# Feature: Civic reports (feedback)

Citizens submit geo-tagged reports: category, title, description, up to
three photos (multipart, ≤5 MB, jpg/png/webp) and a map location stored as
MySQL `POINT SRID 4326`. Photos are written to `uploads/feedback/{id}/` and
served by feedback-service at `/uploads/**` (the gateway routes it as a
public path). `GET /feedback/near-me` orders by real distance with
`ST_Distance_Sphere`. Citizens upvote once per report (composite PK → 409)
and comment. The report wizard checks for similar reports within ~300 m
before submitting.

Admins triage: status transitions OPEN → IN_PROGRESS → RESOLVED are
validated against an allowed-transition map, recorded in
`feedback_status_history`, and fire the notification chain after commit.
Assignment, public/internal notes and hiding complete the workflow, and
`GET /admin/audit` returns the full trail. Pre-signed cloud uploads (R2/
MinIO/SeaweedFS) were removed — files live on a Docker volume that survives
restarts.
