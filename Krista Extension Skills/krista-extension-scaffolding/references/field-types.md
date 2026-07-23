# Field types — the `@Field.*` input/output grammar

Catalog-request inputs, catalog-request outputs, connection fields, and entity fields all use the
`app.krista.extension.impl.anno.Field` family. This is the single most error-prone area, so the exact
forms below are copied verbatim from shipping extensions.

## The variants

| Annotation | Java type of the value | Notes |
|---|---|---|
| `@Field.Text(name=, required=, isSecured=, description=, attributes={}, options={})` | `String` | `isSecured=true` for secrets; on the extension class use `value=` for the key |
| `@Field.Boolean(name=, required=, ...)` | `Boolean`/`boolean` | |
| `@Field.Date(name=, required=, includeTimeOfDay=, allowPast=, allowToday=, allowFuture=, ...)` | `Long` (epoch millis) | |
| `@Field.File(name=, multipleFileUpload=, required=, ...)` | `app.krista.model.base.File` | to read/write the bytes use `KristaMediaClient`/`FileRepository` — see business-logic `file-handling.md` |
| `@Field.PickOne(name=, values={"A","B"}, required=, ...)` | `String` | fixed dropdown |
| `@Field.Desc(name=, type="<TYPE-STRING>", required=, description=)` | matches the type string (see below) | composite / entity / list carrier |
| `@Field(name=, type="<TYPE-STRING>", required=, attributes={}, options={})` | matches the type string | generic form for scalar type strings |

## Scalar `type="..."` strings (used by the generic `@Field` and `@Field.Desc`)

`Text`, `Number` (Java `Double`), `Paragraph` (multi-line text), `RichText`, `FreeForm`
(`app.krista.model.base.FreeForm` — arbitrary JSON/map), `Identifier`, `Date`, `Email`, `Phone`,
`Currency`, `Percentage`, `Time`.

## Composite / entity `type="..."` string DSL (`@Field.Desc`)

Spacing is significant and consistent — a single space inside `[ ]` and `{ }`, and `Key: Type` with a
space after the colon.

| Shape | `type` string | Java param/return type |
|---|---|---|
| List of scalars | `"[ Text ]"` | `List<String>` |
| Single entity | `"Entity(Issue)"` | `Entity` class or `ExtensionResponse` |
| List of entities | `"[ Entity(Issue) ]"` | `List<Entity>` or `ExtensionResponse` |
| Inline object | `"{ Id: Text, Summary: Text, Done: Boolean }"` | `Map<String,Object>` |
| List of inline objects | `"[ { key: Text, value: Text } ]"` | `List<Map<String,Object>>` |
| Object with a file | `"{ key: Text, value: Text, file: File }"` | `Map<String,Object>` |
| Opaque composite list | `"[ Composite ]"` | `Map<String,Object>` / `List<...>` |

The name inside `Entity(...)` is the **`@Entity` display name** — spaces allowed, e.g.
`"[ Entity(Company Ticket Analysis By Status) ]"`.

## `@Attribute` decorations (inside `attributes = { ... }`)

- `@Attribute(name = "visualWidth", value = "S" | "M" | "L" | "XL")` — UI column width.
- `@Attribute(name = "toolTip", value = "'hover text'")` — note the **single-quoted string inside** the double-quoted value.
- `@Attribute(name = "dateFormat", value = "'MMM DD, yyyy h:mm:ss a'")` — same single-quote-inside rule.
- `@Attribute(name = "isSecured", value = "true")` — the generic-`@Field` way to secure (equivalent to `@Field.Text(isSecured=true)`).

Empty decoration is `attributes = {}`. Always pair with `options = {}` (observed on nearly every field).

## Where each is used

- **Connection fields** (extension class): repeated `@Field.Text(value = KEY, ...)` / `@Field.PickOne` / `@Field.Boolean`. Use `value=` (the attribute key constant), plus `isSecured`/`required`.
- **Catalog-request inputs** (method parameters): one `@Field.*` per parameter, using `name=`.
- **Catalog-request outputs** (method-level, above the signature): `@Field.Desc(...)` for composite/entity outputs, or typed `@Field.Text/.Boolean/.File` / generic `@Field(type="Number"|"FreeForm")` for scalar outputs. A request may declare several output fields.
- **Entity fields**: `@Searchable`/`@ToString` markers + a `@Field.*`.

## Worked examples (verbatim)

Input mix (text + date + number):
```java
public ExtensionResponse searchTickets(
    @Field.Text(name = "Company ID", required = false, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) String companyId,
    @Field.Date(name = "From Date", required = false, attributes = {@Attribute(name = "visualWidth", value = "M")}, options = {}) Long fromDate,
    @Field(name = "Max Results", type = "Number", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) Double maxResults) { ... }
```

Entity-list output + count:
```java
@Field.Desc(name = "Companies", type = "[ Entity(Company) ]", required = false)
@Field(name = "Count", type = "Number", required = false, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})
public ExtensionResponse searchCompanies( ... ) { ... }
```

Composite input (list of key/value) + composite output:
```java
@Field.Desc(name = "Response", type = "[ Composite ]", required = false)
public Map<String, Object> getWithFilters(
    @Field(name = "URL", type = "Text", required = true, attributes = {}, options = {}) String url,
    @Field.Desc(name = "QueryParameters", type = "[ { key: Text, value: Text } ]", required = true) List<Map<String, Object>> queryParameters) { ... }
```

File input + FreeForm output:
```java
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse addAttachmentToTicket(
    @Field.Text(name = "Ticket ID", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {}) String ticketId,
    @Field.File(name = "File", required = true, attributes = {}, options = {}) File file) { ... }
```
