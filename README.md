# golden-retriever

Terraform-based governance system for managing contributors, teams, and repository access across **GitHub** and **Forgejo** (Codeberg), with **Figma** project tracking.

Members, repositories, Figma projects, and teams register themselves by adding JSON files to this repository. When applied, Terraform automatically syncs team memberships and repository permissions to the configured platforms. Figma projects are tracked for reference and verified via the Figma API in CI.

## How it works

1. **Contributors** add a JSON file to [`contributors/`](contributors/README.md) with their profile info.
2. **Repositories** add a JSON file to [`repos/`](repos/README.md) declaring which platforms they live on.
3. **Figma projects** add a JSON file to [`figma-projects/`](figma-projects/README.md) with their Figma team and project IDs.
4. **Teams** add a JSON file to [`teams/`](teams/README.md) listing their members, maintainers, repo slugs, and Figma project slugs.
5. Terraform reads every JSON file, builds the desired state, and reconciles it with GitHub and/or Forgejo. Figma projects are verified via the read-only Figma API.

### Permission model

Each team produces **two platform teams**:

| Platform team | Members | GitHub permission | Forgejo permission |
|---|---|---|---|
| `<slug>` | All contributors | `push` | `write` |
| `<slug>-maintainers` | Maintainers only | `maintain` | `admin` |

Platform permissions resolve to the **highest** grant, so maintainers (who appear in both teams) receive the elevated level.

> **Forgejo note:** The `svalabs/forgejo` provider does not yet support per-repo team assignments (`forgejo_team_repository`). Teams and memberships are fully managed, but repo-level access should be assigned via the Forgejo web UI or API until upstream support lands. Set `includes_all_repositories = true` in the Terraform resource if the team should access every org repo.

### Sync flags

| Flag | Default | Effect |
|------|---------|--------|
| `sync_github` | `true` | Create GitHub teams, memberships, and repo associations |
| `sync_forgejo` | `false` | Create Forgejo/Codeberg teams, memberships, and repo associations |

Set a flag to `false` to opt a team out of a specific platform entirely.

## Quick start

### 1. Register a contributor

Create `contributors/<your-username>.json`:

```json
{
  "full_name": "Jane Doe",
  "github_username": "janedoe",
  "forgejo_username": "janedoe"
}
```

### 2. Register a repository

Create `repos/<slug>.json`:

```json
{
  "name": "My Project",
  "slug": "my-project",
  "description": "A web application that does great things.",
  "github": "my-org/my-project",
  "forgejo": "my-org/my-project"
}
```

A repo can live on one or both platforms — just include the fields that apply.

### 3. Register a Figma project (optional)

Create `figma-projects/<slug>.json`:

```json
{
  "name": "My Project Designs",
  "slug": "my-project-designs",
  "figma_team_id": "123456789",
  "figma_project_id": "987654321",
  "url": "https://www.figma.com/files/team/123456789/project/987654321"
}
```

> **Note:** The Figma API is read-only for permissions. CI will verify the project exists, but access must be granted manually in Figma.

### 4. Register a team

Create `teams/<slug>.json`:

```json
{
  "name": "My Project",
  "slug": "my-project",
  "description": "A web app that does great things.",
  "maintainers": ["janedoe"],
  "contributors": ["janedoe", "bobsmith"],
  "repos": ["my-project"],
  "figma_projects": ["my-project-designs"],
  "sync_github": true,
  "sync_forgejo": false
}
```

### 5. Apply

```bash
export GITHUB_TOKEN="ghp_..."
export TF_VAR_github_owner="my-org"

# Optional: Forgejo / Codeberg
export FORGEJO_API_TOKEN="..."
export TF_VAR_forgejo_owner="my-org"

terraform init
terraform plan
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `github_owner` | GitHub org or user | `""` |
| `github_token` | GitHub PAT (or set `GITHUB_TOKEN`) | `""` |
| `forgejo_host` | Forgejo instance URL (or set `FORGEJO_HOST`) | `https://codeberg.org` |
| `forgejo_owner` | Forgejo org | `""` |
| `forgejo_api_token` | Forgejo API token (or set `FORGEJO_API_TOKEN`) | `""` |

## File structure

```
golden-retriever/
├── README.md
├── schemas/
│   ├── contributor.schema.json
│   ├── figma-project.schema.json
│   ├── repository.schema.json
│   └── team.schema.json
├── contributors/
│   ├── README.md
│   └── <username>.json
├── repos/
│   ├── README.md
│   └── <slug>.json
├── figma-projects/
│   ├── README.md
│   └── <slug>.json
├── teams/
│   ├── README.md
│   └── <slug>.json
├── versions.tf
├── variables.tf
├── providers.tf
├── locals.tf
├── github.tf
├── forgejo.tf
└── outputs.tf
```

## Providers

| Provider | Registry | Purpose |
|----------|----------|---------|
| [integrations/github](https://registry.terraform.io/providers/integrations/github/latest) | `~> 6.0` | GitHub org, team, and repo management |
| [svalabs/forgejo](https://registry.terraform.io/providers/svalabs/forgejo/latest) | `~> 1.3` | Forgejo / Codeberg org, team, and membership management |

## JSON schemas

Validate all data files against the schemas in [`schemas/`](schemas/):

```bash
# Using ajv-cli or any JSON Schema validator
npx ajv validate -s schemas/contributor.schema.json -d "contributors/*.json"
npx ajv validate -s schemas/repository.schema.json -d "repos/*.json"
npx ajv validate -s schemas/figma-project.schema.json -d "figma-projects/*.json"
npx ajv validate -s schemas/team.schema.json -d "teams/*.json"
```
