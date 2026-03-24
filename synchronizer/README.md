# Governance synchronizer (optional)

This directory is reserved for a **Python synchronizer** that applies Keycloak, HashiCorp Vault, Slack, and Google Drive changes from `contributors/`, `teams/`, and `repos/` — the same role as [ScottyLabs/governance `__meta/synchronizer`](https://github.com/ScottyLabs/governance/tree/main/__meta/synchronizer).

## When you add code here

1. Add **`pyproject.toml`** (recommended, with **`uv`**) and an entrypoint **`sync`** (e.g. `uv run sync`), matching [`.github/workflows/governance-synchronizer.yml`](../.github/workflows/governance-synchronizer.yml).
2. Set repository variable **`ENABLE_GOVERNANCE_SYNCHRONIZER`** = `true`.
3. Configure **GitHub Actions secrets** listed in [`docs/github-actions-secrets.md`](../docs/github-actions-secrets.md).

Until `pyproject.toml` exists, the workflow exits successfully with a notice.

## Terraform

GitHub and Forgejo are already managed by **Terraform** in the repo root (`.github/workflows/sync.yml`). This synchronizer is for everything else in the [synchronizer model](../docs/synchronizer-model.md).
