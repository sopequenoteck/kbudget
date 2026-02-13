#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
BACKUP_DIR="${BACKUP_DIR:-/opt/k-budget-api/backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
DB_NAME="${DB_NAME:-budget_db}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-budget_u}"

# --- Execution ---
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
FILENAME="budget_db_${TIMESTAMP}.sql.gz"
FILEPATH="${BACKUP_DIR}/${FILENAME}"

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Backup de ${DB_NAME} vers ${FILEPATH}..."

pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" "${DB_NAME}" | gzip > "${FILEPATH}"

# Verification fichier non vide
if [ ! -s "${FILEPATH}" ]; then
    echo "[$(date)] ERREUR : le fichier backup est vide, suppression."
    rm -f "${FILEPATH}"
    exit 1
fi

SIZE=$(du -h "${FILEPATH}" | cut -f1)
echo "[$(date)] Backup OK : ${FILENAME} (${SIZE})"

# Rotation : supprimer les backups plus anciens que BACKUP_RETENTION_DAYS
DELETED=$(find "${BACKUP_DIR}" -name "budget_db_*.sql.gz" -mtime +"${BACKUP_RETENTION_DAYS}" -delete -print | wc -l)
if [ "${DELETED}" -gt 0 ]; then
    echo "[$(date)] Rotation : ${DELETED} ancien(s) backup(s) supprime(s)."
fi

echo "[$(date)] Termine."
