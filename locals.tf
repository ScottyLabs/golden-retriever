locals {
  # ---------------------------------------------------------------------------
  # Load contributor JSON files
  # ---------------------------------------------------------------------------
  contributor_files = fileset("${path.module}/contributors", "*.json")

  contributors = {
    for f in local.contributor_files :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/contributors/${f}"))
  }

  # ---------------------------------------------------------------------------
  # Load repository JSON files
  # ---------------------------------------------------------------------------
  repo_files = fileset("${path.module}/repos", "*.json")

  repositories = {
    for f in local.repo_files :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/repos/${f}"))
  }

  # ---------------------------------------------------------------------------
  # Load Figma project JSON files
  # ---------------------------------------------------------------------------
  figma_project_files = fileset("${path.module}/figma-projects", "*.json")

  figma_projects = {
    for f in local.figma_project_files :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/figma-projects/${f}"))
  }

  # ---------------------------------------------------------------------------
  # Load team JSON files
  # ---------------------------------------------------------------------------
  team_files = fileset("${path.module}/teams", "*.json")

  teams = {
    for f in local.team_files :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/teams/${f}"))
  }

  # ---------------------------------------------------------------------------
  # GitHub-synced teams
  # ---------------------------------------------------------------------------
  github_teams = {
    for slug, team in local.teams :
    slug => team
    if lookup(team, "sync_github", true)
  }

  github_contributor_memberships = merge([
    for slug, team in local.github_teams : {
      for username in lookup(team, "contributors", []) :
      "${slug}/${username}" => {
        team_slug       = slug
        github_username = lookup(lookup(local.contributors, username, {}), "github_username", username)
      }
    }
  ]...)

  github_maintainer_memberships = merge([
    for slug, team in local.github_teams : {
      for username in lookup(team, "maintainers", []) :
      "${slug}/${username}" => {
        team_slug       = slug
        github_username = lookup(lookup(local.contributors, username, {}), "github_username", username)
      }
    }
  ]...)

  # Resolve team repo slugs → GitHub owner/repo, keeping only repos that have
  # a "github" field in their repository file.
  github_contributor_repos = merge([
    for slug, team in local.github_teams : {
      for repo_slug in lookup(team, "repos", []) :
      "${slug}/${repo_slug}" => {
        team_slug  = slug
        repository = element(split("/", local.repositories[repo_slug].github), 1)
      }
      if lookup(local.repositories[repo_slug], "github", null) != null
    }
  ]...)

  github_maintainer_repos = merge([
    for slug, team in local.github_teams : {
      for repo_slug in lookup(team, "repos", []) :
      "${slug}/${repo_slug}" => {
        team_slug  = slug
        repository = element(split("/", local.repositories[repo_slug].github), 1)
      }
      if lookup(local.repositories[repo_slug], "github", null) != null
    }
  ]...)

  # ---------------------------------------------------------------------------
  # Forgejo-synced teams
  # ---------------------------------------------------------------------------
  forgejo_teams = {
    for slug, team in local.teams :
    slug => team
    if lookup(team, "sync_forgejo", false)
  }

  forgejo_contributor_memberships = merge([
    for slug, team in local.forgejo_teams : {
      for username in lookup(team, "contributors", []) :
      "${slug}/${username}" => {
        team_slug        = slug
        forgejo_username = lookup(lookup(local.contributors, username, {}), "forgejo_username", username)
      }
    }
  ]...)

  forgejo_maintainer_memberships = merge([
    for slug, team in local.forgejo_teams : {
      for username in lookup(team, "maintainers", []) :
      "${slug}/${username}" => {
        team_slug        = slug
        forgejo_username = lookup(lookup(local.contributors, username, {}), "forgejo_username", username)
      }
    }
  ]...)

  # NOTE: forgejo_team_repository is not yet available in the svalabs/forgejo
  # provider. Repo slugs with a "forgejo" field are preserved so that
  # team-repo linking can be added when upstream support lands.
}
