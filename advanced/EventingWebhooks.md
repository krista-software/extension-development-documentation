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

## Delta sync and change detection

When the external system provides incremental queries:

- **Cursor-based sync** — store a cursor/token in `KeyValueStore`, call the API's delta endpoint, update the cursor after each sync. Handle cursor expiration (HTTP 410) by clearing and re-syncing.
- **Snapshot comparison** — store full state periodically, compare with current state, emit field-level change events (created, updated, deleted).

See: [Prompt 33: Delta Sync](../prompts/33-delta-sync-change-detection.md) for implementation details.

## Dual push/polling fallback

Some systems (for example Gmail, Microsoft Graph) support both push notifications and polling. Use push as the primary path and polling as a fallback:

- Run a background polling scheduler alongside webhook subscriptions
- Use a shared deduplication set to prevent double-processing across both paths
- Preserve request-scoped `ThreadLocal` context when dispatching from background threads

## Event deduplication

Track recently processed event IDs in a bounded in-memory set:

- Use a `LinkedHashSet` or `ConcurrentHashMap` with capacity eviction
- Evict oldest entries when capacity is reached (for example 1000 entries)
- Check the set before processing — skip if already seen
- Thread-safe access is required when webhook and polling paths run concurrently

## Reliability and idempotency

Events are often delivered at-least-once.

Recommended:

1. deduplicate using event IDs where possible
2. make handlers idempotent
3. track processing outcomes with metrics

See: [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)

## Background scheduler pattern

For extensions that need periodic polling independent of user requests:

- Create a `ScheduledExecutorService` in the extension constructor or `INVOKER_LOADED`
- Guard against duplicate schedulers — check if one is already running before starting
- Preserve `ThreadLocal` context for the background thread
- Shut down the scheduler in `INVOKER_REMOVED`
- Make the interval configurable via Setup tab attributes

## Webhook subscription lifecycle

When external APIs require subscription registration:

- **Create** a subscription with a callback URL and expiry (for example 28 days)
- **Renew** before expiry — check remaining time on each request and renew if expiring soon
- **Delete** on `INVOKER_REMOVED` to prevent orphaned subscriptions
- **Handle validation handshakes** — some APIs echo a token on subscription creation

## Observability

Track:

- events received/processed
- processing latency
- deduplication hits
- failures by error category

See: [Operations](../operations/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
