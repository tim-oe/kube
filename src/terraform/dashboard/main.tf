provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Local variables to handle certificate formatting
# value is base64 encoded 
# need to get value back to what's in the file
locals {
  # variable value portable with kube and TF
  formatted_cert = base64decode(var.TLS_CERTIFICATE)
  formatted_key = base64decode(var.TLS_PRIVATE_KEY)
  
  # Trim any extra whitespace
  clean_cert = trimspace(local.formatted_cert)
  clean_key  = trimspace(local.formatted_key)
}

resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"

    labels = {
      name = "kubernetes-dashboard"
    }
  }
}

resource "helm_release" "kubernetes_dashboard" {
  name             = "kubernetes-dashboard"
  repository       = "https://kubernetes.github.io/dashboard/"
  chart            = "kubernetes-dashboard"
  namespace        = "kubernetes-dashboard"
  create_namespace = true
  version          = "7.10.0"  # Specify the version you want to use

  values = [
    yamlencode({

      # RBAC configuration
      rbac = {
        create = true
        clusterRoleBinding = {
          create = true
        }
      }

      # Security settings
      securityContext = {
        runAsUser    = 1001
        runAsGroup   = 2001
        fsGroup      = 3001
      }

      # Resource limits
      resources = {
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }

      # Metrics configuration
      metricsScraper = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.kubernetes_dashboard
  ]
}

# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
resource "kubernetes_service_account" "dashboard_admin" {
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"
  }

  depends_on = [
    kubernetes_namespace.kubernetes_dashboard
  ]
}

resource "kubernetes_secret" "admin_user" {
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"

    annotations = {
      "kubernetes.io/service-account.name" = "dashboard-admin"
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [
    kubernetes_namespace.kubernetes_dashboard
  ]
}


resource "kubernetes_cluster_role_binding" "dashboard_admin" {
  metadata {
    name = "dashboard-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dashboard_admin.metadata[0].name
    namespace = "kubernetes-dashboard"
  }

  depends_on = [
    kubernetes_namespace.kubernetes_dashboard,
    kubernetes_service_account.dashboard_admin
  ]
}


resource "kubernetes_ingress_v1" "kubernetes_dashboard_ingress" {
  metadata {
    name      = "kubernetes-dashboard-ingress"
    namespace = "kubernetes-dashboard"

    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol"    = "HTTPS"
      "nginx.ingress.kubernetes.io/proxy-ssl-protocols" = "TLSv1.2 TLSv1.3"
      "nginx.ingress.kubernetes.io/proxy-ssl-verify"    = "false"
      "nginx.ingress.kubernetes.io/ssl-redirect"        = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["dashboard.kube"]
      secret_name = "dashboard-tls"
    }

    rule {
      host = "dashboard.kube"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kubernetes-dashboard-kong-proxy"

              port {
                number = 8443
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.kubernetes_dashboard]
}

resource "kubernetes_secret" "dashboard_tls" {
  metadata {
    name      = "dashboard-tls"
    namespace = "kubernetes-dashboard"
  }

  data = {
    "tls.crt" = local.clean_cert
    "tls.key"  = local.clean_key
  }

  type = "kubernetes.io/tls"

  depends_on = [
    kubernetes_ingress_v1.kubernetes_dashboard_ingress
  ]
}