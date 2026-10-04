# Feature: User & role management

Roles are CITIZEN and ADMIN (MODERATOR was removed). Registration always
creates CITIZEN; the built-in admin is seeded by migration V2 and further
promotions happen through `PATCH /api/v1/auth/admin/users/{id}/role`
(admin-only; self-demotion is rejected with 409). The React admin Users
page lists, searches and filters accounts and changes roles from a
dropdown. Because the role rides in the JWT, a changed role takes effect
when the token expires (≤24 h).
