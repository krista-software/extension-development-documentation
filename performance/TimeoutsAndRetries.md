<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Performance](README.md) > Timeouts and retries

# Timeouts and retries

## Overview

Timeouts and retries determine how your extension behaves under upstream slowness or transient failures. Poor defaults can cause cascading failures and long-running requests.

## Timeouts

Recommendations:

1. Set explicit connect and read timeouts for every upstream call.
2. Keep defaults conservative and configurable when needed.
3. Fail fast for user-facing requests (avoid long hangs).

## Retries

Retry only when it is safe:

- network timeouts
- certain 5xx responses
- rate limit responses (with backoff)

Avoid retrying:

- validation errors
- authorization errors (unless you refresh tokens)
- non-idempotent operations without idempotency keys

## Backoff

Use exponential backoff with jitter, and cap the maximum delay.

## See also

- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)
- [Error handling](../operations/ErrorHandling.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
