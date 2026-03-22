# Adding a Google file

> **Note:** This is for registering individual Google files (Docs, Sheets, Slides, etc.) so that teams can reference them by slug.

Create a new JSON file in `google-files/` with the file slug as the filename, e.g. `my-team-runbook.json`:

```json
{
  "name": "My Team Runbook",
  "slug": "my-team-runbook",
  "description": "Operational runbook for the My Team project.",
  "url": "https://docs.google.com/document/d/1ABCxyz.../edit"
}
```

- `name` **(required)** — Human-readable name for the file.
- `slug` **(required)** — URL-safe identifier; must match the filename (without `.json`).
- `description` — Optional brief description.
- `url` **(required)** — Direct link to the Google file.

## Finding the URL

1. Open the file in Google Docs, Sheets, Slides, etc.
2. Copy the URL from the browser address bar, or use **Share > Copy link**.
   - Docs: `https://docs.google.com/document/d/<file_id>/edit`
   - Sheets: `https://docs.google.com/spreadsheets/d/<file_id>/edit`
   - Slides: `https://docs.google.com/presentation/d/<file_id>/edit`

> **Note:** Permissions are not managed automatically. Access must be granted manually in Google. This system only tracks the association between teams and files.

See the [Google file schema](../schemas/google-file.schema.json) for full field definitions and validation rules.
