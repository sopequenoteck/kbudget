#!/usr/bin/env bash
set -euo pipefail

# Build, tag et push les images Docker sur Docker Hub
# Usage: ./scripts/docker-publish.sh v1.0.0
# Build multi-architecture (amd64 + arm64) : la cible self-hosted tourne aussi
# sur Raspberry Pi, NAS ARM et Apple Silicon (KKS-308).

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.0.0"
  exit 1
fi

PLATFORMS="linux/amd64,linux/arm64"
API_IMAGE="sopequenotech/k-budget-api"
APP_IMAGE="sopequenotech/k-budget-app"

echo "=== Build & push API image (${PLATFORMS}) ==="
docker buildx build --platform "${PLATFORMS}" \
  -t "${API_IMAGE}:${VERSION}" \
  -t "${API_IMAGE}:latest" \
  -f api/Dockerfile api/ \
  --push

echo "=== Build & push Frontend image (${PLATFORMS}) ==="
docker buildx build --platform "${PLATFORMS}" \
  -t "${APP_IMAGE}:${VERSION}" \
  -t "${APP_IMAGE}:latest" \
  -f app/Dockerfile app/ \
  --push

echo "=== Done ==="
echo "Published (${PLATFORMS}):"
echo "  ${API_IMAGE}:${VERSION}"
echo "  ${API_IMAGE}:latest"
echo "  ${APP_IMAGE}:${VERSION}"
echo "  ${APP_IMAGE}:latest"
