#!/usr/bin/env bash
#
# monitoring-up.sh — install the cluster monitoring stack on AKS via Argo CD.
#
# Deploys kube-prometheus-stack (Prometheus + Grafana + Alertmanager +
# node-exporter + kube-state-metrics) by applying the Argo CD Application in
# deploy/argocd/monitoring.yaml. Argo CD then renders the Helm chart and syncs
# it into the `monitoring` namespace.
#
# Prereqs (already true after the AKS setup):
#   - kubectl pointed at the AKS cluster (az aks get-credentials ...)
#   - Argo CD installed in the `argocd` namespace
#
# Usage:
#   ./scripts/monitoring-up.sh            # uses context "school-demo"
#   KUBE_CONTEXT=my-ctx ./scripts/monitoring-up.sh
#
set -euo pipefail

CONTEXT="${KUBE_CONTEXT:-school-demo}"
# Resolve the repo root so the script works from any directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_FILE="$REPO_ROOT/deploy/argocd/monitoring.yaml"

if [[ ! -f "$APP_FILE" ]]; then
  echo "ERROR: $APP_FILE not found" >&2
  exit 1
fi

echo "==> Using kube context: $CONTEXT"
kubectl config use-context "$CONTEXT" >/dev/null

echo "==> Sanity check: Argo CD must be installed"
if ! kubectl get ns argocd >/dev/null 2>&1; then
  echo "ERROR: namespace 'argocd' not found — install Argo CD first." >&2
  exit 1
fi

echo "==> Applying monitoring Application: $APP_FILE"
kubectl apply -f "$APP_FILE"

echo "==> Waiting for Argo CD to sync the stack (Helm render + CRDs can take 2-4 min)..."
SYNCED=""
for i in $(seq 1 48); do
  SYNC=$(kubectl get application monitoring -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  HEALTH=$(kubectl get application monitoring -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  printf '    [%02d] sync=%s health=%s\n' "$i" "${SYNC:-?}" "${HEALTH:-?}"
  if [[ "$SYNC" == "Synced" && "$HEALTH" == "Healthy" ]]; then
    SYNCED="yes"
    break
  fi
  sleep 10
done

echo
echo "==> Pods in 'monitoring' namespace:"
kubectl get pods -n monitoring 2>/dev/null || echo "    (namespace not created yet)"

if [[ -z "$SYNCED" ]]; then
  echo
  echo "WARN: Application not yet Synced+Healthy. It may still be converging."
  echo "      Watch with:  kubectl get application monitoring -n argocd -w"
fi

cat <<'EOF'

============================================================
 Access the monitoring UIs (each runs in its own terminal):

   Grafana       kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
                 -> http://localhost:3000   (user: admin  password: admin)

   Prometheus    kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
                 -> http://localhost:9090

   Alertmanager  kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
                 -> http://localhost:9093

 Tear down monitoring only (leaves the app running):
   kubectl delete -f deploy/argocd/monitoring.yaml
============================================================
EOF
