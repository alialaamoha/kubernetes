# A distributed Kubernetes cluster ready for microservice, Data Analaytics, MLOps,  DevOps and Gitops

Setting up a Kubernetes cluster and alot of addons like longhorn , gitlab and  Istio service mesh 

**Note**: using virtual machines to setup distributed Kubernetes cluster will bring a high load on your computer

## Demo

### Architecture

We will create a Kubernetes 1.15.0 cluster with 3 nodes which contains the components below:

| IP            | Hostname | Componets                                |
| ------------  | -------- | ---------------------------------------- |
| 192.168.56.10 | node1    | kube-apiserver, kube-controller-manager, kube-scheduler, etcd, kubelet, docker, flannel, dashboard |
| 192.168.56.11  | node2    | kubelet, crio, calico、traefik , Metallp         |
| 192.168.56.12  | node3    | kubelet, crio, flannel , Metallb                 |
**increase the count of workers form the yaml settings file**

The default setting will create the private network from 192.168.56.10 to 192.168.56.29 for nodes, and it will use the host's DHCP for the public IP.

The kubernetes service's VIP range is `10.254.0.0/16`.

The container network range is `172.16.1.0/16` owned by flanneld calico

The Metallp loadbalancer ip ranges is ' 192.168.56.30-192.168.56.60' 

all the settings you can change from the settings folder 

## Usage

### Prerequisite

* Host server with 8G+ mem(More is better), 60G disk, 8 core cpu at lease
* **Vagrant latest（2.2.16 recommended）**
* **VirtualBox 7**
* Kubernetes 1.26.1-00 (support the latest version 1.16.14)
* MacOS/Linux and windows
* NFS Server Package 

### Supported Add-ons

**Core**

- CoreDNS
- Metallb
- Traefik
- longhorn
- Dashboard
 
**Optional**

- gitlab includes Cert-manager 
- artifactory for code dependency 
- harbor "private registry for images and helm charts"
- MinIO  "S3 object store"
- Argocd  "Gitops" 
- Helm
- Vault 
- ElasticSearch + Fluentd + Kibana
- Heapster + InfluxDB + Grafana
- Istio service mesh
- Vistio
- Kiali
- valero

**aplications** 
- postgress operator
- mongodb operator
- kafka operator
- 

#### Setup

Clone this repo into your local machine and download kubernetes and helm binary release first and move them into the root directory of this repo (GitBash for the Windows must be run as Administrator to install ```vagrant``` plugin).

```bash
vagrant plugin install vagrant-winnfsd
git clone https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster.git

```


Set up Kubernetes cluster with vagrant.

```bash
vagrant up
```

Wait about 10 minutes the kubernetes cluster will be setup automatically.

#### Note for Mac

VirtualBox may be blocked by Mac's security limit.
Go to `System Preferences` - `Security & Privacy` - `Gerneral` click the blocked app and unblock it.

Run  `sudo "/Library/Application Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh" restart` in terminal and then `vagrant up`.

Solution:

```bash
vagrant ssh node3
sudo -i
cd /vagrant/addon/dns
yum -y install dos2unix
dos2unix dns-deploy.sh
./dns-deploy.sh -r 10.254.0.0/16 -i 10.254.0.2 |kubectl apply -f -
```

#### Connect to kubernetes cluster

There are 3 ways to access the kubernetes cluster.

- on local
- login to VM
- Kubernetes dashboard

**local**

In order to manage the cluster on local you should Install `kubectl` command line tool first(But, you don't need to do it manually because of ```install.sh``` script itself does this).

Go to [Kubernetes release notes](https://kubernetes.io/docs/setup/release/notes/), download the client binaries, unzip it and then move `kubectl`  to your `$PATH` folder, for MacOS:

```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.16.14/kubernetes-client-darwin-amd64.tar.gz
tar xvf kubernetes-client-darwin-amd64.tar.gz && cp kubernetes/client/bin/kubectl /usr/local/bin
```

Copy `conf/admin.kubeconfig` to `~/.kube/config`, using `kubectl` CLI to access the cluster.

```bash
mkdir -p ~/.kube
cp conf/admin.kubeconfig ~/.kube/config
```

We recommend you follow this way.

**VM**

Login to the virtual machine for debuging. In most situations, you have no need to login the VMs.

```bash
vagrant ssh node1
sudo -i
kubectl get nodes
kubectl get pods --namespace=kube-system
```

**Kubernetes dashboard**

refere to the readme section for kubernetes dashboard

**Note**: You can see the token message on console when  `vagrant up` done.

![Kubernetes dashboard animation](images/dashboard-animation.gif)

## Components

**Traefik**

Run this command on your local machine.

```bash
kubectl apply -f /vagrant/addon/traefik-ingress
```

Append the following item to your  local file  `/etc/hosts`.

```ini
172.17.8.102 traefik.jimmysong.io
```

Traefik UI URL: <http://traefik.jimmysong.io>

![Traefik Ingress controller](images/traefik-ingress.gif)

**EFK**

Run this command on your local machine.

```bash
kubectl apply -f /vagrant/addon/efk/
```

**Note**: Powerful CPU and memory allocation required. At least 4G per virtual machine.

### Service Mesh

We use [istio](https://istio.io) as the default service mesh.

**Installation**

Go to [Istio release](https://github.com/istio/istio/releases) to download the binary package, install istio command line tool on local and move `istioctl` to your `$PATH` folder, for Mac:

```bash
wget https://github.com/istio/istio/releases/download/1.0.0/istio-1.0.0-osx.tar.gz
tar xvf istio-1.0.0-osx.tar.gz
mv istio-1.0.0/bin/istioctl /usr/local/bin/
```

Deploy istio into Kubernetes:

```bash
kubectl apply -f /vagrant/addon/istio/istio-demo.yaml
kubectl apply -f /vagrant/addon/istio/istio-ingress.yaml
```

**Run sample**

We will let the sidecars be auto injected.

```bash
kubectl label namespace default istio-injection=enabled
kubectl apply -n default -f /vagrant/yaml/istio-bookinfo/bookinfo.yaml
kubectl apply -n default -f /vagrant/yaml/istio-bookinfo/bookinfo-gateway.yaml
kubectl apply -n default -f /vagrant/yaml/istio-bookinfo/destination-rule-all.yaml
```

Add the following items into the file  `/etc/hosts` of your local machine.

```
172.17.8.102 grafana.istio.jimmysong.io
172.17.8.102 prometheus.istio.jimmysong.io
172.17.8.102 servicegraph.istio.jimmysong.io
172.17.8.102 jaeger-query.istio.jimmysong.io
```

We can see the services from the following URLs.

| Service      | URL                                                          |
| ------------ | ------------------------------------------------------------ |
| grafana      | http://grafana.istio.jimmysong.io                            |
| servicegraph | <http://servicegraph.istio.jimmysong.io/dotviz>, <http://servicegraph.istio.jimmysong.io/graph>,<http://servicegraph.istio.jimmysong.io/force/forcegraph.html> |
| tracing      | http://jaeger-query.istio.jimmysong.io                       |
| productpage  | http://172.17.8.101:31380/productpage                        |

More detail see https://istio.io/docs/examples/bookinfo/

![Bookinfo Demo](images/bookinfo-demo.gif)

### Vistio

[Vizceral](https://github.com/Netflix/vizceral) is an open source project released by Netflix to monitor network traffic between applications and clusters in near real time. Vistio is an adaptation of Vizceral for Istio and mesh monitoring. It utilizes metrics generated by Istio Mixer which are then fed into Prometheus. Vistio queries Prometheus and stores that data locally to allow for the replaying of traffic.

Run the following commands in your local machine.

```bash
# Deploy vistio via kubectl
kubectl -n default apply -f /vagrant/addon/vistio/

# Expose vistio-api
kubectl -n default port-forward $(kubectl -n default get pod -l app=vistio-api -o jsonpath='{.items[0].metadata.name}') 9091:9091 &

# Expose vistio in another terminal window
kubectl -n default port-forward $(kubectl -n default get pod -l app=vistio-web -o jsonpath='{.items[0].metadata.name}') 8080:8080 &
```

If everything up until now is working you should be able to load the Vistio UI  in your browser http://localhost:8080

![vistio animation](images/vistio-animation.gif)

More details see [Vistio — Visualize your Istio Mesh Using Netflix’s Vizceral](https://itnext.io/vistio-visualize-your-istio-mesh-using-netflixs-vizceral-b075c402e18e).

### Kiali

Kiali is a project to help observability for the Istio service mesh, see [https://kiali.io](https://kiali.io/).

Run the following commands in your local machine.

```bash
kubectl apply -n istio-system -f /vagrant/addon/kiali
```

Kiali web: http://172.17.8.101:32439

User/password: admin/admin

![kiali](images/kiali.gif)

**Note**: Kiali use jaeger for tracing. Do not block the pop-up windows for kiali.

## Operation

Except for special claim, execute the following commands under the current git repo's root directory.

### Suspend

Suspend the current state of VMs.

```bash
vagrant suspend
```

### Resume

Resume the last state of VMs.

```bash
vagrant resume
```

Note: every time you resume the VMs you will find that the machine time is still at you last time you suspended it. So consider to halt the VMs and restart them.

### Restart

Halt the VMs and up them again.

```bash
vagrant halt
vagrant up
# login to node1
vagrant ssh node1
# run the prosivision scripts
/vagrant/hack/k8s-init.sh
exit
# login to node2
vagrant ssh node2
# run the prosivision scripts
/vagrant/hack/k8s-init.sh
exit
# login to node3
vagrant ssh node3
# run the prosivision scripts
/vagrant/hack/k8s-init.sh
sudo -i
cd /vagrant/hack
./deploy-base-services.sh
exit
```

Now you have provisioned the base kubernetes environments and you can login to kubernetes dashboard, run the following command at the root of this repo to get the admin token.

```bash
hack/get-dashboard-token.sh
```

Following the hint to login.

### Clean

Clean up the VMs.

```bash
vagrant destroy
rm -rf .vagrant
```

### Note

Only use for development and test, don't use it in production environment. 

for production ready check  aws , linode version for the same archeticture using terraform 

for on peromise check bearmetal  , VMware tanzu