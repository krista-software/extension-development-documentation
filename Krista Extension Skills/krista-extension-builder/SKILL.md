---
name: krista-extension-builder
description: >-
  THE front door for building a Krista Global Catalog extension end to end. Invoke this to create an
  entire extension from a description, a Postman/OpenAPI collection, or a Jira ticket: it runs a
  build runbook that auto-detects the right variant at each phase (auth mechanism, entity search,
  webhooks/events, Microsoft-auth-SDK, MCP) and pulls the specialized skills in as steps —
  krista-extension-scaffolding (framework templates), krista-extension-doc-writer (docs), entity
  search, adding-krista-msauth-tabs, krista-mcp-enable, and krista-extension-docs (audit). Use for
  "create/build a new extension", "scaffold an extension for <system>", "turn this Postman collection
  / API into an extension", "build the <X> extension end to end". For a single isolated piece (just a
  catalog request, just the docs, just enabling MCP), you may jump straight to the matching sub-skill;
  this orchestrator is for producing a whole, compiling extension.
---

# Krista Extension Builder — end-to-end runbook

When invoked, execute the phases below **in order**. Each phase says what to determine, what to do,
and which sub-skill / templates to pull. Branch on the spec gathered in Phase 0 — skip a phase only
when Phase 0 shows it does not apply. The goal is a complete, compiling extension.

The template library and framework references live in **`krista-extension-scaffolding/`** — read its
`references/` (extension-structure, annotations-cheatsheet, field-types, authentication-patterns,
build-and-release, custom-tabs, verify) before building. Deterministic placeholder values are in
`references/placeholders.md` here.

---

## ⛔ Completeness contract — DO NOT SKIP (read before building, verify at the end)

The most common failure is silently doing less than the spec: mapping only some endpoints, skipping
`@Entity` classes, leaving `// TODO` bodies, or skipping docs/tests/jar. **This is prohibited.**

- **Cover every endpoint.** Every operation in the Phase-0 inventory becomes a `@CatalogRequest`. If
  you deliberately build a subset, you MUST say so explicitly and list exactly what's deferred — never
  silently drop endpoints or stop early.
- **Every domain object → an `@Entity` + transformer + typed `Entity(X)` output.** No raw
  FreeForm/`Map` passthrough (see Phase 4).
- **Every request has typed `@Field` inputs and a typed output.** No bare `Map` parameter.
- **Fill every `// TODO`.** Ship real business logic (Phase 4 / business-logic skill), not stub bodies.
- **No phase silently omitted.** A phase is skipped only when Phase 0 shows it does not apply, and you
  state *why* it was skipped. Auth (Phase 3), docs (Phase 6), and the jar (Phase 7) are never optional.
- **Write the pure-Java tests** (testing skill) — don't ship untested logic.
- **No silent truncation.** If anything is partial, incomplete, or assumed, surface it in the Phase-7
  report — don't present a partial build as complete.

Phase 7 ends with a **self-audit against the Phase-0 inventory** that proves none of the above was
skipped. If the audit finds a gap, either fix it or report it explicitly — do not declare done.

---

## Phase 0 — Gather the spec (do this first, always)

Determine the items below. **If the user's prompt or attachments already answer one, use that and do
not ask.** A Postman/OpenAPI collection answers the endpoints, base URL, and auth; a Jira ticket
answers the name/purpose/scope. Ask only the genuine unknowns, and batch them with AskUserQuestion.

| # | Need | How to resolve / detect |
|---|---|---|
| 1 | Extension name + one-line purpose | from the ticket/prompt |
| 2 | Target system, API base URL, API reference | from the Postman/OpenAPI/prompt |
| 3 | Ecosystem + Domain names | from the ticket, or ask (e.g. "Field Service Management" / "Essentials") |
| 4 | `@Domain` id / ecosystemId / ecosystemVersion | Krista-registered → ask; if unavailable, generate stable placeholder UUIDs and FLAG them |
| 5 | Java package + Gradle group | derive: `app.krista.extensions.<ecosystem>.<domain>.<name>` (see placeholders.md) |
| 6 | **Auth mechanism → pattern (A/B/C/D)** | detect from the API's auth (see the AUTH DECISION table below) |
| 7 | Operations to expose, grouped into Areas | from the collection/endpoints; per op capture name, area, HTTP verb→type, inputs, output, whether `tool` |
| 8 | Capabilities: entity search? inbound webhooks/events? MCP `tool=true`? | see CAPABILITY DETECTION below |
| 9 | krista-apis version | default `1.0.126`; use ≥ `1.0.125-sp1` if any request needs `tool = true` |
| 10 | Target location | new module dir here, or a path inside a real `krista-global-catalog` clone |

### AUTH DECISION (sets which Phase 3 branch runs)
| If the system uses… | Pattern | Phase 3 templates |
|---|---|---|
| a pasted token / API key / PAT | **A** | `authentication/TokenAuthenticator` + `integration/AttributeStore` |
| OAuth2 client-credentials (machine token) | **B** | a small token manager (client-credentials); no authenticator |
| OAuth2 interactive (authorization-code / 3-legged) | **C** | `authentication/RequestAuthenticator` + `AuthCallbackResource` + `webhook/WebhookApplication` (JAX-RS host) + `AttributeStore` + scribejava dep |
| a Microsoft product (Outlook/SharePoint/Teams/OneDrive) | **D** | `msauth/*` + load the **adding-krista-msauth-tabs** skill |

### CAPABILITY DETECTION (adds optional phases)
- **Binary files** — any operation uploads or downloads a file (attachment, export, download,
  `content`, `asset`, `multipart`/`octet-stream`) → the request uses `@Field.File`, and the impl uses
  **`KristaMediaClient` + `FileRepository`** to bridge `app.krista.model.base.File` ↔ bytes (see
  `krista-extension-business-logic/references/file-handling.md` + `idioms/KristaMediaClient.java`).
- **Entity search** — the system has first-class searchable objects Krista should query as entities →
  Phase 5a (load the **entity-search-implementation** skill).
- **Webhooks / events** — the system pushes notifications the workflow should wait on → Phase 5b.
- **Solutions tab** — users should generate conversations/agents from the catalog requests or import
  packaged solutions → Phase 5c (load the **solution-sdk-integration** skill).
- **MCP** — some requests should be AI-agent callable → set `tool = true` (Phase 4); for bulk enable
  across existing branches, the **krista-mcp-enable** skill.

---

## Phase 1 — Module skeleton
From `krista-extension-scaffolding/templates/`, copy and fill placeholders (see placeholders.md):
`build.gradle.template`, `gradle.properties.template`, `release.properties.template`,
`gitignore.template`, and `settings.gradle.template` (only if standalone). Create the package dirs.
**Point `generateReleaseProperties` in build.gradle at your real `<Name>Extension.java` and one Area
file.** Add `resources/log4j2.xml.template`.

## Phase 2 — Core Java
Copy `ExtensionClass.java.template` + `Attributes.java.template`. Declare the Setup-tab connection
`@Field`s that match the chosen auth pattern (e.g. token secured field for A; client id/secret for
B/C). Add `integration/ApiClient.java.template`.

## Phase 3 — Authentication (run the ONE branch from the AUTH DECISION table)
- **A**: `TokenAuthenticator` + `AttributeStore`; wire `@InvokerRequest(AUTHENTICATOR)`.
- **B**: token manager doing `grant_type=client_credentials`; `TEST_CONNECTION` acquires a token.
- **C**: `RequestAuthenticator` + `AuthCallbackResource` + a JAX-RS `Application`
  (`webhook/WebhookApplication.java.template`) + `AttributeStore`; add `scribejava-apis`.
- **D**: use `msauth/` (AuthConfig, ExtensionDescriptor, RequestAuthenticator, services file,
  build-snippet) and **load the adding-krista-msauth-tabs skill** for the traps and tab wiring.
See `krista-extension-scaffolding/references/authentication-patterns.md`.

## Phase 4 — Areas + catalog requests (structure) + business logic (implementation)
Always add `SetupArea.java.template` (Test Connection + Health Check). Then one Area per group
(`Area.java.template`), and one method per operation from `CatalogRequest.snippets.java` — each with
**typed `@Field` inputs and a typed `@Field.Desc`/`@Field` output** (never a bare `Map` param; see
`field-types.md`). Set `tool = true` on requests that should be agent-callable. For large uniform
APIs, generate the Areas programmatically from the collection (as done for ServiceTrade).

> ### ⛔ MANDATORY: model the response as an Entity — do NOT dump the raw response as FreeForm
> This is the #1 shortcut to avoid. For **every** request that returns a domain object (a job, ticket,
> release, contact, …) or a list of them, you MUST:
> 1. **Define an `@Entity` class** for that object (`entity/Entity.java.template`) — public fields with
>    `@Field.*`, `@Searchable`/`@ToString`, a `toFields()` — one per distinct object the API returns.
> 2. **Declare the output as the entity**: `@Field.Desc(name="…", type="Entity(<Name>)")` for one, or
>    `type="[ Entity(<Name>) ]"` for a list — plus a `Count`/metadata field where useful.
> 3. **Map the API JSON to the entity with a transformer** (business-logic `Transformer.java`), then
>    return it in the `ExtensionResponse`.
>
> **`FreeForm` is NOT the response type.** Use `FreeForm` only for genuinely unstructured / caller-defined
> data (arbitrary custom-field bags, opaque event payloads) or `WAIT_FOR_EVENT` `eventData` — never as
> the default "the API response," and never as a reason to skip building entities. A catalog request
> whose output is a raw `FreeForm`/`Map` of the vendor payload is a defect: it shows no fields in Krista
> and can't be composed in workflows. If in doubt, build the entity. Entities are required whenever the
> object is also searchable (`supportStore=true` → Phase 5a).

Then **fill each request's `// TODO` body to production standard — load the
`krista-extension-business-logic` skill**: the HTTP client + interceptors (auth/retry/rate-limit),
DTO→entity transformers, input validation, the centralized error→exception mapping, the audited
try/catch→`ExtensionResponse` classification, telemetry, and secret handling. That skill's
`references/` + `idioms/` provide the patterns and adaptable code; its `production-checklist.md` is
the go/no-go gate.

## Phase 5 — Optional capabilities (only if detected in Phase 0)
- **5a Entity search**: add `entity/Entity.java.template` + `entity/EntityStore.java.template`; then
  **load the entity-search-implementation skill** and follow its mandatory order (mapping table →
  annotations → registry → dialect → stores → resolvers → tests).
- **5b Webhooks / WAIT_FOR_EVENT**: add `webhook/WebhookApplication` + `webhook/WebhookApiResource`
  (→ `EventHandler.handleEvent`) and `WaitForEvent.snippet.java` triggers.
- **5c Solutions tab**: **load the solution-sdk-integration skill** — add the
  `com.krista.extension:solution-sdk` dependency, a "Solutions" custom tab, expose the SDK's JAX-RS
  resources (`SolutionsTabProvider.resourceClasses()`), and add `config.properties`. Requires that the
  extension already exposes catalog requests (the SDK generates conversations from them).

## Phase 6 — Documentation tab
**Load the krista-extension-doc-writer skill** and author the Docsify site under
`src/main/resources/docs/` (index.html, README home, _sidebar grouped by Area, per-request pages,
configuration, authentication, supported-requests, entities, release-notes). Confirm the wiring:
`@StaticResource(path="docs", file="docs")`, a `customTabs()` "Documentation" entry, and (optional)
`@ChangeLog`.

## Phase 7 — Compile & generate the jar (YOUR final action)
This is the last thing you do — after everything above is written, **you (Claude) compile the
extension and produce the jar yourself.** Do not hand the user a list of build commands to run; run
the build and deliver the artifact. Follow `krista-extension-scaffolding/references/verify.md` for the
exact mechanism:

1. `JAVA_HOME` = JDK 21 (`/usr/libexec/java_home -v 21` on macOS).
2. Use the module's `./gradlew` if present; otherwise a system `gradle`; otherwise the cached
   distribution (`find ~/.gradle/wrapper/dists/gradle-8.14-bin -path '*/bin/gradle'`).
3. From the module dir, run `gradle clean jar` (add `--offline` if the internal Artifactory is
   unreachable but the `krista-apis` / `extension-impl-anno-processors` deps are already in
   `~/.gradle`). The annotation processor emits `META-INF/krista/extension.json` and the fat jar lands
   at `build/libs/<extension.name>-<version>.jar`.
4. If the processor/deps can't be resolved (fully offline, no cache), fall back to a `-proc:none`
   compile to prove the sources are green, and say plainly that the descriptor/jar step needs the
   Artifactory.

**Self-audit against the Phase-0 inventory FIRST (the anti-skip gate).** Before reporting, prove
nothing was skipped — walk the completeness contract:
- endpoints in the spec **vs** `@CatalogRequest` methods written → count both; they must match (or
  every deferral is listed);
- every domain object has an `@Entity` + transformer + typed `Entity(X)` output (grep for
  `type = "FreeForm"` outputs → each must be justified as genuinely unstructured);
- no `@CatalogRequest` takes a bare `Map` / returns a raw payload;
- **no `// TODO` left** in shipped code (`grep -rn "// TODO"` → must be empty or explicitly flagged);
- auth (Phase 3), docs (Phase 6), tests, and the jar all exist.

Then run the **krista-extension-docs** skill's `scripts/audit_docs.py` and **report** a coverage line:
extension name+version, package, auth pattern, **endpoints covered = N of M** (list any deferred),
entities created, capabilities enabled, tests written, the **jar path** (or why it couldn't be
produced), and any FLAGGED placeholders (esp. the `@Domain`/`ecosystem` ids). **If the audit finds a
gap, fix it or state it — never present a partial build as complete.**

> Scope: Phase 7 stops at the **jar**. Binding the domain, deploying to a Krista appliance, and
> publishing into `krista-global-catalog` are out of scope — they need Krista's registered IDs and
> infrastructure (see `references/placeholders.md`).

---

## Which sub-skill each phase uses

| Phase | Sub-skill / assets |
|---|---|
| 1–4 (skeleton, core, auth, request structure) | `krista-extension-scaffolding` (templates + references) |
| 4–5 (implement request business logic to production standard) | `krista-extension-business-logic` (patterns + idioms) |
| 3D (Microsoft) | `adding-krista-msauth-tabs` |
| 5a (entity search) | `entity-search-implementation` |
| 5c (Solutions tab) | `solution-sdk-integration` |
| 6 (docs authoring) | `krista-extension-doc-writer` |
| 7 (pure-Java unit tests) | `krista-extension-testing` |
| 7 (docs audit) | `krista-extension-docs` (`scripts/audit_docs.py`) |
| MCP bulk-enable across branches | `krista-mcp-enable` |

## The kit is self-contained
The templates and references already encode the patterns extracted from the shipping extensions, so
you do NOT need repo access at build time — build straight from the kit. If you genuinely hit a shape
none of the templates cover, use the closest template, adapt it to the conventions in
`annotations-cheatsheet.md` / `field-types.md`, and **flag the gap** for the developer — never invent
an unverified annotation. (Filling such gaps by adding a new template to the kit is a maintenance task,
not a build-time one.)

## Non-negotiables (carried from the real code)
- Java 21 everywhere; `krista-apis` and `extension-impl-anno-processors` pinned to the SAME version.
- Every catalog request declares typed `@Field` inputs and a typed output; returns `ExtensionResponse`.
- **Output = an `@Entity` for domain objects, PLUS scalar fields as needed** (`@Field.Text`,
  `@Field(type="Number")`, `@Field.Boolean`, `@Field.Date`) for count/status/message/timestamp — a
  request may declare several output fields. Never a raw-FreeForm passthrough of the vendor payload.
- DI is HK2 (`@Service` + `@Inject`); JAX-RS is `javax.ws.rs.*` (not jakarta).
- `@Domain` ids are platform-registered — placeholders compile but must be replaced before binding.
- Never hand-roll Microsoft OAuth — use pattern D.
