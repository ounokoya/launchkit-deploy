#!/usr/bin/env bash
# On the server, as root (D5): draws the ArangoDB and super admin passwords at random and stores them in the Secret
# « launchkit-secrets ». They never leave the server. Refuses to replace an existing Secret.
# Read the super admin password later: k3s kubectl -n launchkit get secret launchkit-secrets -o jsonpath='{.data.admin_password}' | base64 -d
set -euo pipefail
k() { k3s kubectl -n launchkit "$@"; }
if k get secret launchkit-secrets > /dev/null 2>&1; then echo "Secret launchkit-secrets already exists: nothing changed."; exit 0; fi
random() { head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24; }
k create secret generic launchkit-secrets \
  --from-literal=arango_root="$(random)" \
  --from-literal=admin_password="$(random)" > /dev/null
echo "Secret launchkit-secrets created (ArangoDB root, super admin)."
