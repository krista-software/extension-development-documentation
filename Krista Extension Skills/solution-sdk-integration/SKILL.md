---
name: solution-sdk-integration
description: >-
  Add a "Solutions" tab to ANY Krista Global Catalog extension by integrating the Solution SDK
  (com.krista.extension:solution-sdk). The Solutions tab lets users generate conversations/agents
  from the extension's catalog requests, auto-publish them to Live, and import pre-built packaged
  solutions from GitHub or Artifactory. Integration is ~3 lines: add the dependency, register a
  "Solutions" custom tab, and expose the SDK's JAX-RS resources. Use when a developer asks to "add
  the Solutions tab", "integrate the solution sdk / automation sdk", "let users generate
  conversations from catalog requests", or "import packaged solutions" into an extension. This is an
  optional capability of the krista-extension-builder runbook (see the folder README). It does NOT
  build catalog requests — it consumes existing ones; scaffold those with krista-extension-scaffolding
  first.
---

# Solution SDK integration

> Part of the Krista extension skill set (see the folder `README.md`). This is an **optional capability**
> of the `krista-extension-builder` runbook — invoke the builder to create a whole extension; use this
> skill to add the Solutions tab to an existing (or freshly scaffolded) extension.

## What it does

The **Solution SDK** is an extension-agnostic library that adds a **Solutions tab** to any extension.
Once integrated, users can:
- **Generate conversations / agents** from the extension's catalog requests and auto-publish to Live.
- **Import packaged solutions** (pre-built conversation/agent ZIPs) from a GitHub or Artifactory repo.

It consumes the catalog requests the extension already exposes — so scaffold those first
(`krista-extension-scaffolding`). The SDK ships its own React UI and JAX-RS backend; you only wire it in.

## Split architecture (why integration is minimal)

- **React UI** runs in the browser iframe (has Studio auth cookies) — user interaction + Studio API calls.
- **SDK backend** runs in the extension JAR (no auth) — builds conversation JSON, downloads solution
  ZIPs, and does server-to-server workspace uploads using forwarded browser cookies.

You don't write either side; you register the SDK's resources and tab.

## Prerequisites

- An extension scaffolded with the standard framework (`@Extension`, a `customTabs()` invoker, and a
  JAX-RS `Application` mounted via `@Extension(jaxrsId=...)` — default `rest`). See
  `krista-extension-scaffolding`.
- The extension already exposes `@CatalogRequest`s (the SDK generates conversations from them).

## Integration — 3 steps

### Step 1 — Dependency
`templates/build-snippet.gradle` — this is the one and only SDK dependency:
```groovy
implementation 'com.krista.extension:solution-sdk:1.0.0'
```
(Resolves from the Krista Artifactory. Ignore the `com.krista.automation:automation-sdk` string in the
SDK's own javadoc — the published artifact is `com.krista.extension:solution-sdk:1.0.0`.)

### Step 2 — Register the "Solutions" tab
In the extension's `@InvokerRequest(CUSTOM_TABS)` method, add a Solutions entry, **preserving any
existing tabs**. Use `SolutionsTabProvider.tabEntry(appPath)` so the URL always matches your JAX-RS
`@ApplicationPath`. See `templates/customTabs-snippet.java`.

### Step 3 — Expose the SDK's JAX-RS resources — pick ONE mode
- **Mode A — the extension has its own `Application`** (most extensions): add the SDK's resource
  classes to your `getClasses()` via `SolutionsTabProvider.resourceClasses()`, and use
  `tabEntry("<yourAppPath>")`.
- **Mode B — no existing `Application`**: register the SDK's own `Application` class
  (`SolutionsTabProvider.application()`, path `krista-automation`) and use the no-arg `tabEntry()`.

See `templates/Application-snippet.java` for both.

### Step 4 — Configure the solution repository
Add `src/main/resources/config.properties` from `templates/config.properties.template` — choose
`solutions.provider=github` (owner/repo/ref/token) or `artifactory` (baseUrl/repoName/path).

That's the whole integration. Build and the Solutions tab appears in the extension's Setup UI.

## API endpoints (served by the SDK backend — reference only)

See `references/endpoints.md` — `/context`, `/build-conversation`, `/build-agent`, `/generated`,
`/save-generated`, `/solutions-config`, `/packaged-solutions`, `/import-solution`,
`/packaged-solution-status`, `/packaged-solution-download`, `/packaged-solutions-refresh`.

## Routing trap (same as custom tabs generally)

The tab URL is `rest/<jaxrsId>/solutions/`. `<jaxrsId>` = `@Extension(jaxrsId=...)` (default `rest`) —
and it must equal the `@ApplicationPath` on the Application that hosts the SDK resources. Mode A uses
your app path; Mode B uses `krista-automation`. A mismatch 404s the tab. See
`krista-extension-scaffolding/references/custom-tabs.md`.

## Files in this skill

- `templates/build-snippet.gradle` — the dependency.
- `templates/customTabs-snippet.java` — the tab registration (both modes).
- `templates/Application-snippet.java` — Mode A (resourceClasses in your Application) and Mode B (SDK Application).
- `templates/config.properties.template` — GitHub / Artifactory provider config.
- `references/endpoints.md` — backend endpoints + architecture notes.
