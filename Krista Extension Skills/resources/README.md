# resources/ — drop your API reference material here

Put anything that describes the API you want an extension for. The builder auto-detects and parses
what it finds — you don't need to pre-process or rename files. Supported:

- **Postman collection** — `*.postman_collection.json` (or any exported Postman `*.json`)
- **OpenAPI / Swagger** — `openapi.json` / `swagger.yaml` / `*.yaml` / `*.json`
- **API-doc PDFs** — `*.pdf`
- **API docs as HTML/Markdown/text** — `*.html`, `*.md`, `*.txt`
- **Sample requests/responses** — any JSON payload examples
- A short note (a `NOTES.md`) if you want to state the extension name, ecosystem/domain, or auth up front

Multiple files are fine — the builder reconciles them. Then start a new Claude Code session and say:

  Read "Krista Extension Skills/START-HERE.md" and build the extension. Reference material is in
  "Krista Extension Skills/resources/".
