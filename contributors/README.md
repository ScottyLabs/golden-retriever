# Joining as a contributor

> **Note:** This is for individuals seeking to register themselves as a contributor under governance.

Create a new JSON file in `contributors/` with your username as the filename,
e.g. `your-github-username.json`:

```json
{
  "full_name": "Your Name",
  "github_username": "your-github-username",
  "forgejo_username": "your-codeberg-username",
  "slack_user_id": "U0123456789",
  "discord_id": "123456789012345678",
  "matrix_id": "@yourname:matrix.org"
}
```

- `full_name` **(required)** — Your display name.
- `github_username` — Your GitHub username. Required if you are on any GitHub-synced team.
- `forgejo_username` — Your Forgejo/Codeberg username. Required if you are on any Forgejo-synced team.
- `slack_user_id` — Your Slack member ID (e.g. `U0123456789`). To find it, open your Slack profile, click the three dots, and select "Copy member ID."
- `discord_id` — Your Discord user ID (numeric). Enable Developer Mode in Settings > Advanced, then right-click your name and select "Copy User ID."
- `matrix_id` — Your Matrix/Element user ID in `@user:server` format (e.g. `@yourname:matrix.org`).

See the [contributor schema](../schemas/contributor.schema.json) for full field definitions and validation rules.
