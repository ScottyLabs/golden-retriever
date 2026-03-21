# Adding a Figma project

> **Note:** This is for registering a Figma project so that teams can reference it by slug.

Create a new JSON file in `figma-projects/` with the project slug as the filename, e.g. `my-project-designs.json`:

```json
{
  "name": "My Project Designs",
  "slug": "my-project-designs",
  "description": "Design files for the My Project team.",
  "figma_team_id": "123456789",
  "figma_project_id": "987654321",
  "url": "https://www.figma.com/files/team/123456789/project/987654321"
}
```

- `name` **(required)** — Human-readable project name.
- `slug` **(required)** — URL-safe identifier; must match the filename (without `.json`).
- `description` — Optional brief description.
- `figma_team_id` **(required)** — Numeric Figma team ID.
- `figma_project_id` **(required)** — Numeric Figma project ID.
- `url` — Direct link to the project in Figma (for convenience).

## Finding your Figma IDs

Navigate to your project in the Figma file browser. The URL has the form:

```
https://www.figma.com/files/team/<team_id>/<team-name>/project/<project_id>/<project-name>
```

Copy the numeric `<team_id>` and `<project_id>` from the URL.

> **Note:** The Figma API is read-only for team/project management. Permissions cannot be synced automatically. CI will verify that referenced projects exist, but access must be granted manually in Figma.

See the [Figma project schema](../schemas/figma-project.schema.json) for full field definitions and validation rules.
