<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > KSDK reference

# KSDK reference

## Overview

The Krista Software Development Kit (KSDK) provides core classes and interfaces used by extensions (responses, invoker configuration, authorization context, and event delivery).

This page summarizes commonly used components.

## Notes on packages and versions

- Package names in examples may vary by platform version.
- Treat this page as a **conceptual reference** for what each type is for and where it belongs in an extension.

## Common components

### `ExtensionResponse`

Used to return success/error responses from catalog requests.

There are several ways to construct responses:

- **`ExtensionResponseFactory.create(Map)`** — success response from a field-name-to-value map
- **`ExtensionResponseFactory.create(Exception, String, ExceptionType)`** — error response from an exception
- **`ExtensionResponseFactory.create(message, ExceptionType, remediationActions, subCatalogName, state)`** — error with remediation actions for guided retry
- **`new ExtensionResponseBuilder().success(Map).build()`** — builder pattern for success
- **`new ExtensionResponse(Result.SUCCESS, Map, null, null, null)`** — direct constructor

Common patterns:

- Return structured data under stable top-level keys (for example: `"user"`, `"items"`).
- Include useful metadata when applicable (for example: `"count"`, paging tokens).
- Use warnings for partial success or degraded results.

### `RemediationActionFactory`

Creates remediation actions attached to error responses. Used to guide users toward correcting invalid input:

- **Inform action** — display an informational message to participants
- Typically combined with sub-catalog request state for re-entry flows

### `InvokerStore`

Used for reading/updating invoker setup configuration.

When you use it:

- **Setup-time flows** (saving configuration) and platform-driven operations.
- Avoid using it as a general-purpose state store for runtime data.

Notes:

- Setup tab attributes are **configuration**, not runtime state.
- Secured fields should remain secured—do not copy secrets into logs or response payloads.

Example:

```java
import app.krista.ksdk.invoker.InvokerStore;
import jakarta.inject.Inject;

@Inject
private InvokerStore invokerStore;

public void saveConfiguration(Map<String, Object> attributes) {
    invokerStore.updateSetup(attributes);
}
```

### `AuthorizationContext`

Used for permission checks and security context.

Typical usage:

- Check whether the caller has a named permission/role before performing sensitive operations.
- Use it at the **controller boundary** (Area class) so authorization is consistent.

Example:

```java
import app.krista.extension.authorization.AuthorizationContext;
import jakarta.inject.Inject;

@Inject
private AuthorizationContext authContext;

public void ensureCanWrite() {
    if (!authContext.hasPermission("write")) {
        throw new IllegalStateException("Missing permission: write");
    }
}
```

### `EventSubscription`

Used for event-driven integrations and delivery callbacks.

Typical usage:

- Handle delivered events in invoker lifecycle callbacks (for example `EVENT_DELIVERED`).
- Store minimal checkpoint state and make event handlers idempotent.

Example:

```java
import app.krista.extension.executor.EventSubscription;
import app.krista.extension.impl.anno.InvokerRequest;

@InvokerRequest(InvokerRequest.Type.EVENT_DELIVERED)
public void handleEvent(EventSubscription subscription, Map<String, Object> eventData) {
    // Use subscription + payload to dedupe/process.
}
```

## Authentication and request identity

### `RequestAuthenticator`

Defines a custom authentication mechanism for an extension.

Common pattern:

1. Implement `RequestAuthenticator`.
2. Register it via an invoker request of type `AUTHENTICATOR`.

Example:

```java
import app.krista.extension.authorization.RequestAuthenticator;
import app.krista.extension.authorization.AuthenticationRequest;
import app.krista.extension.authorization.AuthenticationResult;

public final class MyRequestAuthenticator implements RequestAuthenticator {
    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        // Validate request credentials and return success/failure.
        return AuthenticationResult.failure("Not implemented");
    }
}
```

### `AuthenticationRequest` / `AuthenticationResult`

- `AuthenticationRequest` represents the inbound authentication material (for example headers, tokens, or other credentials).
- `AuthenticationResult` represents the outcome (success/failure) and any derived identity/roles metadata.

If you support authentication, also review:

- [Advanced: Authentication patterns](../advanced/AuthPatterns.md)
- [Operations: Error handling](../operations/ErrorHandling.md)

## Protocol/API request types

### `ProtoRequest` / `ProtoResponse`

Used for protocol-specific API handlers (for example inbound webhooks) typically paired with `@ApiRequest`.

Example shape:

```java
import app.krista.extension.impl.anno.ApiRequest;
import app.krista.extension.request.ProtoRequest;
import app.krista.extension.request.ProtoResponse;

@ApiRequest(pathElement = "webhook", protocol = {"http", "https"})
public ProtoResponse handleWebhook(String pathElement, ProtoRequest request) {
    String payload = request.getBody();
    String eventType = request.getHeader("X-Event-Type");
    return ProtoResponse.success();
}
```

## State and storage

### `KeyValueStore`

A per-invoker key-value store for persisting runtime state that must survive restarts (for example refresh tokens, delta sync cursors, cached credentials).

When to use it:

- **Refresh tokens** — store OAuth tokens keyed by user or invoker identity
- **Sync cursors** — store delta links or checkpoint tokens for incremental data sync
- **Cached configuration** — store resolved attributes that are expensive to compute

When NOT to use it:

- Do not use it as a general-purpose database or cache for request data.
- Do not store secrets in plaintext — use secured attributes for credentials configured at setup time.

Key operations: `get(key)`, `put(key, value)`, `remove(key)`.

### `AccountProvider`

Resolves Krista user accounts. Used in per-user authentication flows to look up a user by email or identifier:

- `lookupAccount(email)` — returns the account's workspace contact ID
- Commonly used in MCP flows to resolve the correct token storage key for a per-user caller

### `RequestContext`

Provides request-scoped context for the current catalog request execution:

- `invokeAsUser()` — returns `true` when the request is invoked on behalf of a specific user (MCP per-user path) rather than the operator
- Use this to branch between operator credentials and per-user credentials in authentication flows

## Entity definition (metadata)

### `EntityDefinition`

Represents entity metadata used for provisioning and describing the entities your extension supports.

You will most commonly see it paired with invoker requests such as provisioning or definition discovery.

## Dependency injection

Many extensions rely on HK2 injection. Keep injection at the controller/service boundary and keep low-level integration clients easy to construct in tests.

Common injection patterns:

1. **Constructor injection** — prefer this for core dependencies.
2. **`@Named(...)`** — qualify injected dependencies by name (for example `@Named("API Key")` for a specific attribute, or `@Named("self")` for the extension's own invoker).
3. **`InvokerAttributeProvider<T>`** — lazy attribute resolution. The value is fetched on first access, useful when attributes may not be available at construction time.
4. **`@Service`** — HK2 service annotation for registering service classes (for example validators, orchestrators).
5. Do not inject platform dependencies deep into the integration layer—wrap them in a thin adapter at the service/controller boundary.

## See also

- [Extension annotations](ExtensionAnnotations.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Eventing and webhooks](../advanced/EventingWebhooks.md)
- [Error handling](../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
