# Governance synchronizer

This directory contains synchronization code for systems outside Terraform-managed GitHub/Forgejo resources.

## Current implementation

`sync.py` currently provides Slack channel membership sync.

What it does:

- reads `teams/*.json` `slack_channels`
- resolves members from `maintainers` + `contributors`
- uses `contributors/*.json` `slack_user_id`
- invites users to channels (public and private)

Channel handling:

- public channels: bot attempts `conversations.join`
- private channels: bot must already be in the channel

## Local run

```bash
cd synchronizer
uv sync
SLACK_TOKEN=xoxb-... uv run sync
```

## Extend in the future

Add additional modules for Keycloak, Vault, Google, etc., and invoke them from `sync.py` while keeping idempotent behavior.
