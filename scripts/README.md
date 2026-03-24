# Scripts

## `secrets/` — Vault ↔ local env (ScottyLabs parity)

This directory is a **git submodule** pointing at [ScottyLabs/secrets-sync-scripts](https://github.com/ScottyLabs/secrets-sync-scripts): helper scripts to **pull/push** team secrets between **local `.env` files** and **HashiCorp Vault** (see that repo’s README).

### First-time clone

After cloning **golden-retriever**, initialize submodules:

```bash
git submodule update --init --recursive
```

Or when cloning:

```bash
git clone --recurse-submodules <repo-url>
```

### Daily use

```bash
cd scripts/secrets
./setup.sh          # Vault login (opens browser / device flow)
./single/pull.sh    # Vault → local .env
./single/push.sh    # local .env → Vault
```

Paths and Vault mount names in those scripts are **ScottyLabs-oriented**. Fork [secrets-sync-scripts](https://github.com/ScottyLabs/secrets-sync-scripts) and point the submodule at your fork if your Vault layout differs.

See **[GitHub Actions secrets](../docs/github-actions-secrets.md)** for CI credentials (not stored in this repo).
