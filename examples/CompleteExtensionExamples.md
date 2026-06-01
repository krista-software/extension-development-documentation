<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Examples](README.md) > Complete extension examples

# Complete extension examples

## Overview

This page outlines end-to-end example patterns you can adapt when building a real extension.

## Example 1: Simple REST API extension (shape)

A minimal extension typically includes:

- `@Extension` + `@Domain` on the main class
- Setup tab attributes (for example API URL and API Key)
- invoker lifecycle hooks (`INVOKER_LOADED`, `VALIDATE_ATTRIBUTES`)
- at least one `QUERY_SYSTEM` catalog request

## Example 2: CRUD-style extension (shape)

A CRUD-style extension typically provides:

- `QUERY_SYSTEM` requests (list/get/search)
- `CHANGE_SYSTEM` requests (create/update/delete)
- shared sub-catalog requests for validation/lookups
- consistent entity models for returned objects

## Example 3: Event-driven extension (shape)

An event-driven extension typically provides:

- `WAIT_FOR_EVENT` requests
- webhook subscription or polling integration
- clear timeout/interval configuration

## See also

- [Catalog requests](../development/catalog-requests/README.md)
- [Java 21 patterns](../development/Java21Patterns.md)
- [Error handling](../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
