# Synchronizer model

This document describes the intended synchronization behavior for maintainers.

## Scope of current implementation

`/synchronizer/sync.py` implements **Slack channel invites** and optional **Discord role grants**.

### Slack

- skips teams with `sync_slack: false` (default when omitted: sync)
- reads `teams/*.json` `slack_channels`
- builds team membership from `maintainers` + `contributors`
- reads each contributor's `slack_user_id` from `contributors/*.json`
- invites members to listed channels
  - public channels: bot attempts `conversations.join`
  - private channels: bot must already be present in the channel

### Discord

- skips teams with `sync_discord_roles: false` (default when omitted: sync)
- reads `teams/*.json` `discord_roles` (`maintainer` and/or `contributor` role IDs)
- reads each contributor's `discord_id` from `contributors/*.json`
- grants the maintainer role to every maintainer (when `discord_roles.maintainer` is set) and the contributor role to every contributor (when `discord_roles.contributor` is set); maintainers receive both when both are set
- requires `DISCORD_BOT_TOKEN` and `DISCORD_GUILD_ID` in the environment (see `docs/github-actions-secrets.md`)
- optional `DISCORD_LOG_CHANNEL_ID`: when set with a valid bot token, posts messages to that channel for failed role assignments and Discord configuration problems
- additive only: does not remove roles when someone leaves a team in JSON

## Team schema fields used by synchronizer (today)

- `teams/*.json`:
  - `maintainers`
  - `contributors`
  - `slack_channels`
  - `sync_slack` (optional; default true)
  - `discord_roles` (optional)
  - `sync_discord_roles` (optional; default true)
- `contributors/*.json`:
  - `slack_user_id`
  - `discord_id` (optional, for Discord sync)

## Planned / contract fields (future work)

These fields are documented and validated, but not yet enforced by synchronizer code:

- `create_oidc_clients`
- `website_slug`
- `ext_admins`
- `applicants`
- `secrets_population_layout`

They are reserved for future Keycloak, Vault, and related integrations.

## Operational expectations

- Channel identifiers in `slack_channels` may be channel IDs (`C...`), channel names, or `#name`.
- For private channels, invite the bot before running sync.
- Sync is additive for Slack invites and Discord roles; no remove-unlisted logic is implemented for those platforms yet.
