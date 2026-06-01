<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Concepts](README.md) > Configuration vs runtime behavior

# Configuration vs runtime behavior

## Overview

In Krista extensions, **configuration** is what a user saves in the Setup tab (attributes, dependencies, authentication choices), while **runtime behavior** is what your code does when handling requests using that saved configuration.

Keeping these concerns separate makes extensions safer, easier to operate, and easier to test.

## Configuration (Setup tab)

Configuration is:

- **User-owned**: entered/selected by a user in the Setup tab
- **Persisted**: stored by the platform (secured fields are stored encrypted)
- **Per invoker**: the same extension can have multiple invokers with different configuration

Typical configuration includes:

- API base URL / tenant
- credentials (API keys, OAuth settings)
- feature flags (enable/disable optional behavior)
- default limits/timeouts

## Runtime behavior

Runtime behavior is:

- **Code-owned**: implemented in your extension
- **Derived from configuration**: you use saved attributes to create runtime resources
- **Time-sensitive**: tokens expire, connections drop, retries happen

Examples:

- creating an HTTP client with a base URL from attributes
- refreshing OAuth access tokens
- applying retries/backoff when the external API rate-limits
- mapping external errors into user-facing errors

## How invokers bridge the two

An **invoker** represents “extension code + a specific saved configuration”.

Use invoker lifecycle events to safely transform configuration into runtime resources:

- **INVOKER_LOADED**: initialize resources using the saved configuration
- **INVOKER_UPDATED**: close old resources, then re-initialize using the new configuration

This prevents cross-invoker leakage and ensures updates take effect predictably.

## Practical guidelines

1. Treat attributes as **immutable inputs**; do not mutate them to store runtime state.
2. Keep secrets out of logs (even if they come from secured fields).
3. Do not create static/global clients unless they are truly config-free.
4. Prefer dependency injection: pass runtime resources into request handlers instead of constructing them repeatedly.
5. Validate configuration at save-time (Setup tab) and validate request inputs at run-time (catalog requests).

## Common pitfalls

- Hardcoding environment-specific values in code instead of using attributes
- Sharing a singleton client across invokers (mixes configuration)
- Using configuration storage as a cache for runtime data (token/session state)

## Related concepts

- [Invokers and lifecycle](InvokersAndLifecycle.md)
- [Extension lifecycle](ExtensionLifecycle.md)

## See also

- [Setup tab](../setup-tab/README.md)
- [Architecture](../architecture/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
