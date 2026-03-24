# GitHub Actions secrets and variables

This document is for any future maintainer configuring CI credentials.

## Workflows in this repository

- `/.github/workflows/sync.yml` — Terraform sync for GitHub/Forgejo
- `/.github/workflows/governance-synchronizer.yml` — Python synchronizer (currently Slack; extendable)

## 1) Terraform sync (`sync.yml`)

### Repository variables

Configure in GitHub: **Settings → Secrets and variables → Actions → Variables**

- `GH_OWNER`: GitHub org/user owner for Terraform
- `FORGEJO_HOST`: Forgejo base URL (for example `https://codeberg.org`)
- `FORGEJO_OWNER`: Forgejo org/user owner

### Repository secrets

Configure in GitHub: **Settings → Secrets and variables → Actions → Secrets**

- `SYNC_GITHUB_TOKEN`
- `FORGEJO_API_TOKEN` (optional if Forgejo sync is not used)

## 2) Governance synchronizer (`governance-synchronizer.yml`)

### Repository variable

- `ENABLE_GOVERNANCE_SYNCHRONIZER=true`

### Repository secrets (governance-compatible names)

- `SYNC_GITHUB_TOKEN`
- `KEYCLOAK_SERVER_URL`
- `KEYCLOAK_USERNAME`
- `KEYCLOAK_PASSWORD`
- `KEYCLOAK_REALM`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_USER_REALM`
- `VAULT_TOKEN`
- `SLACK_TOKEN`
- `GOOGLE_CLIENT_EMAIL`
- `GOOGLE_PRIVATE_KEY`
- `SCOTTYLABS_GOOGLE_DRIVE_ID`

## Slack token requirements

For channel invites, configure `SLACK_TOKEN` with at least:

- `conversations:read`
- `conversations:write`
- `users:read`

Add `users:read.email` only if matching users by email is introduced.

## Notes for maintainers

- Prefer organization-level secrets when multiple repos share the same automation.
- Rotate secrets periodically.
- Never commit secrets into git; keep local `.env*` files ignored.
