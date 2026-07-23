<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > Operations > Error handling

# Error handling

## Overview

Guidance for categorizing, reporting, and troubleshooting errors in catalog requests and service integrations.

## Error categories

| Category | Cause | User action |
|----------|-------|-------------|
| **Input/validation** | Missing or invalid parameters | Fix the input and retry |
| **Authorization** | Missing permissions, expired token | Re-authenticate or add scope |
| **External dependency** | Rate limit, timeout, upstream 5xx | Wait and retry, or contact external provider |
| **Internal/system** | Unexpected exception, serialization failure | Report to extension developer |

## Circuit breaker pattern

When an external service fails repeatedly, use a circuit breaker to stop calling it temporarily:

- **CLOSED** — calls proceed normally; track consecutive failures
- **OPEN** — calls are blocked after failure threshold (for example 5 failures); return fallback or error
- **HALF_OPEN** — after recovery timeout (for example 30 seconds), allow one test call; if it succeeds, close the circuit

Isolate circuit breakers per invoker or per tool — one failing integration should not block others.

## Graceful degradation

When a non-critical dependency is unavailable:

- Return cached or partial data instead of failing entirely
- Include a warning field in the response (for example `"warning": "Partial results — calendar service unavailable"`)
- Log the degradation for monitoring

## Input sanitization

Sanitize all user-provided input at the Area class boundary:

- **SQL queries** — detect dangerous functions, multi-statement injection, comment injection
- **File paths** — block path traversal (`..`), normalize separators
- **Identifiers** — validate against allowlist patterns
- **Log output** — redact credentials, truncate long values, strip newlines

See: [Prompt 36: Input Sanitization](../prompts/36-input-sanitization-security.md)

## Topics

- Error types and recommended mapping
- Retry guidance
- Logging and observability

## See also

- [Validation and error mapping](../development/catalog-requests/ValidationAndErrorMapping.md)
- [Retry and idempotency](../development/catalog-requests/RetryAndIdempotency.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
