# Maintainer checklist (secrets and sync)

Use this checklist when onboarding a new maintainer or setting up a new repository copy.

## GitHub configuration

1. Add repository variables:
   - `GH_OWNER`
   - `FORGEJO_HOST`
   - `FORGEJO_OWNER`

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

## Verification

8. Trigger `Governance Synchronizer` workflow manually.
9. Inspect logs for channel resolution/invite warnings.
10. Confirm members appear in expected channels.
