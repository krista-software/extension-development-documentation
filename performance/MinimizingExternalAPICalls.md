<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Performance](README.md) > Minimizing external API calls

# Minimizing external API calls

## Overview

Most extension performance problems come from excessive upstream calls. Reduce upstream dependency by caching, batching, and avoiding repeated lookups.

## Strategies

### 1) Avoid N+1 call patterns

If a request returns N items, avoid fetching extra details in a loop. Prefer bulk endpoints or return less data.

### 2) Cache stable reference data

Cache reference data that changes infrequently (for example projects, user lists, schemas) with a bounded TTL.

Guidance:

- cache per invoker
- invalidate on **INVOKER_UPDATED**
- keep caches small and bounded

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

### 3) Prefer server-side filtering

Use upstream query parameters to filter results instead of pulling large datasets and filtering locally.

## Best practices

1. Add metrics for external call counts per request.
2. Add timeouts to every external call.
3. Keep retry behavior bounded.

## See also

- [Pagination and batching](PaginationAndBatching.md)
- [Timeouts and retries](TimeoutsAndRetries.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
