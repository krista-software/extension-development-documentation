<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Advanced](README.md) > Authentication patterns

# Authentication patterns

## Overview

Extensions commonly integrate with systems that require short-lived tokens, rotating credentials, or delegated access. This page outlines practical patterns for implementing authentication safely and predictably.

## Principles

1. **Keep secrets out of logs** and never return them in responses.
2. **Separate configuration from runtime state**: credentials settings are configuration; access tokens are runtime state.
3. **Centralize auth logic** in the integration layer, not in catalog request handlers.

See: [Configuration vs runtime behavior](../concepts/ConfigurationVsRuntimeBehavior.md)

## Common models

### API key

- Store the API key as a secured Setup tab attribute.
- Inject it into outgoing calls as a header.

Recommended:

- validate the key is present during setup-time validation
- apply request signing consistently in a single client wrapper

### OAuth 2.0 / token-based auth

Typical requirements:

- access tokens expire
- refresh requires a refresh token or client credentials
- tokens must be refreshed safely under concurrency

Recommended pattern:

1. Create a `TokenProvider` component (integration layer)
2. Cache access tokens in memory per-invoker
3. Refresh on-demand when expired (with a lock to prevent thundering herd)
4. On refresh failure, surface a clear authorization error

## Where to initialize auth components

Use invoker lifecycle events to initialize long-lived runtime resources:

- create HTTP client(s)
- construct token providers
- warm any metadata caches (optional)

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## Error mapping guidance

When authentication fails, return errors that tell users what to do next:

- missing credentials: "configure <field> in Setup tab"
- invalid/revoked credentials: "re-authenticate" or "rotate API key"
- insufficient permissions: "add scope/role" (name the missing scope/permission if known)

See: [Error handling](../operations/ErrorHandling.md)

## Best practices

1. **Avoid storing runtime tokens in Setup tab attributes.**
2. **Redact headers** (Authorization, API keys) in HTTP logs.
3. **Use bounded retries** for auth endpoints; do not retry indefinitely.
4. **Prefer idempotent refresh operations** and cache results.


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
