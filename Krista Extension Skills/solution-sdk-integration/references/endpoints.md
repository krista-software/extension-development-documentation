# Solution SDK — backend endpoints & architecture (reference)

The SDK backend is served by the JAX-RS resources you register in Step 3 (`SolutionsApiResource`,
`SolutionsAssetResource`, `SDKContextFilter`). You do not implement these — they ship in the SDK.
Reference only, for debugging and understanding the flow.

## Endpoints (under `rest/<appPath>/solutions/`)

| Method | Path | Description |
|--------|------|-------------|
| GET  | `/context` | Returns `wsId`, `invokerId`, `defnWsId` for the current session. |
| POST | `/build-conversation` | Builds conversation JSON for one catalog request. |
| POST | `/build-agent` | Builds an agent-creation payload. |
| GET  | `/generated` | Load previously generated conversations. |
| POST | `/save-generated` | Persist generated-conversation metadata. |
| GET  | `/solutions-config` | Read the current provider configuration. |
| GET  | `/packaged-solutions` | List packaged solutions (cached). |
| POST | `/import-solution` | Server-side import (upload + execute). |
| GET  | `/packaged-solution-status` | Whether a solution ZIP is cached. |
| GET  | `/packaged-solution-download` | Serve a cached solution ZIP. |
| POST | `/packaged-solutions-refresh` | Clear cache, re-fetch from the repository. |
| GET  | `/packaged-solutions-debug` | Diagnostic: test repository download. |

## Split architecture (recap)

| Layer | Runs where | Auth | Does |
|---|---|---|---|
| React UI | Browser iframe | Studio cookies | User interaction; calls Studio APIs (invokerDetails, conversationUpsert, conversationPublish). |
| SDK backend | Extension JAR (HK2) | none | Builds conversation/agent JSON; downloads solution ZIPs; server-to-server workspace upload. |
| Studio APIs | Browser → Studio | cookies | Upsert/publish conversations. |
| Solution repo | SDK backend → GitHub/Artifactory | token/anon | Hosts packaged solution ZIPs `{ext}/{ver}/*.zip`. |

The SDK backend has no Studio auth, so it only computes payloads and downloads; the browser (which has
cookies) performs the actual deploy. Large imports go server-to-server (bypassing nginx size limits)
using forwarded browser cookies.

## Key SDK classes (for reference; you interact only with SolutionsTabProvider)

- `com.krista.automation.ui.SolutionsTabProvider` — the only class you touch: `tabEntry(appPath)`,
  `tabEntry()`, `application()`, `resourceClasses()`.
- `ui/SolutionsApplication` (`@ApplicationPath("krista-automation")`), `SolutionsApiResource`,
  `SolutionsAssetResource`, `SDKContextFilter`, `GitHubSolutionsProvider`.
- `generation/{ConversationBuilder, StepBuilder, ExpressionBuilder}` — build Krista conversation JSON.
- `extension/{CatalogRequest, ExtensionDetails, FieldDefinition}` — the SDK's model of an extension's
  catalog requests (populated from the running extension).
- `core/config/SolutionsConfig` — loads `config.properties`.

## Repository layout for packaged solutions

`{extension}/{version}/*.zip` under the configured GitHub repo or Artifactory path. Publishing a new
packaged solution means adding a ZIP under that path; `/packaged-solutions-refresh` re-reads it.
