# OpenProject wrapper for Railway. Upstream's compose runs four containers from one image (web, worker, cron, one-shot seeder) that
# share an assets volume, which Railway cannot do (a volume attaches to one service), plus a memcached. This image runs the seeder,
# the web server and the background worker in one container on one volume, creates the admin login from variables, and closes
# public self-registration, which upstream leaves open ("activation by e-mail").
# upstream: opf/openproject
# 17.9.8 is the newest release at build time (checked against the GitHub releases API and Docker Hub on 2026-11-23).
FROM openproject/openproject:17.9.8-slim@sha256:9555489b1ec84c53275dbf63c4c101e7002222e6f273d7fc10e8ff18f8f726c0

USER root

# Baked so the deploy form stays empty: a literal template variable publishes as a blank required field.
# SELF__REGISTRATION=0 turns self-registration off (upstream default 2: anyone may register, activation by e-mail).
ENV OPENPROJECT_HTTPS=true \
    OPENPROJECT_SELF__REGISTRATION=0 \
    OPENPROJECT_SEED_ADMIN_USER_PASSWORD_RESET=false \
    OPENPROJECT_SEED_ADMIN_USER_NAME="OpenProject Admin"

COPY boot.sh /app/railway-boot.sh
COPY api-token.rb /app/railway-api-token.rb
RUN chmod 0755 /app/railway-boot.sh

EXPOSE 8080
ENTRYPOINT ["/app/railway-boot.sh"]
