# variables read from env vars TF_VAR_* prefix
variable "tls_certificate" {
  description = "TLS certificate content (PEM format)"
  type        = string
  sensitive   = true
}

variable "tls_private_key" {
  description = "TLS private key content (PEM format)"
  type        = string
  sensitive   = true
}
