# GitHub Actions secrets and variables

This document is for any future maintainer configuring CI credentials.

## Workflows in this repository

- `/.github/workflows/sync.yml` — Terraform sync for GitHub/Forgejo
- `/.github/workflows/governance-synchronizer.yml` — Python synchronizer (Slack channel invites, optional Discord roles)

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
- `DISCORD_BOT_TOKEN` (optional — omit to skip Discord role sync)
- `DISCORD_GUILD_ID` (optional — your Discord server snowflake ID; omit with `DISCORD_BOT_TOKEN` to skip Discord)
- `GOOGLE_CLIENT_EMAIL`
- `GOOGLE_PRIVATE_KEY`
- `SCOTTYLABS_GOOGLE_DRIVE_ID`

## Slack token requirements

For channel invites, configure `SLACK_TOKEN` with at least:

- `conversations:read`
- `conversations:write`
- `users:read`

Add `users:read.email` only if matching users by email is introduced.

## Discord bot requirements

For `teams/*.json` `discord_roles` and `contributors/*.json` `discord_id`, configure both:

- `DISCORD_BOT_TOKEN` — a **bot** token from the [Discord Developer Portal](https://discord.com/developers/applications) (Bot → Reset Token). The bot account must be **in your server**.
- `DISCORD_GUILD_ID` — the server ID (Developer Mode on, right-click the server → Copy Server ID). It is not highly sensitive, but this workflow reads it from **Actions secrets** like the other synchronizer values; you may switch the workflow to a repository **variable** if you prefer.

Enable the bot’s **Server Members Intent** only if you add features that need member list events; role assignment via REST uses `PUT /guilds/.../members/.../roles/...` and does not require that intent.

OAuth2 scopes are irrelevant for a plain bot token. In **Server Settings → Integrations → Bots → your bot**, ensure the bot has **Manage Roles**. In **Server Settings → Roles**, drag the bot’s role **above** every Discord role it should assign (otherwise the API returns 403).

Members must **already be in the Discord server** before the synchronizer can attach roles (otherwise the API returns 404).

### Discord log channel (optional)

Set repository **variable** `DISCORD_LOG_CHANNEL_ID` to a text channel’s numeric ID (Developer Mode → right-click channel → Copy Channel ID). The governance synchronizer workflow passes it as `DISCORD_LOG_CHANNEL_ID`. When set **and** `DISCORD_BOT_TOKEN` is set, the bot posts there when:

- a Discord **role assignment succeeds** (each successful grant), or
- a Discord **role assignment** fails (user not in server, missing permissions, HTTP errors, etc.), or
- Discord sync is **skipped** because only one of `DISCORD_BOT_TOKEN` / `DISCORD_GUILD_ID` is configured.

The bot needs **View Channel** and **Send Messages** (and **Embed Links** if you rely on formatting) in that channel. If posting fails, the workflow log prints a warning.

To use a **secret** instead of a variable, change the workflow line to `${{ secrets.DISCORD_LOG_CHANNEL_ID }}`.

## Notes for maintainers

- Prefer organization-level secrets when multiple repos share the same automation.
- Rotate secrets periodically.
- Never commit secrets into git; keep local `.env*` files ignored.
