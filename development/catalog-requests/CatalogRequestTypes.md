<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../../kristaLogo.png)

**Breadcrumbs:** [Home](../../index.md) > [Development](../README.md) > [Catalog requests](README.md) > Catalog request types

# Catalog request types

## Overview

Catalog request **types** communicate intent (read vs write vs wait) and guide user expectations around retries, side effects, and error handling.

## Types

### QUERY_SYSTEM

Use `QUERY_SYSTEM` when the request:

- reads data from an external system
- does not change external state

Typical examples: list, search, get-by-id, validate configuration.

### CHANGE_SYSTEM

Use `CHANGE_SYSTEM` when the request:

- creates/updates/deletes external resources
- triggers workflows
- sends messages/notifications

Typical examples: create ticket, update status, delete resource.

### WAIT_FOR_EVENT

Use `WAIT_FOR_EVENT` when the request:

- waits until a condition becomes true (polling)
- waits for an external callback (webhook)
- monitors status changes

Typical examples: wait for build completion, wait for approval, wait for delivery.

## Choosing the right type

| If your request… | Use | Why |
|---|---|---|
| only reads state | `QUERY_SYSTEM` | safe to retry; no side effects |
| changes state | `CHANGE_SYSTEM` | users expect side effects and careful retries |
| waits for something to happen | `WAIT_FOR_EVENT` | different UX and time semantics |

## Retry and idempotency guidance

- Prefer idempotent `CHANGE_SYSTEM` requests when possible (request can be safely retried).
- If the external API is not idempotent, design inputs to make it idempotent (for example: idempotency keys).
- For `WAIT_FOR_EVENT`, implement timeouts and clear “still waiting” responses.

## See also

- [Implement a catalog request](ImplementCatalogRequest.md)
- [Entities and catalog requests (concepts)](../../concepts/EntitiesAndCatalogRequests.md)
- [Error handling](../../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../../LICENSE).
