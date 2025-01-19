# kubernetes workbench

![pi 3 node cluster](docs/img/pi-kube.jpg?raw=true)

- [setup guide (used to install)](https://anthonynsimon.com/blog/kubernetes-cluster-raspberry-pi/)
- [another setup guide](https://blog.alexellis.io/self-hosting-kubernetes-on-your-raspberry-pi/)

## goals

- Create a home managable kubernetes cluster beyond mimkube.
- automate system configuration
- become familiur with different deployment mechanisms
  - [kubectl](https://kubernetes.io/docs/reference/kubectl/)
  - [terraform](https://developer.hashicorp.com/terraform/docs)
  - [helm](https://helm.sh/docs/)
  - [argocd](https://argo-cd.readthedocs.io/en/stable/)
    - [k3s install](https://blog.differentpla.net/blog/2022/02/02/argocd/)
- migrate docker home services
  - to kube manifest
  - to terraform resources
  - to helm charts
- longhorn distributive [fs](https://gdha.github.io/pi-stories/pi-stories9/)
  - [for rancher k3s](https://github.com/sleighzy/raspberry-pi-k3s-homelab/blob/main/rancher-longhorn-storage.md)
  - [rpi cluster block storage](https://rpi4cluster.com/k3s-storage-setting/)

## cluster and kube stuff

- [remove traefik](https://qdnqn.com/k3s-remove-traefik/)
- [install nginx](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters)

### kubernetes

- [kube docs](https://kubernetes.io/docs/home/)
- [minikube](https://minikube.sigs.k8s.io/docs/)
  - used for local testing/dev
- [kompose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
  - translate docker -> kube not always helpfull
  - see gradle scripts for some useful commands
- [K3S pi cluster](https://docs.k3s.io/)
  - [releases](https://github.com/k3s-io/k3s/releases)
  - [system upgrade controller](https://github.com/rancher/system-upgrade-controller)
    - [more howto](https://www.cncf.io/blog/2020/11/25/upgrade-a-k3s-kubernetes-cluster-with-system-upgrade-controller/)
  - [local-path pv and pvc](https://github.com/rancher/local-path-provisioner)
  - [NFS Volumes](https://www.phillipsj.net/posts/k3s-enable-nfs-storage/)

### pv/pvc
- nfs issues 
  - [k3s](https://github.com/k3s-io/k3s/issues/5165)
  - [pgsql k3s 1](https://www.reddit.com/r/devops/comments/tuxaak/issues_deploying_postgres_onto_k3s/)
  - [pgsql k3s 2](https://www.reddit.com/r/kubernetes/comments/tuxar0/issues_deploying_postgres_onto_k3s/)
  - [possible solution](https://www.itwonderlab.com/postgres-kubernetes-nfs-volume/)

### kubectl
- get logs ```kubectl logs <podname> -f  -n <namespace>```
- recycle pod ```kubectl rollout restart deployment <deployment_name> -n <namespace>```
- check ingress ```kubectl logs -n ingress-nginx deployment/ingress-nginx-controller```
- create adhok secret ```kubectl create secret generic <name> ...```
  - for help ```kubectl create secret generic --help```

### terraform
- [docs](https://developer.hashicorp.com/terraform?ajs_aid=cbf6f5d7-2a05-47c6-8353-14ea3695c4c4&product_intent=terraform)
- [structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- providers
  - [helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
  - [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [k2tf](https://github.com/sl1pm4t/k2tf)
  - handy for converting kube manifest to terraform
  - not 100% but does most of the brute force work
- [.gitignore](https://github.com/github/gitignore/blob/main/Terraform.gitignore)

### ansible
- used to provision PIs
- [docs](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4)

## services

### dashboard
- [repo](https://github.com/kubernetes/dashboard/tree/master)
- [doc](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- working with kube manifest and ingress via https
- auth token embedded in nginx proxy/loadbalancer  
- TODO load via TF

### jenkins
  - from docker-comose.yml -> KOMPOSE kube manifest -> k2tf terraform manifest
  - nfs volume store
  - nginx ingress

### sonarqube
- [official docs](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/deploy-on-kubernetes/deploy-sonarqube-on-kubernetes/?gads_campaign=SQ-Hroi-PMax&gads_ad_group=Global&gads_keyword=&gclid=EAIaIQobChMIj7njhtaugQMVLofCCB1hZgc_EAAYAiAAEgLCnfD_BwE)
  - some local glitches i ran into
- [medium aritcle](https://medium.com/codex/easy-deploy-sonarqube-on-kubernetes-with-yaml-configuration-27f5adc8de90)
  - got some tweaks
- [example setup](https://github.com/doctor500/sonarqube-on-kubernetes)
  - more tweaks and hackery
- [posgres setup](https://adamtheautomator.com/postgres-to-kubernetes/)
  - [bitnami helm](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
  - [possible issue 1](https://github.com/bitnami/charts/issues/7282)
  - [possible issue 2](https://github.com/helm/charts/issues/9093)
  - went with this and got it working on mimikube
  - still wip on cluster
  - pgsql service crasing


### ingress
- minikube
  - [on minkube](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
  
  - got a working version for minikube [here](https://stackoverflow.com/questions/51751462/nginx-ingress-jenkins-path-rewrite-configuration-not-working)
- k3s
- [nginx ingres controller](https://kubernetes.github.io/ingress-nginx/)
- [key is to configure loadbalancer](https://blog.thenets.org/how-to-create-a-k3s-cluster-with-nginx-ingress-controller/)
- TODO need to determine ip mappings but seems i can hit from any node ip...
  - [ingress endpoint addr](https://stackoverflow.com/questions/49845021/getting-an-kubernetes-ingress-endpoint-ip-address)

### aws

- [ebs volume](https://angelmarybabu.github.io/posts/How-to-create-Persistent-Volume-in-EKS/)
- [eks storage](https://repost.aws/knowledge-center/eks-persistent-storage)

## TODOs

- [cloud-init](https://help.ubuntu.com/community/CloudInit) to bridge imaging and ansible
- service running with both kube manifest and terraform
- proper host ingress on cluster
- https via [opnsense CA](https://www.ssltrust.com/help/setup-guides/use-opnsense-ca-certificate-authority)
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
  - [http access issue](https://github.com/argoproj/argo-cd/issues/2953)
- deploy to [GKE](https://cloud.google.com/kubernetes-engine/)
- deploy to [EKS](https://aws.amazon.com/eks/)
  - [aws provitioning](https://stackoverflow.com/questions/75758115/persistentvolumeclaim-is-stuck-waiting-for-a-volume-to-be-created-either-by-ex)
- [pi monitoring](https://dirtyoptics.com/how-to-monitor-a-raspberry-pi-remotely/)
- [kube jenkins agents](https://plugins.jenkins.io/kubernetes/)
- [longhorn](https://github.com/longhorn/longhorn)
  - [ks3 install](https://medium.com/@pongsatt/k3s-kubernetes-cluster-storage-with-longhorn-ff201947d3f5)

## FAQ

- [unbounded volume](https://stackoverflow.com/questions/60774220/kubernetes-pod-has-unbound-immediate-persistentvolumeclaims)
- [pvc creation excededs timeout](https://github.com/hashicorp/terraform-provider-kubernetes/issues/1349)
- [node labeling](https://linuxhandbook.com/kubectl-label-node/)
- [pod debugging](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [stalled k3s upgrade](https://github.com/k3s-io/k3s/issues/9350)
  - [uncordon node](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_uncordon/)