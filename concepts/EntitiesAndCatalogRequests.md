<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Concepts](README.md) > Entities and catalog requests

# Entities and catalog requests

## Overview

**Catalog requests** are the operations your extension exposes to Krista, and **entities** are the structured data models those operations return and manipulate.

## Catalog requests

Catalog requests are the primary way extensions interact with external systems.

### Catalog request types

- **CHANGE_SYSTEM**: modifies external system state (create/update/delete, trigger workflows)
- **QUERY_SYSTEM**: reads data without modification (search, list, retrieve)
- **WAIT_FOR_EVENT**: waits for external events (polling, webhooks, condition monitoring)

### Best practices

1. Validate inputs before calling external APIs.
2. Use meaningful, user-focused error messages.
3. Keep each request focused on one operation.
4. Return structured data using entities (avoid returning raw external payloads).

### Sub-catalog requests

Sub-catalog requests are helper methods used to break complex operations into reusable pieces. They are not exposed as user-facing operations.

## Entities

Entities represent external system concepts within the Krista platform. They define the data structures that:

- are stored and displayed by the platform
- can be returned from catalog requests
- can be referenced by other requests

### Entity best practices

1. Prefer immutable structures (for example Java records).
2. Include basic validation (constructors/factories) for critical invariants.
3. Use business-friendly field names.

## Relationship between requests and entities

A common flow is:

1. Catalog request handler validates inputs
2. Integration layer calls the external system
3. Transformation converts external models → Krista entities
4. Response returns entities + useful metadata

## See also

- [Architecture](../architecture/README.md)
- [Catalog requests (development)](../development/catalog-requests/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
