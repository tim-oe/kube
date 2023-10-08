provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_pod" "dnsutils" {
  metadata {
    name      = "dnsutils"
    namespace = "default"
  }

  spec {
    container {
      name    = "dnsutils"
      image   = "gcr.io/kubernetes-e2e-test-images/dnsutils:1.3"
      command = ["sleep", "3600"]

      resources {
        limits = {
          cpu = "1"

          memory = "256Mi"
        }

        requests = {
          cpu = "1"

          memory = "128Mi"
        }
      }

      image_pull_policy = "IfNotPresent"
    }

    restart_policy = "Always"
  }
}

