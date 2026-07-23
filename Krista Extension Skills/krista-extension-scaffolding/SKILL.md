---
name: krista-extension-scaffolding
description: >-
  Scaffold a new Krista Global Catalog extension from framework-accurate templates. Use when
  creating a new extension from scratch, or adding a standard framework piece to one (a catalog
  request, an Area/@Domain, an authenticator, a webhook/WAIT_FOR_EVENT handler, an entity +
  EntityStore, custom tabs, the build.gradle + release.properties, or a Microsoft-auth-SDK
  migration). The templates under templates/ are the Krista framework skeleton ONLY — annotations,
  DI wiring, JAX-RS wiring, build config — with business logic intentionally left as TODO stubs.
  Every pattern here was extracted verbatim from shipping extensions on krista-global-catalog
  release branches (autotask, restapi, salesforce_sales, servicenow, connect-wise, jira, outlook-4,
  sharepoint-4.0, slack, oauth2-authentication, base-authentication). Trigger on "create a new
  extension", "scaffold an extension", "add a catalog request", "add an Area", "add an entity /
  entity search", "add a webhook / wait-for-event", "add authentication", "set up build.gradle for
  an extension", "add the Documentation/Authentication/Audit/AI-Assistant tab".
---

# Krista Extension Scaffolding

> This is the **template library** used by the `krista-extension-builder` orchestrator. To create a
> whole extension end to end, invoke **`krista-extension-builder`** (it sequences these templates
> across all phases). Use this skill directly when you only need to add one framework piece.

Framework-only templates for building a Krista Global Catalog extension. **Business logic is out of
scope** — every template leaves method bodies as `// TODO: business logic`. What these give you is
the exact Krista framework surface that must be correct for an extension to compile, register, and
run: the annotations, the HK2 dependency injection, the JAX-RS wiring, and the Gradle build.

Everything here was reverse-engineered from real, shipping extensions. Where two extensions differ,
the difference is called out so you can pick the right variant.

## The mental model

A Krista extension is a Gradle module that produces a fat jar. At its core:

1. **One `@Extension` class** — identity (`name`/`version`), connection fields (`@Field.Text` for
   credentials), lifecycle hooks (`@InvokerRequest(...)`), and the Setup-tab tabs (`customTabs()`).
2. **One `@Service` Attributes class** — reads the saved connection attributes from the `Invoker`.
3. **One or more Area classes** — each carries a `@Domain(...)` and holds `@CatalogRequest` methods.
   A catalog request is one user-invokable operation; its **inputs are typed method parameters**
   (each `@Field.*`-annotated) and its **outputs are method-level `@Field.*` declarations**. It
   returns an `ExtensionResponse`.
4. **Integration classes** — HTTP client, token handling. Framework-free; not templated in detail.
5. **(Optional) Entities + EntityStores** — for Krista's entity-search; JAX-RS webhook + WAIT_FOR_EVENT
   triggers; a `RequestAuthenticator` for interactive auth; or the Microsoft-auth-SDK for MS products.
6. **`build.gradle` + `release.properties`** — the fat-jar build; `release.properties` is generated
   from the `@Extension` and `@Domain` annotations at build time.

## Decision guide — which templates you need

| You are building… | Use these templates |
|---|---|
| Any extension (always) | `build.gradle.template`, `gradle.properties.template`, `release.properties.template`, `ExtensionClass.java.template`, `Attributes.java.template`, `Area.java.template`, `CatalogRequest.snippets.java`, `SetupArea.java.template` (Test Connection + Health Check), `integration/ApiClient.java.template`, `resources/log4j2.xml.template`, `gitignore.template`, `resources/docs/*` (Documentation tab) |
| Read/write against a REST API with an API key or pasted token | + `authentication/TokenAuthenticator.java.template` + `integration/AttributeStore.java.template` (token is a secured `@Field.Text`; client sends `Authorization: Bearer`) |
| Interactive OAuth2 login (authorization-code / refresh) | + `authentication/RequestAuthenticator.java.template`, `authentication/AuthCallbackResource.java.template`, `webhook/WebhookApplication.java.template` (as the JAX-RS app that also hosts the callback), `integration/AttributeStore.java.template` |
| A Microsoft product (Outlook/SharePoint/Teams/OneDrive) | + `msauth/` (whole folder) — do NOT hand-roll OAuth; migrate onto microsoft-auth-sdk |
| Krista entity search over the system's objects | + `entity/Entity.java.template`, `entity/EntityStore.java.template` |
| Reacting to inbound webhooks / events | + `webhook/WebhookApplication.java.template`, `webhook/WebhookApiResource.java.template`, `WaitForEvent.snippet.java` |
| Custom Setup-tab tabs (Auth / Audit / AI Assistant) | see `references/custom-tabs.md` (routing rules) |

**Canonical references** (read these branches when a template leaves you unsure): `github` — the
cleanest end-to-end layered extension (PAT auth, webhook receiver, Setup/Health area, entities +
transformers, KeyValueStore attribute store, telemetry); `connect-wise` (module `xpertech/`, extension
"ConnectWise Manage Service") — Basic-auth + webhook + entities, the leanest build.gradle.

## Assembly order (new extension from scratch)

1. Pick the ecosystem/domain and package. Read `references/extension-structure.md` for the naming
   convention and directory layout. Generate the `@Domain` identifiers (see that file — they are
   registered in Krista; use placeholders and flag them if you do not have the real ones).
2. Copy `build.gradle.template` + `release.properties.template` + (if multi-module) `settings.gradle`.
   Fill the version pins from `references/build-and-release.md`.
3. Copy `ExtensionClass.java.template` and `Attributes.java.template`. Declare your connection fields.
4. Copy `Area.java.template`; add requests from `CatalogRequest.snippets.java`, one method per
   operation, with **typed `@Field` inputs and a `@Field.Desc`/`@Field` output** (this is mandatory —
   a request with only a `Map` parameter shows no inputs in the product).
5. Add the specialized pieces from the decision guide.
6. Verify: `references/verify.md` (compile against the SDK, run the annotation processor).

## Non-negotiables (learned from the real code)

- **Java 21 everywhere**: `@Java(version = Java.Version.JAVA_21)` on the extension + `sourceCompatibility/targetCompatibility = '21'`.
- **`krista-apis` and `extension-impl-anno-processors` must be pinned to the SAME version.**
- **Every catalog request declares typed inputs and a typed output** via `@Field.*`. See `references/field-types.md`.
- **`@Domain` id / ecosystem values are platform-registered.** Placeholders compile but won't bind to
  a real domain until replaced with Krista-assigned identifiers.
- **DI is HK2**: `org.jvnet.hk2.annotations.@Service` + `javax.inject.@Inject`. JAX-RS is `javax.ws.rs.*` (NOT `jakarta`).
- **Never hand-roll Microsoft OAuth** — use the microsoft-auth-sdk templates.

## Files in this skill

`references/` — extension-structure, annotations-cheatsheet, field-types, build-and-release,
authentication-patterns, custom-tabs, verify.

`templates/`
- Build: `build.gradle.template` (complete — fat-jar + JaCoCo + Sonar + publishing + optional UI, with a dependency catalog), `gradle.properties.template`, `release.properties.template`, `settings.gradle.template`, `gitignore.template`
- Core Java: `ExtensionClass.java.template`, `Attributes.java.template`, `Area.java.template`, `SetupArea.java.template`, `CatalogRequest.snippets.java`, `WaitForEvent.snippet.java`
- `integration/` — `ApiClient.java.template`, `AttributeStore.java.template` (@Service KeyValueStore)
- `authentication/` — `TokenAuthenticator.java.template` (PAT/API-key), `RequestAuthenticator.java.template` (OAuth2), `AuthCallbackResource.java.template`
- `webhook/` — `WebhookApplication.java.template` (JAX-RS app), `WebhookApiResource.java.template`
- `entity/` — `Entity.java.template`, `EntityStore.java.template`
- `msauth/` — `AuthConfig`, `ExtensionDescriptor`, `RequestAuthenticator`, `services-descriptor.txt`, `build-snippet.gradle`
- `resources/` — `log4j2.xml.template`, `docs/` (Docsify `index.html` + `_sidebar.md` + `pages/`) for the Documentation tab
