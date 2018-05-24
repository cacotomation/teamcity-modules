variable "project_name" {}

variable "github_repository_url" {}

variable "auto-deploy-testing" {
  type    = "bool"
  default = true
}

variable "auto-deploy-acceptance" {
  type    = "bool"
  default = true
}

variable "auto-deploy-production" {
  type    = "bool"
  default = false
}

variable "octopus_apikey" {
  type = "string"
}

variable "octopus_server" {
  type = "string"
}
