#!/usr/bin/env bash
#
# k-budget — restauration (KKS-322)
#
#   ./deploy/restore.sh 2026-09-04_143022
#
# L'horodatage est celui affiche par backup.sh, ou visible dans les noms de
# fichiers du repertoire de sauvegarde.
#
# CE SCRIPT REMPLACE LES DONNEES EXISTANTES. Il demande confirmation avant
# d'agir, sauf si FORCE=1.
#
# La restauration s'effectue API arretee : Flyway et Hibernate tiennent des
# connexions ouvertes, et restaurer sous leurs pieds laisse un etat incoherent.

set -euo pipefail

TIMESTAMP="${1:-}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
MODE="${MODE:-docker}"
DB_NAME="${DB_NAME:-budget_db}"
DB_USERNAME="${DB_USERNAME:-budget_u}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

if [ -z "${TIMESTAMP}" ]; then
    echo "Usage : $0 <horodatage>" >&2
    echo >&2
    echo "Sauvegardes disponibles dans ${BACKUP_DIR} :" >&2
    ls -1 "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null \
        | sed 's|.*/db_||; s|\.sql\.gz$||; s|^|  |' >&2 || echo "  (aucune)" >&2
    exit 1
fi

DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
AVATARS_FILE="${BACKUP_DIR}/avatars_${TIMESTAMP}.tar.gz"

[ -f "${DB_FILE}" ] || { echo "ERREUR : ${DB_FILE} introuvable." >&2; exit 1; }

echo "Restauration de la sauvegarde ${TIMESTAMP}"
echo "  base    : $(basename "${DB_FILE}")"
[ -f "${AVATARS_FILE}" ] && echo "  avatars : $(basename "${AVATARS_FILE}")" \
                         || echo "  avatars : aucun dans cette sauvegarde"
echo
echo "Les donnees actuelles seront REMPLACEES."

if [ "${FORCE:-0}" != "1" ]; then
    printf "Continuer ? [oui/N] "
    read -r reply
    [ "${reply}" = "oui" ] || { echo "Annule."; exit 0; }
fi

# --- Arret de l'API ---
# La base reste en service : c'est elle qui recoit la restauration.
if [ "${MODE}" = "docker" ]; then
    echo "[1/4] Arret de l'API"
    docker compose stop api >/dev/null 2>&1 || true
else
    echo "[1/4] Arret de l'API (systemd)"
    sudo systemctl stop k-budget-api || true
fi

# --- Recreation du schema ---
# `DROP SCHEMA public CASCADE` plutot que `DROP DATABASE` : la base est en
# cours d'utilisation par le conteneur, et la supprimer echouerait.
echo "[2/4] Recreation du schema"
if [ "${MODE}" = "docker" ]; then
    docker compose exec -T db psql -U "${DB_USERNAME}" -d "${DB_NAME}" \
        -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null
else
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" -d "${DB_NAME}" \
        -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null
fi

# --- Restauration de la base ---
echo "[3/4] Restauration de la base"
if [ "${MODE}" = "docker" ]; then
    gzip -dc "${DB_FILE}" | docker compose exec -T db psql -U "${DB_USERNAME}" -d "${DB_NAME}" >/dev/null
else
    gzip -dc "${DB_FILE}" | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USERNAME}" -d "${DB_NAME}" >/dev/null
fi

# --- Restauration des avatars ---
if [ -f "${AVATARS_FILE}" ]; then
    echo "[4/4] Restauration des avatars"
    if [ "${MODE}" = "docker" ]; then
        docker compose start api >/dev/null 2>&1
        sleep 5
        docker compose exec -T api sh -c 'rm -rf /app/data/avatars/*' 2>/dev/null || true
        # `cat` et non `gzip -dc` : tar decompresse deja via -z. Enchainer les
        # deux donne « stdin: not in gzip format » et le tar echoue en silence,
        # laissant croire a une restauration reussie.
        cat "${AVATARS_FILE}" | docker compose exec -T api tar -xzf - -C /app/data
    else
        AVATAR_PATH="${AVATAR_STORAGE_PATH:-/opt/k-budget-api/data/avatars}"
        rm -rf "${AVATAR_PATH:?}"/*
        tar -xzf "${AVATARS_FILE}" -C "$(dirname "${AVATAR_PATH}")"
    fi
else
    echo "[4/4] Aucun avatar a restaurer"
fi

# --- Redemarrage ---
if [ "${MODE}" = "docker" ]; then
    docker compose start api >/dev/null 2>&1
else
    sudo systemctl start k-budget-api
fi

echo
echo "Restauration terminee. Verifier que l'application repond avant de"
echo "considerer l'operation reussie :"
echo "  curl -s http://localhost:\${APP_PORT:-8080}/api/meta"
