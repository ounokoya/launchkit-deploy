#!/usr/bin/env bash
# Applies the manifests of k8s/ on the server, with the images of <version> (loaded by scripts/images.sh).
# Usage: scripts/deploy.sh <version> [--dry-run]     SERVER (required, e.g. root@your-server)
set -euo pipefail
VERSION=${1:?version expected, e.g. 0.1.0}
DRY=${2:-}
HERE=$(cd "$(dirname "$0")/.." && pwd)
SERVER=${SERVER:?set SERVER, e.g. SERVER=root@your-server}
manifests() { for f in "$HERE"/k8s/*.yaml; do sed "s/:VERSION$/:$VERSION/" "$f"; echo '---'; done; }
if [ "$DRY" = "--dry-run" ]; then
  # The namespace must exist for the server-side check of the other objects.
  manifests | ssh "$SERVER" 'k3s kubectl apply --dry-run=server -f -'
  exit 0
fi
ssh "$SERVER" 'k3s kubectl apply -f -' < "$HERE/k8s/00-namespace.yaml"
ssh "$SERVER" 'bash -s' < "$HERE/scripts/secrets.sh"
manifests | ssh "$SERVER" 'k3s kubectl apply -f -'
ssh "$SERVER" 'k3s kubectl -n launchkit rollout status statefulset/arangodb --timeout=180s
  for d in mailpit api worker web; do k3s kubectl -n launchkit rollout status deployment/$d --timeout=180s; done'
echo "LaunchKit $VERSION deployed: https://saas.koyad.com"
