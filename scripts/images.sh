#!/usr/bin/env bash
# Builds the three LaunchKit images from the launchkit-server and launchkit-web checkouts and loads them straight
# into the k3s of the server (D4, no registry yet).
# Usage: scripts/images.sh <version>        e.g. scripts/images.sh 0.1.0
# SERVER (default root@31.57.224.79), SERVER_REPO (default ../launchkit-server or ../server), WEB_REPO (idem).
set -euo pipefail
VERSION=${1:?version expected, e.g. 0.1.0}
HERE=$(cd "$(dirname "$0")/.." && pwd)
SERVER=${SERVER:-root@31.57.224.79}
first() { for d in "$@"; do [ -d "$d" ] && { echo "$d"; return; }; done; echo "missing: $*" >&2; exit 1; }
SERVER_REPO=${SERVER_REPO:-$(first "$HERE/../launchkit-server" "$HERE/../server")}
WEB_REPO=${WEB_REPO:-$(first "$HERE/../launchkit-web" "$HERE/../web")}

build() { echo "image $1: build"; docker build -q "${@:2}" -t "docker.io/launchkit/$1:$VERSION" > /dev/null; }
build api -f "$SERVER_REPO/api/Dockerfile" "$SERVER_REPO"
build worker --network host -f "$SERVER_REPO/worker/Dockerfile" "$SERVER_REPO"
build web "$WEB_REPO"
for i in api worker web; do
  echo "image $i: $(docker image inspect "docker.io/launchkit/$i:$VERSION" --format '{{.Size}}' | awk '{printf "%.0f MB", $1/1e6}')"
done
echo "loading into the k3s of $SERVER"
docker save "docker.io/launchkit/api:$VERSION" "docker.io/launchkit/worker:$VERSION" "docker.io/launchkit/web:$VERSION" \
  | gzip -1 | ssh "$SERVER" 'gunzip | k3s ctr -n k8s.io images import - > /dev/null'
echo "images $VERSION loaded"
