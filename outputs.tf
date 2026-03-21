output "github_teams" {
  description = "GitHub teams created by this configuration."
  value = {
    for slug, team in github_team.contributors :
    slug => {
      contributor_team_id = team.id
      maintainer_team_id  = github_team.maintainers[slug].id
    }
  }
}

output "forgejo_teams" {
  description = "Forgejo teams created by this configuration."
  value = {
    for slug, team in forgejo_team.contributors :
    slug => {
      contributor_team_id = team.id
      maintainer_team_id  = forgejo_team.maintainers[slug].id
    }
  }
}

output "contributor_count" {
  description = "Total number of registered contributors."
  value       = length(local.contributors)
}

output "team_count" {
  description = "Total number of registered teams."
  value       = length(local.teams)
}
