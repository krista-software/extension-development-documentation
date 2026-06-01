<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Validation and troubleshooting

# Validation and troubleshooting

## Overview

The Setup tab is the earliest (and cheapest) place to detect configuration problems. Your goal is to **fail fast** with clear, user-actionable messages *before* users run catalog requests.

Setup-time validation complements (but does not replace) request-time validation.

See: [Validation and error mapping](../development/catalog-requests/ValidationAndErrorMapping.md)

## What to validate at setup time

### 1) Attribute presence and format

- Required fields are present and non-empty
- URLs are valid
- numeric ranges are safe (timeouts, limits)

### 2) Credentials sanity

Validate that credentials *look* correct (non-empty, well-formed). Avoid making assumptions that require external calls unless necessary.

### 3) Dependency wiring

If your extension depends on other invokers:

- ensure required dependencies are present
- verify dependency invokers are reachable/usable

See: [Dependencies](Dependencies.md)

### 4) Connectivity (when appropriate)

If you support a “test connection” style check, validate:

- DNS/host reachability
- authentication succeeds
- permissions are sufficient

Keep these tests fast and safe.

## How validation fits the lifecycle

Conceptually, setup-time validation happens before configuration is saved as an invoker (or as part of an update). After save, invoker lifecycle hooks can initialize runtime resources based on the validated configuration.

See:

- [Extension lifecycle](../concepts/ExtensionLifecycle.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## Writing actionable validation messages

Good messages tell the user:

1. what is wrong
2. where it is wrong (which field)
3. how to fix it

Examples:

- “API Base URL must be a valid URL (for example `https://api.example.com`).”
- “Authentication dependency is required. Select an invoker that implements the Authentication domain.”

Avoid:

- raw stack traces
- “Invalid input” without details
- echoing secret values

## Troubleshooting checklist

### Setup tab save fails

1. Re-check required fields and formats.
2. Verify dependency selections.
3. Review server logs for validation errors.

### Catalog request fails but setup saved successfully

1. Confirm the invoker you’re using is the one you configured.
2. Check for time-sensitive failures (token expiration, revoked credentials).
3. Validate request-time inputs separately.

See:

- [Error handling](../operations/ErrorHandling.md)
- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)

### Works in one environment but not another

This commonly indicates configuration drift between invokers.

1. Compare attribute values (base URL, tenant, scopes).
2. Compare dependency invokers (Prod vs Staging).
3. Ensure runtime resources are reinitialized on configuration changes.

## Next steps

- Continue with [Catalog requests](../development/catalog-requests/README.md)
- For production readiness, see [Operations](../operations/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
