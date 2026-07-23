# Krista extension docs — structure and conventions

The Documentation tab is a [Docsify](https://docsify.js.org) site. Docsify serves Markdown
directly in the browser (no build step) — `index.html` loads the framework, and the Markdown
files are the content. This is why editing docs is just editing `.md` files and rebuilding the
jar; there is nothing to "compile."

## How the docs are wired to the extension

On the class annotated `@Extension` (find it with `grep -rl "@Extension(" src/main/java`):

```java
@Extension(version = "1.0.7", name = "Canvas", description = "...")
@StaticResource(path = "docs", file = "docs")          // bundles src/main/resources/docs into the jar
@ChangeLog(file = "docs/pages/ReleaseNotes.md")        // release notes surfaced in-platform
public final class CanvasExtension {

    @InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
    public Map<String, String> customTabs() {
        return Map.of("Documentation", "static/docs/"); // renders the site as a tab
    }
}
```

Take-aways for the skill:
- The **version, extension name, and one-line description** come from `@Extension(...)`. This is
  the authoritative version; docs must agree with it.
- The docs folder is always `src/main/resources/docs/` (the `@StaticResource` `file` value,
  resolved under resources). Confirm the exact path per module rather than assuming.
- `@ChangeLog` points at the release-notes file. If it points somewhere other than
  `docs/pages/ReleaseNotes.md`, follow the annotation.

**These three are not always all present**, and a docs site with a missing annotation silently
fails to reach users (no `@StaticResource` → nothing is bundled; no `@ChangeLog` → no in-platform
change log; no `"Documentation"` tab → the site is bundled but unreachable). When one is missing,
add it — SKILL.md Step 0 ("If the wiring is missing, add it") has the exact attribute values and
how to derive each path. The `@ChangeLog` `file` is resolved relative to `src/main/resources`
(e.g. `"docs/pages/ReleaseNotes.md"`), and the tab value is `"static/<@StaticResource path>"`.

## Layout of `src/main/resources/docs/`

```
docs/
├── index.html          # Docsify config: site "name", sidebar/search options. Rarely edited —
│                        #   only when the extension is renamed (updates the displayed site title).
├── README.md           # Home page. Feature list, quick-start, a full link index of every page,
│                        #   and a version line. The link index and version line drift easily.
├── _sidebar.md         # Left navigation. Grouped headings + links. MUST list every page a
│                        #   reader should reach. A link here to a missing file is a broken nav item.
├── assets/             # Vendored Docsify JS/CSS. DO NOT EDIT — framework, not content.
└── pages/
    ├── overview.md
    ├── ExtensionConfiguration.md      # setup / configuration guides (naming varies per module)
    ├── configuration.md
    ├── authentication.md
    ├── CreatingCanvasApp.md           # provider-specific "how to get credentials" guide
    ├── supported-requests.md          # AGGREGATE summary of all catalog requests
    ├── <OnexPerCatalogRequest>.md     # one detailed page per catalog request
    ├── entities.md                    # data-structure reference for returned entities
    └── ReleaseNotes.md                # per-version changelog (also the @ChangeLog target)
```

File naming is not perfectly uniform across modules (some pages use PascalCase, some
kebab/lowercase). Match whatever the module already does; do not rename existing files just to
normalize them — that breaks every inbound link.

## The four places a catalog request appears

When a request is added, renamed, or removed, keep these in agreement:

1. **`pages/<Request>.md`** — the full detailed page (see `catalog-request-template.md`).
2. **`pages/supported-requests.md`** — a shorter summary entry (description + input/output/error
   tables) for the same request.
3. **`_sidebar.md`** — a nav link, usually nested under an area heading (e.g. "Course Management").
4. **`README.md`** — the home-page link index also lists the request under its area.

Miss one and the site is inconsistent: an orphan page (no sidebar/README link) is unreachable;
a dangling link (no file) is a broken nav entry.

## Source-of-truth mapping (code → docs)

- **Catalog requests**: methods annotated `@CatalogRequest`, living in classes annotated
  `@Domain` (the "Area" classes, e.g. `CourseManagementArea`). The area name and request
  names/params come from here and the service/impl layers they delegate to. Read the method to
  learn the real input parameters, output type, validation, and error behavior.
- **Entities**: the extension's own entity classes (e.g. `entity/Course`, `entity/User`,
  `entity/Assignment`). `entities.md` documents their fields. Field name/type/description must
  match the class.
- **Connection attributes**: `@Field.*` annotations on the `@Extension` class (e.g.
  `@Field.Text(value = ..., isSecured = true)`). The configuration/authentication pages document
  these — how to obtain them and what they do.
- **Version / name / description**: `@Extension(...)`.

## House-style notes

- Tables are the workhorse. Input/output parameters, validation rules, entity fields, and
  error scenarios are all rendered as Markdown tables with consistent column sets. Reuse the
  neighboring page's columns exactly.
- Pages are written for the **end user configuring/calling the extension in Krista**, not for
  the extension's own developer. Keep implementation detail in the single "Technical
  Implementation" section the request template provides.
- Tone is factual and example-heavy. Realistic example values (real-looking IDs, term names)
  make the pages far more useful than placeholders like `<id>`.
