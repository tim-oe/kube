provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"

    labels = {
      name = "jenkins"
    }
  }
}

resource "kubernetes_persistent_volume" "jenkins_pv" {
  metadata {
    name = "jenkins-pv"

    labels = {
      namespace = "jenkins"
      type = "local"
    }
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      host_path  {
        path  = "/mnt/data"
      }
    }
  }
  depends_on = [kubernetes_namespace.jenkins]
}

resource "kubernetes_persistent_volume_claim" "jenkins_home" {
  metadata {
    name      = "jenkins-home"
    namespace = "jenkins"

    labels = {
      app = "jenkins"
    }
  }

  spec {
    access_modes = ["ReadWriteMany"]
    
    resources {
      requests = {
        storage = "2Gi"
      }
    }

    storage_class_name = "standard"
  }

  wait_until_bound = false
  depends_on = [kubernetes_persistent_volume.jenkins_pv]
}

resource "kubernetes_deployment" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jenkins"
      }
    }

    template {
      metadata {
        labels = {
          app = "jenkins"
        }
      }

      spec {
        volume {
          name = "jenkins-pv"

          persistent_volume_claim {
            claim_name = "jenkins-home"
          }
        }

        container {
          name  = "jenkins"
          image = "jenkins/jenkins:lts-jdk17"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu = "1"

              memory = "2Gi"
            }

            requests = {
              cpu = "1"

              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "var/jenkins_home"
          }

          image_pull_policy = "IfNotPresent"
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/arch"
                  operator = "In"
                  values   = ["amd64", "arm64"]
                }
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_persistent_volume_claim.jenkins_home]
}

resource "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }

  spec {
    port {
      name        = "8080"
      port        = 8080
      target_port = "8080"
      node_port   = 31080
    }

    port {
      name        = "50000"
      port        = 50000
      target_port = "50000"
    }

    selector = {
      app = "jenkins"
    }

    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.jenkins]
}

resource "kubernetes_ingress_v1" "jenkins_ingress" {
  metadata {
    name      = "jenkins-ingress"
    namespace = "jenkins"

    annotations = {
      "nginx.ingress.kubernetes.io/add-base-url" = "true"

      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "jenkins.tec.net"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "jenkins"

              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.jenkins]
}