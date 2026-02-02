# Prompt 08: Add WAIT_FOR_EVENT Catalog Request (Webhook)

## Purpose

Add a catalog request that waits for an event using webhooks instead of polling. This is more efficient than polling for systems that support webhook notifications.

## Prerequisites

- Existing extension with project structure
- External system supports webhooks
- Krista platform webhook endpoint configured
- Understanding of webhook payload format

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Wait For Payment Completed` |
| Domain Name | `{{DOMAIN_NAME}}` | `Payments` |
| Description | `{{DESCRIPTION}}` | `Wait for payment to complete` |
| Webhook Event Type | `{{WEBHOOK_EVENT}}` | `payment.completed` |
| Entity Name | `{{ENTITY_NAME}}` | `Payment` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.stripe` |

---

## Prompt

```
I need you to add a WAIT_FOR_EVENT catalog request using webhooks to my existing Krista extension.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **Webhook Event Type**: {{WEBHOOK_EVENT}}
- **Entity Name**: {{ENTITY_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Add Catalog Request to Area Class

Add this method to your `{{DOMAIN_NAME}}Area.java`:

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import app.krista.extension.api.event.*;
import {{PACKAGE_NAME}}.entity.{{ENTITY_NAME}};
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.transformation.{{ENTITY_NAME}}Transformer;

import java.util.*;

public class {{DOMAIN_NAME}}Area {

    private final ApiClient client;
    private final {{ENTITY_NAME}}Transformer transformer;

    public {{DOMAIN_NAME}}Area(ApiClient client) {
        this.client = client;
        this.transformer = new {{ENTITY_NAME}}Transformer();
    }

    /**
     * {{DESCRIPTION}}
     * 
     * This is a WAIT_FOR_EVENT request that waits for a webhook notification
     * from the external system.
     */
    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.WAIT_FOR_EVENT,
        description = "{{DESCRIPTION}}"
    )
    // Input fields
    @Field.Text(name = "{{ENTITY_NAME}} ID", required = true,
        description = "ID of the {{ENTITY_NAME}} to monitor")
    @Field.Text(name = "Timeout Minutes", required = false,
        description = "Maximum time to wait (default: 60 minutes)")
    // Output fields
    @Field.Output(name = "Event Occurred", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "{{ENTITY_NAME}}", type = Field.Output.Type.ENTITY,
        entityType = "{{ENTITY_NAME}}")
    @Field.Output(name = "Event Type", type = Field.Output.Type.TEXT)
    @Field.Output(name = "Event Timestamp", type = Field.Output.Type.TEXT)
    public EventResult {{REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        
        String entityId = (String) params.get("{{ENTITY_NAME}} ID");
        
        // Parse timeout (default 60 minutes)
        int timeoutMinutes = 60;
        String timeoutStr = (String) params.get("Timeout Minutes");
        if (timeoutStr != null && !timeoutStr.isBlank()) {
            timeoutMinutes = Integer.parseInt(timeoutStr);
        }
        
        // Validate inputs
        if (entityId == null || entityId.isBlank()) {
            return EventResult.error("INPUT_ERROR", "{{ENTITY_NAME}} ID is required");
        }
        
        // Create webhook subscription configuration
        WebhookConfig config = WebhookConfig.builder()
            .eventType("{{WEBHOOK_EVENT}}")
            .entityId(entityId)
            .timeoutMinutes(timeoutMinutes)
            .build();
        
        // Register for webhook and wait
        return EventResult.waitForWebhook(config, (webhookPayload) -> {
            return processWebhook(webhookPayload, entityId);
        });
    }

    /**
     * Process incoming webhook payload.
     * Called when a matching webhook is received.
     */
    private Map<String, Object> processWebhook(WebhookPayload payload, String expectedEntityId) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Verify the webhook is for the expected entity
            String webhookEntityId = payload.getEntityId();
            if (!expectedEntityId.equals(webhookEntityId)) {
                // Not our event, continue waiting
                return null;
            }
            
            // Extract event data
            String eventType = payload.getEventType();
            String timestamp = payload.getTimestamp();
            
            // Transform payload to entity
            {{ENTITY_NAME}} entity = transformer.transform(payload.getData());
            
            // Build result
            result.put("Event Occurred", true);
            result.put("{{ENTITY_NAME}}", entity);
            result.put("Event Type", eventType);
            result.put("Event Timestamp", timestamp);
            
        } catch (Exception e) {
            result.put("Event Occurred", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Failed to process webhook: " + e.getMessage());
        }
        
        return result;
    }
}
```

## 2. Create Webhook Handler

Add the webhook endpoint handler to your extension:

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.{{EXTENSION_NAME}}Extension;
import {{PACKAGE_NAME}}.integration.WebhookValidator;

import java.util.*;

/**
 * Handles incoming webhooks from the external system.
 */
public class WebhookHandler {

    private final {{EXTENSION_NAME}}Extension extension;
    private final WebhookValidator validator;

    public WebhookHandler({{EXTENSION_NAME}}Extension extension) {
        this.extension = extension;
        this.validator = new WebhookValidator(extension.getAttributes());
    }

    /**
     * Handle incoming webhook from external system.
     * This method is called by the Krista platform when a webhook is received.
     */
    @InvokerRequest(InvokerRequest.Type.EVENT_DELIVERED)
    public EventDeliveryResult handleWebhook(
            Map<String, String> headers,
            String body,
            Map<String, Object> metadata) {

        try {
            // Step 1: Validate webhook signature
            String signature = headers.get("X-Webhook-Signature");
            if (!validator.validateSignature(body, signature)) {
                return EventDeliveryResult.rejected("Invalid webhook signature");
            }

            // Step 2: Parse webhook payload
            WebhookPayload payload = parsePayload(body);

            // Step 3: Check if this is an event we're waiting for
            String eventType = payload.getEventType();
            String entityId = payload.getEntityId();

            // Step 4: Notify waiting catalog requests
            return EventDeliveryResult.accepted(payload);

        } catch (Exception e) {
            return EventDeliveryResult.error("Failed to process webhook: " + e.getMessage());
        }
    }

    private WebhookPayload parsePayload(String body) {
        // Parse JSON body into WebhookPayload
        return new Gson().fromJson(body, WebhookPayload.class);
    }
}
```

## 3. Create Webhook Validator

```java
package {{PACKAGE_NAME}}.integration;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;
import java.util.Map;

/**
 * Validates webhook signatures to ensure authenticity.
 */
public class WebhookValidator {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private final String webhookSecret;

    public WebhookValidator(Map<String, Object> attributes) {
        this.webhookSecret = (String) attributes.get("Webhook Secret");
    }

    /**
     * Validate webhook signature using HMAC-SHA256.
     */
    public boolean validateSignature(String payload, String signature) {
        if (webhookSecret == null || webhookSecret.isBlank()) {
            // No secret configured - skip validation (not recommended for production)
            return true;
        }

        if (signature == null || signature.isBlank()) {
            return false;
        }

        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            SecretKeySpec secretKey = new SecretKeySpec(
                webhookSecret.getBytes(), HMAC_ALGORITHM);
            mac.init(secretKey);

            byte[] hash = mac.doFinal(payload.getBytes());
            String expectedSignature = Base64.getEncoder().encodeToString(hash);

            // Use constant-time comparison to prevent timing attacks
            return constantTimeEquals(expectedSignature, signature);

        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Constant-time string comparison to prevent timing attacks.
     */
    private boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }

        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }
}
```

## 4. Create Webhook Payload Class

```java
package {{PACKAGE_NAME}}.entity;

import com.google.gson.JsonObject;
import java.util.Map;

/**
 * Represents an incoming webhook payload.
 */
public class WebhookPayload {

    private String id;
    private String eventType;
    private String entityId;
    private String timestamp;
    private JsonObject data;

    // Getters
    public String getId() { return id; }
    public String getEventType() { return eventType; }
    public String getEntityId() { return entityId; }
    public String getTimestamp() { return timestamp; }
    public JsonObject getData() { return data; }

    // Setters
    public void setId(String id) { this.id = id; }
    public void setEventType(String eventType) { this.eventType = eventType; }
    public void setEntityId(String entityId) { this.entityId = entityId; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
    public void setData(JsonObject data) { this.data = data; }
}
```

## 5. Add Webhook Configuration to Extension

Add these fields to your main extension class:

```java
@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_DISPLAY_NAME}}",
    description = "{{DESCRIPTION}}"
)
// ... existing fields ...
@Field.Text(name = "Webhook Secret", required = false, isSecured = true,
    description = "Secret key for validating webhook signatures")
@Field.Output(name = "Webhook URL", type = Field.Output.Type.TEXT,
    description = "URL to configure in external system for webhooks")
public class {{EXTENSION_NAME}}Extension {
    // ... existing code ...
}
```

## 6. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.integration.WebhookValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class WebhookHandlerTest {

    private WebhookValidator validator;

    @BeforeEach
    void setUp() {
        Map<String, Object> attributes = new HashMap<>();
        attributes.put("Webhook Secret", "test-secret-key");
        validator = new WebhookValidator(attributes);
    }

    @Test
    void testValidateSignature_withValidSignature_returnsTrue() {
        String payload = "{\"event\":\"payment.completed\",\"id\":\"123\"}";
        // Generate valid signature for test
        String validSignature = generateSignature(payload, "test-secret-key");

        assertTrue(validator.validateSignature(payload, validSignature));
    }

    @Test
    void testValidateSignature_withInvalidSignature_returnsFalse() {
        String payload = "{\"event\":\"payment.completed\",\"id\":\"123\"}";
        String invalidSignature = "invalid-signature";

        assertFalse(validator.validateSignature(payload, invalidSignature));
    }

    @Test
    void testValidateSignature_withNullSignature_returnsFalse() {
        String payload = "{\"event\":\"payment.completed\"}";

        assertFalse(validator.validateSignature(payload, null));
    }

    @Test
    void testValidateSignature_withNoSecretConfigured_returnsTrue() {
        Map<String, Object> noSecretAttrs = new HashMap<>();
        WebhookValidator noSecretValidator = new WebhookValidator(noSecretAttrs);

        assertTrue(noSecretValidator.validateSignature("any-payload", "any-signature"));
    }

    private String generateSignature(String payload, String secret) {
        try {
            javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
            javax.crypto.spec.SecretKeySpec key =
                new javax.crypto.spec.SecretKeySpec(secret.getBytes(), "HmacSHA256");
            mac.init(key);
            byte[] hash = mac.doFinal(payload.getBytes());
            return Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
```

## Validation Checklist

- [ ] `@CatalogRequest` annotation has `type = WAIT_FOR_EVENT`
- [ ] Webhook signature validation is implemented
- [ ] Constant-time comparison used for signature validation
- [ ] Webhook secret is stored securely (`isSecured = true`)
- [ ] Timeout is configurable with reasonable default
- [ ] Entity ID matching ensures correct event correlation
- [ ] Error handling for malformed payloads
- [ ] EVENT_DELIVERED invoker request is implemented

## Best Practices

1. **Always validate signatures** - Never trust unvalidated webhooks
2. **Use constant-time comparison** - Prevent timing attacks
3. **Store secrets securely** - Use `isSecured = true` for webhook secrets
4. **Handle duplicates** - Webhooks may be delivered multiple times
5. **Log webhook activity** - Track received webhooks for debugging
6. **Set reasonable timeouts** - Don't wait forever for events
7. **Provide webhook URL** - Make it easy for users to configure

## Webhook vs Polling Comparison

| Aspect | Webhook | Polling |
|--------|---------|---------|
| Efficiency | High (event-driven) | Low (constant API calls) |
| Latency | Low (near real-time) | High (depends on interval) |
| Complexity | Higher (signature validation) | Lower |
| Reliability | Requires retry handling | Built-in retry |
| API Limits | No impact | May hit rate limits |

## Related Prompts

- [07 - Add WAIT_FOR_EVENT with Polling](07-add-wait-for-event-polling.md)
- [20 - Add Webhook Handler with Signature Validation](20-add-webhook-handler.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
```

