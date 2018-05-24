resource "teamcity_project" "project" {
  name = "${var.project_name}"
}

resource "teamcity_vcs_root_git" "vcs_root" {
  name       = "Application"
  project_id = "${teamcity_project.project.id}"

  repo_url       = "${var.github_repository_url}"
  default_branch = "refs/head/master"
}

resource "teamcity_build_config" "pullrequest" {
  project_id  = "${teamcity_project.project.id}"
  name        = "Pull Request"
  description = "Inspection build"

  vcs_root {
    id             = "${teamcity_vcs_root_git.vcs_root.id}"
    checkout_rules = ["+:*"]
  }

  step {
    type = "powershell"
    file = "build.ps1"
    args = "-Target pullrequest"
  }
}

resource "teamcity_trigger" "pullrequest_vcs_trigger" {
  build_config_id = "${teamcity_build_config.pullrequest.id}"
  rules           = "+:*"
  branch_filter   = "+:pull/*"
}

resource "teamcity_build_config" "buildrelease" {
  project_id  = "${teamcity_project.project.id}"
  name        = "Build Release"
  description = "Build Release"

  vcs_root {
    id             = "${teamcity_vcs_root_git.vcs_root.id}"
    checkout_rules = ["+:*"]
  }

  step {
    type = "powershell"
    file = "build.ps1"
    args = "-Target buildrelease"
  }

  env_params {
    OCTOPUS_APIKEY = "${var.octopus_apikey}"
    OCTOPUS_SERVER = "${var.octopus_server}"
  }
}

resource "teamcity_build_config" "release_testing" {
  project_id  = "${teamcity_project.project.id}"
  name        = "Release To Testing"
  description = "Deploys and validates a release to Testing Environment"

  vcs_root {
    id             = "${teamcity_vcs_root_git.vcs_root.id}"
    checkout_rules = ["+:*"]
  }

  step {
    type = "powershell"
    file = "build.ps1"
    args = "-Target release"
  }

  env_params {
    OCTOPUS_APIKEY      = "${var.octopus_apikey}"
    OCTOPUS_SERVER      = "${var.octopus_server}"
    RELEASE_VERSION     = "%dep.${teamcity_build_config.buildrelease.id}.env.RELEASE_VERSION%"
    RELEASE_ENVIRONMENT = "Testing"
  }
}

resource "teamcity_build_config" "release_acceptance" {
  project_id  = "${teamcity_project.project.id}"
  name        = "Release To Acceptance"
  description = "Deploys and validates a release to Acceptance Environment"

  vcs_root {
    id             = "${teamcity_vcs_root_git.vcs_root.id}"
    checkout_rules = ["+:*"]
  }

  step {
    type = "powershell"
    file = "build.ps1"
    args = "-Target release"
  }

  env_params {
    OCTOPUS_APIKEY      = "${var.octopus_apikey}"
    OCTOPUS_SERVER      = "${var.octopus_server}"
    RELEASE_VERSION     = "%dep.${teamcity_build_config.buildrelease.id}.env.RELEASE_VERSION%"
    RELEASE_ENVIRONMENT = "Acceptance"
  }
}

resource "teamcity_build_config" "release_production" {
  project_id  = "${teamcity_project.project.id}"
  name        = "Release To Production"
  description = "Deploys and validates a release to Production Environment"

  vcs_root {
    id             = "${teamcity_vcs_root_git.vcs_root.id}"
    checkout_rules = ["+:*"]
  }

  step {
    type = "powershell"
    file = "build.ps1"
    args = "-Target release"
  }

  env_params {
    OCTOPUS_APIKEY      = "${var.octopus_apikey}"
    OCTOPUS_SERVER      = "${var.octopus_server}"
    RELEASE_VERSION     = "%dep.${teamcity_build_config.buildrelease.id}.env.RELEASE_VERSION%"
    RELEASE_ENVIRONMENT = "PRoduction"
  }
}

resource "teamcity_snapshot_dependency" "testing_chain" {
  count                  = "${var.auto-deploy-testing}"
  source_build_config_id = "${teamcity_build_config.buildrelease.id}"
  build_config_id        = "${teamcity_build_config.release_testing.id}"
}

resource "teamcity_snapshot_dependency" "acceptance_chain" {
  count                  = "${var.auto-deploy-acceptance}"
  source_build_config_id = "${teamcity_build_config.release_testing.id}"
  build_config_id        = "${teamcity_build_config.release_acceptance.id}"
}

resource "teamcity_snapshot_dependency" "production_chain" {
  count                  = "${var.auto-deploy-production}"
  source_build_config_id = "${teamcity_build_config.release_acceptance.id}"
  build_config_id        = "${teamcity_build_config.release_production.id}"
}

resource "teamcity_trigger" "buildrelease_vcs_trigger" {
  build_config_id = "${teamcity_build_config.buildrelease.id}"
  rules           = "+:*"
  branch_filter   = "+:pull/*"
}

resource "teamcity_agent_requirement" "aws_agent_requirement" {
  // Count cannot be computed :(
  count           = 4
  build_config_id = "${element(list(teamcity_build_config.pullrequest.id, teamcity_build_config.buildrelease.id, teamcity_build_config.release_testing.id, teamcity_build_config.release_acceptance.id, teamcity_build_config.release_production.id), count.index)}"

  condition = "equals"
  name      = "teamcity.agent.datacenter"
  value     = "aws"
}
