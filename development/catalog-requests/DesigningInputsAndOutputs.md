<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../../kristaLogo.png)

**Breadcrumbs:** [Home](../../index.md) > [Development](../README.md) > [Catalog requests](README.md) > Designing inputs and outputs

# Designing inputs and outputs

## Overview

A catalog request’s inputs and outputs are a contract. Treat them as stable public API: name them clearly, validate them early, and return structured outputs that remain consistent over time.

## Input design

### Prefer stable, user-friendly names

1. Use business-friendly names (for example “Project Key”, not “projKey”).
2. Avoid renaming fields after release; saved configurations and automations often depend on them.

### Make required vs optional explicit

- Mark truly required inputs as required.
- For optional fields, document defaults and behavior when omitted.

### Keep types predictable

- Prefer simple scalar types for request parameters (text/number/boolean/date) unless you truly need an entity reference.
- If a parameter is an ID, document the format (and validate it).

### Add an idempotency input for state-changing requests

For `CHANGE_SYSTEM`, consider adding an idempotency key (or request ID) so retries do not create duplicates.

## Output design

### Return structured entities (not raw external payloads)

- Transform external API responses into stable entities/DTOs.
- Avoid exposing vendor-specific field names unless they are part of your intended contract.

### Use stable top-level keys

If you return a list, prefer a stable key such as `items` or a domain-specific key such as `tickets`, and keep it consistent across versions.

### Include useful metadata

Common metadata examples:

- `count` (number of returned items)
- paging tokens (`nextPageToken`)
- request identifiers for support/debugging

### Use warnings intentionally

If partial results are possible (for example some items failed to load), return success with warnings rather than failing the entire request.

## Checklist

- [ ] Parameter names are stable and user-friendly
- [ ] Required vs optional is explicit
- [ ] IDs and formats are validated
- [ ] `CHANGE_SYSTEM` requests have an idempotency strategy
- [ ] Outputs are entities/DTOs, not raw vendor payloads
- [ ] Metadata includes counts/paging where relevant

## See also

- [Implement a catalog request](ImplementCatalogRequest.md)
- [Validation and error mapping](ValidationAndErrorMapping.md)
- [Retry and idempotency](RetryAndIdempotency.md)
- [Entities and catalog requests (concepts)](../../concepts/EntitiesAndCatalogRequests.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../../LICENSE).
