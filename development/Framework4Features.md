<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Framework 4 features

# Framework 4 features

## Overview

Framework 4 (`Krista_4_O`) extends the annotation model with containerized deployment, embedded documentation, MCP tool exposure, changelog support, and built-in telemetry. This page summarizes the new capabilities and when to use them.

## Implementation model

Declare the Framework 4 model in the `@Extension` annotation:

- `Krista_4_O` — standard Framework 4 model with per-request constructor injection, full KSDK integration, and the features described below
- `Krista_4_1` — extended model used by MCP server extensions; adds additional lifecycle and governance capabilities

Use `Krista_4_O` for most extensions. Use `Krista_4_1` only when building platform-level MCP server extensions.

## @Containerize

Declares that the extension should be packaged and deployed as a container:

- `baseImageVersion` — the base container image version to use (for example `"3.5.8"`, `"3.5.9"`, `"3.6.1-sp1"`)

Use the base image version recommended for your platform release. Newer versions may include runtime fixes or dependency updates.

## @ChangeLog

Points to a markdown file containing structured release notes:

- `file` — path to the release-notes file relative to extension source

### Release notes conventions

- Use semantic versioning headings (`## Version X.Y.Z — Title`)
- Categorize changes: New Feature, Bug Fix, Performance, Removed
- Document backward compatibility and breaking changes for each version
- Include a version-information table (extension version, developer, APIs version, global catalog version)

There is no enforced path convention. Common patterns include `resources/docs/pages/release-notes.md` and `docs/pages/releaseNotes.md`. Choose one and keep it consistent within your extension.

## @StaticResource

Bundles static web content (HTML, images, CSS) served by the platform:

- `path` — URL segment under which content is served
- `file` — resource directory containing the static files

### Recommended documentation structure

Most extensions embed a Docsify-powered site under `src/main/resources/docs/`:

```
src/main/resources/docs/
├── index.html          # Docsify entry point
├── README.md           # Landing page
├── _sidebar.md         # Navigation sidebar
├── assets/
│   ├── docsify.js
│   ├── search-min.js
│   └── theme-simple.css
├── _media/             # Screenshots and diagrams
└── pages/
    ├── overview.md
    ├── Authentication.md
    ├── release-notes.md
    └── ...per-request docs
```

The `index.html` loads Docsify and renders the markdown files as a navigable documentation site. Each catalog request can have its own page under `pages/`.

Access the docs via a custom tab (see below) or directly at the static resource path.

## Custom setup tabs

Use `@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)` to add tabs to the Setup UI:

- Return a `Map<String, String>` where keys are tab names and values are URL paths.
- Paths can point to REST endpoints or static resource paths.

## MCP tool exposure

Add `tool = true` to a `@CatalogRequest` annotation to expose it as an MCP (Model Context Protocol) tool. MCP-compatible AI clients can then invoke the request directly.

### When to use `tool = true`

- Query operations (list, fetch, search)
- Simple action operations (send, create, move)

### When NOT to use `tool = true`

- Async pair operations (start + get-result)
- Event-waiting operations (`WAIT_FOR_EVENT`)
- Operations that require complex multi-step workflows

### MCP authentication

When an MCP client calls a tool before the user has authenticated:

1. Extension detects missing credentials and throws `MustAuthorizeException`
2. Platform redirects the user to the identity provider
3. On success, credentials are stored for subsequent calls

**Critical rule:** always rethrow `MustAuthorizeException` in catch blocks — never swallow it.

### RequestContext and invokeAsUser

Use `RequestContext.invokeAsUser()` to determine the execution mode:

- **`true`** — MCP per-user path. Use the default public OAuth client and resolve tokens via `AccountProvider.lookupAccount(email)`.
- **`false`** — operator shared path. Use credentials configured in the Setup tab.

Check `invokeAsUser()` **before** loading operator attributes to avoid identity bleed between the two paths.

### Auth keyspace separation

- Per-user tokens and operator tokens must use separate key shapes in `KeyValueStore`.
- `invokeAsUser=true` always uses the default public OAuth client; operator credentials are only consulted for shared paths.

## TelemetryMetrics

Framework 4 injects `TelemetryMetrics` for built-in observability:

- Increment counters per catalog request
- Record success, error, and validation outcomes with timing
- Tag metrics with relevant (non-secret) parameters

Consider a `TelemetryHelper` wrapper to standardize metric names and tag maps across all catalog requests.

## See also

- [Build configuration](BuildConfiguration.md)
- [Java 21 patterns](Java21Patterns.md)
- [Authentication patterns](../advanced/AuthPatterns.md)
- [Catalog request types](catalog-requests/CatalogRequestTypes.md)
- [Observability](../operations/Observability.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
