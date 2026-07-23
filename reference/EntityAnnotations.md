<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > Entity annotations

# Entity annotations

## Overview

Entity annotations declare the structure and metadata of entities your extension exposes. The platform uses these declarations for catalog display, search, and entity storage.

## `@Entity`

Declares an entity class.

Key parameters:

- `name` — display name (for example "Issue", "Event Details", "Drive File")
- `id` — unique entity identifier (UUID format, prefixed with `localDomainEntity_`)
- `primaryKey` — name of the field that uniquely identifies an instance
- `supportStore` — whether the platform persists entity instances (`true` or `false`)
- `description` — optional human-readable description
- `options` — additional entity options (typically `{}`)

Typical location: entity/DTO classes annotated alongside `@Domain`.

## `@Searchable`

Marks an entity field as searchable in catalog queries. Can be applied at class level (all fields searchable) or at individual field level.

## `@ToString`

Marks a field to be included in the entity's string representation. Useful for logging and display.

## Field annotations on entities

Entity fields use the same `@Field.*` annotations as catalog request parameters:

- `@Field.Text` — string properties
- `@Field.Boolean` — boolean properties
- `@Field` — typed properties (for example `type = "RichText"`, `type = "Number"`)

## Referencing entities from catalog requests

Use `@Field.Desc` to declare entity-typed outputs:

- Single entity: `type = "Entity(Issue)"`
- Entity list: `type = "[ Entity(Event Details) ]"`

The field name in the response map must match the annotation name exactly.

## Design guidance

1. **Use stable field names** — renaming breaks saved configurations and references.
2. **Set a meaningful `primaryKey`** — choose the natural business identifier.
3. **Prefer `supportStore = false`** unless the platform needs to persist your entities.
4. **Keep entities immutable** — prefer Java records or final-field classes.
5. **Annotate searchable fields explicitly** — only mark fields that are useful for filtering.

## See also

- [Extension annotations](ExtensionAnnotations.md)
- [Entity requests (`@EntityRequest`)](EntityRequests.md)
- [Concepts: Entities and catalog requests](../concepts/EntitiesAndCatalogRequests.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
