<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Attributes

# Attributes

## Overview

**Attributes** are the user-configurable inputs your extension needs at runtime (for example an API base URL, a default project, or a feature flag). Users set these values in the **Setup tab**, and Krista persists them as part of an **invoker** configuration.

Attributes should be treated as **immutable configuration**: read them to build runtime resources (clients, token managers), but do not use them to store runtime state.

## What makes a good attribute

1. **User-friendly name**: choose a stable, descriptive label.
2. **Minimal required set**: ask only for what you need to operate.
3. **Safe handling of secrets**: mark sensitive values as secured and never log them.
4. **Deterministic behavior**: the same attribute values should produce the same runtime configuration.

## Declaring attributes

Attributes are declared using Krista field annotations (for example `@Field.*`). The platform uses these declarations to render the Setup tab UI and to persist the values.

Common declaration ideas:

- **Name stability matters**: changing a field name can break existing invokers.
- **Required vs optional**: make fields required only when the extension cannot operate without them.
- **Defaults**: where possible, provide safe defaults to reduce friction.
- **Secured fields**: use secured/password-style fields for secrets.

See also:

- [Extension annotations](../reference/ExtensionAnnotations.md)
- [Configuration vs runtime behavior](../concepts/ConfigurationVsRuntimeBehavior.md)

## Typical attribute categories

- **Connection**: host/base URL, region, tenant.
- **Authentication**: client id/secret, API keys, audience.
- **Behavior**: feature flags, default limits, paging size.
- **Safety**: timeouts, allow-retry toggle, dry-run mode.

## Reading attributes at runtime

At runtime, your code should:

1. Read the saved invoker configuration.
2. Validate critical invariants again as needed (especially for request-time inputs).
3. Build runtime resources from configuration in lifecycle hooks.

### Recommended pattern

- Build/refresh runtime resources in lifecycle events (for example **INVOKER_LOADED** / **INVOKER_UPDATED**).
- Keep resources per-invoker to prevent configuration leakage across environments.

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## Common pitfalls

### Attribute name drift

If you rename a field (or change casing/spacing), existing invokers may continue to store the old key.

**Recommendation:** keep a compatibility layer (read both old/new keys) or explicitly migrate configurations.

### Logging secrets

Even if the platform stores secured values encrypted, your runtime logs can still leak secrets.

**Recommendation:** redact secrets in logs and avoid logging entire attribute maps.

## Next steps

- Define [Dependencies](Dependencies.md) if your extension needs other extensions.
- Add save-time validation: [Validation and troubleshooting](ValidationAndTroubleshooting.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
