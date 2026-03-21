# Adding a repository

> **Note:** This is for registering a repository so that teams can reference it by slug.

Create a new JSON file in `repos/` with the repo slug as the filename, e.g. `my-project.json`:

```json
{
  "name": "My Project",
  "slug": "my-project",
  "description": "A web application that does great things.",
  "github": "my-org/my-project",
  "forgejo": "my-org/my-project"
}
```

- `name` **(required)** — Human-readable repository name.
- `slug` **(required)** — URL-safe identifier; must match the filename (without `.json`).
- `description` — Optional brief description.
- `github` — The GitHub repository in `owner/repo` format. Required if any team referencing this repo syncs to GitHub.
- `forgejo` — The Forgejo/Codeberg repository in `owner/repo` format. Required if any team referencing this repo syncs to Forgejo.

At least one of `github` or `forgejo` must be provided.

See the [repository schema](../schemas/repository.schema.json) for full field definitions and validation rules.
