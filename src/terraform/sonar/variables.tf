# variables read from env vars TF_VAR_* prefix
# https://developer.hashicorp.com/terraform/cli/config/environment-variables
# kubectl get secret -n sonar sonarqube-secret -o jsonpath='{.data.DATABASE_PWD}' | base64 -d
# kubectl get secret -n sonar sonarqube-secret -o jsonpath='{.data.DATABASE_USER}' | base64 -d
variable "SONAR_DB_USER" {
  description = "sonar pg db user name"
  type        = string
  sensitive   = true
}

variable "SONAR_DB_PWD" {
  description = "sonar pg db user password"
  type        = string
  sensitive   = true
}
