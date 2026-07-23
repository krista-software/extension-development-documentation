<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Concepts](README.md) > Invokers and lifecycle

# Invokers and lifecycle

## Overview

An **invoker** is a runtime instance of an extension with a specific saved configuration. You can have multiple invokers for the same extension (for example: “Prod”, “Staging”, “Sandbox”).

## Why invokers exist

Invokers separate:

- **Configuration** (attributes chosen in the Setup tab)
- **Runtime behavior** (resources created from that configuration: clients, caches, credentials)

This enables the same extension code to run safely in multiple environments.

## Lifecycle events

The platform can call invoker lifecycle handlers when configuration changes:

- **INVOKER_LOADED**: when an invoker is first created/loaded
- **INVOKER_UPDATED**: when an invoker’s configuration changes
- **INVOKER_UNLOADED**: when an invoker is destroyed/unloaded (implicit in many cases)

## What to do in each event

### INVOKER_LOADED

Use this event to initialize runtime resources, for example:

- HTTP clients / connection pools
- token managers
- caches
- background schedulers

### INVOKER_UPDATED

Use this event to:

1. Close/cleanup old resources
2. Re-initialize resources using the updated configuration

### INVOKER_UNLOADED

Ensure you clean up any remaining resources and stop background work.

## Resource management best practices

1. Initialize resources in **INVOKER_LOADED**.
2. Cleanup before re-initializing in **INVOKER_UPDATED**.
3. Keep shared state thread-safe (for example: `volatile`, synchronized, or an atomic state holder).
4. If initialization fails, log with enough context to diagnose configuration problems.

## Common pitfalls

- Creating global/static clients that accidentally share config across invokers
- Leaking resources on update (not closing old clients)
- Treating invoker attributes as mutable runtime state (they are configuration)

## See also

- [Extension lifecycle](ExtensionLifecycle.md)
- [Configuration vs runtime behavior](ConfigurationVsRuntimeBehavior.md)
- [Setup tab](../setup-tab/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
