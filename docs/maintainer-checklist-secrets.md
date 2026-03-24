# Maintainer checklist (secrets and sync)

Use this checklist when onboarding a new maintainer or setting up a new repository copy.

## GitHub configuration

1. Add repository variables:
   - `GH_OWNER`
   - `FORGEJO_HOST`
   - `FORGEJO_OWNER`
   - `DISCORD_LOG_CHANNEL_ID` (optional — Discord text channel ID for governance sync failure posts; see `docs/github-actions-secrets.md`)

2. Add Terraform sync secrets:
   - `SYNC_GITHUB_TOKEN`
   - `FORGEJO_API_TOKEN` (optional)

3. If using governance synchronizer, set:
   - `ENABLE_GOVERNANCE_SYNCHRONIZER=true`

4. Add synchronizer secrets listed in `docs/github-actions-secrets.md`.

## Slack prerequisites

5. Ensure contributors have `slack_user_id` in `contributors/*.json`.
6. Ensure teams define `slack_channels` in `teams/*.json` as needed.
7. Invite bot to private channels once (`/invite @Governance` or equivalent).

## Discord prerequisites (optional)

8. Create repository secrets `DISCORD_BOT_TOKEN` and `DISCORD_GUILD_ID` (see `docs/github-actions-secrets.md`).
9. Add bot to the server with **Manage Roles**; place the bot’s role above managed roles in the role list.
10. Set `discord_roles.maintainer` / `discord_roles.contributor` on teams as needed (numeric role IDs).
11. Ensure contributors who should receive roles have `discord_id` set and have **joined** the Discord server.

## Verification

12. Trigger `Governance Synchronizer` workflow manually.
13. Inspect logs for Slack/Discord warnings.
14. Confirm members appear in expected Slack channels and Discord roles.
