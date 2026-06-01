<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Advanced](README.md) > Pagination and rate limits

# Pagination and rate limits

## Overview

Many external APIs limit response size and enforce rate limits. Extensions should implement pagination and throttling in a way that is predictable, testable, and resilient.

## Pagination patterns

### Offset/limit

- Inputs: `offset`, `limit`
- Risks: large offsets can become slow

Recommended:

- cap `limit` to a safe max
- expose paging tokens/metadata in outputs

### Cursor-based

- Inputs: `cursor` (token), `pageSize`
- Benefits: stable performance

Recommended:

- treat cursors as opaque
- pass cursors through without modification

## Rate limiting patterns

### Respect upstream signals

When the upstream provides guidance (headers or error codes):

- use it to compute backoff
- propagate a clear error when limits are exceeded

### Client-side throttling

If you know the API limits, add a per-invoker rate limiter in the integration layer.

Keep it:

- shared across requests for the same invoker
- thread-safe
- configurable (where appropriate)

## Error handling and retries

Treat rate limit errors as **external dependency failures** with bounded retries and exponential backoff.

See:

- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)
- [Error handling](../operations/ErrorHandling.md)

## Testing guidance

1. Unit test pagination logic (token handling, caps).
2. Unit test rate limiter behavior (burst, steady-state).
3. Simulate upstream 429/5xx responses and validate retry/backoff decisions.

## See also

- [Performance: Pagination and batching](../performance/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
