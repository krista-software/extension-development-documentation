<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Advanced](README.md) > Eventing and webhooks

# Eventing and webhooks

## Overview

Event-driven extensions react to changes in an external system. In Krista, these integrations are commonly expressed using `WAIT_FOR_EVENT` catalog requests, polling loops, or webhook subscriptions.

## Models

### Polling

Use polling when:

- the external system has no webhooks
- webhooks are not reliable

Guidance:

- make poll interval configurable
- store minimal checkpoint state safely (do not store secrets)
- ensure idempotent processing

### Webhooks

Use webhooks when:

- the external system supports callbacks
- you can validate webhook authenticity

Guidance:

- validate signatures/tokens
- handle retries from the webhook sender
- return fast acknowledgements and process asynchronously when possible

## Reliability and idempotency

Events are often delivered at-least-once.

Recommended:

1. deduplicate using event IDs where possible
2. make handlers idempotent
3. track processing outcomes with metrics

See: [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)

## Observability

Track:

- events received/processed
- processing latency
- deduplication hits
- failures by error category

See: [Operations](../operations/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
