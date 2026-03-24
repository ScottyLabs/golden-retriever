# golden-retriever

Terraform-based governance system for managing contributors, teams, and repository access across **GitHub** and **Forgejo** (Codeberg), with **Figma** and **Google file** tracking.

Team JSON follows the same **synchronizer model** as [ScottyLabs/governance — `__meta/synchronizer/README.md`](https://github.com/ScottyLabs/governance/blob/main/__meta/synchronizer/README.md): GitHub teams/repos, **Keycloak** OIDC clients & groups, **HashiCorp Vault** layout, **Slack** channels, and leadership rules are documented in [`docs/synchronizer-model.md`](docs/synchronizer-model.md). **Terraform** here applies **GitHub** and **Forgejo**; other platforms are **declared** in team files for a future synchronizer or separate automation.

Members, repositories, Figma projects, Google files, and teams register themselves by adding JSON files to this repository. When applied, Terraform syncs team memberships and repository permissions to the configured platforms. Figma projects are verified via the Figma API in CI where a token is configured. Google files are reference links only.

## How it works

1. **Contributors** add a JSON file to [`contributors/`](contributors/README.md) with their profile info.
2. **Repositories** add a JSON file to [`repos/`](repos/README.md) declaring which platforms they live on.
3. **Figma projects** add a JSON file to [`figma-projects/`](figma-projects/README.md) with their Figma team and project IDs.
4. **Google files** add a JSON file to [`google-files/`](google-files/README.md) with a link to the Google document.
5. **Teams** add a JSON file to [`teams/`](teams/README.md) listing members, maintainers, repos, optional Figma/Google slugs, and **synchronizer fields** (`create_oidc_clients`, `website_slug`, `secrets_population_layout`, `slack_channels`, etc.). See [`docs/synchronizer-model.md`](docs/synchronizer-model.md).
6. Terraform reads JSON under `contributors/`, `repos/`, and `teams/`, and reconciles **GitHub** and/or **Forgejo**. Other synchronizer behaviors are specified for parity with governance.

### Permission model

Each team produces **two platform teams**:

| Platform team | Members | GitHub permission | Forgejo permission |
|---|---|---|---|
| `<slug>` | All contributors | `push` | `write` |
| `<slug>-maintainers` | Maintainers only | `maintain` | `admin` |

This mirrors governance’s **main team** + **Admins** sub-team; we use the `-maintainers` suffix in GitHub. Platform permissions resolve to the **highest** grant.

> **Forgejo note:** The `svalabs/forgejo` provider does not yet support per-repo team assignments (`forgejo_team_repository`). Teams and memberships are fully managed, but repo-level access should be assigned via the Forgejo web UI or API until upstream support lands.

### Sync flags

| Flag | Default | Effect |
|------|---------|--------|
| `sync_github` | `true` | Create GitHub teams, memberships, and repo associations |
| `sync_forgejo` | `false` | Create Forgejo/Codeberg teams, memberships, and repo associations |

Set a flag to `false` to opt a team out of a specific platform entirely.

## Secrets, CI & local Vault (ScottyLabs parity)

| What | Where |
|------|--------|
| **Terraform sync** (GitHub / Forgejo) | [`.github/workflows/sync.yml`](.github/workflows/sync.yml) — secrets `SYNC_GITHUB_TOKEN`, `FORGEJO_API_TOKEN`; variables `GITHUB_OWNER`, `FORGEJO_HOST`, `FORGEJO_OWNER`. |
| **Governance synchronizer** (Keycloak, Vault, Slack, Google) | [`.github/workflows/governance-synchronizer.yml`](.github/workflows/governance-synchronizer.yml) — same secret **names** as [ScottyLabs/governance `sync.yml`](https://github.com/ScottyLabs/governance/blob/main/.github/workflows/sync.yml). Off until you set variable `ENABLE_GOVERNANCE_SYNCHRONIZER` = `true`. |
| **Full secret list & setup** | [`docs/github-actions-secrets.md`](docs/github-actions-secrets.md) · [maintainer checklist](docs/maintainer-checklist-secrets.md) |
| **Local `.env` ↔ Vault** | Git submodule [`scripts/secrets`](scripts/README.md) ([secrets-sync-scripts](https://github.com/ScottyLabs/secrets-sync-scripts)). Run `git submodule update --init --recursive` after clone. |

**Never commit** `.env` or private keys; they are [gitignored](.gitignore).

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

> **Note:** The Figma API is read-only for permissions. CI will verify the project exists when `FIGMA_TOKEN` is set.

### 4. Register a Google file (optional)

Create `google-files/<slug>.json`:

```json
{
  "name": "My Team Runbook",
  "slug": "my-team-runbook",
  "description": "Operational runbook for the team.",
  "url": "https://docs.google.com/document/d/1ABCxyz.../edit"
}
```

> **Note:** Permissions are not managed automatically in Google.

### 5. Register a team

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
  "google_files": ["my-team-runbook"],
  "create_oidc_clients": true,
  "website_slug": "my-project",
  "secrets_population_layout": "single",
  "slack_channels": ["#my-project"],
  "sync_github": true,
  "sync_forgejo": false
}
```

Optional: `ext_admins`, `applicants`, `create_oidc_clients: false`, etc. — see [`teams/README.md`](teams/README.md) and [`docs/synchronizer-model.md`](docs/synchronizer-model.md).

### 6. Apply

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
├── docs/
│   ├── synchronizer-model.md
│   ├── github-actions-secrets.md
│   └── keycloak-vault-credentials.md
├── scripts/
│   ├── README.md
│   └── secrets/          # git submodule → secrets-sync-scripts
├── synchronizer/
│   └── README.md           # optional Python sync (future)
├── schemas/
│   ├── contributor.schema.json
│   ├── figma-project.schema.json
│   ├── google-file.schema.json
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
├── google-files/
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
npx ajv validate -s schemas/contributor.schema.json -d "contributors/*.json"
npx ajv validate -s schemas/repository.schema.json -d "repos/*.json"
npx ajv validate -s schemas/figma-project.schema.json -d "figma-projects/*.json"
npx ajv validate -s schemas/google-file.schema.json -d "google-files/*.json"
npx ajv validate -s schemas/team.schema.json -d "teams/*.json"
```
