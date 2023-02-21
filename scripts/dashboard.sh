#!/bin/bash
#
# Deploys the Kubernetes dashboard when enabled in settings.yaml

set -euxo pipefail

config_path="/vagrant/configs"

DASHBOARD_VERSION=$(grep -E '^\s*dashboard:' /vagrant/settings.yaml | sed -E 's/[^:]+: *//')
if [ -n "${DASHBOARD_VERSION}" ]; then
  while sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for metrics server to be ready...'
    sleep 5
  done