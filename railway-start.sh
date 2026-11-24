#!/bin/sh
# Railway start script for Beaver Habit Tracker.
# Fails (non-zero exit) on any setup problem so Railway's ON_FAILURE restart policy applies.
set -eu
cd /app

fail() { echo "railway-start: $*" >&2; exit 1; }

# --- Secrets -----------------------------------------------------------------
JWT_SECRET="${JWT_SECRET:-}"
[ "${#JWT_SECRET}" -ge 32 ] || fail "JWT_SECRET must be set to a random value of at least 32 characters."
[ -n "${ADMIN_EMAIL:-}" ] || fail "ADMIN_EMAIL is empty. Set it to the email you will sign in with."
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
[ "${#ADMIN_PASSWORD}" -ge 12 ] || fail "ADMIN_PASSWORD must be at least 12 characters."
export JWT_SECRET ADMIN_EMAIL ADMIN_PASSWORD
derive() { printf '%s:%s' "$1" "$JWT_SECRET" | sha256sum | cut -d' ' -f1; }
# Upstream defaults are public ("dev"/empty): always replace them unless the deployer set their own.
[ -n "${NICEGUI_STORAGE_SECRET:-}" ] && [ "$NICEGUI_STORAGE_SECRET" != "dev" ] || NICEGUI_STORAGE_SECRET="$(derive nicegui-storage)"
[ -n "${RESET_PASSWORD_TOKEN_SECRET:-}" ] || RESET_PASSWORD_TOKEN_SECRET="$(derive reset-password)"
export NICEGUI_STORAGE_SECRET RESET_PASSWORD_TOKEN_SECRET

# --- Sign-up lock --------------------------------------------------------------
# The GUI sign-up page is closed once MAX_USER_COUNT users exist; the admin is created below,
# so with the default of 1 nobody else can sign up. The API's /auth/register needs the admin's token.
export MAX_USER_COUNT="${MAX_USER_COUNT:-1}"
export REQUIRE_ADMIN_FOR_REGISTRATION="${REQUIRE_ADMIN_FOR_REGISTRATION:-true}"
# Railway serves HTTPS, so session cookies are Secure there.
if [ -n "${RAILWAY_ENVIRONMENT_ID:-}" ]; then
  export NICEGUI_SESSION_HTTPS_ONLY="${NICEGUI_SESSION_HTTPS_ONLY:-true}"
fi

# --- Data volume ------------------------------------------------------------
mkdir -p /app/.user/.nicegui
if [ "$(id -u)" = "0" ]; then
  chown -R nobody:nogroup /app/.user
  RUN_AS="setpriv --reuid=nobody --regid=nogroup --clear-groups"
else
  RUN_AS=""
fi

# --- Admin account (created on first boot, password kept in sync with ADMIN_PASSWORD) ---
$RUN_AS python /app/bootstrap_admin.py || fail "admin bootstrap failed; not starting with open sign-up."

# --- Server -----------------------------------------------------------------
# One worker (NiceGUI's socket.io needs it). gunicorn exits 0 on SIGINT/SIGQUIT and when it
# gives up, which Railway's ON_FAILURE policy treats as a clean stop. So any exit that Railway
# didn't ask for (SIGTERM on redeploy/stop) is turned into a non-zero code and restarts the service.
stopping=0
trap 'stopping=1; kill -TERM "$pid" 2>/dev/null' TERM
$RUN_AS gunicorn beaverhabits.main:app \
  --bind "0.0.0.0:${PORT:-8080}" \
  -w 1 -k uvicorn_worker.UvicornWorker \
  --forwarded-allow-ips '*' \
  --max-requests 10000 --timeout 120 --graceful-timeout 10 --no-control-socket \
  --log-level info &
pid=$!
rc=0
set +e
while :; do wait "$pid"; rc=$?; kill -0 "$pid" 2>/dev/null || break; done
[ "$stopping" = "1" ] && exit 0
echo "railway-start: gunicorn exited unexpectedly (code $rc); exiting non-zero so Railway restarts it." >&2
[ "$rc" -eq 0 ] && rc=1
exit "$rc"
