# variables read from env vars TF_VAR_* prefix
# kubectl get secret -n kubernetes-dashboard dashboard-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d
# kubectl get secret -n kubernetes-dashboard dashboard-tls-secret -o jsonpath='{.data.tls\.key}' | base64 -d
variable "TLS_CERTIFICATE" {
  description = "TLS certificate content (PEM format)"
  type        = string
  sensitive   = true
}

variable "TLS_PRIVATE_KEY" {
  description = "TLS private key content (PEM format)"
  type        = string
  sensitive   = true
}
