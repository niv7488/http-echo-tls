#!/usr/bin/env bash
# One-shot setup + verification for the http-echo home assignment.
# Usage: ./setup.sh            (from the directory containing this script)
#        SKIP_HOSTS=1 ./setup.sh   (don't touch /etc/hosts)
set -euo pipefail

RELEASE="http-echo"
HOST="http-echo.k8s-server.local"
CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# 1. Prerequisites
log "Checking prerequisites"
for bin in minikube kubectl helm curl; do
  command -v "$bin" >/dev/null 2>&1 || fail "'$bin' is not installed (see README step 1)"
done

# 2. Cluster + ingress controller
log "Starting minikube"
if minikube status >/dev/null 2>&1; then
  echo "minikube already running"
else
  minikube start
fi

log "Enabling nginx ingress controller"
minikube addons enable ingress
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

# The ingress admission webhook can lag behind the controller being Ready
log "Waiting for ingress admission webhook"
for i in $(seq 1 30); do
  kubectl -n ingress-nginx get endpoints ingress-nginx-controller-admission \
    -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null | grep -q . && break
  sleep 2
done

# 3. Validate the chart
log "helm lint"
helm lint "$CHART_DIR"

log "helm install --dry-run=server (validated by the real API server)"
helm upgrade --install "$RELEASE" "$CHART_DIR" --dry-run=server >/dev/null
echo "dry run OK"

# 4. Deploy
log "Deploying chart"
helm upgrade --install "$RELEASE" "$CHART_DIR" --wait --timeout 180s

log "Cluster state"
kubectl get pods,svc,ingress -l "app.kubernetes.io/instance=$RELEASE"

# 5. Host mapping
DRIVER="$(minikube profile list -o json 2>/dev/null | grep -o '"Driver":"[^"]*"' | head -1 | cut -d'"' -f4 || true)"
if [[ "$(uname -s)" == "Darwin" && "$DRIVER" == "docker" ]]; then
  IP="127.0.0.1"
  echo "NOTE: macOS + docker driver detected. Run 'minikube tunnel' in another terminal"
  echo "      (ports 80/443 on 127.0.0.1) before the curl tests below will succeed."
else
  IP="$(minikube ip)"
fi

if [[ "${SKIP_HOSTS:-0}" != "1" ]]; then
  if grep -qE "[[:space:]]$HOST(\$|[[:space:]])" /etc/hosts; then
    log "/etc/hosts already has an entry for $HOST (make sure it points to $IP)"
  else
    log "Adding '$IP $HOST' to /etc/hosts (sudo required)"
    echo "$IP $HOST" | sudo tee -a /etc/hosts >/dev/null
  fi
fi

# 6. Verify
log "Verifying HTTP (expect redirect to HTTPS)"
curl -sS -o /dev/null -w "HTTP  status: %{http_code} -> %{redirect_url}\n" \
  --resolve "$HOST:80:$IP" "http://$HOST/" || true

log "Verifying HTTPS (self-signed cert, hence -k)"
BODY="$(curl -ksS --fail --resolve "$HOST:443:$IP" "https://$HOST/")" \
  || fail "HTTPS request failed"
echo "$BODY" | head -c 300; echo " ..."
echo "$BODY" | grep -q "\"hostname\":\"$HOST\"" \
  && echo "OK: echo server responded with the expected host" \
  || fail "Unexpected response body"

log "helm test"
helm test "$RELEASE"

log "Done. Try: curl -k https://$HOST/"
