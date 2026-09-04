#!/usr/bin/env bash
set -euo pipefail

# Build et publie les images sur GHCR et Docker Hub.
#
#   ./scripts/docker-publish.sh 6.3.1
#
# Publication de secours : en temps normal c'est `.github/workflows/release.yml`
# qui publie, au merge vers main, apres le gate de tests. Ce script sert quand
# la CI est indisponible — il ne rejoue aucun test.
#
# Build multi-architecture (amd64 + arm64) : la cible self-hosted tourne aussi
# sur Raspberry Pi, NAS ARM et Apple Silicon (KKS-308).
#
# Prerequis : etre authentifie sur les deux registres.
#   echo $GITHUB_TOKEN | docker login ghcr.io -u <votre-login> --password-stdin
#   docker login

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Exemple: $0 6.3.1"
  exit 1
fi

# Refuse un prefixe 'v' : les tags d'image suivent VERSION (6.3.1), les tags
# git portent le prefixe (v6.3.1). Les melanger publierait `:v6.3.1`, que
# personne n'ira chercher.
if [[ "$VERSION" == v* ]]; then
  echo "ERREUR : donner la version sans prefixe 'v' (6.3.1, pas v6.3.1)." >&2
  exit 1
fi

PLATFORMS="linux/amd64,linux/arm64"
MINOR="$(cut -d. -f1,2 <<< "$VERSION")"

# ATTENTION : les deux comptes ne s'ecrivent pas pareil.
#   GitHub   : sopequenoteck  (…teck)
#   DockerHub: sopequenotech  (…tech)
GHCR_OWNER="sopequenoteck"
HUB_OWNER="sopequenotech"

publish() {
  local component="$1"
  echo "=== ${component} (${PLATFORMS}) ==="
  docker buildx build --platform "${PLATFORMS}" \
    -t "ghcr.io/${GHCR_OWNER}/k-budget-${component}:${VERSION}" \
    -t "ghcr.io/${GHCR_OWNER}/k-budget-${component}:${MINOR}" \
    -t "ghcr.io/${GHCR_OWNER}/k-budget-${component}:latest" \
    -t "${HUB_OWNER}/k-budget-${component}:${VERSION}" \
    -t "${HUB_OWNER}/k-budget-${component}:${MINOR}" \
    -t "${HUB_OWNER}/k-budget-${component}:latest" \
    -f "${component}/Dockerfile" "${component}/" \
    --push
}

publish api
publish app

echo
echo "=== Publie ==="
for component in api app; do
  echo "  ghcr.io/${GHCR_OWNER}/k-budget-${component}:{${VERSION}, ${MINOR}, latest}"
  echo "  ${HUB_OWNER}/k-budget-${component}:{${VERSION}, ${MINOR}, latest}"
done
echo
echo "Premiere publication sur GHCR ? Les paquets y sont PRIVES par defaut."
echo "Les rendre publics : https://github.com/users/${GHCR_OWNER}/packages"
echo "  -> chaque paquet -> Package settings -> Change visibility -> Public"
