# Annotations cheatsheet

All annotations are in `app.krista.extension.impl.anno.*` unless noted. Members below are the exact
names/enums observed in shipping extensions.

## `@Extension` (on the main class — exactly one)

```java
@Extension(
    name = "...",                 // required — display name; jar base name
    version = "...",              // required — semver; jar version + release.properties
    description = "...",          // optional
    jaxrsId = "...",              // optional — mounts JAX-RS resources under rest/<jaxrsId>/ ; default "rest"
    implementationModel = Extension.ImplementationModel.Krista_4_O,  // optional; needs @Containerize
    implementingDomainIds = "catEntryDomain_...",  // optional — auth-provider/agent extensions
    requireWorkspaceAdminRights = true             // optional — auth providers
)
```

Companion class-level annotations almost always present:

```java
@Java(version = Java.Version.JAVA_21)                 // required in practice
@StaticResource(path = "docs", file = "docs")         // bundles src/main/resources/<file> as the docs site; "file" is the folder name
@ChangeLog(file = "docs/pages/releaseNotes.md")       // optional — surfaces release notes tab; path relative to resources
@Containerize(baseImageVersion = "3.6.2-sp3")         // REQUIRED when implementationModel = Krista_4_O
```

Connection fields are declared as repeated class-level `@Field.Text` (see field-types.md):

```java
@Field.Text(value = MyAttributes.CLIENT_ID)
@Field.Text(value = MyAttributes.CLIENT_SECRET, isSecured = true)
@Field.Text(value = MyAttributes.BASE_URL, required = false)
@Field.PickOne(name = MyAttributes.AUTH_TYPE, values = {"Oauth", "BasicAuth"})   // servicenow style
@Field.Boolean(value = MyAttributes.SANDBOX, required = false)
```

## `@InvokerRequest(InvokerRequest.Type.X)` (lifecycle / platform hooks, on extension-class methods)

| Type | Signature | Purpose |
|---|---|---|
| `CUSTOM_TABS` | `Map<String,String> m()` | Setup-tab tabs → `Map.of("Documentation","static/docs", ...)` |
| `VALIDATE_ATTRIBUTES` | `void m(Map<String,Object> attrs)` | validate config before save (throw to reject) |
| `TEST_CONNECTION` | `void m()` | Test-Connection button |
| `INVOKER_UPDATED` | `void m(Map old, Map new)` | config changed → `attributes.update(new)` |
| `INVOKER_LOADED` / `INVOKER_UNLOADED` / `INVOKER_REMOVED` | `void m()` (loaded takes `Map`) | lifecycle |
| `AUTHENTICATOR` | `RequestAuthenticator m()` | register the request authenticator (interactive auth) |
| `REGISTER_EVENT_LISTENER` / `UNREGISTER_EVENT_LISTENER` | `void m(WaitForEventListener l)` | WAIT_FOR_EVENT plumbing (often SDK-handled) |

Most REST extensions use only `CUSTOM_TABS`, `VALIDATE_ATTRIBUTES`, `TEST_CONNECTION`, `INVOKER_UPDATED`.

## `@Domain` (on each Area class and each `@Entity`)

```java
@Domain(id = "catEntryDomain_<uuid>", name = "...",
        ecosystemId = "catEntryEcosystem_<uuid>", ecosystemName = "...",
        ecosystemVersion = "<uuid>")
```

## `@CatalogRequest` (on Area methods — one per operation)

```java
@CatalogRequest(
    id = "localDomainRequest_<uuid>",   // required, unique
    name = "...",                        // required — display name
    description = "...",
    area = "...",                        // grouping label within the domain
    type = CatalogRequest.Type.QUERY_SYSTEM,  // QUERY_SYSTEM | CHANGE_SYSTEM | WAIT_FOR_EVENT
    tool = true)                         // optional — expose as an AI-agent (MCP) tool
```
- GET-like reads → `QUERY_SYSTEM`; creates/updates/deletes/actions → `CHANGE_SYSTEM`; event triggers → `WAIT_FOR_EVENT`.
- **Output** = `@Field.*` annotations placed on the method (between `@CatalogRequest` and the signature).
- **Input** = `@Field.*` annotations on each method parameter.
- Return type: `app.krista.extension.executor.ExtensionResponse` (preferred), or a concrete `List<Entity>` / `Map<String,Object>` / `String` / `app.krista.model.base.File`.

## `@Entity` (on entity classes)

```java
@Searchable                              // class-level marker
@Domain(...)                             // as above
@Entity(name = "...", id = "localDomainEntity_<uuid>", primaryKey = "<field display name>",
        supportStore = true, description = "...", options = {})
```
Field-level: `@Searchable` (searchable), `@ToString` (part of display/toString), plus a `@Field.*`.
`supportStore = true` requires a matching `@Service EntityStore<T>` (see EntityStore.java.template).

## `@Field.*` (inputs, outputs, connection fields, entity fields)

See `field-types.md` for the full grammar. Variants: `@Field.Text`, `@Field.Boolean`, `@Field.Date`,
`@Field.File`, `@Field.PickOne`, `@Field.Desc` (composite/entity types via a `type="..."` string),
and the generic `@Field(name=, type=, ...)`. Decorate with `@Attribute(name=, value=)` inside
`attributes = { ... }`; empty is `attributes = {}, options = {}`.

## DI & JAX-RS packages (get these right)

- `org.jvnet.hk2.annotations.Service` — marks an injectable bean.
- `org.jvnet.hk2.annotations.ContractsProvided` — on the JAX-RS `Application` subclass.
- `javax.inject.Inject` / `javax.inject.Named` — constructor injection (`@Named("self") Invoker`).
- `javax.ws.rs.*` — JAX-RS (`@Path`, `@POST`, `@GET`, `@ApplicationPath`, `@Consumes`, `@QueryParam`). **Not `jakarta`.**
- `app.krista.extension.executor.{Invoker, ExtensionResponse}`, `app.krista.extension.executor.ExtensionResponseBuilder`.
- `app.krista.extension.authorization.{RequestAuthenticator, MustAuthorizeException, MustAuthenticateException}`.
- `app.krista.extensions.util.{EventHandler, KeyValueStore}`, `app.krista.model.base.{FreeForm, File}`.
- `app.krista.extension.util.EntityStore`, `app.krista.extension.executor.{SearchQuery, SearchCondition, QueryClause}`.
