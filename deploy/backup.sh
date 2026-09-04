#!/usr/bin/env bash
#
# k-budget — sauvegarde complete (KKS-322)
#
# Sauvegarde la base ET les avatars. Les deux sont necessaires : restaurer la
# base seule laisse des comptes dont la photo a disparu.
#
#   ./deploy/backup.sh                 # sauvegarde dans ./backups
#   BACKUP_DIR=/mnt/nas ./deploy/backup.sh
#
# A lancer depuis le repertoire qui contient docker-compose.yml. Pour une
# installation sans Docker, voir MODE=native plus bas.
#
# Restauration : ./deploy/restore.sh <horodatage>

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
MODE="${MODE:-docker}"          # docker | native
DB_NAME="${DB_NAME:-budget_db}"
DB_USERNAME="${DB_USERNAME:-budget_u}"
DB_HOST="${DB_HOST:-localhost}" # MODE=native uniquement
DB_PORT="${DB_PORT:-5432}"      # MODE=native uniquement

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
AVATARS_FILE="${BACKUP_DIR}/avatars_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"
echo "[$(date +%H:%M:%S)] Sauvegarde vers ${BACKUP_DIR}"

# --- Base de donnees ---
if [ "${MODE}" = "docker" ]; then
    docker compose exec -T db pg_dump -U "${DB_USERNAME}" "${DB_NAME}" | gzip > "${DB_FILE}"
else
    pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" "${DB_NAME}" | gzip > "${DB_FILE}"
fi

# Un pg_dump qui echoue peut laisser un fichier gzip valide mais vide de
# contenu utile : on verifie que le dump contient bien du SQL.
if [ ! -s "${DB_FILE}" ] || ! gzip -dc "${DB_FILE}" | head -50 | grep -q "PostgreSQL database dump"; then
    echo "ERREUR : le dump est vide ou invalide, suppression." >&2
    rm -f "${DB_FILE}"
    exit 1
fi
echo "  base    : $(basename "${DB_FILE}") ($(du -h "${DB_FILE}" | cut -f1))"

# --- Avatars ---
# Absents tant qu'aucun utilisateur n'a televerse de photo : ce n'est pas une
# erreur, mais il faut le dire plutot que de laisser croire a une sauvegarde
# complete.
if [ "${MODE}" = "docker" ]; then
    if docker compose exec -T api sh -c '[ -d /app/data/avatars ] && [ "$(ls -A /app/data/avatars 2>/dev/null)" ]' 2>/dev/null; then
        docker compose exec -T api tar -czf - -C /app/data avatars > "${AVATARS_FILE}"
        echo "  avatars : $(basename "${AVATARS_FILE}") ($(du -h "${AVATARS_FILE}" | cut -f1))"
    else
        echo "  avatars : aucun a sauvegarder"
    fi
else
    AVATAR_PATH="${AVATAR_STORAGE_PATH:-/opt/k-budget-api/data/avatars}"
    if [ -d "${AVATAR_PATH}" ] && [ -n "$(ls -A "${AVATAR_PATH}" 2>/dev/null)" ]; then
        tar -czf "${AVATARS_FILE}" -C "$(dirname "${AVATAR_PATH}")" "$(basename "${AVATAR_PATH}")"
        echo "  avatars : $(basename "${AVATARS_FILE}") ($(du -h "${AVATARS_FILE}" | cut -f1))"
    else
        echo "  avatars : aucun a sauvegarder"
    fi
fi

# --- Rotation ---
DELETED=$(find "${BACKUP_DIR}" \( -name "db_*.sql.gz" -o -name "avatars_*.tar.gz" \) \
            -mtime +"${RETENTION_DAYS}" -delete -print 2>/dev/null | wc -l | tr -d ' ')
[ "${DELETED}" -gt 0 ] && echo "  rotation : ${DELETED} fichier(s) de plus de ${RETENTION_DAYS} jours supprime(s)"

echo "[$(date +%H:%M:%S)] Termine — horodatage ${TIMESTAMP}"
echo
echo "Pour restaurer cette sauvegarde :"
echo "  ./deploy/restore.sh ${TIMESTAMP}"
