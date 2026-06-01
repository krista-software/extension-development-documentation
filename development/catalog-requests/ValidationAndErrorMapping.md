<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../../kristaLogo.png)

**Breadcrumbs:** [Home](../../index.md) > [Development](../README.md) > [Catalog requests](README.md) > Validation and error mapping

# Validation and error mapping

## Overview

Validate inputs before external calls, and map failures into clear, user-actionable errors. This keeps requests predictable and reduces support load.

## Validation stages

### 1) Setup-time validation (Setup tab)

Validate invoker configuration at save-time (attributes/dependencies/auth), so users find problems before they run requests.

### 2) Request-time validation (catalog request execution)

Validate request parameters every time the request is invoked.

## Common validation patterns

### Required and empty checks

- Null/blank checks for required text
- Range checks for numbers

### Format checks

- URLs
- email addresses
- external IDs (prefix/length/charset)

### Cross-field rules

Examples:

- start time must be before end time
- at least one of {A, B} must be provided
- if `includeDetails=true`, then `detailsLevel` is required

### External existence checks (carefully)

Sometimes you must validate against the external system (for example: project exists). Do this only after all local validation passes.

## Error mapping principles

1. **Fail fast** for input errors.
2. **Separate user-actionable failures** (bad inputs, missing permissions) from **system failures** (timeouts, upstream outage).
3. **Preserve context** (what operation failed) but do not leak secrets.

### Suggested categories

- **Input/validation**: missing/invalid parameters
- **Authorization**: missing permissions, token expired, invalid credentials
- **External dependency**: rate limiting, timeouts, 5xx upstream errors
- **Internal/system**: unexpected exceptions, serialization failures

## Writing good error messages

A good error message includes:

- which parameter (or operation) failed
- what was expected
- how to fix it

Avoid:

- raw stack traces
- vendor-specific jargon without explanation
- including secured fields in logs or messages

## Observability

Log and emit telemetry for:

- request name + type
- external operation name
- upstream status codes (where safe)
- retry counts and backoff decisions

## See also

- [Implement a catalog request](ImplementCatalogRequest.md)
- [Designing inputs and outputs](DesigningInputsAndOutputs.md)
- [Error handling (operations)](../../operations/ErrorHandling.md)
- [Configuration vs runtime behavior](../../concepts/ConfigurationVsRuntimeBehavior.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../../LICENSE).
