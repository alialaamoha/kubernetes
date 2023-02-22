#!/bin/bash
#
# Deploys the Metallb 

set -euxo pipefail

config_path="/vagrant/configs"


echo "Deploying METALLB ..."
sudo -i -u vagrant kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml


# Enhanments tip: to load ip pools from settings file 
# ip ranges for external advertised loadbalancer cluster 
cat <<EOF | kubectl apply -f - 
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: class-a-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.30-192.168.56.60
EOF


cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: class-a--ip-advertised
  namespace: metallb-system
spec:
  ipAddressPools:
  - class-a-pool
EOF