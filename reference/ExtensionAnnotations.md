<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > Extension annotations

# Extension annotations

## Overview

Krista extensions use annotations to declare metadata (extension, domain), expose operations (catalog requests), and define inputs/outputs (fields).

This page is a high-level reference. Use it to find what annotation to use and where it typically belongs in the architecture.

## Core annotations

### `@Extension`

Declares the extension’s identity and platform behavior.

Key parameters:

- `name` — display name
- `version` — semantic version (X.Y.Z)
- `description` — human-readable description
- `jaxrsId` — JAX-RS application identifier for REST endpoints
- `implementationModel` — framework model (`Krista_4_O` or `Krista_4_1`)
- `supportingModes` — execution modes the extension supports (for example `ExecutionMode.LIVE`)
- `requireWorkspaceAdminRights` — restrict installation to workspace admins
- `implementingDomainIds` — domain IDs the extension implements (used by agent-style extensions)

Typical location: the main extension class.

### `@Domain` (and `@Domains`)

Declares one or more domains implemented by the extension.

Typical location: the main extension class.

### `@CatalogRequest`

Declares a user-invokable operation exposed by the extension.

Key fields include:

- `name`: display name
- `area`: grouping label
- `type`: `QUERY_SYSTEM`, `CHANGE_SYSTEM`, or `WAIT_FOR_EVENT`

Typical location: controller/Area classes.

### `@ApiRequest`

Declares a protocol-level API handler (for example inbound webhooks or a health/status endpoint).

See: [API requests (`@ApiRequest`)](ApiRequests.md)

### `@EntityRequest`

Declares entity CRUD/lookup operations for entities exposed by the extension.

See: [Entity requests (`@EntityRequest`)](EntityRequests.md)

### `@SubCatalogRequest`

Declares a helper operation used by other requests (not a primary user-facing request).

### `@Field.*`

Declares inputs/fields. Available variants:

- `@Field.Text` — text input (`isSecured = true` for passwords/API keys)
- `@Field.Boolean` — toggle/checkbox
- `@Field.Date` — date picker (with `includeTimeOfDay`, `allowPast`, `allowFuture`, `showHowManyDaysInViewer`, `defaultTimeSpan`)
- `@Field.File` — file upload (`multipleFileUpload = true` for multiple files)
- `@Field.PickOne` — dropdown selection (`values = {"A", "B", "C"}`)
- `@Field.Desc` — descriptive/complex types (Entity, lists, composites)
- `@Field` — generic field with explicit `type` parameter

Common `@Attribute` decorations:

- `visualWidth` — display width (`"S"`, `"M"`, `"L"`, `"XL"`)
- `toolTip` — hover text providing field guidance

### `@Entity`

Declares an entity class exposed by the extension.

Key parameters:

- `name` — entity display name
- `id` — unique entity identifier (UUID)
- `primaryKey` — field name used as the primary key
- `supportStore` — whether the platform should store entity instances
- `description` — human-readable description
- `options` — additional entity options

Related field-level annotations:

- `@Searchable` — marks a field as searchable in catalog queries
- `@ToString` — marks a field for string representation

Typical location: entity/DTO classes in the `entity/` or `catalog/entities/` package.

## Deployment/runtime annotations

### `@Java`

Declares the Java runtime requirement (for example `JAVA_21`).

## Best practices

1. Keep Krista annotations in controller/area and extension entry points; keep integration code framework-free.
2. Use stable, user-friendly field names; changing names can break saved configurations.
3. Avoid logging secured fields.

## See also

- [Entity annotations](EntityAnnotations.md)
- [Catalog requests](../development/catalog-requests/README.md)
- [Catalog request types](../development/catalog-requests/CatalogRequestTypes.md)
- [Designing inputs and outputs](../development/catalog-requests/DesigningInputsAndOutputs.md)
- [Project structure](../development/ProjectStructure.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
