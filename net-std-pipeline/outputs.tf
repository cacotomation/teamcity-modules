output "pull_request_configuration_id" {
  value = "${teamcity_build_config.pullrequest.id}"
}

output "build_release_configuration_id" {
  value = "${teamcity_build_config.buildrelease.id}"
}

output "project_id" {
  value = "${teamcity_project.project.id}"
}
