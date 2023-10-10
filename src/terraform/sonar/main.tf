provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "sonar" {
  metadata {
    name = "sonar"

    labels = {
      name = "sonar"
    }
  }
}

##########################
# Posgresql 
##########################
resource "kubernetes_config_map" "postgres_config" {
  metadata {
    name      = "postgres-config"
    namespace = "sonar"

    labels = {
      app = "postgres"
    }
  }

  # TODO vault
  data = {
    POSTGRES_DB = "sonar_db"
    POSTGRES_PASSWORD = "S0N4RQUB3"
    POSTGRES_USER = "sonar_user"
  }
  depends_on = [kubernetes_namespace.sonar]
}

resource "kubernetes_persistent_volume" "postgres_pv" {
  metadata {
    name = "postgres-pv"

    labels = {
      app = "postgres"

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
        path  = "/mnt/sonar/pg"
      }
    }
  }
  depends_on = [kubernetes_namespace.sonar]
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = "sonar"

    labels = {
      app = "postgres"
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
  depends_on = [kubernetes_persistent_volume.postgres_pv]
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "sonar"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        volume {
          name = "postgredb"

          persistent_volume_claim {
            claim_name = "postgres-pv-claim"
          }
        }

        container {
          name  = "postgres"
          image = "postgres:15.4"

          port {
            container_port = 5432
          }

          env_from {
            config_map_ref {
              name = "postgres-config"
            }
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
            name       = "postgredb"
            mount_path = "/var/lib/postgresql/data"
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
  depends_on = [kubernetes_persistent_volume_claim.postgres_pvc]
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "sonar"

    labels = {
      app = "postgres"
    }
  }

  spec {
    port {
      port      = 5432
      node_port = 31032
    }

    selector = {
      app = "postgres"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.postgres]
}

##########################
# SonarQube 
##########################
resource "kubernetes_persistent_volume" "sonar_pv" {
  metadata {
    name = "sonar-pv"

    labels = {
      app = "sonar"
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
        path  = "/mnt/sonar/sq"
      }
    }
  }
  depends_on = [kubernetes_namespace.sonar]
}

resource "kubernetes_persistent_volume_claim" "sonar_pvc" {
  metadata {
    name      = "sonar-pvc"
    namespace = "sonar"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }

  wait_until_bound = false
  depends_on = [kubernetes_persistent_volume.sonar_pv]
}

resource "kubernetes_deployment" "sonar" {
  metadata {
    name      = "sonar"
    namespace = "sonar"

    labels = {
      app = "sonar"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sonar"
      }
    }

    template {
      metadata {
        labels = {
          app = "sonar"
        }
      }

      spec {
        volume {
          name = "app-pvc"

          persistent_volume_claim {
            claim_name = "sonar-pvc"
          }
        }

        init_container {
          name              = "init"
          image             = "busybox"
          command           = ["sysctl", "-w", "vm.max_map_count=262144"]
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = true
          }
        }

        container {
          name  = "sonarqube"
          image = "sonarqube:10.2-community"

          port {
            container_port = 9000
          }

          env_from {
            config_map_ref {
              name = "sonar-config"
            }
          }

          resources {
            limits = {
              cpu = "1"

              memory = "2Gi"
            }

            requests = {
              memory = "1Gi"
            }
          }

          volume_mount {
            name       = "app-pvc"
            mount_path = "/opt/sonarqube/data/"
            sub_path   = "data"
          }

          volume_mount {
            name       = "app-pvc"
            mount_path = "/opt/sonarqube/extensions/"
            sub_path   = "extensions"
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

    strategy {
      type = "Recreate"
    }
  }

  depends_on = [kubernetes_deployment.postgres]
}

resource "kubernetes_service" "sonar" {
  metadata {
    name      = "sonar"
    namespace = "sonar"

    labels = {
      app = "sonar"
    }
  }

  spec {
    port {
      name      = "sonar"
      port      = 9000
      node_port = 31900
    }

    selector = {
      app = "sonar"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.sonar]
}

resource "kubernetes_ingress_v1" "sonar_ingress" {
  metadata {
    name      = "sonar-ingress"
    namespace = "sonar"

    annotations = {
      "nginx.ingress.kubernetes.io/add-base-url" = "true"

      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "sonar.tec.net"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "sonar"

              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.sonar]
}

