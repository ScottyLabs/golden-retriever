# Joining as a contributor

> **Note:** This is for individuals seeking to register themselves as a contributor under governance.

Create a new JSON file in `contributors/` with your username as the filename,
e.g. `your-github-username.json`:

```json
{
  "full_name": "Your Name",
  "github_username": "your-github-username",
  "forgejo_username": "your-codeberg-username"
}
```

- `full_name` **(required)** — Your display name.
- `github_username` — Your GitHub username. Required if you are on any GitHub-synced team.
- `forgejo_username` — Your Forgejo/Codeberg username. Required if you are on any Forgejo-synced team.

See the [contributor schema](../schemas/contributor.schema.json) for full field definitions and validation rules.
