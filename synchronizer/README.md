# Governance synchronizer

This directory contains synchronization code for systems outside Terraform-managed GitHub/Forgejo resources.

## Current implementation

`sync.py` provides Slack channel membership sync and optional Discord role sync.

### Slack

- reads `teams/*.json` `sync_slack` (default true; set `false` to opt out)
- reads `teams/*.json` `slack_channels`
- resolves members from `maintainers` + `contributors`
- uses `contributors/*.json` `slack_user_id`
- invites users to channels (public and private)

Channel handling:

- public channels: bot attempts `conversations.join`
- private channels: bot must already be in the channel

### Discord

- reads `teams/*.json` `sync_discord_roles` (default true; set `false` to opt out)
- reads `teams/*.json` `discord_roles` (`maintainer` / `contributor` role snowflakes)
- uses `contributors/*.json` `discord_id`
- grants roles via Discord REST (members must already be in the guild)

## Local run

```bash
cd synchronizer
uv sync
SLACK_TOKEN=xoxb-... uv run sync
```

With Discord:

```bash
DISCORD_BOT_TOKEN=... DISCORD_GUILD_ID=... uv run sync
```

Optional: send Discord-side failures to a text channel (bot needs Send Messages there):

```bash
DISCORD_LOG_CHANNEL_ID=1234567890123456789 DISCORD_BOT_TOKEN=... DISCORD_GUILD_ID=... uv run sync
```

## Extend in the future

Add additional modules for Keycloak, Vault, Google, etc., and invoke them from `sync.py` while keeping idempotent behavior.
