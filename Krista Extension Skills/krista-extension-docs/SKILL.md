---
name: krista-extension-docs
description: >-
  Update, sync, or audit the in-platform "Documentation" tab (a Docsify site under
  src/main/resources/docs/) of a Krista Global Catalog extension so it matches the current
  code, typically right before raising a PR. Use this whenever a developer has finished code
  changes on a krista-global-catalog extension — new or changed catalog requests, entities,
  connection attributes, or a version bump — and wants the docs brought up to date. Trigger on
  phrases like "update the docs", "sync the documentation", "refresh the release notes",
  "update the Documentation tab", "the docs are out of date", or "check the docs before I raise
  a PR", even when the developer names only the code change and not the docs. Covers the
  per-request pages, supported-requests.md, entities.md, the _sidebar.md navigation, the
  README home page, ReleaseNotes.md, and version consistency with the @Extension annotation.
---

# Krista Extension Documentation Sync

## What this is for

Every Krista Global Catalog extension ships an in-platform **Documentation** tab. It is a
[Docsify](https://docsify.js.org) static site bundled inside the extension jar. The docs are
written by hand and therefore drift from the code — a new catalog request gets added but no
page is written, a parameter is renamed but the table still shows the old name, the version is
bumped in the annotation but the release notes and home page still show the old number.

This skill's job is to close that gap: bring an extension's docs back into agreement with its
code before a PR goes up. **The code is the source of truth; the docs describe it.** You are
never inventing behavior — you are reading what the code actually does and making the docs say
that accurately, in the house style the existing pages already use.

Work on **one extension module at a time** (e.g. the `canvas/` module). Do not touch vendored
Docsify assets under `docs/assets/` — those are the framework, not content.

## Before you edit anything — work on a safe branch

`release/*` branches are shared, protected lines that ship to customers. Documentation edits (and
the wiring changes in Step 0) must never land directly on one. So the **first thing to do**, before
locating files or making any change, is confirm the checked-out branch:

```bash
current=$(git rev-parse --abbrev-ref HEAD)
echo "current branch: $current"
```

- **If it is a release branch** (name starts with `release/`), do not edit it. Create a separate
  working branch off it under the `feature/` prefix — strip the `release/` prefix, prepend
  `feature/`, and append `-extension-documentation` — then switch to it and do every modification
  there. The new branch must start with `feature/`, never `release/`:

  ```bash
  base=${current#release/}                                      # release/canvas -> canvas
  new="feature/${base}-extension-documentation"                 # -> feature/canvas-extension-documentation
  git checkout -b "$new"
  ```

  `checkout -b` branches from the current commit and carries any working-tree changes along, so
  nothing is lost. If that branch already exists, switch to it instead (`git checkout "$new"`).
  Tell the user which branch you created and that all edits will happen there. The release branch
  you just branched from (`$current`) is the **diff base** for Step 1 — you already know it, so you
  do not need to ask.

- **If it is already a feature branch** (anything not starting with `release/`), stay on it — the
  developer is already working in an isolated line. But you still need a baseline to know what
  changed, and a feature branch does not tell you which release it was cut from. So **ask the
  developer which `release/*` branch this feature branch is based on** (its parent). Do not guess a
  base — the wrong base produces the wrong scope. Record their answer as the **diff base** for
  Step 1.

Always state the branch you are working on in the Step 6 summary, so the developer knows where the
changes live before they open the PR.

## Step 0 — Locate the extension and its docs

The docs are wired to the extension through annotations on the single class annotated
`@Extension`. Find that class first, because it also tells you the current version, name, and
the connection attributes.

```bash
# From the extension module directory (the one with its own build.gradle):
grep -rl "@Extension(" src/main/java
```

On that class you will typically see:

- `@Extension(version = "1.0.7", name = "Canvas", description = "...")` — the **authoritative
  version, name, and one-line description**.
- `@StaticResource(path = "docs", file = "docs")` — confirms the docs folder is bundled.
- `@ChangeLog(file = "docs/pages/ReleaseNotes.md")` — the release-notes file surfaced in-platform.
- `@Field.Text(value = ...)` / other `@Field.*` — the **connection attributes** (some `isSecured`).
- `@InvokerRequest(CUSTOM_TABS)` returning a map with `"Documentation"` — confirms the tab.

The docs site itself lives at `src/main/resources/docs/`. Read `references/doc-structure.md`
for the full layout and the conventions each file follows — read it now if you have not worked
on these docs before, so your edits match the established structure rather than guessing.

### If the wiring is missing, add it

Great docs are invisible if the extension does not serve them. Three things on the `@Extension`
class make the docs reach users; if any is absent, add it. These are small, safe edits, but
they touch production Java — so also add the annotation's `import`, match the file's existing
formatting, and remember the developer will need to `./gradlew build` afterwards. Whenever you
add one, call it out in the PR summary (Step 6), and since the tab and changelog are
user-visible, add a release-notes line for them.

1. **`@StaticResource(path = "docs", file = "docs")`** — bundles the docs folder into the jar.
   Without it the site ships nowhere, and both the tab and the changelog break. `file` is the
   docs folder's name under `src/main/resources` (almost always `docs`; use the actual folder).
   This is the prerequisite for the other two.

2. **`@ChangeLog(file = "...")`** — surfaces `ReleaseNotes.md` as the in-platform change log.
   The `file` attribute is **required** and is resolved relative to `src/main/resources`. So if
   the release notes live at `src/main/resources/docs/pages/ReleaseNotes.md`, the value is
   `"docs/pages/ReleaseNotes.md"`. **Locate the actual ReleaseNotes file and set the path to
   match it** — do not assume the Canvas path. If no `ReleaseNotes.md` exists yet, create one
   (Step 4) first so the annotation points at a real file. Import
   `app.krista.extension.impl.anno.ChangeLog` (match how the file imports its other `anno`
   annotations — some files use a wildcard `import ...anno.*`).

3. **The "Documentation" custom tab** — a method annotated
   `@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)` returning a `Map<String, String>` that
   contains a `"Documentation"` entry pointing at `"static/<path>"`, where `<path>` is the
   `@StaticResource` `path` value (e.g. `"static/docs"`). Two cases:
   - **The method already exists** (it may already return other tabs such as `"Authentication"`):
     add the `"Documentation"` entry to the returned map, **preserving every existing entry**.
     `Map.of(...)` takes all pairs in one call, so extend the argument list rather than replacing it.
   - **The method does not exist**: add it. Minimal form:
     ```java
     @InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
     public Map<String, String> customTabs() {
         return Map.of("Documentation", "static/docs");
     }
     ```
   The path segment after `static/` must match the `@StaticResource` `path`, or the tab 404s.

The audit script (Step 5) reports which of these three are missing and suggests the correct
`@ChangeLog` path, so run it early as a discovery aid, not only at the end.

## Step 1 — Scope the work: find out what actually changed

Because this runs before a PR, scope the work by diffing against the **parent `release/` branch**
established in the pre-flight step — everything your branch changed relative to release is exactly
what needs documenting, and nothing that release already has does. This keeps you from rewriting
untouched pages and focuses effort where the code moved.

```bash
git fetch origin >/dev/null 2>&1
release="<parent release/ branch from the pre-flight step>"   # try local; use origin/<name> if local is stale
# Everything in the current working tree that differs from the release branch:
git diff --stat "$release"
git diff "$release" -- '**/*.java'     # read the actual code changes you must document
```

`git diff "$release"` compares the working tree against the release tip, so it captures both
committed and still-uncommitted work — the full set of changes this branch introduces. Document
**every** change it surfaces; the diff against release is the authoritative list of what this PR
adds, not your memory of it.

Map changed source files to the docs they affect:

| Changed in code | Docs to update |
|---|---|
| `@Extension(version=...)` bumped | `ReleaseNotes.md` (new block), `README.md` version line |
| New/changed `@CatalogRequest` method in an `@Domain` Area class | That request's page in `pages/`, `supported-requests.md`, `_sidebar.md` |
| New/removed catalog request | New page + `_sidebar.md` + `README.md` links + `supported-requests.md` |
| `tool = true` added to a `@CatalogRequest` | That request's page must state it is Ask Agent / MCP callable (see Step 3), plus a ReleaseNotes line |
| Entity class fields added/renamed | `entities.md` (and any request page whose output shows those fields) |
| `@Field.*` connection attribute added/changed | `configuration.md` / `ExtensionConfiguration.md` / `authentication.md` |
| Extension renamed | `index.html` site name, `README.md` title, `@Extension(name=...)` |

If the developer describes the change in words instead ("I added a Get Enrollments request"),
use that as the scope and confirm it against the code before writing.

The **inventory of catalog requests and attributes** the code currently exposes is worth
gathering explicitly. `scripts/audit_docs.py` (see Step 4) prints this for you, so you can run
it first as a discovery aid, not only as a final check.

## Step 2 — Understand the current doc style before editing

Open one existing page of the same kind you are about to write and match it. Consistency
matters more than personal preference here: a reader moving between pages should feel one
authorial voice. The two templates that carry the most structure:

- **Catalog-request pages** follow a fixed multi-section template. Read
  `references/catalog-request-template.md` and mirror an existing request page (its section
  order, its tables, its tone). Do not drop sections a sibling page has, and do not invent new
  top-level sections unless every page is getting them.
- **Release notes** follow a per-version block format. See `references/release-notes-template.md`.

For everything else (overview, entities, configuration, `supported-requests.md`), open the
existing file and follow its shape.

## Step 3 — Make the edits

Guiding principles, in priority order:

1. **Accuracy over completeness.** Read the actual Area/Service/Impl method, its input and
   output parameters, its validation, and its error handling, then describe *that*. If the code
   says enrollment filtering is done client-side, the docs must not imply a server-side filter.
   When the code and an existing doc claim disagree, the code wins — fix the doc.
2. **Every catalog request must have its own page — if one is missing, create it.** This is a
   hard invariant, not just a diff-driven step: for *every* `@CatalogRequest` in the code, there
   must be a dedicated page under `pages/` whose H1 title matches the request's `name`. This holds
   even for requests that predate your change — if the audit (Step 5) reports a request with no
   dedicated page, author one now from `references/catalog-request-template.md`, describing what
   the code actually does, and wire it into `_sidebar.md`, `README.md`, and the aggregate
   "supported requests" page. A request that exists in code but has no page is undocumented, full
   stop.
3. **Keep the cross-references in sync.** A catalog request exists in up to four places:
   its own page, `supported-requests.md`, `_sidebar.md`, and the link list in `README.md`.
   When you add, rename, or remove a request, update all four. A page that no page links to is
   invisible in the site; a sidebar link to a missing file is a broken nav entry.
4. **Match, don't reformat.** Reuse the existing table columns, heading levels, and emoji/tick
   conventions the neighboring pages use. Avoid gratuitous restyling of untouched sections — it
   bloats the diff and buries the real change from reviewers.
5. **Write for the end user of the extension**, not the extension's developer. These pages are
   read by people configuring and calling the extension in Krista. Explain inputs, outputs,
   errors, and realistic use cases; keep deep implementation notes to the one "Technical
   Implementation" section where the template already allows them.
6. **Surface `tool = true` on the request's page.** When a `@CatalogRequest` carries `tool = true`,
   it is callable by Krista's AI agent (Ask Agent / MCP). This is a user-visible capability, so the
   request's page must say so — add it to the page's "Request Details" list in the same style the
   page already uses, e.g. `- Ask Agent (MCP): Enabled (callable by the Krista AI agent)`. Do this
   for every request whose annotation has `tool = true`, and mention the enablement in the release
   notes too. Requests without `tool = true` should not claim to be agent-callable.

## Step 4 — Version and release notes

The `@Extension(version = ...)` annotation is the single source of truth for the version.
Whenever it has changed (or whenever you are preparing a release PR):

1. Add a new version block at the **top** of `ReleaseNotes.md` using
   `references/release-notes-template.md`. Fill New Features / Resolved Bugs / Dependency
   Updates / Known Issues / Limitations from what actually changed on the branch. Leave a
   section as "Not Available" rather than deleting it if it has no entries — that matches the
   existing style.
2. Update the version line in `README.md` so it agrees with the annotation. This is a common
   drift point (home page left showing an old version) — always reconcile it.
3. **Set the Krista Service APIs version in the release-notes block from `build.gradle`, not from
   the previous block.** The source of truth is the `annotationProcessor` dependency line in the
   module's `build.gradle`:

   ```
   annotationProcessor 'app.krista:extension-impl-anno-processors:<CORRECT_VERSION>'
   ```

   Read `<CORRECT_VERSION>` from that line and use it for the "Krista Service APIs Java" metadata
   line in the new (top) release-notes block. Carrying the previous block's number forward is a
   frequent mistake — the whole reason for a new block is often that this dependency moved. Verify
   the two agree before finishing.

## Step 5 — Verify before handing off

Run the audit script from the extension module directory. It cross-checks the code against the
docs and reports drift deterministically, so you catch broken nav links and version mismatches
before a reviewer does:

```bash
python3 ~/.claude/skills/krista-extension-docs/scripts/audit_docs.py .
```

It reports: whether the `@Extension` class has the wiring annotations (`@StaticResource`,
`@ChangeLog`, and the `"Documentation"` custom tab) — and, for any that are missing, the exact
annotation to add per the "If the wiring is missing, add it" guidance in Step 0; the full list of
custom tabs the class exposes, with an advisory to confirm each **user-facing** tab (anything
besides `Documentation`, e.g. an Authentication or Audit Dashboard tab) is actually covered by a
doc page — a new tab is a user-visible feature that is easy to ship undocumented; the version
according to the annotation vs. `README.md` vs. `ReleaseNotes.md`; `_sidebar.md` links that
point to missing files; pages not referenced by the sidebar (orphans); for **every**
`@CatalogRequest` in the code, whether it has a dedicated page (H1 matching its `name`) — flagging
`no dedicated page — create one` when it doesn't — plus whether the request is in the sidebar/
aggregate page and, when `tool = true`, whether its page documents the Ask Agent / MCP
capability; and the `@Field` attribute inventory. Treat its output as a checklist — resolve every
flagged item or explain why it is intentional. It cannot judge prose accuracy; that is on you.

Do a final read of the pages you changed as if you were a first-time user. If you built the
extension jar (`./gradlew build`), the docs are bundled from `src/main/resources/docs`, so no
extra copy step is needed.

## Step 6 — Summarize for the PR

Close with a short summary the developer can paste into the PR description: which pages you
changed and why, the version transition (old → new), and any doc claim you corrected because
the code disagreed with it. Flag anything you could not verify from the code and left for the
developer to confirm.

## Files in this skill

- `references/doc-structure.md` — the Docsify layout, the wiring annotations, and per-file conventions.
- `references/catalog-request-template.md` — the section template for a catalog-request page.
- `references/release-notes-template.md` — the per-version release-notes block.
- `scripts/audit_docs.py` — deterministic code-vs-docs drift check (version, nav links, inventory).
