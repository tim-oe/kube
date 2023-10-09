# kubernetes workbench

![lpi cluster](docs/img/pi-kube.jpg?raw=true)

- [setup guide](https://anthonynsimon.com/blog/kubernetes-cluster-raspberry-pi/)
- [another seup guide](https://blog.alexellis.io/self-hosting-kubernetes-on-your-raspberry-pi/)

## goals

- Create a home managable kubernetes cluster beyond mimkube.
- automate system configuration
- become familiur with different deployment mechanisms
  - kubectl
  - terraform
  - helm
  - ARGOCD
- migrate docker home services
  - to kube manifest
  - to terraform resources

## cluster and kube stuff

### kubernetes

- [kube docs](https://kubernetes.io/docs/home/)
- [minikube](https://minikube.sigs.k8s.io/docs/)
  - used for local testing/dev
- [kompose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) 
  - translate docker -> kube not always helpfull
- see gradle scripts for some useful commands
- [K3S](https://docs.k3s.io/)

### terraform

- [docs](https://developer.hashicorp.com/terraform?ajs_aid=cbf6f5d7-2a05-47c6-8353-14ea3695c4c4&product_intent=terraform)
- [structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- providers
  - [helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
  - [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [k2tf](https://github.com/sl1pm4t/k2tf)
  - handy for converting kube manifest to terraform
  - not 100% but does most of the brute force work

### ansible

- used to prevision PIs
- [docs](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4)

## services

### dashboard

- [repo](https://github.com/kubernetes/dashboard/tree/master)
- [doc](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- got working via proxy with [kube manifest](https://github.com/kubernetes/dashboard/releases/tag/v3.0.0-alpha0)
- [helm](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard), better suited for terraform, not currently working
  - [awaiting responses](https://discuss.kubernetes.io/t/getting-error-trying-to-access-dashoard-helm-install/25651)
  - [possible solution](https://dev.to/garis_space/terraform-and-helm-to-deploy-the-kubernetes-dashboard-1dpl)
  - [possible solution](https://opensource.com/article/21/8/terraform-deploy-helm)

### sonarqube

- [official docs](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/deploy-on-kubernetes/deploy-sonarqube-on-kubernetes/?gads_campaign=SQ-Hroi-PMax&gads_ad_group=Global&gads_keyword=&gclid=EAIaIQobChMIj7njhtaugQMVLofCCB1hZgc_EAAYAiAAEgLCnfD_BwE)
  - some local glitches i ran into
- [medium aritcle](https://medium.com/codex/easy-deploy-sonarqube-on-kubernetes-with-yaml-configuration-27f5adc8de90)
  - got some tweaks
- [example setup](https://github.com/doctor500/sonarqube-on-kubernetes)
  - more tweaks and hackery
- [posgres setup](https://adamtheautomator.com/postgres-to-kubernetes/)
  - went with this and got it working on mimikube
  - still wip on cluster

### jenkins

- [jenkins recomended setup](https://www.jenkins.io/doc/book/installing/kubernetes/)
  - did not get working made simplified version based on kompose output and much googling
  - running on minikube
  - still wip on cluster

### ingress

- [on minkube](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
- got a working version for minikube [here](https://stackoverflow.com/questions/51751462/nginx-ingress-jenkins-path-rewrite-configuration-not-working)
- still days to go with cluster

## TODOs

- cloud-init to bridge imaging and ansible
- service running with both kube manifest and terraform
- proper host ingress on cluster
- https via [opnsense CA](https://www.ssltrust.com/help/setup-guides/use-opnsense-ca-certificate-authority)
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- deploy to [GKE](https://cloud.google.com/kubernetes-engine/)
- deploy to [EKS](https://aws.amazon.com/eks/)
  - [aws provitioning](https://stackoverflow.com/questions/75758115/persistentvolumeclaim-is-stuck-waiting-for-a-volume-to-be-created-either-by-ex)

## FAQ

- [unbounded volume](https://stackoverflow.com/questions/60774220/kubernetes-pod-has-unbound-immediate-persistentvolumeclaims)
- [pvc creation excededs timeout](https://github.com/hashicorp/terraform-provider-kubernetes/issues/1349)
