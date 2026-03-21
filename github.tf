# =============================================================================
# GitHub team and membership management
#
# For each team with sync_github = true, two GitHub teams are created:
#   - <slug>              : contributors get "push" access to repos
#   - <slug>-maintainers  : maintainers get "maintain" access to repos
# =============================================================================

# -----------------------------------------------------------------------------
# Contributor teams
# -----------------------------------------------------------------------------

resource "github_team" "contributors" {
  for_each = local.github_teams

  name        = each.value.slug
  description = lookup(each.value, "description", "")
  privacy     = "closed"
}

resource "github_team_membership" "contributors" {
  for_each = local.github_contributor_memberships

  team_id  = github_team.contributors[each.value.team_slug].id
  username = each.value.github_username
  role     = "member"
}

resource "github_team_repository" "contributors" {
  for_each = local.github_contributor_repos

  team_id    = github_team.contributors[each.value.team_slug].id
  repository = each.value.repository
  permission = "push"
}

# -----------------------------------------------------------------------------
# Maintainer teams
# -----------------------------------------------------------------------------

resource "github_team" "maintainers" {
  for_each = local.github_teams

  name        = "${each.value.slug}-maintainers"
  description = "Maintainers for ${each.value.name}"
  privacy     = "closed"
}

resource "github_team_membership" "maintainers" {
  for_each = local.github_maintainer_memberships

  team_id  = github_team.maintainers[each.value.team_slug].id
  username = each.value.github_username
  role     = "maintainer"
}

resource "github_team_repository" "maintainers" {
  for_each = local.github_maintainer_repos

  team_id    = github_team.maintainers[each.value.team_slug].id
  repository = each.value.repository
  permission = "maintain"
}
