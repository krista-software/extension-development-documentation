<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > Invoker requests

# Invoker requests (`@InvokerRequest`)

## Overview

Invoker requests are **platform-invoked entry points** that let your extension participate in lifecycle hooks (load/update/unload), Setup tab workflows (validation, testing, custom UI), authentication, provisioning, and event delivery.

They are implemented as methods annotated with `@InvokerRequest(...)`.

> **Note**: Available invoker request types and supported method signatures can vary by platform version. Use this page as a **conceptual reference** and prefer the platform SDK/Javadocs when in doubt.

## Annotation

- **Annotation**: `@InvokerRequest`
- **Package**: `app.krista.extension.impl.anno.InvokerRequest`
- **Parameter**: `value()` → `InvokerRequest.Type` (required)

## Common invoker request types

### Lifecycle hooks

| Type | Purpose | Typical signature | When called |
|------|---------|-------------------|-------------|
| `INVOKER_INSTALLED` | One-time initialization | `void method()` | Once when an invoker is first installed |
| `INVOKER_LOADED` | Initialize runtime resources | `void method(Map<String, Object> attributes)` | When an invoker loads/reloads |
| `INVOKER_UPDATED` | React to config changes | `void method(Map<String, Object> oldAttrs, Map<String, Object> newAttrs)` | When saved attributes change |
| `INVOKER_UNLOADED` | Cleanup runtime resources | `void method()` | When an invoker is unloaded |
| `INVOKER_REMOVED` | Final cleanup before deletion | `void method()` | Before an invoker is deleted |

### Setup tab and configuration

| Type | Purpose | Typical signature | When called |
|------|---------|-------------------|-------------|
| `VALIDATE_ATTRIBUTES` | Validate configuration before save | `List<String> method(Map<String, Object> attributes)` | Before saving Setup tab configuration |
| `TEST_CONNECTION` | Validate external connectivity | `void method()` | When user clicks **Test Connection** (if enabled) |
| `CUSTOM_TABS` | Provide custom Setup tab UI sections | `List<?> method()` | When rendering extension UI / Setup tab |

### Authentication

| Type | Purpose | Typical signature | When called |
|------|---------|-------------------|-------------|
| `AUTHENTICATOR` | Register a request authenticator | `RequestAuthenticator method()` | When authentication is needed |

### Eventing

| Type | Purpose | Typical signature | When called |
|------|---------|-------------------|-------------|
| `EVENT_DELIVERED` | Handle a delivered event | `void method(EventSubscription subscription, Map<String, Object> eventData)` | When an event is delivered to the extension |

## Additional / advanced types

Some platforms expose additional invoker request types to support dynamic execution and event listener registration.

| Type | Purpose | Typical signature | Notes |
|------|---------|-------------------|-------|
| `RUNTIME_CATALOG_REQUEST` | Runtime catalog execution | `Map<String, Object> method(CatalogRequest request, Map<String, Object> params)` | Used for dynamic catalog execution patterns |
| `RUNTIME_API_REQUEST` | Runtime API execution | `ProtoResponse method(String pathElement, ProtoRequest request)` | Used for dynamic API/webhook execution patterns |
| `REGISTER_EVENT_LISTENER` | Register a WAIT_FOR_EVENT listener | `void method(WaitForEventListener listener)` | Used by WAIT_FOR_EVENT implementations |
| `UNREGISTER_EVENT_LISTENER` | Unregister a WAIT_FOR_EVENT listener | `void method(WaitForEventListener listener)` | Used by WAIT_FOR_EVENT implementations |
| `CATALOG_REQUEST_PROVISION` | Provision a catalog request | `void method(CatalogRequest request, Object data)` | Provisioning workflows |
| `GET_CATALOG_REQUESTS` | Return catalog request metadata | `Map<String, Object> method()` | Metadata discovery |
| `GET_DEFINITIONS` | Return entity definitions | `List<EntityDefinition> method()` | Entity metadata loading |
| `PROVISION` | Provision entities | `void method(EntityDefinition definition)` | Entity provisioning |
| `PREPARE_CHANGE_ROUTING_ID` | Prepare routing for change requests | `void method(String routingId)` | Routing workflows |

## Usage examples

### Validate attributes

```java
@InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
public List<String> validateAttributes(Map<String, Object> attributes) {
  List<String> errors = new ArrayList<>();
  String apiKey = (String) attributes.get("API Key");
  if (apiKey == null || apiKey.isBlank()) {
    errors.add("API Key is required");
  }
  return errors;
}
```

### Initialize on load / update

```java
@InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
public void onLoaded(Map<String, Object> attributes) {
  // Initialize clients, caches, schedulers using configuration
}

@InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
  // Cleanup old resources and reinitialize from newAttrs
}
```

### Register an authenticator

```java
@InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
public RequestAuthenticator getAuthenticator() {
  return new MyRequestAuthenticator();
}
```

### Handle a delivered event

```java
@InvokerRequest(InvokerRequest.Type.EVENT_DELIVERED)
public void handleEvent(EventSubscription subscription, Map<String, Object> eventData) {
  // Make processing idempotent and checkpoint minimally
}
```

## Best practices

1. **Keep handlers idempotent**. Lifecycle and event callbacks can be retried or replayed.
2. **Do not treat Setup attributes as runtime state**—they are configuration.
3. **Avoid long blocking work** in lifecycle hooks; prefer background workers where appropriate.
4. **Never log secured fields**. Assume attributes may contain secrets.
5. **Close resources on update/unload** to avoid leaks.

## See also

- [Invoker lifecycle](../concepts/InvokersAndLifecycle.md)
- [Extension lifecycle](../concepts/ExtensionLifecycle.md)
- [Setup tab: Attributes](../setup-tab/Attributes.md)
- [Setup tab: Validation & troubleshooting](../setup-tab/ValidationAndTroubleshooting.md)
- [Advanced: Authentication patterns](../advanced/AuthPatterns.md)
- [Advanced: Eventing and webhooks](../advanced/EventingWebhooks.md)
- [KSDK reference](KsdkReference.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
