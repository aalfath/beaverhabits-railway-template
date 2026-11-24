[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/beaver-habit-tracker?utm_medium=integration&utm_source=button&utm_campaign=beaverhabits)

# Beaver Habit Tracker on Railway

One-click Railway template for [Beaver Habit Tracker](https://github.com/daya0576/beaverhabits), a self-hosted habit tracker with quick daily check-ins, streaks, notes, tags and a JSON import/export.

- **App version:** `v0.10.1`, official image `daya0576/beaverhabits:0.10.1@sha256:a924af2bb5db56d44210b4cc8935233fb0a71731a6748c244391405ebd3cc3d2`
- **Services:** one, `Beaver Habit Tracker`, built from this repo's `Dockerfile`
- **Storage:** SQLite (`habits.db`) and session files on a Railway volume at `/app/.user`
- **Health check:** `GET /health`
- **Memory:** about 160 MB in use; runs on Railway's Free plan (0.5 GB / 1 vCPU)

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *(you enter it)* | The email you sign in with. The account is created on first boot. |
| `ADMIN_PASSWORD` | `${{secret(20, …)}}` | Generated. Read it in the service's **Variables** tab. Change it there and redeploy to reset your password. |
| `JWT_SECRET` | `${{secret(48, …)}}` | Generated signing key for login tokens. Session and reset-token secrets are derived from it. |
| `PORT` | `8080` | Port the app listens on. |

## What the wrapper changes

Upstream's defaults are made for a private home network. This wrapper makes a public Railway URL safe:

- Upstream's built-in secrets (`JWT_SECRET=SECRET`, `NICEGUI_STORAGE_SECRET=dev`) are public and would let anyone forge a login. The start script refuses to start without a random `JWT_SECRET` and derives the other secrets from it.
- Upstream's sign-up page is open to anyone. Here the admin account is created from `ADMIN_EMAIL`/`ADMIN_PASSWORD` before the web server starts, and `MAX_USER_COUNT=1` closes sign-up, so nobody else can register. The API's `/auth/register` also needs the admin's token. To allow more people, set `MAX_USER_COUNT` to a higher number (each visitor can then create an account until the limit is reached).
- Session cookies are marked Secure behind Railway's HTTPS.
- The container starts as root only to fix the volume's ownership, then runs the app as `nobody`.
- Any setup failure exits non-zero, so Railway's restart policy applies.

Optional upstream settings (time zone, first day of week, index columns, daily backups, SMTP for password reset) are documented in the [upstream wiki](https://github.com/daya0576/beaverhabits/wiki/Environment-variables) and can be added as service variables.

## Updates

Deployers get Railway's "update available" notice when this repo's `main` changes. Each version bump is listed in [CHANGELOG.md](CHANGELOG.md), with breaking changes first. Your data stays on the volume across updates.

## Licence

Beaver Habit Tracker is BSD-3-Clause, © Henry Zhu. The wrapper files in this repo are provided under the same licence.
