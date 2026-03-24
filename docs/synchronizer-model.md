# Synchronizer model

This document describes the intended synchronization behavior for maintainers.

## Scope of current implementation

`/synchronizer/sync.py` currently implements **Slack channel invites** only.

Behavior:

- reads `teams/*.json` `slack_channels`
- builds team membership from `maintainers` + `contributors`
- reads each contributor's `slack_user_id` from `contributors/*.json`
- invites members to listed channels
  - public channels: bot attempts `conversations.join`
  - private channels: bot must already be present in the channel

## Team schema fields used by synchronizer (today)

- `teams/*.json`:
  - `maintainers`
  - `contributors`
  - `slack_channels`
- `contributors/*.json`:
  - `slack_user_id`

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
- Sync is additive for Slack invites; no remove-unlisted logic is implemented yet.
