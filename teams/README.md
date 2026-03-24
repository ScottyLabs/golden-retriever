# Adding a team

> **Note:** This is for tech leads and team members seeking to register their team under governance.

Team files mirror the **[ScottyLabs governance synchronizer](https://github.com/ScottyLabs/governance/blob/main/__meta/synchronizer/README.md)** model (JSON / snake_case here). See **[Synchronizer model (full behavior)](../docs/synchronizer-model.md)** for GitHub, Keycloak, HashiCorp Vault, Slack, and leadership semantics.

**Terraform** in this repo applies **GitHub** and **Forgejo** only today. Fields like `create_oidc_clients`, `slack_channels`, and `secrets_population_layout` are for a **future synchronizer** or other automation aligned with that README.

Create a new JSON file in `teams/` with the team slug as the filename, e.g. `my-project.json`:

```json
{
  "name": "My Project",
  "slug": "my-project",
  "description": "A brief description of what the project does.",
  "maintainers": [
    "alice"
  ],
  "contributors": [
    "alice",
    "bob"
  ],
  "repos": [
    "my-project",
    "my-project-docs"
  ],
  "figma_projects": [
    "my-project-designs"
  ],
  "google_files": [
    "my-project-runbook"
  ],
  "create_oidc_clients": true,
  "website_slug": "my-project",
  "ext_admins": [],
  "applicants": [],
  "secrets_population_layout": "single",
  "slack_channels": ["#my-project"],
  "sync_github": true,
  "sync_forgejo": false,
  "remove_unlisted": true
}
```

## Field reference

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | yes | — | Human-readable team name. |
| `slug` | string | yes | — | URL-safe identifier; must match the filename. |
| `description` | string | no | `""` | Brief description of the team or project. |
| `maintainers` | string[] | yes | — | Contributor filenames (without `.json`). At least one required. Maintainers receive elevated repo permissions and can manage team membership. |
| `contributors` | string[] | yes | — | Contributor filenames (without `.json`). All maintainers should also be listed here. |
| `repos` | string[] | no | `[]` | Repository filenames (without `.json`) from [`repos/`](../repos/README.md). Platform details are defined in each repo file. |
| `figma_projects` | string[] | no | `[]` | Figma project filenames (without `.json`) from [`figma-projects/`](../figma-projects/README.md). |
| `google_files` | string[] | no | `[]` | Google file slugs (without `.json`) from [`google-files/`](../google-files/README.md). |
| `create_oidc_clients` | boolean | no | `true`¹ | When true, synchronizer creates Keycloak OIDC clients (`<slug>-local`, `-dev`, `-staging`, `-prod`). Set `false` to opt out. |
| `website_slug` | string | no | — | Used in default OIDC redirect URIs (`api.<website_slug>.…`). Set when using OIDC clients. |
| `ext_admins` | string[] | no | — | Contributor slugs for external-admins Keycloak/Vault group. |
| `applicants` | string[] | no | — | Contributor slugs for applicants group / Vault `applicants` path. |
| `secrets_population_layout` | string | no | — | One of `none`, `single`, `multi` — HashiCorp Vault secrets tree. See synchronizer model doc. |
| `slack_channels` | string[] | no | `[]` | Slack channels for synchronizer member invites. |
| `sync_github` | boolean | no | `true` | Automatically sync membership and repo access to GitHub (Terraform). |
| `sync_forgejo` | boolean | no | `false` | Automatically sync membership and repo access to Forgejo/Codeberg (Terraform). |
| `remove_unlisted` | boolean | no | `true` | Remove members not listed in this file from the platform team. Set `false` during migration. |

¹ *Omitted field:* synchronizer treats as `true` per [governance README](https://github.com/ScottyLabs/governance/blob/main/__meta/synchronizer/README.md); JSON Schema does not insert defaults—omit only if you intend the synchronizer default.

See the [team schema](../schemas/team.schema.json) for full validation rules.
