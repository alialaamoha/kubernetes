
  echo 'Metrics server is ready. Installing dashboard...'

  sudo -i -u vagrant kubectl create namespace kubernetes-dashboard

  echo "Creating the dashboard user..."

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  echo "Deploying the dashboard..."
 # sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"
   sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"

  sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}" >> "${config_path}/token"
  echo "The following token was also saved to: configs/token"
  cat "${config_path}/token"
  echo "
Use it to log in at:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
"
fi