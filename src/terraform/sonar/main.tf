
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

resource "kubernetes_secret" "sonarqube_secret" {
  metadata {
    name      = "sonarqube-secret"
    namespace = "sonar"
  }

  data = {
    DATABASE_PWD  = var.SONAR_DB_PWD
    DATABASE_USER = var.SONAR_DB_USER
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_persistent_volume_claim" "postgresql" {
  metadata {
    name      = "postgresql"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "postgresql"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "4Gi"
      }
    }

    storage_class_name = "longhorn"
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_persistent_volume_claim" "postgresql_data" {
  metadata {
    name      = "postgresql-data"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "postgresql-data"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "16Gi"
      }
    }

    storage_class_name = "longhorn"
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_service" "db" {
  metadata {
    name      = "db"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "db"
    }

    annotations = {
      "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    port {
      name        = "5432"
      port        = 5432
      target_port = "5432"
    }

    selector = {
      "io.kompose.service" = "db"
    }
  }
  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_deployment" "db" {
  metadata {
    name      = "db"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "db"
    }

    annotations = {
      "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "io.kompose.service" = "db"
      }
    }

    template {
      metadata {
        labels = {
          "io.kompose.service" = "db"
        }

        annotations = {
          "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
          "kompose.version" = "1.35.0 (9532ceef3)"
        }
      }

      spec {
        volume {
          name = "postgresql"

          persistent_volume_claim {
            claim_name = "postgresql"
          }
        }

        volume {
          name = "postgresql-data"

          persistent_volume_claim {
            claim_name = "postgresql-data"
          }
        }

        init_container {
          name    = "init-lf"
          image   = "busybox"
          command = ["sh", "-c", "rm -fR /var/lib/postgresql/data/lost+found"]

          volume_mount {
            name       = "postgresql-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        container {
          name  = "postgresql"
          image = "postgres:13"

          port {
            container_port = 5432
            protocol       = "TCP"
          }

          env {
            name  = "POSTGRES_DB"
            value = "sonar"
          }

          env {
            name = "POSTGRES_PASSWORD"

            value_from {
              secret_key_ref {
                name = "sonarqube-secret"
                key  = "DATABASE_PWD"
              }
            }
          }

          env {
            name = "POSTGRES_USER"

            value_from {
              secret_key_ref {
                name = "sonarqube-secret"
                key  = "DATABASE_USER"
              }
            }
          }

          volume_mount {
            name       = "postgresql"
            mount_path = "/var/lib/postgresql"
          }

          volume_mount {
            name       = "postgresql-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        restart_policy = "Always"
        hostname       = "postgresql"
      }
    }

    strategy {
      type = "Recreate"
    }
  }

  depends_on = [
    kubernetes_namespace.sonar,
    kubernetes_service.db,
    kubernetes_persistent_volume_claim.postgresql,    
    kubernetes_persistent_volume_claim.postgresql_data
  ]
}

resource "kubernetes_persistent_volume_claim" "sonarqube_data" {
  metadata {
    name      = "sonarqube-data"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "sonarqube-data"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "8Gi"
      }
    }
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_persistent_volume_claim" "sonarqube_extensions" {
  metadata {
    name      = "sonarqube-extensions"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "sonarqube-extensions"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "4Gi"
      }
    }
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_persistent_volume_claim" "sonarqube_logs" {
  metadata {
    name      = "sonarqube-logs"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "sonarqube-logs"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "128Mi"
      }
    }
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_service" "sonarqube" {
  metadata {
    name      = "sonarqube"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "sonarqube"
    }

    annotations = {
      "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    port {
      name        = "9000"
      port        = 9000
      target_port = "9000"
    }

    selector = {
      "io.kompose.service" = "sonarqube"
    }
  }

  depends_on = [
    kubernetes_namespace.sonar
  ]
}

resource "kubernetes_deployment" "sonarqube" {
  metadata {
    name      = "sonarqube"
    namespace = "sonar"

    labels = {
      "io.kompose.service" = "sonarqube"
    }

    annotations = {
      "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
      "kompose.version" = "1.35.0 (9532ceef3)"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "io.kompose.service" = "sonarqube"
      }
    }

    template {
      metadata {
        labels = {
          "io.kompose.service" = "sonarqube"
        }

        annotations = {
          "kompose.cmd"     = "kompose convert -f /src/mnt/raid/sonarqube/docker-compose.yml"
          "kompose.version" = "1.35.0 (9532ceef3)"
        }
      }

      spec {
        volume {
          name = "sonarqube-data"

          persistent_volume_claim {
            claim_name = "sonarqube-data"
          }
        }

        volume {
          name = "sonarqube-extensions"

          persistent_volume_claim {
            claim_name = "sonarqube-extensions"
          }
        }

        volume {
          name = "sonarqube-logs"

          persistent_volume_claim {
            claim_name = "sonarqube-logs"
          }
        }

        init_container {
          name              = "init-max-map"
          image             = "busybox"
          command           = ["sysctl", "-w", "vm.max_map_count=262144"]
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = true
          }
        }

        init_container {
          name              = "init-file-max"
          image             = "busybox"
          command           = ["sysctl", "-w", "fs.file-max=131072"]
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = true
          }
        }

        init_container {
          name    = "init-perms"
          image   = "busybox"
          command = ["sh", "-c", "chown -R 1000:1000 /opt/sonarqube"]

          volume_mount {
            name       = "sonarqube-data"
            mount_path = "/opt/sonarqube/data"
          }

          volume_mount {
            name       = "sonarqube-extensions"
            mount_path = "/opt/sonarqube/extensions"
          }

          volume_mount {
            name       = "sonarqube-logs"
            mount_path = "/opt/sonarqube/logs"
          }
        }

        container {
          name  = "sonarqube"
          image = "sonarqube:lts-community"

          port {
            container_port = 9000
            protocol       = "TCP"
          }

          env {
            name  = "SONAR_JDBC_URL"
            value = "jdbc:postgresql://db:5432/sonar"
          }

          env {
            name = "SONAR_JDBC_PASSWORD"

            value_from {
              secret_key_ref {
                name = "sonarqube-secret"
                key  = "DATABASE_PWD"
              }
            }
          }

          env {
            name = "SONAR_JDBC_USERNAME"

            value_from {
              secret_key_ref {
                name = "sonarqube-secret"
                key  = "DATABASE_USER"
              }
            }
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
            name       = "sonarqube-data"
            mount_path = "/opt/sonarqube/data"
          }

          volume_mount {
            name       = "sonarqube-extensions"
            mount_path = "/opt/sonarqube/extensions"
          }

          volume_mount {
            name       = "sonarqube-logs"
            mount_path = "/opt/sonarqube/logs"
          }

          security_context {
            run_as_user  = 1000
            run_as_group = 1000
          }
        }

        restart_policy = "Always"
        hostname       = "sonarqube"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
  depends_on = [
    kubernetes_deployment.db,
    kubernetes_service.sonarqube,
    kubernetes_persistent_volume_claim.sonarqube_data,    
    kubernetes_persistent_volume_claim.sonarqube_logs,    
    kubernetes_persistent_volume_claim.sonarqube_extensions
  ]
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
      host = "sonar.kube"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "sonarqube"

              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.sonarqube
  ]
}
