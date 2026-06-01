<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > Extension annotations

# Extension annotations

## Overview

Krista extensions use annotations to declare metadata (extension, domain), expose operations (catalog requests), and define inputs/outputs (fields).

This page is a high-level reference. Use it to find what annotation to use and where it typically belongs in the architecture.

## Core annotations

### `@Extension`

Declares the extension’s identity and platform behavior (name, version, supported execution modes, etc.).

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

Declares inputs/fields (for example text, number, boolean, entity references). Use required flags and secured fields to guide Setup tab behavior and request validation.

## Deployment/runtime annotations

### `@Java`

Declares the Java runtime requirement (for example `JAVA_21`).

## Best practices

1. Keep Krista annotations in controller/area and extension entry points; keep integration code framework-free.
2. Use stable, user-friendly field names; changing names can break saved configurations.
3. Avoid logging secured fields.

## See also

- [Catalog requests](../development/catalog-requests/README.md)
- [Catalog request types](../development/catalog-requests/CatalogRequestTypes.md)
- [Project structure](../development/ProjectStructure.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
