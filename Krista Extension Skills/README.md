# Krista Extension Skills

A coordinated set of skills for building and maintaining Krista Global Catalog extensions.

**New here / building an extension from an API spec?** Read **`START-HERE.md`** — drop your Postman
collection / OpenAPI / API-doc PDFs into `resources/`, open a new session, and tell it to follow
`START-HERE.md`. It auto-analyzes the spec and runs the whole build to the jar.

**Under the hood** the flow is driven by **`krista-extension-builder`** — the front door that pulls the
other skills in as phases. Reach for an individual skill directly only when you want just that one piece.

## Start here

| Invoke | To… |
|---|---|
| **`krista-extension-builder`** | **Create an entire extension end to end** (from a description, a Postman/OpenAPI collection, or a Jira ticket). Auto-detects auth pattern, entity search, webhooks, Microsoft-SDK, MCP, and sequences every step. |

## The skills (phases of the builder, also usable standalone)

| Skill | What it does | Builder phase |
|---|---|---|
| `krista-extension-scaffolding` | Framework-only templates + references (build.gradle, extension/attributes/area/catalog-request, entities, auth, webhook, msauth, resources) — the template library (structure). | 1–4 |
| `krista-extension-business-logic` | Write the production business logic that fills the scaffolding's `// TODO` bodies: HTTP client + interceptors, transformers/DTOs, validation, error mapping, retry/pagination/rate-limit, telemetry, security (patterns + idiom library). | 4–5 |
| `adding-krista-msauth-tabs` | Migrate a Microsoft extension onto microsoft-auth-sdk (Auth/Audit/AI-Assistant tabs). | 3 (auth pattern D) |
| `entity-search-implementation` | Implement Krista entity search (EntityStore pattern) for a system's objects. | 5a |
| `solution-sdk-integration` | Add a "Solutions" tab to any extension (generate conversations/agents from catalog requests; import packaged solutions) via the Solution SDK. | 5c |
| `krista-extension-doc-writer` | Author the in-platform Documentation tab from scratch (technical-writer voice + page templates). | 6 |
| `krista-extension-testing` | Unit-testing policy — test the pure-Java classes only (transformers, validation, builders, client); deliberately neglect the framework classes (kept thin, validated by build + manual). | 7 |
| `krista-extension-docs` | Sync/audit an existing Documentation tab against the code before a PR (+ `audit_docs.py`). | 7 (and ongoing maintenance) |
| `krista-mcp-enable` | Bulk-enable MCP (`tool = true`) across many extension release branches. | optional / fleet-wide |

## How they fit together

```
krista-extension-builder  (runbook: gather spec → skeleton → auth → areas → capabilities → docs → verify)
        │
        ├─ Phase 1–4  → krista-extension-scaffolding   (templates + framework references — structure)
        ├─ Phase 4–5  → krista-extension-business-logic (HTTP client, transformers, validation, errors, telemetry)
        ├─ Phase 3D   → adding-krista-msauth-tabs       (Microsoft products)
        ├─ Phase 5a   → entity-search-implementation    (entity search)
        ├─ Phase 5c   → solution-sdk-integration         (Solutions tab)
        ├─ Phase 7    → krista-extension-testing          (pure-Java unit tests)
        ├─ Phase 6    → krista-extension-doc-writer      (author docs)
        └─ Phase 7    → krista-extension-docs            (audit docs)   +  krista-mcp-enable (MCP)
```

## Layout

Every capability is a kebab-case folder with a `SKILL.md` entry; supporting material lives in each
skill's `references/`, `templates/`, or `scripts/`. The builder's `references/placeholders.md` gives
the deterministic values for filling the scaffolding templates.

## Conventions (apply across all skills)

- Java 21; `krista-apis` and `extension-impl-anno-processors` pinned to the same version.
- HK2 DI (`@Service` + `@Inject`); JAX-RS is `javax.ws.rs.*`.
- Every catalog request: typed `@Field` inputs + typed output, returns `ExtensionResponse`.
- `@Domain` ids are platform-registered — placeholders must be replaced before the domain binds.
- The code is the source of truth; docs describe it.
