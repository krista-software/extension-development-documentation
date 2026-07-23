---
name: krista-extension-doc-writer
description: >-
  Author the in-platform Documentation tab for a Krista extension AS A TECHNICAL WRITER — create the
  Docsify doc site from scratch (index.html, README home, _sidebar navigation, pages/ per-request
  pages, configuration, authentication, supported-requests, entities, release-notes.md) in the house
  voice, deriving every fact from the extension's code. Use when a NEW extension has no docs yet, when
  writing a new catalog-request page, or when a developer asks to "write the docs / documentation tab
  / release notes / user guide" for an extension. This is the AUTHORING counterpart to the
  krista-extension-docs skill (which SYNCS/AUDITS existing docs against code before a PR) — reuse that
  skill's per-request and release-notes reference templates; this skill adds the writing style guide,
  the ready-to-fill page templates, and the create-from-scratch workflow. Trigger on "write docs for
  the extension", "create the documentation tab", "document this catalog request", "write the
  configuration/authentication page", "draft release notes", "the extension has no docs".
---

# Krista Extension Documentation — Technical Writer

> Part of the Krista extension skill set (see the folder `README.md`). This is **Phase 6** of the
> `krista-extension-builder` runbook — invoke the builder to create a whole extension; use this skill
> directly to author (or add to) an extension's Documentation tab. Its counterpart
> `krista-extension-docs` audits existing docs.

You are writing the **Documentation tab** an operator sees inside Krista. It is a
[Docsify](https://docsify.js.org) site bundled in the extension jar (`src/main/resources/docs/`),
wired via `@StaticResource(path="docs", file="docs")` + a `customTabs()` entry `"Documentation" →
"static/docs"`. No build step — Docsify renders the Markdown in the browser.

## Who you write for

The reader is a **business/automation user configuring and calling the extension in Krista** — not
the extension's Java developer. They want to know: what does this request do, what do I put in, what
comes back, what errors will I hit, and when would I use it. Keep implementation detail out of the
main flow (one optional "Technical Implementation" section is the only place it belongs).

## The golden rule

**The code is the source of truth; you describe it.** Never invent behavior. Read the actual
`@CatalogRequest` method, its `@Field` inputs/outputs, its validation and error strings, and the
service it calls — then write *that*. Wrong parameter names copied from a sibling page are the #1
documentation bug. Read `references/style-guide.md` before writing a word.

## The doc site (what you create)

```
src/main/resources/docs/
├── index.html            # Docsify config (site name). Rarely edited.
├── README.md             # Home — title, one-line purpose, link to Overview.
├── _sidebar.md           # Left nav — requests grouped by Area / use case. Every page linked here.
└── pages/
    ├── overview.md            # What the extension is + the use cases it covers.
    ├── ExtensionConfiguration.md  # Setup-tab fields table (Field | Required | Default | Description).
    ├── Authentication.md      # How to obtain credentials (provider-specific "create app / PAT" guide).
    ├── <OnexPerCatalogRequest>.md  # one page per request (lean github style — see template).
    ├── supported-requests.md  # aggregate one-line index of every request.
    ├── entities.md            # field reference for returned entities.
    └── release-notes.md       # metadata header + reverse-chron version blocks (@ChangeLog target).
```

File naming isn't uniform across modules (PascalCase vs kebab). **Match the module you're in**;
never rename existing files (breaks inbound links).

## Workflow — documenting a new extension

1. **Inventory the code.** Find the `@Extension` class (name/version/description, connection
   `@Field`s) and every `@CatalogRequest` (name, area, type, inputs, outputs, `tool`). Group requests
   by their `area` / business use case — that grouping becomes the sidebar sections.
2. **Home + nav.** Write `README.md` (home) and `_sidebar.md` from `templates/`. Sidebar sections =
   the areas; one link per request.
3. **Getting-started pages.** `overview.md` (what it does + use cases), `ExtensionConfiguration.md`
   (the Setup-tab field table — pull fields verbatim from the `@Field` annotations), `Authentication.md`
   (how to get credentials for this provider).
4. **One page per request.** Use `templates/pages/catalog-request.md.template` (the lean, real-world
   github shape: Overview → Request Details → Input Parameters → Output Parameters → Example → Error
   Handling). For a request that needs deep validation/retry/business-rule coverage, escalate to the
   richer 15-section structure in the **krista-extension-docs** skill's `catalog-request-template.md`.
5. **Aggregate + entities.** `supported-requests.md` (one row per request), `entities.md` (field
   tables for returned entities).
6. **Release notes.** `release-notes.md` — metadata header + a `## vX.Y.Z (Month Year)` block. Follow
   the krista-extension-docs skill's `release-notes-template.md`; the **Krista Service APIs Java**
   line comes from the `extension-impl-anno-processors` version in `build.gradle`, not a guess.
7. **Wire + verify.** Confirm `@StaticResource` + `customTabs()` + (if used) `@ChangeLog` exist. Then
   run the krista-extension-docs skill's `audit_docs.py` to catch orphan pages, broken sidebar links,
   and version drift before the PR.

## Relationship to the other doc skill

- **This skill** = author docs from scratch, in-voice, for a new extension or new page.
- **`krista-extension-docs`** = sync/audit existing docs against changed code before a PR (and its
  `scripts/audit_docs.py` drift checker). Its `references/catalog-request-template.md` (exhaustive
  15-section page) and `references/release-notes-template.md` are the shared house templates — this
  skill reuses them rather than redefining them.

## Files in this skill

- `references/style-guide.md` — the technical-writing voice, formatting, and do/don't rules.
- `references/site-structure.md` — sidebar grouping + page-set conventions (with real examples).
- `templates/` — ready-to-fill `index.html`, `README.md` (home), `_sidebar.md`, and `pages/*`
  (overview, configuration, authentication, catalog-request [lean], supported-requests, entities,
  release-notes).
