provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
}

resource "helm_release" "kubernetes_dashboard" {
  name              = "kubernetes-dashboard-svc"
  repository        = "https://kubernetes.github.io/dashboard/"
  chart             = "kubernetes-dashboard"
  create_namespace  = true
  namespace         = "kubernetes-dashboard"
}

resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}

resource "kubernetes_secret" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"

    annotations = {
      "kubernetes.io/service-account.name" = "admin-user"
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
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
}