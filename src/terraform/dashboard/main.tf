provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
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

  depends_on = [kubernetes_namespace.kubernetes_dashboard]
}

resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

resource "kubernetes_cluster_role_binding" "admin_user_binding" {
  metadata {
    name = "admin_user_binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  depends_on = [kubernetes_service_account.admin_user]
}

resource "kubernetes_secret" "admin-user-token" {
  
  metadata {
    name = "admin-user-token"
    namespace = "kubernetes-dashboard"

    annotations = {
      "kubernetes.io/service-account.name" = "admin-user"
    }
  }

  type = "kubernetes.io/service-account-token"
  depends_on = [kubernetes_service_account.admin_user]
}