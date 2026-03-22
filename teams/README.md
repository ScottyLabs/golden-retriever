# Adding a team

> **Note:** This is for tech leads and team members seeking to register their team under governance.

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
| `sync_github` | boolean | no | `true` | Automatically sync membership and repo access to GitHub. |
| `sync_forgejo` | boolean | no | `false` | Automatically sync membership and repo access to Forgejo/Codeberg. |
| `remove_unlisted` | boolean | no | `true` | Remove members not listed in this file from the platform team. Set `false` during migration. |

See the [team schema](../schemas/team.schema.json) for full validation rules.
