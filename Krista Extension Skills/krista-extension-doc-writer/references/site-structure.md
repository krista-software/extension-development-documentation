# Doc-site structure & navigation conventions

(For the code-wiring details — `@StaticResource` / `@ChangeLog` / `customTabs()` — see the
**krista-extension-docs** skill's `references/doc-structure.md`. This page focuses on the writer-facing
layout and navigation grouping.)

## Page set

| File | Purpose | Notes |
|---|---|---|
| `index.html` | Docsify config | set `name` to "<Extension> Extension"; `loadSidebar: true` |
| `README.md` | Home | minimal: title, one-line purpose, link to Overview |
| `_sidebar.md` | Left nav | grouped by Area / use case; every reachable page linked |
| `pages/overview.md` | What it is + the use cases it covers | the landing read |
| `pages/ExtensionConfiguration.md` | Setup-tab field table | fields verbatim from `@Field` annotations |
| `pages/Authentication.md` | How to obtain credentials | provider-specific ("create a PAT / app") |
| `pages/<Request>.md` | one per catalog request | lean shape (see catalog-request template) |
| `pages/supported-requests.md` | aggregate index | one row per request |
| `pages/entities.md` | returned-entity field reference | link request output tables here |
| `pages/release-notes.md` | changelog | metadata header + reverse-chron version blocks |

## Sidebar grouping (real example — github)

Group requests by their `@CatalogRequest(area = ...)` / business use case, with a bold heading per
group. Getting-Started first, then one group per area:

```markdown
* [Home](/)

* **Getting Started**
    * [Overview](pages/overview.md)
    * [Extension Configuration](pages/ExtensionConfiguration.md)
    * [Authentication](pages/Authentication.md)

* **Release Management**
    * [List Releases](pages/ListReleases.md)
    * [Create Release](pages/CreateRelease.md)
    ...

* **Webhook Management**
    * [List Webhooks](pages/ListWebhooks.md)
    ...
```

The link text is the request's display `name`; the target file is one page per request. A Setup area
typically holds **Test Connection** and **Health Check** pages.

## The four places a request appears (keep in sync)

A catalog request should be reachable from: its own `pages/<Request>.md`, a `_sidebar.md` link, a row
in `supported-requests.md`, and (for larger docs) the home link index. An orphan page (no sidebar
link) is unreachable; a sidebar link to a missing file is a broken nav item. The
krista-extension-docs `audit_docs.py` flags both.

## Home page (real example — github)

Keep it tiny; the sidebar does the navigating:

```markdown
# GitHub Extension

Krista Integration with GitHub REST API.

See [Overview](pages/overview.md) to get started.
```
