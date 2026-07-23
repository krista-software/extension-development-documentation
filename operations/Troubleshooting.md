<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Operations](README.md) > Troubleshooting

# Troubleshooting

## Overview

This page provides a quick, operational checklist for diagnosing common extension issues.

## Common symptoms and checks

### Extension loads but Setup tab save fails

1. Check validation errors surfaced by the platform.
2. Verify required fields and formats.
3. Verify required dependencies are selected.

See: [Setup tab validation](../setup-tab/ValidationAndTroubleshooting.md)

### Setup saves, but catalog requests fail

1. Verify the request is using the expected invoker.
2. Validate request-time inputs.
3. Check authentication/token expiry errors.
4. Check upstream API status and rate limits.

See:

- [Error handling](ErrorHandling.md)
- [Validation and error mapping](../development/catalog-requests/ValidationAndErrorMapping.md)

### Intermittent timeouts

1. Review upstream latency and timeouts.
2. Confirm retry/backoff is bounded.
3. Reduce payload sizes or page through results.

See:

- [Performance](../performance/README.md)
- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)

### Dependency injection / dependency missing

1. Confirm the dependency is declared and configured.
2. Ensure `@Named(...)` values match dependency names.
3. Verify the dependency invoker exists and is healthy.

See: [Setup tab dependencies](../setup-tab/Dependencies.md)

## What to collect for support

- invoker name/id and environment
- catalog request name + time window
- upstream correlation id (if available)
- sanitized logs (no secrets)

## See also

- [Observability](Observability.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
