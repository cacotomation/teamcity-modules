variable "project_name" {}

variable "github_repository_url" {}

variable "auto-deploy-testing" {
  default = true
}

variable "auto-deploy-acceptance" {
  default = true
}

variable "auto-deploy-production" {
  default = false
}

variable "octopus_apikey" {
  type = "string"
}

variable "octopus_server" {
  type = "string"
}
