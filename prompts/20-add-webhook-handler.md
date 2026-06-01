# Prompt 20: Add Webhook Handler with Signature Validation

## Purpose

Add a webhook handler to your extension that receives incoming webhooks from external services, validates their signatures for security, and routes events to appropriate handlers. This enables real-time event-driven integrations.

## Prerequisites

- Existing extension with basic structure
- Understanding of the external service's webhook format
- Knowledge of the signature algorithm (HMAC-SHA256, etc.)

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Stripe` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.stripe` |
| Webhook Secret Field | `{{SECRET_FIELD}}` | `Webhook Signing Secret` |
| Signature Header | `{{SIGNATURE_HEADER}}` | `Stripe-Signature` |

---

## Prompt

```
I need you to add a webhook handler to my extension that receives and validates incoming webhooks.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Webhook Secret Field**: {{SECRET_FIELD}}
- **Signature Header**: {{SIGNATURE_HEADER}}

## 1. Webhook Controller

Create the webhook endpoint using @ApiRequest:

```java
package {{PACKAGE_NAME}}.controller;

import ai.krista.platform.extension.sdk.annotation.*;
import ai.krista.platform.extension.sdk.annotation.Field.*;
import ai.krista.platform.extension.sdk.api.ApiRequestContext;
import ai.krista.platform.extension.sdk.api.ApiRequestResult;

import {{PACKAGE_NAME}}.webhook.WebhookProcessor;
import {{PACKAGE_NAME}}.webhook.WebhookSignatureValidator;
import {{PACKAGE_NAME}}.webhook.WebhookEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

@Domain(name = "Webhooks")
public class WebhooksArea {

    private static final Logger logger = LoggerFactory.getLogger(WebhooksArea.class);

    private final WebhookProcessor webhookProcessor;
    private final WebhookSignatureValidator signatureValidator;

    public WebhooksArea(WebhookProcessor webhookProcessor, 
                        WebhookSignatureValidator signatureValidator) {
        this.webhookProcessor = webhookProcessor;
        this.signatureValidator = signatureValidator;
    }

    /**
     * Webhook endpoint for receiving events from {{EXTENSION_NAME}}.
     * 
     * URL: POST /api/extensions/{extensionId}/webhook
     */
    @ApiRequest(
        name = "Receive Webhook",
        path = "/webhook",
        method = "POST",
        description = "Receives and processes incoming webhooks from {{EXTENSION_NAME}}"
    )
    public ApiRequestResult receiveWebhook(ApiRequestContext context) {
        String requestId = UUID.randomUUID().toString();
        logger.info("Webhook received [requestId={}]", requestId);

        try {
            // 1. Extract signature from headers
            String signature = context.getHeader("{{SIGNATURE_HEADER}}");
            if (signature == null || signature.isBlank()) {
                logger.warn("Missing signature header [requestId={}]", requestId);
                return ApiRequestResult.error(401, "Missing signature header");
            }

            // 2. Get raw payload for signature verification
            String rawPayload = context.getRawBody();
            if (rawPayload == null || rawPayload.isBlank()) {
                logger.warn("Empty webhook payload [requestId={}]", requestId);
                return ApiRequestResult.error(400, "Empty payload");
            }

            // 3. Get webhook secret from invoker attributes
            String webhookSecret = context.getInvokerAttribute("{{SECRET_FIELD}}");
            if (webhookSecret == null || webhookSecret.isBlank()) {
                logger.error("Webhook secret not configured [requestId={}]", requestId);
                return ApiRequestResult.error(500, "Webhook secret not configured");
            }

            // 4. Validate signature
            if (!signatureValidator.isValid(rawPayload, signature, webhookSecret)) {
                logger.warn("Invalid webhook signature [requestId={}]", requestId);
                return ApiRequestResult.error(401, "Invalid signature");
            }

            // 5. Parse and process webhook
            WebhookEvent event = webhookProcessor.parseEvent(rawPayload);
            logger.info("Processing webhook event [requestId={}, type={}, eventId={}]",
                requestId, event.getType(), event.getId());

            webhookProcessor.processEvent(event, context);

            // 6. Return success
            logger.info("Webhook processed successfully [requestId={}, eventId={}]",
                requestId, event.getId());
            
            return ApiRequestResult.success(Map.of(
                "status", "received",
                "eventId", event.getId(),
                "eventType", event.getType()
            ));

        } catch (WebhookParseException e) {
            logger.error("Failed to parse webhook [requestId={}]: {}", requestId, e.getMessage());
            return ApiRequestResult.error(400, "Invalid webhook format: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Webhook processing failed [requestId={}]", requestId, e);
            return ApiRequestResult.error(500, "Internal error processing webhook");
        }
    }
}
```

## 2. Signature Validator

Create the signature validation utility:

```java
package {{PACKAGE_NAME}}.webhook;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Validates webhook signatures using HMAC-SHA256.
 */
public class WebhookSignatureValidator {

    private static final Logger logger = LoggerFactory.getLogger(WebhookSignatureValidator.class);
    private static final String HMAC_ALGORITHM = "HmacSHA256";

    /**
     * Validates the webhook signature.
     *
     * @param payload The raw webhook payload
     * @param signature The signature from the header
     * @param secret The webhook signing secret
     * @return true if signature is valid, false otherwise
     */
    public boolean isValid(String payload, String signature, String secret) {
        if (payload == null || signature == null || secret == null) {
            return false;
        }

        try {
            String expectedSignature = computeSignature(payload, secret);
            return secureCompare(expectedSignature, parseSignature(signature));
        } catch (Exception e) {
            logger.error("Signature validation error", e);
            return false;
        }
    }

    /**
     * Computes HMAC-SHA256 signature for the payload.
     */
    private String computeSignature(String payload, String secret)
            throws NoSuchAlgorithmException, InvalidKeyException {
        Mac mac = Mac.getInstance(HMAC_ALGORITHM);
        SecretKeySpec secretKey = new SecretKeySpec(
            secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM);
        mac.init(secretKey);

        byte[] hash = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
        return HexFormat.of().formatHex(hash);
    }

    /**
     * Parses the signature from the header format.
     * Override this method for service-specific signature formats.
     *
     * Example formats:
     * - Simple: "abc123def456"
     * - Stripe: "t=1234567890,v1=abc123def456"
     * - GitHub: "sha256=abc123def456"
     */
    protected String parseSignature(String signatureHeader) {
        // Default: assume signature is the raw value
        // Override for service-specific formats

        // Handle "sha256=signature" format (GitHub style)
        if (signatureHeader.startsWith("sha256=")) {
            return signatureHeader.substring(7);
        }

        // Handle "v1=signature" format (Stripe style)
        if (signatureHeader.contains(",v1=")) {
            String[] parts = signatureHeader.split(",");
            for (String part : parts) {
                if (part.startsWith("v1=")) {
                    return part.substring(3);
                }
            }
        }

        return signatureHeader;
    }

    /**
     * Performs constant-time comparison to prevent timing attacks.
     */
    private boolean secureCompare(String expected, String actual) {
        if (expected == null || actual == null) {
            return false;
        }
        return MessageDigest.isEqual(
            expected.getBytes(StandardCharsets.UTF_8),
            actual.getBytes(StandardCharsets.UTF_8)
        );
    }
}
```

## 3. Webhook Event Model

```java
package {{PACKAGE_NAME}}.webhook;

import java.time.Instant;
import java.util.Map;

/**
 * Represents a parsed webhook event.
 */
public class WebhookEvent {

    private final String id;
    private final String type;
    private final Instant timestamp;
    private final Map<String, Object> data;
    private final String rawPayload;

    public WebhookEvent(String id, String type, Instant timestamp,
                        Map<String, Object> data, String rawPayload) {
        this.id = id;
        this.type = type;
        this.timestamp = timestamp;
        this.data = data;
        this.rawPayload = rawPayload;
    }

    public String getId() { return id; }
    public String getType() { return type; }
    public Instant getTimestamp() { return timestamp; }
    public Map<String, Object> getData() { return data; }
    public String getRawPayload() { return rawPayload; }

    @Override
    public String toString() {
        return "WebhookEvent{id='" + id + "', type='" + type + "'}";
    }
}
```

## 4. Webhook Processor

```java
package {{PACKAGE_NAME}}.webhook;

import ai.krista.platform.extension.sdk.api.ApiRequestContext;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.*;

/**
 * Processes incoming webhook events.
 */
public class WebhookProcessor {

    private static final Logger logger = LoggerFactory.getLogger(WebhookProcessor.class);
    private final ObjectMapper objectMapper;
    private final Map<String, WebhookEventHandler> handlers;

    public WebhookProcessor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.handlers = new HashMap<>();
        registerHandlers();
    }

    /**
     * Register handlers for different event types.
     */
    private void registerHandlers() {
        // Register event-specific handlers
        handlers.put("payment.completed", this::handlePaymentCompleted);
        handlers.put("payment.failed", this::handlePaymentFailed);
        handlers.put("subscription.created", this::handleSubscriptionCreated);
        handlers.put("subscription.cancelled", this::handleSubscriptionCancelled);
        handlers.put("customer.created", this::handleCustomerCreated);
        handlers.put("customer.updated", this::handleCustomerUpdated);
        // Add more handlers as needed
    }

    /**
     * Parses the raw webhook payload into a WebhookEvent.
     */
    public WebhookEvent parseEvent(String rawPayload) throws WebhookParseException {
        try {
            JsonNode root = objectMapper.readTree(rawPayload);

            // Extract common fields (adjust based on service format)
            String id = extractField(root, "id", "event_id", "eventId");
            String type = extractField(root, "type", "event_type", "eventType");

            // Parse timestamp
            Instant timestamp = parseTimestamp(root);

            // Extract data object
            JsonNode dataNode = root.has("data") ? root.get("data") : root;
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.convertValue(dataNode, Map.class);

            if (id == null || type == null) {
                throw new WebhookParseException("Missing required fields: id or type");
            }

            return new WebhookEvent(id, type, timestamp, data, rawPayload);

        } catch (WebhookParseException e) {
            throw e;
        } catch (Exception e) {
            throw new WebhookParseException("Failed to parse webhook: " + e.getMessage(), e);
        }
    }

    /**
     * Processes the webhook event by routing to appropriate handler.
     */
    public void processEvent(WebhookEvent event, ApiRequestContext context) {
        String eventType = event.getType();

        WebhookEventHandler handler = handlers.get(eventType);
        if (handler != null) {
            logger.debug("Routing event to handler [type={}]", eventType);
            handler.handle(event, context);
        } else {
            // Check for wildcard handlers (e.g., "payment.*")
            String category = eventType.contains(".") ?
                eventType.substring(0, eventType.indexOf('.')) + ".*" : null;

            if (category != null && handlers.containsKey(category)) {
                handlers.get(category).handle(event, context);
            } else {
                logger.info("No handler registered for event type: {}", eventType);
                handleUnknownEvent(event, context);
            }
        }
    }

    // ============================================================
    // EVENT HANDLERS
    // ============================================================

    private void handlePaymentCompleted(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing payment completed [eventId={}]", event.getId());
        Map<String, Object> data = event.getData();

        // Extract payment details
        String paymentId = (String) data.get("payment_id");
        Object amount = data.get("amount");
        String currency = (String) data.get("currency");

        // Trigger Krista workflow or update state
        // context.triggerWorkflow("payment_received", Map.of(...));
    }

    private void handlePaymentFailed(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing payment failed [eventId={}]", event.getId());
        // Handle payment failure
    }

    private void handleSubscriptionCreated(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing subscription created [eventId={}]", event.getId());
        // Handle new subscription
    }

    private void handleSubscriptionCancelled(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing subscription cancelled [eventId={}]", event.getId());
        // Handle subscription cancellation
    }

    private void handleCustomerCreated(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing customer created [eventId={}]", event.getId());
        // Handle new customer
    }

    private void handleCustomerUpdated(WebhookEvent event, ApiRequestContext context) {
        logger.info("Processing customer updated [eventId={}]", event.getId());
        // Handle customer update
    }

    private void handleUnknownEvent(WebhookEvent event, ApiRequestContext context) {
        logger.warn("Unknown event type received [type={}, eventId={}]",
            event.getType(), event.getId());
        // Optionally store for later processing or alerting
    }

    // ============================================================
    // HELPER METHODS
    // ============================================================

    private String extractField(JsonNode root, String... fieldNames) {
        for (String fieldName : fieldNames) {
            if (root.has(fieldName) && !root.get(fieldName).isNull()) {
                return root.get(fieldName).asText();
            }
        }
        return null;
    }

    private Instant parseTimestamp(JsonNode root) {
        // Try common timestamp field names
        String[] timestampFields = {"created", "timestamp", "created_at", "createdAt"};

        for (String field : timestampFields) {
            if (root.has(field)) {
                JsonNode node = root.get(field);
                if (node.isNumber()) {
                    // Unix timestamp (seconds or milliseconds)
                    long value = node.asLong();
                    return value > 1_000_000_000_000L ?
                        Instant.ofEpochMilli(value) : Instant.ofEpochSecond(value);
                } else if (node.isTextual()) {
                    // ISO 8601 format
                    return Instant.parse(node.asText());
                }
            }
        }
        return Instant.now();
    }

    @FunctionalInterface
    interface WebhookEventHandler {
        void handle(WebhookEvent event, ApiRequestContext context);
    }
}
```

## 5. Webhook Parse Exception

```java
package {{PACKAGE_NAME}}.webhook;

/**
 * Exception thrown when webhook parsing fails.
 */
public class WebhookParseException extends Exception {

    public WebhookParseException(String message) {
        super(message);
    }

    public WebhookParseException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

## 6. Setup Tab Configuration

Add webhook secret field to your extension's setup tab:

```java
@Extension(
    name = "{{EXTENSION_NAME}}",
    description = "{{EXTENSION_NAME}} integration extension"
)
@Domains({
    @Domain(name = "Webhooks")
})
public class {{EXTENSION_NAME}}Extension {

    // Setup tab fields
    @Field.Text(
        name = "API Key",
        description = "Your {{EXTENSION_NAME}} API key",
        secured = true,
        required = true
    )
    private String apiKey;

    @Field.Text(
        name = "{{SECRET_FIELD}}",
        description = "Secret key for validating webhook signatures",
        secured = true,
        required = true
    )
    private String webhookSecret;

    @Field.Output(
        name = "Webhook URL",
        description = "Configure this URL in your {{EXTENSION_NAME}} dashboard"
    )
    private String webhookUrl;

    // The webhook URL is generated dynamically
    // Format: https://api.krista.ai/extensions/{extensionId}/webhook
}
```

## 7. Unit Tests

```java
package {{PACKAGE_NAME}}.webhook;

import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Webhook Signature Validator Tests")
class WebhookSignatureValidatorTest {

    private WebhookSignatureValidator validator;

    @BeforeEach
    void setUp() {
        validator = new WebhookSignatureValidator();
    }

    @Test
    @DisplayName("Should validate correct signature")
    void isValid_withCorrectSignature_returnsTrue() {
        // Arrange
        String payload = "{\"id\":\"evt_123\",\"type\":\"payment.completed\"}";
        String secret = "whsec_test_secret";

        // Compute expected signature
        String signature = computeTestSignature(payload, secret);

        // Act & Assert
        assertTrue(validator.isValid(payload, signature, secret));
    }

    @Test
    @DisplayName("Should reject incorrect signature")
    void isValid_withIncorrectSignature_returnsFalse() {
        // Arrange
        String payload = "{\"id\":\"evt_123\"}";
        String secret = "whsec_test_secret";
        String wrongSignature = "invalid_signature";

        // Act & Assert
        assertFalse(validator.isValid(payload, wrongSignature, secret));
    }

    @Test
    @DisplayName("Should reject tampered payload")
    void isValid_withTamperedPayload_returnsFalse() {
        // Arrange
        String originalPayload = "{\"amount\":100}";
        String tamperedPayload = "{\"amount\":1000}";
        String secret = "whsec_test_secret";
        String signature = computeTestSignature(originalPayload, secret);

        // Act & Assert
        assertFalse(validator.isValid(tamperedPayload, signature, secret));
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "  "})
    @DisplayName("Should reject blank signature")
    void isValid_withBlankSignature_returnsFalse(String signature) {
        assertFalse(validator.isValid("{}", signature, "secret"));
    }

    @Test
    @DisplayName("Should handle null inputs safely")
    void isValid_withNullInputs_returnsFalse() {
        assertFalse(validator.isValid(null, "sig", "secret"));
        assertFalse(validator.isValid("{}", null, "secret"));
        assertFalse(validator.isValid("{}", "sig", null));
    }

    @Test
    @DisplayName("Should parse GitHub-style signature header")
    void isValid_withGitHubStyleSignature_parsesCorrectly() {
        String payload = "{\"action\":\"opened\"}";
        String secret = "github_secret";
        String rawSignature = computeTestSignature(payload, secret);
        String headerSignature = "sha256=" + rawSignature;

        assertTrue(validator.isValid(payload, headerSignature, secret));
    }

    @Test
    @DisplayName("Should parse Stripe-style signature header")
    void isValid_withStripeStyleSignature_parsesCorrectly() {
        String payload = "{\"id\":\"evt_123\"}";
        String secret = "stripe_secret";
        String rawSignature = computeTestSignature(payload, secret);
        String headerSignature = "t=1234567890,v1=" + rawSignature;

        assertTrue(validator.isValid(payload, headerSignature, secret));
    }

    private String computeTestSignature(String payload, String secret) {
        try {
            javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
            javax.crypto.spec.SecretKeySpec key = new javax.crypto.spec.SecretKeySpec(
                secret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(key);
            byte[] hash = mac.doFinal(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
```

```java
package {{PACKAGE_NAME}}.webhook;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Webhook Processor Tests")
class WebhookProcessorTest {

    private WebhookProcessor processor;

    @BeforeEach
    void setUp() {
        processor = new WebhookProcessor(new ObjectMapper());
    }

    @Test
    @DisplayName("Should parse valid webhook payload")
    void parseEvent_withValidPayload_returnsEvent() throws Exception {
        // Arrange
        String payload = """
            {
                "id": "evt_123456",
                "type": "payment.completed",
                "created": 1704067200,
                "data": {
                    "payment_id": "pay_789",
                    "amount": 1000,
                    "currency": "USD"
                }
            }
            """;

        // Act
        WebhookEvent event = processor.parseEvent(payload);

        // Assert
        assertEquals("evt_123456", event.getId());
        assertEquals("payment.completed", event.getType());
        assertNotNull(event.getTimestamp());
        assertNotNull(event.getData());
        assertEquals("pay_789", event.getData().get("payment_id"));
    }

    @Test
    @DisplayName("Should throw exception for missing required fields")
    void parseEvent_withMissingId_throwsException() {
        String payload = "{\"type\":\"test\"}";

        assertThrows(WebhookParseException.class,
            () -> processor.parseEvent(payload));
    }

    @Test
    @DisplayName("Should throw exception for invalid JSON")
    void parseEvent_withInvalidJson_throwsException() {
        String payload = "not valid json";

        assertThrows(WebhookParseException.class,
            () -> processor.parseEvent(payload));
    }

    @Test
    @DisplayName("Should handle alternative field names")
    void parseEvent_withAlternativeFieldNames_parsesCorrectly() throws Exception {
        String payload = """
            {
                "event_id": "evt_alt_123",
                "event_type": "customer.created",
                "timestamp": "2024-01-01T00:00:00Z"
            }
            """;

        WebhookEvent event = processor.parseEvent(payload);

        assertEquals("evt_alt_123", event.getId());
        assertEquals("customer.created", event.getType());
    }
}
```

## Validation Checklist

- [ ] Webhook endpoint is accessible via @ApiRequest
- [ ] Signature validation uses HMAC-SHA256
- [ ] Constant-time comparison prevents timing attacks
- [ ] Webhook secret is stored securely (secured = true)
- [ ] Event parsing handles multiple formats
- [ ] Event handlers are registered for all event types
- [ ] Unknown events are logged but don't cause errors
- [ ] Unit tests cover signature validation
- [ ] Unit tests cover event parsing
- [ ] Error responses use appropriate HTTP status codes

## Security Best Practices

### 1. Always Validate Signatures
Never process webhooks without validating the signature first.

### 2. Use Constant-Time Comparison
Prevent timing attacks by using `MessageDigest.isEqual()`.

### 3. Store Secrets Securely
Use `secured = true` for webhook secret fields.

### 4. Log Webhook Activity
Log all webhook receipts for debugging and auditing.

### 5. Handle Replay Attacks
Consider checking timestamps to reject old webhooks:

```java
private boolean isTimestampValid(Instant timestamp) {
    Instant now = Instant.now();
    Duration age = Duration.between(timestamp, now);
    return age.toMinutes() < 5; // Reject webhooks older than 5 minutes
}
```

### 6. Return Quickly
Return 200 OK quickly and process asynchronously if needed.

## Common Webhook Formats

### Stripe
```json
{
  "id": "evt_123",
  "type": "payment_intent.succeeded",
  "created": 1234567890,
  "data": { "object": { ... } }
}
```
Header: `Stripe-Signature: t=timestamp,v1=signature`

### GitHub
```json
{
  "action": "opened",
  "repository": { ... },
  "sender": { ... }
}
```
Header: `X-Hub-Signature-256: sha256=signature`

### Slack
```json
{
  "type": "event_callback",
  "event": { "type": "message", ... }
}
```
Header: `X-Slack-Signature: v0=signature`

## Related Prompts

- [08 - Add WAIT_FOR_EVENT with Webhook](08-add-wait-for-event-webhook.md)
- [12 - Configure Setup Tab](12-configure-setup-tab.md)
- [16 - Implement Error Handling](16-implement-error-handling.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

