# START HERE — build a Krista extension in a new session

This kit builds a complete, production-standard Krista Global Catalog extension from an API spec, end
to end, finishing at the jar. It works for **any** extension.

---

## For you (the human) — 3 steps

1. **Drop your API reference material into `resources/`** (this folder's `resources/` subfolder):
   a Postman collection, an OpenAPI/Swagger file, API-doc PDFs, HTML/Markdown docs, sample payloads —
   anything. Multiple files are fine. See `resources/README.md`.
2. Open a **new Claude Code session** with this `Krista Extension Skills` folder available.
3. Paste this one line:

   > **Read `START-HERE.md` and build the extension by following it. My API reference material is in `resources/`.**

Claude will analyze the material, ask you only what it genuinely can't infer (extension name,
ecosystem/domain, auth if unclear), then build the whole extension and produce the jar.

---

## For Claude — the instructions to execute

You are building a Krista Global Catalog extension. Follow this exactly; do not improvise a different
process.

### Step 0 — Orient
- This file lives inside the **`Krista Extension Skills`** folder. Locate that folder and the
  **`resources/`** folder next to this file (if `resources/` is empty or missing, ask the user where
  the API material is).
- Read, in order: `README.md` (the index), `krista-extension-builder/SKILL.md` (the authoritative
  runbook), and `krista-extension-builder/references/placeholders.md`. **`krista-extension-builder` is
  the process — run its Phase 0→7.** Load the sub-skills it names, when it names them.
- **Obey the builder's "Completeness contract — DO NOT SKIP."** Cover every endpoint; build an
  `@Entity` (typed output) for every domain object; fill every `// TODO`; never skip auth/docs/tests/
  jar; never silently do a subset. If anything is partial, say so explicitly in the Step-5 report.

### Step 1 — Analyze `resources/` (do this before asking anything)
Detect and parse whatever is present — do not require a specific format:
- `*.postman_collection.json` / exported Postman `*.json` → base URL (variables), auth, and every
  request (method, path, path/query params, body).
- `openapi.*` / `swagger.*` / `*.yaml` / `*.json` → servers, security schemes, paths, schemas.
- `*.pdf`, `*.html`, `*.md`, `*.txt` → read for base URL, auth, endpoints, field meanings.
- Sample payloads → infer entity/DTO shapes and output fields.
Reconcile multiple sources. Produce an internal inventory: base URL, **auth mechanism**, and the list
of operations grouped by area/use case (each with inputs, output, and read-vs-write intent).

### Step 2 — Gather only the genuine unknowns (builder Phase 0)
From the analysis, auto-fill everything you can. Then ask the user — **batched, only what the docs
don't answer** — typically:
- Extension **name** + one-line purpose (if not stated).
- **Ecosystem + Domain**, and whether it **joins an existing domain** (then you need the registered
  `@Domain`/`ecosystemId` — have them copy from a sibling extension, or supply them) **or is new**
  (placeholder IDs, flagged). See `placeholders.md` — this is the one thing that must be right.
- **Auth** only if the spec is ambiguous (map to pattern A/B/C/D in the builder).
- Target location for the module (default: a new folder here).
Do not ask what `resources/` already answers.

### Step 3 — Build (builder Phases 1–6)
Execute the runbook, pulling the sub-skills it directs:
- **Structure** → `krista-extension-scaffolding` (build.gradle, extension/attributes/area/catalog
  requests with **typed `@Field` inputs + typed output**, SetupArea, entities, resources, docs stubs).
  - **Build `@Entity` classes for the domain objects — do NOT skip them.** Every request that returns
    an object (or list) declares its output as `Entity(<Name>)` / `[ Entity(<Name>) ]` and maps the
    JSON via a transformer. Returning the raw API payload as a `FreeForm`/`Map` is a defect (no fields
    in Krista). `FreeForm` is only for genuinely unstructured data. See scaffolding `field-types.md`.
- **Production business logic** (fill every `// TODO`) → `krista-extension-business-logic` (HTTP client
  + interceptors, transformers/DTOs, validation, error→exception mapping, the audited
  try/catch→`ExtensionResponse`, telemetry, secret handling). Use its `production-checklist.md`.
- **Capabilities as detected** → `entity-search-implementation` (searchable objects),
  webhook/WAIT_FOR_EVENT, `solution-sdk-integration` (Solutions tab), `adding-krista-msauth-tabs`
  (Microsoft products).
- **Docs** → `krista-extension-doc-writer` (author the Documentation tab from the code).
Honor the non-negotiables: Java 21; `krista-apis` == `extension-impl-anno-processors` version; HK2 DI
(`@Service`/`@Inject`); JAX-RS `javax.ws.rs.*`; **domain objects modeled as `@Entity` with typed
outputs (no raw-FreeForm passthrough)**; request/entity IDs random-with-prefix + stable;
**domain/ecosystem IDs real-registered-or-flagged**; never log secrets.

### Step 4 — Compile & generate the jar (builder Phase 7 — YOUR final action)
After everything is written, **you compile and produce the jar** (don't hand the user commands):
`JAVA_HOME`=JDK 21; use `./gradlew` / system `gradle` / the cached `gradle-8.14`; run `gradle clean
jar` (`--offline` if Artifactory is unreachable but deps are cached). Deliver
`build/libs/<name>-<version>.jar` + confirm `META-INF/krista/extension.json` generated. If deps/
processor can't resolve, fall back to a `-proc:none` compile to prove the sources are green and say so
plainly.

### Step 5 — Report
Summarize: extension name+version, package, auth pattern, request count by area, capabilities enabled,
the **jar path** (or the honest reason it couldn't be built), and any **flagged placeholders**
(especially `@Domain`/`ecosystem` IDs) the developer must replace before the extension binds and
deploys in Krista. Stop at the jar — binding the domain and deploying into `krista-global-catalog` +
a Krista appliance are out of scope and need Krista's registered IDs and infrastructure.
