# kubernetes workbench

![initial version raspberry pi cluster](docs/img/pi-kube.jpg?raw=true)

## goals

- Create a home managable kubernetes cluster beyond mimkube.
- automate system configuration
- become familiur with different deployment mechanisms
  - [kubectl](https://kubernetes.io/docs/reference/kubectl/)
  - [terraform](https://developer.hashicorp.com/terraform/docs)
  - [helm](https://helm.sh/docs/)
  - [argocd](https://argo-cd.readthedocs.io/en/stable/)
- become familiur with different persistent storage engines
  - [local-path](https://github.com/rancher/local-path-provisioner/blob/master/README.md)
  - [nfs](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
  - [longhorn](https://longhorn.io/docs/1.8.0/)
- become familiur with ingress configuration
  - [nginx controller](https://github.com/kubernetes/ingress-nginx)
  - [remove traefik](https://qdnqn.com/k3s-remove-traefik/)
- migrate docker home services
  - to kube manifest
  - to terraform resources
  - to helm charts where possible
  - to argocd deployment

## Pi hardware
- [raspberry pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)
- controller
  - 8g memory
  - 128 sd card
  - 500g nvme drive over usb3
- nodes
  - 4g memory
  - 128 sd card
  - 256g usb3 flash drive

## Pi software
- custom base image build with [SDM](https://github.com/gitbls/sdm)
- additional softward install and configs via [ansible](https://docs.ansible.com/)
 - see [scripts](src/ansible)
- [rancher k3s](https://docs.k3s.io/installation)
  - [system upgrade controller](https://github.com/rancher/system-upgrade-controller)
- [nginx controller](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters)
- [nfs storage](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md)
- [longhorn](https://longhorn.io/docs/1.8.0/deploy/install/install-with-kubectl/)
- controller
  - nfs storage
  - nginx as cluster loadbalancer

## deployed services

services converted from docker compose -> kubectl -> terraform
- seed kube manifasts with [kompose](https://kompose.io/)
  - need to create PVC manifests
  - externalize any sensitive data via [envsubst](https://www.baeldung.com/linux/envsubst-command)
- seed terraform resources with [k2tf](https://formulae.brew.sh/formula/k2tf)
  - externalize any sensitive data via [tf environment variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables)
- made enviroment variables portable to be used for both deployents  
- used gradle task wrappers for deployments
  - see [scripts](src/gradle)

### dashboard
- [repo](https://github.com/kubernetes/dashboard/tree/master)
- [doc](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- deployments
  - [kubectl](src/kube/dashboard/)
  - [terraform](src/terraform/dashboard/)
- [nginx](src/conf/etc/nginx/sites-available/dashboard.conf)
- requires tls certs to expose 

### jenkins
- [image](https://hub.docker.com/_/jenkins)
- [doc](https://www.jenkins.io/doc/book/installing/kubernetes/)
- deployments
  - [kubectl](src/kube/jenkins)
  - [terraform](src/terraform/jenkins)
- [nginx](src/conf/etc/nginx/sites-available/jenkins.conf)

### sonarqube
- images
  - [sonar](https://hub.docker.com/_/sonarqube)
  - [postgres](https://hub.docker.com/_/postgres)
- [doc](https://docs.sonarsource.com/sonarqube-server/9.6/setup-and-upgrade/deploy-on-kubernetes/deploy-sonarqube-on-kubernetes/)
  - did not get official install/helm working
  - only working postgres with longhorn storage
  - addtional work arounds within deployments
- deployments
  - [kubectl](src/kube/sonar)
  - [terraform](src/terraform/sonar)
- [nginx](src/conf/etc/nginx/sites-available/sonar.conf)

## cloud storage (wip)

- [ebs volume](https://angelmarybabu.github.io/posts/How-to-create-Persistent-Volume-in-EKS/)
- [eks storage](https://repost.aws/knowledge-center/eks-persistent-storage)

## kubectl useful commands
- get logs ```kubectl logs <podname> -f  -n <namespace>```
- recycle pod ```kubectl rollout restart deployment <deployment_name> -n <namespace>```
- check ingress ```kubectl logs -n ingress-nginx deployment/ingress-nginx-controller```
- get storage classes ```kubectl get storageclass --all-namespaces```
- create adhok secret ```kubectl create secret generic <name> ...```
  - for help ```kubectl create secret generic --help```
- change storage class default ```kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'```
- dump all resources ```kubectl api-resources --verbs=list --namespaced -o name | xargs -t -i kubectl get {} -n=<namespace> --ignore-not-found```

## TODOs

- need to init intial image ansible user/ssh/hostname
  - [cloud-init](https://help.ubuntu.com/community/CloudInit) to bridge imaging and ansible
- deploy to [GKE](https://cloud.google.com/kubernetes-engine/)
- deploy to [EKS](https://aws.amazon.com/eks/)
  - [aws provitioning](https://stackoverflow.com/questions/75758115/persistentvolumeclaim-is-stuck-waiting-for-a-volume-to-be-created-either-by-ex)
- [kube base jenkins agents](https://plugins.jenkins.io/kubernetes/)
- [support bundle](https://github.com/rancher/support-bundle-kit/tree/master)
- standup mini pc nodes
  - [thinkcentre 920q](https://www.lenovo.com/us/en/p/desktops/thinkcentre/m-series-tiny/thinkcentre-m920q/11tc1mtm92q?orgRef=https%253A%252F%252Fwww.google.com%252F&srsltid=AfmBOoqfJde58W9ybDoj4Xi2nrvFXK8io-XDBNUJ8xnuuy4uRPzBqb2-)

## helpfull links found along the way

- [unbounded volume](https://stackoverflow.com/questions/60774220/kubernetes-pod-has-unbound-immediate-persistentvolumeclaims)
- [pvc creation excededs timeout](https://github.com/hashicorp/terraform-provider-kubernetes/issues/1349)
- [node labeling](https://linuxhandbook.com/kubectl-label-node/)
- [pod debugging](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [stalled k3s upgrade](https://github.com/k3s-io/k3s/issues/9350)
  - [uncordon node](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_uncordon/)
- [kube docs](https://kubernetes.io/docs/home/)
- [minikube](https://minikube.sigs.k8s.io/docs/)
  - used for local testing/dev
- [kompose](https://kompose.io/)
  - [usage](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
  - not always complete, volumes need to be manually converted
  - see gradle scripts for some useful commands
- [K3S pi cluster](https://docs.k3s.io/)
  - [releases](https://github.com/k3s-io/k3s/releases)
    - [more howto](https://www.cncf.io/blog/2020/11/25/upgrade-a-k3s-kubernetes-cluster-with-system-upgrade-controller/)
  - [local-path pv and pvc](https://github.com/rancher/local-path-provisioner)
  - [NFS Volumes](https://www.phillipsj.net/posts/k3s-enable-nfs-storage/)
  - [longhorn](https://longhorn.io/docs/1.7.2/)
    - [example](https://rpi4cluster.com/k3s-storage-setting/)
    - [basic auth ui](https://longhorn.io/docs/1.7.2/deploy/accessing-the-ui/longhorn-ingress/)
- longhorn distributive [fs](https://gdha.github.io/pi-stories/pi-stories9/)
  - [for rancher k3s](https://github.com/sleighzy/raspberry-pi-k3s-homelab/blob/main/rancher-longhorn-storage.md)
  - [rpi cluster block storage](https://rpi4cluster.com/k3s-storage-setting/)
- [setup guide (used to install)](https://anthonynsimon.com/blog/kubernetes-cluster-raspberry-pi/)
- [another setup guide](https://blog.alexellis.io/self-hosting-kubernetes-on-your-raspberry-pi/)
- [docs](https://developer.hashicorp.com/terraform?ajs_aid=cbf6f5d7-2a05-47c6-8353-14ea3695c4c4&product_intent=terraform)
- [structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- providers
  - [helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
  - [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [.gitignore](https://github.com/github/gitignore/blob/main/Terraform.gitignore)
