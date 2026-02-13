#!/usr/bin/env bash
set -euo pipefail

# Build, tag et push les images Docker sur Docker Hub
# Usage: ./scripts/docker-publish.sh v1.0.0
# Build multi-platform (linux/amd64) pour serveur x86_64

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.0.0"
  exit 1
fi

PLATFORM="linux/amd64"
API_IMAGE="sopequenotech/k-budget-api"
APP_IMAGE="sopequenotech/k-budget-app"

echo "=== Build & push API image (${PLATFORM}) ==="
docker buildx build --platform "${PLATFORM}" \
  -t "${API_IMAGE}:${VERSION}" \
  -t "${API_IMAGE}:latest" \
  -f api/Dockerfile api/ \
  --push

echo "=== Build & push Frontend image (${PLATFORM}) ==="
docker buildx build --platform "${PLATFORM}" \
  -t "${APP_IMAGE}:${VERSION}" \
  -t "${APP_IMAGE}:latest" \
  -f app/Dockerfile app/ \
  --push

echo "=== Done ==="
echo "Published (${PLATFORM}):"
echo "  ${API_IMAGE}:${VERSION}"
echo "  ${API_IMAGE}:latest"
echo "  ${APP_IMAGE}:${VERSION}"
echo "  ${APP_IMAGE}:latest"
