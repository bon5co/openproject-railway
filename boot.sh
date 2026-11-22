#!/bin/bash
# Railway boot for OpenProject: fix the volume owner, run the seeder (migrations, seed data, the admin login), then run the web
# server and the background worker side by side. Runs as root only for the chown; every OpenProject process runs as the image's
# `app` user.
set -euo pipefail

DATA="${APP_DATA_PATH:-/var/openproject/assets}"
RUN_AS=(setpriv --reuid=app --regid=app --init-groups)

: "${DATABASE_URL:?DATABASE_URL is not set}"
: "${SECRET_KEY_BASE:?SECRET_KEY_BASE is not set}"
: "${RAILWAY_PUBLIC_DOMAIN:?RAILWAY_PUBLIC_DOMAIN is not set (the service needs a public domain)}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is not set}"
: "${API_TOKEN:?API_TOKEN is not set}"

# Railway mounts the volume owned by root; OpenProject writes attachments and caches under it as `app`.
echo "[railway] uid=$(id -u) assets owner before=$(stat -c %u:%g "$DATA")"
mkdir -p "$DATA/files"
chown -R app:app "$DATA"
echo "[railway] assets owner after=$(stat -c %u:%g "$DATA")"

export OPENPROJECT_HOST__NAME="$RAILWAY_PUBLIC_DOMAIN"
export OPENPROJECT_SEED_ADMIN_USER_PASSWORD="$ADMIN_PASSWORD"
export OPENPROJECT_SEED_ADMIN_USER_MAIL="${ADMIN_EMAIL:-admin@$RAILWAY_PUBLIC_DOMAIN}"
export PORT="${PORT:-8080}"

echo "[railway] seeding (migrations, seed data, admin login)"
"${RUN_AS[@]}" env HOME=/home/app /app/docker/prod/seeder

echo "[railway] api token"
"${RUN_AS[@]}" env HOME=/home/app bash -c 'cd /app && bundle exec rails runner /app/railway-api-token.rb'

echo "[railway] starting worker and web on port $PORT"
"${RUN_AS[@]}" env HOME=/home/app /app/docker/prod/worker &
WORKER=$!
"${RUN_AS[@]}" env HOME=/home/app /app/docker/prod/web &
WEB=$!

stop() { kill -TERM "$WEB" "$WORKER" 2>/dev/null || true; wait "$WEB" "$WORKER" 2>/dev/null || true; }
trap 'stop; exit 143' TERM INT

# Either process ending takes the container down so Railway restarts both.
wait -n "$WEB" "$WORKER" || true
echo "[railway] a process exited; stopping the container"
stop
exit 1
