# Placeholder resolution

Every template uses `{{PLACEHOLDER}}` tokens. Resolve them once in Phase 0, then fill consistently
across all files. Derivations below make the fill deterministic.

## Identity

| Placeholder | How to derive | Example |
|---|---|---|
| `{{EXT_NAME}}` | display name from the ticket | `ServiceTrade` |
| `{{EXT_MODULE}}` | lowercase, no spaces | `servicetrade` |
| `{{EXT_CLASS}}` | `{{EXT_NAME}}` + `Extension`, no spaces | `ServiceTradeExtension` |
| `{{EXT_VERSION}}` | start at `1.0.0` | `1.0.0` |
| `{{ONE_LINE_PURPOSE}}` | one sentence | `Krista integration with the ServiceTrade field-service platform.` |

## Package & group

| Placeholder | How to derive | Example |
|---|---|---|
| `{{ECOSYSTEM_NAME}}` | ecosystem display | `Essentials` |
| `{{DOMAIN_NAME}}` | domain display | `Field Service Management` |
| `{{PACKAGE}}` | `app.krista.extensions.<ecosystem>.<domain>.<name>`, lowercased, spaces removed | `app.krista.extensions.essentials.fieldservicemanagement.servicetrade` |
| `{{PACKAGE_PATH}}` | `{{PACKAGE}}` with `.`→`/` | `app/krista/extensions/essentials/fieldservicemanagement/servicetrade` |
| `{{GROUP}}` | `app.krista.extensions.<Ecosystem>.<Domain>` (display casing, spaces removed) | `app.krista.extensions.Essentials.FieldServiceManagement` |

## @Domain identifiers  (PLATFORM-REGISTERED & SHARED — do NOT invent)

`domainId` + `ecosystemId` + `ecosystemName` are **registered, shared** identifiers — two different
extensions in the same domain carry byte-identical values (github & jira share
`catEntryDomain_7edc1712-…`/`catEntryEcosystem_98c365b2-…`; salesforce & connect-wise share
`catEntryEcosystem_8a0e8ce7-…`). A random UUID compiles but will NOT bind to the real domain.

| Placeholder | Where it comes from |
|---|---|
| `{{DOMAIN_ID}}` | **Copy from a sibling extension** in the same domain, or register a new domain in Krista. `git grep '@Domain' origin/release/<sibling>` |
| `{{DOMAIN_NAME}}` | the registered domain display name (e.g. "Development", "CRM") — must match the sibling |
| `{{ECOSYSTEM_ID}}` | copy from a sibling in the same ecosystem (registered) |
| `{{ECOSYSTEM_NAME}}` | the registered ecosystem name (e.g. "Dev Sec Ops", "Essentials", "CRM") |
| `{{ECOSYSTEM_VERSION}}` | the one loose value — varies per file; a stable UUID is fine |

Within one extension the block (`{{DOMAIN_ID}}`/`{{DOMAIN_NAME}}`/`{{ECOSYSTEM_ID}}`/`{{ECOSYSTEM_NAME}}`)
is the SAME on every Area and Entity; only `{{ECOSYSTEM_VERSION}}` varies.

**If you cannot obtain the real IDs yet:** mint stable placeholder UUIDs so the code compiles, but in
Phase 7 report them explicitly as **must-replace-before-deploy** — the extension will not bind to the
platform catalog until they are the real registered values.

`{{REQUEST_ID}}` (`localDomainRequest_`) and entity IDs (`localDomainEntity_`) are the opposite: **local
to the extension → random-with-prefix is correct**, needing only uniqueness + stability across releases
(prefer `uuid5` of `"<ext>.<area>.<method>"`). Never treat these like the domain/ecosystem IDs.

## Catalog requests / areas

| Placeholder | How to derive |
|---|---|
| `{{AREA_CLASS}}` | `<Group>Area`, e.g. `JobArea` |
| `{{AREA_LABEL}}` / `{{AREA_NAME}}` | the `@CatalogRequest(area=...)` grouping label |
| `{{REQUEST_ID}}` | `localDomainRequest_<uuid>` (unique per request; `uuid5` of `"<ext>.<area>.<method>"` for stability) |
| `{{REQUEST_NAME}}` | request display name |
| `{{REQUEST_METHOD}}` | camelCase Java method name from the request name |
| request `type` | GET→`QUERY_SYSTEM`; POST/PUT/DELETE→`CHANGE_SYSTEM`; event trigger→`WAIT_FOR_EVENT` |
| `{{ENTITY_NAME}}` / `{{ENTITY_CLASS}}` | entity display name / Java class |

## Integration / auth class names

| Placeholder | Example |
|---|---|
| `{{ATTRS_CLASS}}` | `ServiceTradeAttributes` |
| `{{ATTR_STORE_CLASS}}` | `ServiceTradeAttributeStore` |
| `{{CLIENT_CLASS}}` | `ServiceTradeClient` |
| `{{SERVICE_CLASS}}` | `ServiceTradeAreaService` (or inject the client directly) |
| `{{AUTH_CLASS}}` | `ServiceTradeRequestAuthenticator` |
| `{{APP_CLASS}}` / `{{WEBHOOK_RESOURCE_CLASS}}` / `{{CALLBACK_RESOURCE_CLASS}}` | `ServiceTradeApplication` / `ServiceTradeWebhookResource` / `ServiceTradeAuthCallbackResource` |
| MS-SDK: `{{AUTH_CONFIG_CLASS}}` / `{{DESCRIPTOR_CLASS}}` / `{{MSAUTH_AUTHENTICATOR_CLASS}}` / `{{EXT_TYPE}}` | `ServiceTradeAuthConfig` / `ServiceTradeExtensionDescriptor` / `ServiceTradeRequestAuthenticator` / `servicetrade` |

## Build

| Placeholder | Value |
|---|---|
| `{{KRISTA_APIS_VERSION}}` | `1.0.126` (≥ `1.0.125-sp1` if any `tool = true`) |
| `{{SONAR_KEY}}` | `sonar-scanner-<module>` |
| `{{EVENT_NAME}}` / `{{PAYLOAD_KEY}}` | webhook event discriminator + payload key |
