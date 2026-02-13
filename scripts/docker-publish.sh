#!/usr/bin/env bash
set -euo pipefail

# Build, tag et push les images Docker sur Docker Hub
# Usage: ./scripts/docker-publish.sh v1.0.0

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.0.0"
  exit 1
fi

API_IMAGE="sopequenotech/budget-api"
APP_IMAGE="sopequenotech/budget-app"

echo "=== Build API image ==="
docker build -t "${API_IMAGE}:${VERSION}" -f api/Dockerfile api/

echo "=== Build Frontend image ==="
docker build -t "${APP_IMAGE}:${VERSION}" -f app/Dockerfile app/

echo "=== Tag latest ==="
docker tag "${API_IMAGE}:${VERSION}" "${API_IMAGE}:latest"
docker tag "${APP_IMAGE}:${VERSION}" "${APP_IMAGE}:latest"

echo "=== Push to Docker Hub ==="
docker push "${API_IMAGE}:${VERSION}"
docker push "${API_IMAGE}:latest"
docker push "${APP_IMAGE}:${VERSION}"
docker push "${APP_IMAGE}:latest"

echo "=== Done ==="
echo "Published:"
echo "  ${API_IMAGE}:${VERSION}"
echo "  ${API_IMAGE}:latest"
echo "  ${APP_IMAGE}:${VERSION}"
echo "  ${APP_IMAGE}:latest"
