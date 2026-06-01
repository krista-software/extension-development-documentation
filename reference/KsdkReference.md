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

Typical usage:

- `ExtensionResponse.success()` with data and metadata
- `ExtensionResponse.error(...)` for failures

Common patterns:

- Return structured data under stable top-level keys (for example: `"user"`, `"items"`).
- Include useful metadata when applicable (for example: `"count"`, paging tokens).
- Use warnings for partial success or degraded results.

Example:

```java
import app.krista.extension.response.ExtensionResponse;

return ExtensionResponse.success()
    .withData("users", users)
    .withMetadata("count", users.size());
```

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

## Entity definition (metadata)

### `EntityDefinition`

Represents entity metadata used for provisioning and describing the entities your extension supports.

You will most commonly see it paired with invoker requests such as provisioning or definition discovery.

## Dependency injection

Many extensions rely on HK2 injection. Keep injection at the controller/service boundary and keep low-level integration clients easy to construct in tests.

Common injection tips:

1. Prefer constructor injection for core dependencies where feasible.
2. Use `@Named(...)` when injecting configured dependencies (for example a dependent invoker).
3. Do not inject platform dependencies deep into the integration layer—wrap them in a thin adapter in the service/controller boundary.

## See also

- [Extension annotations](ExtensionAnnotations.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Eventing and webhooks](../advanced/EventingWebhooks.md)
- [Error handling](../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
