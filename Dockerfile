# Beaver Habit Tracker for Railway: official image, pinned by version and digest.
FROM daya0576/beaverhabits:0.10.1@sha256:a924af2bb5db56d44210b4cc8935233fb0a71731a6748c244391405ebd3cc3d2

USER root
COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh
COPY --chmod=644 bootstrap_admin.py /app/bootstrap_admin.py

ENV PORT=8080 \
    ENV=production \
    HABITS_STORAGE=DATABASE \
    NICEGUI_STORAGE_PATH=/app/.user/.nicegui \
    PYTHONUNBUFFERED=1

WORKDIR /app
EXPOSE 8080
# Starts as root only to fix the volume's ownership, then drops to `nobody`.
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
