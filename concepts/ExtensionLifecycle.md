<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Concepts](README.md) > Extension lifecycle

# Extension lifecycle

## Overview

An extension moves through a predictable lifecycle: it is deployed, configured in the Setup tab, validated, saved as an **invoker**, and then becomes available for catalog requests.

## Lifecycle at a glance

The “happy path” lifecycle is:

1. **Extension deployed** (extension code is available to the platform)
2. **User opens Setup tab**
3. **User configures attributes** (and dependencies/auth if needed)
4. **Platform validates configuration**
5. **Configuration is saved** and an **invoker** is created/updated
6. **Extension is ready for use** (catalog requests can run using invoker config)

## Lifecycle diagram

```
┌─────────────────────────────────────────────────────────────┐
│              Extension Lifecycle                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Extension       │
                    │  Deployed        │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  User Opens      │
                    │  Setup Tab       │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Configure       │
                    │  Attributes      │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Validate        │
                    │  Configuration   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Save & Deploy   │
                    │  Invoker         │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Extension       │
                    │  Ready for Use   │
                    └──────────────────┘
```

## What changes between phases

- **Before the Setup tab is saved**, the extension exists but there may be **no invoker** (no runtime configuration).
- **After save**, the platform persists configuration (including secured values) and your extension can initialize runtime resources using the invoker’s attributes.

## Best practices

1. Treat the Setup tab as the single source of truth for runtime configuration.
2. Fail fast during validation with clear, actionable messages (for example: “Host URL must be a valid URL”).
3. Initialize expensive resources (HTTP clients, caches, thread pools) only when an invoker is loaded.

## Related concepts

- [Invoker lifecycle](InvokersAndLifecycle.md)
- [Configuration vs runtime behavior](ConfigurationVsRuntimeBehavior.md)

## See also

- [Setup tab](../setup-tab/README.md)
- [Architecture](../architecture/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
