# =============================================================================
# Forgejo / Codeberg team and membership management
#
# For each team with sync_forgejo = true, two Forgejo teams are created:
#   - <slug>              : contributors get "write" permission
#   - <slug>-maintainers  : maintainers get "admin" permission
#
# The svalabs/forgejo provider maps to the Gitea-compatible API used by
# Codeberg and self-hosted Forgejo instances.
#
# NOTE: The provider does not yet offer a forgejo_team_repository resource.
# Per-repo team assignments should be managed via the Forgejo web UI or API
# until upstream support is added. Set includes_all_repositories = true on a
# team if you want it to have access to every org repo automatically.
# =============================================================================

data "forgejo_organization" "this" {
  count = length(local.forgejo_teams) > 0 ? 1 : 0

  name = var.forgejo_owner
}

# -----------------------------------------------------------------------------
# Contributor teams
# -----------------------------------------------------------------------------

resource "forgejo_team" "contributors" {
  for_each = local.forgejo_teams

  organization_id           = data.forgejo_organization.this[0].id
  name                      = each.value.slug
  description               = lookup(each.value, "description", "")
  permission                = "write"
  units                     = ["repo.code", "repo.issues", "repo.pulls"]
  includes_all_repositories = false
}

resource "forgejo_team_member" "contributors" {
  for_each = local.forgejo_contributor_memberships

  team_id = forgejo_team.contributors[each.value.team_slug].id
  user    = each.value.forgejo_username
}

# -----------------------------------------------------------------------------
# Maintainer teams
# -----------------------------------------------------------------------------

resource "forgejo_team" "maintainers" {
  for_each = local.forgejo_teams

  organization_id           = data.forgejo_organization.this[0].id
  name                      = "${each.value.slug}-maintainers"
  description               = "Maintainers for ${each.value.name}"
  permission                = "admin"
  units                     = ["repo.code", "repo.issues", "repo.pulls", "repo.releases", "repo.wiki", "repo.projects", "repo.packages", "repo.actions"]
  includes_all_repositories = false
}

resource "forgejo_team_member" "maintainers" {
  for_each = local.forgejo_maintainer_memberships

  team_id = forgejo_team.maintainers[each.value.team_slug].id
  user    = each.value.forgejo_username
}
