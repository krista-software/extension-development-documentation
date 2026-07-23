---
name: adding-krista-msauth-tabs
description: Use when adding Authentication, Audit Dashboard, or AI Assistant (MCP) tabs to a Krista catalog extension, or migrating an extension in krista-global-catalog from hand-rolled MSAL4J/ScribeJava OAuth onto microsoft-auth-sdk (symptoms - custom tabs 404, OAuth callback dies, extension has raw @Field.Text credential fields)
---

# Adding microsoft-auth-sdk Tabs to a Krista Extension

## Overview

Krista extensions get Authentication / Audit / AI-Assistant (MCP) tabs by migrating onto `app.krista.sdk:microsoft-auth-sdk:1.0.5`. The tabs are pre-built HTML inside the SDK JAR. Copy-adapt from the shipped references, then avoid the traps below — several survived expert planning and 13 per-task reviews before a final review caught them.

## Where things live

- Repo `git@bitbucket.org:syncappinc/krista-global-catalog.git` keeps **each extension on its own branch**; default branch is nearly empty. Find yours: `git branch -a | grep -i <name>`.
- References: `release/outlook-4` (`outlook4/` — all three tabs, collaboration domain), `release/sharepoint-4.0`, `release/teams-api` branch `feature/teams-api-tabs` (newest full migration; spec/plan under `docs/superpowers/` there).
- Local SDK source (`feature/microsoft-auth-sdk`) is 1.0.0 — **stale vs published 1.0.5**. Verify signatures via `javap -cp <1.0.5 jar from ~/.gradle or ~/.m2> <class>`, never the source checkout.

## Trap 1 — Tab URL routing (breaks everything silently)

Tab and callback URLs resolve as `<routingUrl>/<jaxrsId>/<applicationPath>/<resource @Path>`. **`jaxrsId` defaults to `"rest"`** — that's the only reason Outlook's `rest/outlook/...` URLs work; the platform does NOT magically prefix `rest/`. If `@Extension(jaxrsId = "x")` is set, `rest/...` URLs 404.

- Either drop the `jaxrsId` override (inherit `rest`, mirror Outlook) or emit `<jaxrsId>/<applicationPath>/...` URLs everywhere: `customTabs()`, `getCallbackEndPoint()`, `EXTENSION_FORWARD_PATH`, docs redirect URIs.
- Internal paths (`@ApplicationPath`, `callbackPathPrefix`, `AbstractRequestAuthenticator` super arg, `@Path`) stay short (e.g. `/teams`) — the router strips the jaxrsId prefix.
- **Verify** registered bindings in generated `build/classes/java/main/META-INF/krista/extension.json` (`apiRequests` keys) — no unit test catches a mismatch; smoke-test one Authorize round trip after deploy.

## Trap 2 — Legacy credential migration semantics

In the SDK attribute model `authType "Private"` = **app-only client credentials (S2S)**, NOT "customer's own app". An old extension doing delegated auth-code with customer credentials maps to **`authType "Public"` + `publicAuthMode "own"`** (users re-authorize once; refresh tokens aren't re-keyed). Mapping to Private silently flips user-context calls to app-context and breaks invokers.

## Trap 3 — Required annotations & build

- `implementationModel = Extension.ImplementationModel.Krista_4_O` **requires** `@Containerize(baseImageVersion = "3.6.2-sp3")` — compile fails without it (references have it; briefs may omit it).
- Deps: `krista-apis` + `extension-impl-anno-processors` `1.0.125-sp1` (adds `CatalogRequest.tool` for MCP), `microsoft-auth-sdk:1.0.5`, graph `5.76.0+`, `azure-identity 1.11.x`. Artifactory: `packages.cicd.in.antbrains.com/artifactory/libs-release`.
- `sdkUi` configuration (`transitive = false`) + Copy task extracting `auth/index.html`, `audit/index.html`, `mcp-setup/index.html` into `build/resources/main`; wire into `processResources`, `compileTestJava`, AND `jar` (`dependsOn`) or clean builds fail task-output validation / ship jars missing the HTML. **Don't copy Outlook's Copy task verbatim — it omits `mcp-setup/index.html`** (its AI tab only works off stale build dirs).
- **No `./gradlew` wrapper exists** in extension projects — use system gradle with `JAVA_HOME=$(/usr/libexec/java_home -v 21)`; JDK 23 breaks Mockito/JaCoCo ("Unsupported class file major version 67").
- Descriptor registration: `META-INF/services/app.krista.sdk.msauth.extension.registry.MsAuthExtensionDescriptor`.

## Security requirements (both found as review defects)

- `getCredentials` must never return a stored clientSecret in plaintext. If the extension lacks Outlook's `EncryptionUtil`, use the masked-placeholder pattern: return `"********"`, and on save treat placeholder/blank incoming secret as "reuse stored". **SharePoint 4.0's shipped `getCredentials` still returns the plaintext secret in own-credentials mode — do not use it as the pattern source for this endpoint.**
- An MCP query service executing LLM-planned Graph calls needs an allowlist guard **on the live execution path**: GET allowed; POST only to `https://graph.microsoft.com/v1.0/search/query`; reject everything else before any HTTP call.

## Quick checklist

| Piece | Pattern source |
|---|---|
| `<X>AuthConfig` (@MsAuthExtension + @AuthScope + @AuditConfig) | `OutlookAuthConfig.java` |
| Descriptor + ServiceLoader file | `OutlookExtensionDescriptor.java` |
| Attributes (`implements MsAuthAttributes`) + KV store | `OutlookAttributes.java` / `OutlookAttributeStore.java` |
| `AbstractRequestAuthenticator` subclass | `OutlookRequestAuthenticator.java` |
| Graph provider = thin alias over `MsAuthGraphClientProvider` | `outlook4 impl/connectors/` |
| Audit service delegating to `MsAuthAuditService(kv, "<ext>")` + `AbstractAuditResource` | `OutlookAuditService/OutlookAuditResource.java` |
| MCP setup/query/product-config + "Ask Agent" catalog request | `outlook4 mcp/` (query-only: delete send-mail branch) |

## Common mistakes

| Mistake | Reality |
|---|---|
| "Platform prefixes rest/ to tabs" | `rest` is just the default jaxrsId; see Trap 1 |
| Legacy creds → `Private` | Private = app-only S2S; use Public+own (Trap 2) |
| "@Containerize optional" | Required with Krista_4_O; compile fails |
| "Use the gradle wrapper" | None exists; system gradle + JDK 21 pin |
| Trust local SDK source for API shapes | It's 1.0.0; javap the 1.0.5 jar |
| Keep `getNotificationPath()` returning a real path with no notification endpoint | Return null (SDK null-checks it) or requests at that path get account-attributed |
