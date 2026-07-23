# Extension structure

## Package & group naming

Real extensions use a reverse-DNS package rooted at `app.krista.extensions` with the ecosystem and
domain in the path, then the extension name:

```
app.krista.extensions.<ecosystem>.<domain>.<name>
```

Observed examples (verbatim from the branches):

| Extension | Package root | Gradle `group` |
|---|---|---|
| autotask | `app.krista.extensions.essentials.itservicemanagement.autotask` | `app.krista.extensions.Essentials.ITServiceManagement` |
| salesforce_sales | `app.krista.extensions.crm.sales.salesforce_sales` | `app.krista.extensions.crm.sales` |
| servicenow | `app.krista.extensions.it.case_management.servicenow` | `app.krista.extensions.it.case_management` |
| restapi | `app.krista.extensions.development.api.rest` | `app.krista.extensions.development.api.rest` |
| outlook-4 | `app.krista.extensions.essentials.collaboration.outlook4` | `app.krista.extensions.essentials.collaboration` |
| jira | `app.krista.extensions.devsecops.development.jira` | `com.kristasoft.extensions.dev_sec_ops.development` |
| connect-wise | `com.xpertechs` | `app.krista.extensions.crm.customerRelations` |

The `group` need not equal the package (third-party authors like `com.xpertechs` keep their own
package but still publish under an `app.krista.extensions.*` group). Prefer the `app.krista.extensions.<ecosystem>.<domain>.<name>` convention for new first-party extensions.

## Directory layout (canonical)

```
<module>/
├── build.gradle
├── release.properties               # generated from annotations at build time
├── settings.gradle                  # only if the module builds standalone
└── src/
    ├── main/
    │   ├── java/<package-path>/
    │   │   ├── <Name>Extension.java          # @Extension entry point
    │   │   ├── <Name>Attributes.java         # @Service connection config
    │   │   ├── api/                          # JAX-RS: Application + resources (auth callback, webhook)
    │   │   ├── catalog/
    │   │   │   ├── <Something>Area.java       # @Domain + @CatalogRequest methods
    │   │   │   ├── entities/                  # @Entity classes
    │   │   │   └── stores/                    # @Service EntityStore<T> impls
    │   │   ├── authentication/  or  auth/     # RequestAuthenticator, OAuth service, token stores
    │   │   ├── impl/ or system/ or connectors/ or infrastructure/  # HTTP client, DAOs (business logic)
    │   │   ├── service/                       # service-layer interfaces + impls
    │   │   └── util/ , constants/             # helpers, key constants
    │   └── resources/
    │       ├── docs/  (or documentations/)    # bundled Docsify site (the Documentation tab)
    │       ├── META-INF/services/...          # ServiceLoader files (e.g. MsAuthExtensionDescriptor)
    │       └── log4j2.xml
    └── test/java/<package-path>/
```

The layered convention (controller → service → integration → transformation → entity) is described
in the platform docs; this skill only fixes the framework-facing files (controller/Area, extension,
attributes, api, entities/stores).

## `@Domain` identifiers

Every Area class and every `@Entity` carries a `@Domain(...)` with five string members:

```java
@Domain(id = "catEntryDomain_<uuid>",
        name = "<Domain display name>",           // e.g. "Sales", "IT Service Management"
        ecosystemId = "catEntryEcosystem_<uuid>",
        ecosystemName = "<Ecosystem display name>", // e.g. "CRM", "Essentials", "Dev Sec Ops"
        ecosystemVersion = "<uuid>")
```

### Two classes of ID — do NOT treat them the same

**`domainId` + `ecosystemId` + `ecosystemName` are platform-REGISTERED and SHARED — never random.**
Proven across branches: two *different* extensions in the same domain carry byte-identical values —
github and jira both use `catEntryDomain_7edc1712-…` ("Development") + `catEntryEcosystem_98c365b2-…`
("Dev Sec Ops"); salesforce and connect-wise both use `catEntryEcosystem_8a0e8ce7-…` ("CRM"). So:
- **Joining an existing ecosystem/domain** (CRM, Essentials, Dev Sec Ops, Field Service Management, …):
  copy the **exact** `id`, `name`, `ecosystemId`, `ecosystemName` from a sibling extension already in
  that domain — `git grep '@Domain' origin/release/<sibling>`. Do not invent them.
- **A genuinely new domain/ecosystem**: it must be **registered in Krista** to obtain valid IDs.
- A random UUID here **compiles** (they are just annotation strings) but the extension **will not bind
  to the real domain/ecosystem** in the catalog — requests won't surface under the right domain and
  provisioning may reject it. Use a placeholder only as a temporary compile-time stand-in, and flag it.
- `ecosystemVersion` is the one loose value — it varies per file across the branches.

**`localDomainRequest_<uuid>` (catalog requests) and `localDomainEntity_<uuid>` (entities) ARE local —
random-with-prefix is fine.** They just need to be **unique** within the extension and **stable across
releases** (never change a shipped id — it orphans references). Keep the fixed prefix; the UUID can be
generated (prefer a deterministic `uuid5` of `ext.area.method` so regeneration is stable).

Other rule: within one extension the domain block (`id`/`name`/`ecosystemId`/`ecosystemName`) is
**constant** across every Area and Entity; only `ecosystemVersion` varies per file.

The `build.gradle` `generateReleaseProperties` task reads `name` and `ecosystemName` from the
`@Domain` on one nominated Area file — so at least one Area must carry the annotation.

## What determines the jar name

`release.properties` `extension.name` (whitespace stripped) + `extension.version` →
`<Name>-<version>.jar`. Both are scraped from the `@Extension` annotation. See
`build-and-release.md`.
