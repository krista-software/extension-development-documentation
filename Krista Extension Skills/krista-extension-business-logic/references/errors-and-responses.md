# Errors, exceptions & response building

Full code: `idioms/Exceptions.java`, `idioms/ResponseFactory.java`, `idioms/AuditedArea.java`.

## Exception strategy — two equivalent idioms

**Compact (github):** the connector throws **built-in** Java exceptions whose *type* carries the
class of failure, mapped once in `handleErrorResponse()`:

| HTTP | Exception | Class |
|---|---|---|
| 401 | `SecurityException` | AUTH |
| 403 | `SecurityException` (unless rate-limited → `IOException`) | AUTH |
| 404 / 422 | `IllegalArgumentException` | INPUT |
| 409 | `IllegalStateException` | conflict |
| 5xx / rate-limit | `IOException` | SYSTEM |

**Decomposed (autotask):** a typed hierarchy — one base `AutotaskException extends RuntimeException`
carrying `statusCode` + `errorCode`, one subclass per failure mode (`AuthenticationException`,
`PermissionDeniedException`, `NotFoundException`, `ValidationException` (list of field errors),
`RateLimitException` (+`retryAfterSeconds`), `NetworkException` (+`isRetryable`)). Subclasses
self-enhance short messages into actionable guidance (idempotently — skip if already enhanced).

Pick built-in exceptions for compact extensions, the typed hierarchy when you need to carry
`retryAfterSeconds` / `isRetryable` / field-error lists.

## The single mapping point
`handleErrorResponse(status, body)` in the connector: read the body once, extract the vendor's
`message`, **log full context** (method, URL, status, vendor message, any SSO/trace header) at ERROR,
then `switch(status)` → the exception. Never put the raw URL/endpoint in the user-facing message.

## User-facing vs log-facing
- User message = a friendly, **actionable** constant ("token may be expired — update it in Setup and
  retry"), optionally with the vendor's terse message appended in parentheses when present.
- Log message = full technical context. Keep these separate; centralize the user strings in a
  `Constants` class.

## Building the ExtensionResponse
- Use `new ExtensionResponseBuilder().success(map).build()` / `.failure(msg).build()`, or a small
  `ExtensionResponseFactory` with `success(map)` + `failure(message, ExceptionType[, cause])` overloads
  that stamp `System.currentTimeMillis()` and attach empty `RemediationActions`.
- Response keys are **stable, human-readable** field names matching the `@Field` output declarations
  (`"Items"`, `"Count"`, `"Success"`, `"Error Message"`). Use `Map.of` for fixed lists, `LinkedHashMap`
  when fields are conditional.
- **CHANGE_SYSTEM convention:** return a `success()` envelope even on business failure, carrying a
  `Success=false` + `Error Message` payload — so the caller can branch on the `Success` field.

## The audited wrapper (compact)
Wrap every Area method body in one helper so the try/catch → classify → response + telemetry + timing
is written once:

```java
private ExtensionResponse audited(String name, CheckedSupplier<ExtensionResponse> action) {
    long t0 = System.currentTimeMillis();
    LOG.info("Catalog '{}' started for invoker {}", name, invokerId);
    try {
        ExtensionResponse r = action.get();
        telemetry.recordSuccess(PREFIX + "." + name, t0, Map.of());
        return r;
    } catch (SecurityException e)        { return fail(name, t0, e, ExceptionType.AUTHENTICATION_ERROR, WARN_OR_ERROR); }
    catch (IllegalArgumentException e)   { return fail(name, t0, e, ExceptionType.INPUT_ERROR, WARN); }
    catch (Exception e)                  { return fail(name, t0, e, ExceptionType.SYSTEM_ERROR, ERROR); }
}
```
See `idioms/AuditedArea.java` for the full version. `MustAuthorize/MustAuthenticateException` (interactive
auth) must be **re-thrown**, never converted to a response.
