# kube stuff
- (kube docs)[https://kubernetes.io/docs/home/]
- used (minikube)[https://minikube.sigs.k8s.io/docs/]
- (kompose)[https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/] to go from docker -> kube

## sonarqube
- (gleened some from medium aritcle)[https://medium.com/codex/easy-deploy-sonarqube-on-kubernetes-with-yaml-configuration-27f5adc8de90]
- (example setup)[https://github.com/doctor500/sonarqube-on-kubernetes]
- (posgres setup)[]

## jenkins
- (jenkins recomended setup)[https://www.jenkins.io/doc/book/installing/kubernetes/]
- ^^^ did not get working made simplified version based on kompose files and pg impl

## ingress
- [on minkube](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
- this still relies on minikube IP

## TODO
- ingress for external access
- deploy to eks