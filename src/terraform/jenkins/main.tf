provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"

    labels = {
      "io.kompose.service" = "jenkins"
    }

    annotations = {
      "kompose.cmd"     = "kompose --file ../../../../home_server/src/mnt/raid/jenkins/docker-compose.yml convert"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "io.kompose.service" = "jenkins"
      }
    }

    template {
      metadata {
        labels = {
          "io.kompose.service" = "jenkins"
        }
      }

      spec {
        volume {
          name = "jenkins-home"

          persistent_volume_claim {
            claim_name = "jenkins-home"
          }
        }

        container {
          name  = "jenkins"
          image = "jenkins/jenkins:latest-jdk17"

          port {
            name           = "web-ui"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "agent"
            container_port = 50000
            protocol       = "TCP"
          }

          env {
            name  = "JENKINS_OPTS"
            value = "--httpPort=8080"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "4Gi"
            }

            requests = {
              cpu    = "250m"
              memory = "2Gi"
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          security_context {
            privileged = true
          }
        }

        restart_policy = "Always"
        hostname       = "jenkins"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "jenkins_home" {
  metadata {
    name      = "jenkins-home"
    namespace = "jenkins"

    labels = {
      "io.kompose.service" = "jenkins-home"
    }
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "16Gi"
      }
    }

    storage_class_name = "nfs"
  }
}

resource "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"

    labels = {
      "io.kompose.service" = "jenkins"
    }

    annotations = {
      "kompose.cmd"     = "kompose --file ../../../../home_server/src/mnt/raid/jenkins/docker-compose.yml convert"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    port {
      name        = "web-ui"
      port        = 8080
      target_port = "8080"
    }

    port {
      name        = "agent"
      port        = 50000
      target_port = "50000"
    }

    selector = {
      "io.kompose.service" = "jenkins"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"

    labels = {
      name = "jenkins"
    }
  }
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
      host = "jenkins.kube"

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
}

