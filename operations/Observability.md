<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Operations](README.md) > Observability

# Observability

## Overview

Operational visibility is what makes an extension supportable in production. Aim to make failures diagnosable without debugging sessions by emitting consistent logs and telemetry.

## What to observe

At minimum, capture:

1. **Which request ran** (catalog request name + type)
2. **Which invoker ran it** (invoker identifier / environment label where available)
3. **Which external operation was called** (endpoint/method or action name)
4. **Latency** (total and upstream)
5. **Outcome** (success, input error, auth error, upstream error)
6. **Retry behavior** (attempt count, backoff)

## Logging guidance

### Do

- log at the controller boundary (request start/end)
- log upstream status codes and correlation IDs when safe
- include stable identifiers (invoker id, request name)

### Do not

- log secrets (API keys, tokens, passwords)
- log entire attribute maps
- log full upstream payloads by default

## Telemetry (metrics/tracing)

### TelemetryMetrics

Framework 4 extensions receive `TelemetryMetrics` via constructor injection. Use it to emit counters and timing data.

### TelemetryHelper pattern

Create a helper class to standardize metric names and tag maps across all catalog requests:

- **`incrementCount(operationName)`** — count each invocation
- **`recordSuccess(operationName, startTime, tags)`** — record success with duration
- **`recordError(operationName, startTime, exception, tags)`** — record system errors
- **`recordValidationError(operationName, startTime, message, tags)`** — record input validation failures
- **`safeTagMap(key, value, ...)`** — build tag maps safely (null-safe, no secrets)

Capture `System.currentTimeMillis()` at method entry and pass it to record methods for duration tracking.

### Recommended metrics

- request count by request name/type
- request duration histogram
- external call duration histogram
- error count by category (success, validation, system, auth)
- retry count

### Tracing guidance

- create spans around upstream calls
- propagate correlation IDs if the external API supports them

## Operational dashboards (suggested)

1. Error rate by catalog request
2. P95/P99 latency by catalog request
3. Rate limit and timeout counts
4. Token refresh failures (if applicable)

## See also

- [Error handling](ErrorHandling.md)
- [Performance](../performance/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
