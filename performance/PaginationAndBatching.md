<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Performance](README.md) > Pagination and batching

# Pagination and batching

## Overview

Pagination prevents large responses from overwhelming your extension or upstream APIs. Batching reduces repeated calls when you need to fetch or update many objects.

## Pagination

Recommendations:

1. Always cap page size to a safe maximum.
2. Return paging metadata (cursor/next token, total count if available).
3. Treat paging tokens as opaque.

## Batching

Batch when:

- the external API supports bulk operations
- your workflow naturally processes lists

Batching guidance:

- limit batch sizes (avoid large payloads)
- handle partial failures (report which items failed)
- keep operations idempotent if retries may happen

## See also

- [Advanced: Pagination and rate limits](../advanced/PaginationRateLimits.md)
- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
