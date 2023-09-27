# kube stuff
- [kube docs](https://kubernetes.io/docs/home/)
- [minikube](https://minikube.sigs.k8s.io/docs/)
    - used for local testing/dev
- [kompose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) 
    - translate docker -> kube not always helpfull
- see gradle scripts for some useful commands

## sonarqube
- [official docs](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/deploy-on-kubernetes/deploy-sonarqube-on-kubernetes/?gads_campaign=SQ-Hroi-PMax&gads_ad_group=Global&gads_keyword=&gclid=EAIaIQobChMIj7njhtaugQMVLofCCB1hZgc_EAAYAiAAEgLCnfD_BwE)
    - some local glitches i ran into
- [medium aritcle](https://medium.com/codex/easy-deploy-sonarqube-on-kubernetes-with-yaml-configuration-27f5adc8de90)
    - got some tweaks
- [example setup](https://github.com/doctor500/sonarqube-on-kubernetes)
    - more tweaks and hackery
- [posgres setup](https://adamtheautomator.com/postgres-to-kubernetes/)
    - went with this and got it working first

## jenkins
- [jenkins recomended setup](https://www.jenkins.io/doc/book/installing/kubernetes/)
    - did not get working made simplified version based on kompose output and much googling

## ingress
- [on minkube](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
- got a working version [here]](https://stackoverflow.com/questions/51751462/nginx-ingress-jenkins-path-rewrite-configuration-not-working)

## TODO
- deploy to eks