# Keycloak and Vault credentials

This is a maintainer-facing reference for credentials related to future Keycloak/Vault sync work.

## Source of truth for CI names

Use `docs/github-actions-secrets.md` for exact secret/variable names expected by workflows.

## Governance-compatible Keycloak secrets

- `KEYCLOAK_SERVER_URL`
- `KEYCLOAK_USERNAME`
- `KEYCLOAK_PASSWORD`
- `KEYCLOAK_REALM`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_USER_REALM`

## Governance-compatible Vault secret

- `VAULT_TOKEN`

## Current status

The current synchronizer implementation uses only `SLACK_TOKEN`.
Keycloak and Vault secrets are reserved for future synchronizer extensions.
