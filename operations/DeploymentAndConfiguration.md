<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Operations](README.md) > Deployment and configuration

# Deployment and configuration

## Overview

This page summarizes operational practices for deploying extensions and managing environment-specific configuration via invokers.

## Environments and invokers

Use separate invokers for environments (for example Prod/Staging/Sandbox). This keeps configuration isolated without requiring multiple builds.

See:

- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Configuration vs runtime behavior](../concepts/ConfigurationVsRuntimeBehavior.md)

## Release checklist (suggested)

1. Confirm the extension builds and tests pass.
2. Ensure Setup tab fields are stable (no breaking renames).
3. Validate required dependencies and permissions.
4. Validate observability: key logs and metrics are emitted.
5. Verify a rollback strategy (previous artifact/version).

## Configuration management tips

- Prefer **attributes** over hard-coded environment settings.
- For secrets, use secured fields and avoid copying secrets into code or logs.
- Keep defaults safe (timeouts, limits) and override per environment.

## Handling updates safely

When configuration changes:

- handle **INVOKER_UPDATED** to rebuild clients/token managers
- close old resources to avoid leaks

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## See also

- [Setup tab](../setup-tab/README.md)
- [Build configuration](../development/BuildConfiguration.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
