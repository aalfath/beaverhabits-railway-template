# Changelog

## 0.10.1 (2026-11-24)

First release of this Railway template.

- Beaver Habit Tracker `v0.10.1`, image `daya0576/beaverhabits:0.10.1@sha256:a924af2bb5db56d44210b4cc8935233fb0a71731a6748c244391405ebd3cc3d2`.
- Admin account created on first boot from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD`; sign-up closed (`MAX_USER_COUNT=1`).
- Generated `JWT_SECRET`; session and reset-token secrets derived from it instead of upstream's public defaults.
- SQLite data on a Railway volume at `/app/.user`; health check at `/health`.
