# Feature: Admin User Management (Roles)

Closes the loop on the role system: admins can see every account and promote
citizens to MODERATOR or ADMIN (or demote them) without touching the
database. Roles were defined from day one — CITIZEN, MODERATOR, ADMIN — and
this feature makes them manageable.

## Role model

| Role | Meaning today |
|---|---|
| CITIZEN | Default for everyone who logs in. Votes, submits feedback, upvotes, comments. |
| MODERATOR | Reserved for content-oversight powers (not yet wired to endpoints — designed for hide/edit review flows). |
| ADMIN | Creates/closes polls, transitions feedback status, reads analytics and the event feed, manages users. |

Where roles are checked:

| Check | Location |
|---|---|
| Admin endpoints in poll/feedback services | Controller + service compare `GatewayUser.role()` / `principal.role()` against ADMIN |
| Admin panel login | `/me` role must be `ADMIN` or the app shows "access denied" |
| User management endpoints | `AdminUserController.requireAdmin` + `AdminUserService.changeRole` |

## Endpoints (auth-service owns the users table)

| Method & path | Who | Purpose |
|---|---|---|
| `GET /api/v1/auth/admin/users?search=&role=&page=&size=` | ADMIN | Paged list; search matches name (case-insensitive) or phone |
| `PATCH /api/v1/auth/admin/users/{id}/role` | ADMIN | Body `{"newRole": "CITIZEN|MODERATOR|ADMIN"}` |

### Business rules (unit-tested)

1. **Only ADMINs** may call either endpoint — anyone else gets **403**
   (`AUT-403`), not 401, so clients don't mistake it for an expired token.
2. **No self-demotion**: an admin changing their own role away from ADMIN is
   rejected with 409 — otherwise the last admin could lock themselves out.
   (Promoting yourself is harmless and also blocked for symmetry.)
3. Unknown user id → 404.
4. Invalid role string → 400 (bean validation on the request record).

### One caveat worth understanding

The role lives **inside the JWT** (`role` claim). After a role change, the
affected user keeps their old authority until their current access token
expires — at most **15 minutes**. This is a deliberate simplicity trade-off;
making it instant would mean adding a `tokenVersion` claim checked against
the database on every request.

## The admin panel's Users tab

```
┌────────────────────────────────────────────────────────────┐
│ [Search by name or phone________________________] →        │
│ (All) (Citizen) (Moderator) (Admin)      ← role filters    │
├────────────────────────────────────────────────────────────┤
│ (N) nihar        9999999999    [ADMIN]      🔒             │ ← own row: locked
│ (N) Nihar        9876543210    [CITIZEN]   ⋮               │ ← menu: Make Citizen/
│ (N) Nihar        7888221430    [CITIZEN]   ⋮                  Moderator/Admin
└────────────────────────────────────────────────────────────┘
```

- Search + filters call the list endpoint; role changes call the PATCH.
- The signed-in admin's own row shows a lock icon (the server enforces the
  same rule — the UI just makes it visible).
- Success/failure toasts come from the shared error message in the
  `ApiResponse` envelope.

## Where the code lives

| Concern | File |
|---|---|
| Endpoints | `backend/auth-service/.../controller/AdminUserController.java` |
| Rules + user search | `backend/auth-service/.../service/AdminUserService.java` |
| Request/response DTOs | `backend/auth-service/.../dto/UpdateRoleRequest.java`, `AdminUserResponse.java` |
| Unit tests | `backend/auth-service/src/test/.../AdminUserServiceTest.java` |
| Users tab UI | `admin/lib/main.dart` (_UsersTab, _RoleChip) |
| Users bloc | `admin/lib/features/users/admin_users_bloc.dart` |
| Signed-in admin id (for the lock icon) | `admin/lib/features/auth/admin_auth_bloc.dart` (AdminAuthenticated.userId) |

## Try it

```bash
# list users
curl -s "localhost:8080/api/v1/auth/admin/users?search=nih" -H "Authorization: Bearer $ADMIN_TOKEN"

# promote user 1 to moderator
curl -s -X PATCH localhost:8080/api/v1/auth/admin/users/1/role \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"newRole":"MODERATOR"}'

# self-demotion → 409
curl -s -o /dev/null -w '%{http_code}\n' -X PATCH \
  localhost:8080/api/v1/auth/admin/users/2/role \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"newRole":"CITIZEN"}'
```
