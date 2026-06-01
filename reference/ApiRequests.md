<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Reference](README.md) > API requests

# API requests (`@ApiRequest`)

## Overview

`@ApiRequest` declares **protocol-level API handlers** implemented by your extension, such as inbound webhook endpoints or simple HTTP health checks.

These handlers typically operate on `ProtoRequest`/`ProtoResponse` rather than catalog-request inputs/outputs.

> **Note**: Supported protocols, routing, and available helper types can vary by platform version.

## Annotation

- **Annotation**: `@ApiRequest`
- **Package**: `app.krista.extension.impl.anno.ApiRequest`

### Parameters

| Parameter | Required | Description |
|----------|----------|-------------|
| `pathElement()` | Yes | Path element used to route requests (for example `webhook`, `status`). |
| `name()` | No | Optional handler name for clarity/metadata. |
| `protocol()` | Yes | Supported protocols (for example `{"http", "https"}`). |

## Typical handler signature

Most handlers follow this shape:

```java
@ApiRequest(pathElement = "webhook", protocol = {"http", "https"})
public ProtoResponse handleWebhook(String pathElement, ProtoRequest request) {
  // read headers/body from request
  // validate authenticity
  // process or enqueue work
  return ProtoResponse.success();
}
```

## Design guidance

### Webhook handlers

Recommended behavior:

1. **Validate authenticity** (signature, shared secret, token, mTLS as appropriate).
2. **Return quickly** (acknowledge and do longer processing asynchronously when possible).
3. **Be idempotent** (webhook senders often retry; deliveries are frequently at-least-once).
4. **Avoid logging secrets** (headers may include `Authorization` or signatures).

### Health/status handlers

Use a lightweight status endpoint for:

- verifying deployment is reachable
- verifying basic dependency initialization
- returning a minimal JSON payload (status + timestamp)

## Example: webhook handler

```java
@ApiRequest(
  pathElement = "webhook",
  name = "Webhook Handler",
  protocol = {"http", "https"}
)
public ProtoResponse handleWebhook(String pathElement, ProtoRequest request) {
  String payload = request.getBody();
  String eventType = request.getHeader("X-Event-Type");
  // validate signature, then route based on eventType
  return ProtoResponse.success();
}
```

## Example: health check

```java
@ApiRequest(pathElement = "status", name = "Health Check", protocol = {"http", "https"})
public ProtoResponse healthCheck(String pathElement, ProtoRequest request) {
  Map<String, Object> status = new HashMap<>();
  status.put("status", "healthy");
  status.put("timestamp", System.currentTimeMillis());
  return ProtoResponse.success(status);
}
```

## Best practices

1. **Treat webhooks as untrusted input**: validate structure, size limits, and authenticity.
2. **Return stable responses**: keep response shapes simple and predictable.
3. **Instrument**: capture counts, latencies, and failure reasons (invalid signature, bad payload, downstream failure).
4. **Avoid heavy work in the handler**: queue/defer where possible.

## See also

- [KSDK reference](KsdkReference.md) (see `ProtoRequest`/`ProtoResponse`)
- [Advanced: Eventing and webhooks](../advanced/EventingWebhooks.md)
- [Operations: Error handling](../operations/ErrorHandling.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
