<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > Entity requests

# Entity requests (`@EntityRequest`)

## Overview

`@EntityRequest` declares **entity CRUD and lookup operations** used by the platform to create, retrieve, search, and manage entities your extension exposes.

Entity requests are different from catalog requests:

- Catalog requests are user-invoked operations.
- Entity requests define **entity-level behaviors** (create/search/get/delete/etc.) for a specific entity type.

> **Note**: Exact supported signatures and entity capabilities can vary by platform version.

## Annotation

- **Annotation**: `@EntityRequest`
- **Package**: `app.krista.extension.impl.anno.EntityRequest`
- **Parameter**: `type()` — `EntityRequest.Type` (required)

## Entity request types

| Type | Purpose | Typical signature | Notes |
|------|---------|-------------------|-------|
| `CREATE` | Create a new entity | `String method(EntityType type, EntityAttributeField attributes)` | Returns created entity ID |
| `UPDATE` | Update an existing entity | `Object method(EntityType type, Object entityId)` | Update logic varies by entity model |
| `GET` | Retrieve an entity by ID | `Object method(EntityType type, String entityId)` | Return the entity object |
| `SEARCH` | Search entities | `List<Object> method(EntityType type, SearchQuery query, Long fetchSize, Integer pageNumber)` | Implement pagination consistently |
| `DELETE` | Delete an entity by ID | `void method(EntityType type, String entityId)` | Prefer idempotent delete |
| `LOOKUP` | Find entity by attributes | `Object method(EntityType type, EntityAttributeField attributes, Object context)` | Commonly used for "find-or-create" flows |
| `SUPPORTS` | Declare supported operations | `Boolean method(EntityType type, Object operation, Object context)` | Return `false` for unsupported operations |
| `CONTAINS` | Check if entity exists | `Boolean method(EntityType type, String entityId)` | Useful for validation / references |

## Usage examples

### Create

```java
@EntityRequest(type = EntityRequest.Type.CREATE)
public String create(EntityType entityType, EntityAttributeField attributes) {
  String name = attributes.getString("Name");
  // call external system + persist mapping if needed
  return externalId;
}
```

### Search

```java
@EntityRequest(type = EntityRequest.Type.SEARCH)
public List<Object> search(EntityType entityType, SearchQuery query, Long fetchSize, Integer pageNumber) {
  // map SearchQuery to external search/filter semantics
  // return a page of results
  return results;
}
```

### Get / Delete

```java
@EntityRequest(type = EntityRequest.Type.GET)
public Object get(EntityType entityType, String entityId) {
  return externalApi.get(entityId);
}

@EntityRequest(type = EntityRequest.Type.DELETE)
public void delete(EntityType entityType, String entityId) {
  externalApi.delete(entityId);
}
```

## Design guidance

### Validation

1. Validate required identifiers and key attributes.
2. Fail fast with user-actionable messages (when surfaced).
3. Avoid logging sensitive entity attributes.

### Pagination

For `SEARCH`, be consistent about:

- `fetchSize` (page size)
- `pageNumber` (page index/number)
- stable ordering (to avoid duplicates/missed results)

See: [Performance: Pagination and batching](../performance/PaginationAndBatching.md)

### Idempotency

- Make `DELETE` idempotent where possible.
- For `CREATE`, avoid accidental duplicates (use LOOKUP patterns or external idempotency keys if available).

## Best practices

1. **Keep entity representations stable**: changing field names can break saved configurations and references.
2. **Separate concerns**: put external API calls in an integration client; keep the handler thin.
3. **Return predictable structures**: prefer well-defined entity models (records/classes) over raw maps.
4. **Handle not-found cleanly**: distinguish "not found" from "system failure".

## See also

- [Concepts: Entities and catalog requests](../concepts/EntitiesAndCatalogRequests.md)
- [Development: Catalog requests](../development/catalog-requests/README.md)
- [Operations: Error handling](../operations/ErrorHandling.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
