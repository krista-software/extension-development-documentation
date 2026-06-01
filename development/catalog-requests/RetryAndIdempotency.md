<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../../kristaLogo.png)

**Breadcrumbs:** [Home](../../index.md) > [Development](../README.md) > [Catalog requests](README.md) > Retry and idempotency

# Retry and idempotency

## Overview

Retries improve reliability for flaky networks and transient upstream failures, but they can create duplicates if a request changes external state. Design retries and idempotency together.

## When retries are appropriate

### `QUERY_SYSTEM`

Generally safe to retry when:

- timeouts
- connection resets
- 429 rate limits (respect `Retry-After`)
- transient 5xx responses

### `CHANGE_SYSTEM`

Retry only when you have an idempotency strategy.

- If you cannot guarantee idempotency, prefer returning a clear error rather than blindly retrying.

### `WAIT_FOR_EVENT`

“Retry” often means polling again. Always define:

- polling interval
- overall timeout
- clear intermediate status messages

## Idempotency strategies

1. **Idempotency key**: add a request ID parameter and store/forward it to the external API if supported.
2. **Upsert semantics**: design the operation to be “create or update”.
3. **Check-before-create**: look up by a stable external key before creating.
4. **Deterministic naming**: derive an external resource name from stable inputs.

## Backoff guidelines

- Use exponential backoff with jitter.
- Cap the maximum backoff.
- Keep max attempts small; prefer failing with actionable messages.

## What not to retry

Avoid retrying:

- most 4xx errors (except 429)
- validation failures
- permission failures (unless you can refresh credentials)

## Telemetry you should capture

- attempt count
- final outcome (success/failure category)
- upstream status code bucket (2xx/4xx/5xx)
- total elapsed time

## See also

- [Catalog request types](CatalogRequestTypes.md)
- [Implement a catalog request](ImplementCatalogRequest.md)
- [Error handling (operations)](../../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../../LICENSE).
