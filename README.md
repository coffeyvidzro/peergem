# PeerGem

PeerGem is a Rails application running on Ruby 4.0.7 and PostgreSQL. Its UI is
server-rendered ERB enhanced with Turbo, Stimulus, Tailwind CSS, Propshaft, and
importmap—no Node.js runtime is required.

## Authentication API

PeerGem supports passwordless email OTP sign-in, optional passwords, and
password recovery. Start with `POST /auth/start` and an `email`, then use one of
the methods returned by that endpoint. Successful verification and login
responses contain a bearer token. Send it as `Authorization: Bearer <token>` to
enroll or replace a password at `POST /auth/password/enroll`.

All password submissions require matching `password` and
`password_confirmation` values and passwords are at least 12 characters. OTPs
expire after 10 minutes, allow five attempts, and can be resent after 60
seconds. The available endpoints are:

| Method | Path | Authentication | Purpose |
|---|---|---:|---|
| `POST` | `/auth/start` | No | Start an authentication transaction |
| `POST` | `/auth/email/send` | No | Send the first email OTP |
| `POST` | `/auth/email/resend` | No | Resend an email OTP after the cooldown |
| `POST` | `/auth/email/verify` | No | Verify an OTP and create a session |
| `POST` | `/auth/password/login` | No | Complete a transaction using a password |
| `POST` | `/auth/password/enroll` | Bearer | Add or replace the authenticated user's password |
| `POST` | `/auth/password/forgot` | No | Start password recovery and send a code |
| `POST` | `/auth/password/reset` | No | Verify a recovery code and replace the password |

Sessions are opaque, revocable bearer credentials prefixed with `pgs_`, and
session public IDs use the `ses_` prefix. Send credentials in the
`Authorization` header:

```http
Authorization: Bearer pgs_<opaque-token>
```

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/sessions` | List all active sessions for the current user |
| `GET` | `/sessions/:id` | Get one active or historical session owned by the user |
| `DELETE` | `/sessions/:id` | Revoke one session |
| `DELETE` | `/sessions` | Revoke every session belonging to the user |

Session listings contain only unrevoked, unexpired sessions ordered newest
first. Individual session responses also include `last_active_at` and a
best-effort MaxMind `location`; either may be `null`, and GeoIP lookup failures
never fail the request.

## User API

The singular `/user` resource manages only the identity associated with the
current bearer session. User public IDs are prefixed with `usr_`; the underlying
identity remains separate from merchant membership and financial records.
Deactivating an identity prevents future sign-in and revokes all of its active
sessions without deleting the record.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/user` | Retrieve the authenticated user's profile |
| `PATCH` | `/user` | Update the authenticated user's display name |
| `DELETE` | `/user` | Safely deactivate the authenticated account |
