#!/bin/bash
set -euo pipefail

# --- Configuration ---
APP_URL="http://localhost/health"
CONTAINER_NAME="mini-app"
LOG_FILE="$HOME/scripts/monitor.log"
BACKUP_DIR="$HOME/backups"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
MAX_BACKUPS=7

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# --- Health check ---
if curl -sf "$APP_URL" > /dev/null; then
    log "Health check OK"
else
    log "Health check FAILED — restarting container"
    docker restart "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    sleep 5
    if curl -sf "$APP_URL" > /dev/null; then
        log "Recovery SUCCESS — container back up after restart"
    else
        log "Recovery FAILED — container still unhealthy after restart"
    fi
fi

# --- Backup: nginx config + recent container logs ---
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"
TMP_DIR=$(mktemp -d)

sudo cp /etc/nginx/sites-available/mini-app "$TMP_DIR/nginx-mini-app.conf"
docker logs "$CONTAINER_NAME" --tail 200 > "$TMP_DIR/container.log" 2>&1

tar -czf "$BACKUP_FILE" -C "$TMP_DIR" .
rm -rf "$TMP_DIR"
log "Backup created: $BACKUP_FILE"

# --- Rotate old backups: keep only the most recent MAX_BACKUPS ---
cd "$BACKUP_DIR"
ls -1t backup_*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm --
log "Backup rotation complete — keeping last $MAX_BACKUPS backups"
