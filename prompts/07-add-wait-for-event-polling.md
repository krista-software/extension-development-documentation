# Prompt 07: Add WAIT_FOR_EVENT Catalog Request (Polling)

## Purpose

Add a catalog request that waits for an event or condition to occur in the external system using a polling mechanism. WAIT_FOR_EVENT requests are used for asynchronous workflows where Krista needs to wait for external state changes.

## Prerequisites

- Existing extension with project structure
- Area class for the domain
- API client configured
- Understanding of the external system's state model

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Wait For Ticket Resolution` |
| Domain Name | `{{DOMAIN_NAME}}` | `Tickets` |
| Description | `{{DESCRIPTION}}` | `Wait for a ticket to be resolved` |
| API Endpoint | `{{API_ENDPOINT}}` | `/tickets/{id}` |
| Entity Name | `{{ENTITY_NAME}}` | `Ticket` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.zendesk` |
| Target Status | `{{TARGET_STATUS}}` | `resolved` |

---

## Prompt

```
I need you to add a WAIT_FOR_EVENT catalog request using polling to my existing Krista extension.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **API Endpoint**: {{API_ENDPOINT}}
- **Entity Name**: {{ENTITY_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Target Status**: {{TARGET_STATUS}}

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
     * This is a WAIT_FOR_EVENT request that polls the external system
     * until the specified condition is met or timeout occurs.
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
    @Field.PickOne(name = "Target Status", required = true,
        values = {"pending", "open", "resolved", "closed"},
        description = "Status to wait for")
    @Field.Text(name = "Timeout Minutes", required = false,
        description = "Maximum time to wait (default: 60 minutes)")
    @Field.Text(name = "Poll Interval Seconds", required = false,
        description = "How often to check (default: 30 seconds)")
    // Output fields
    @Field.Output(name = "Event Occurred", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "{{ENTITY_NAME}}", type = Field.Output.Type.ENTITY,
        entityType = "{{ENTITY_NAME}}")
    @Field.Output(name = "Final Status", type = Field.Output.Type.TEXT)
    @Field.Output(name = "Wait Duration Seconds", type = Field.Output.Type.NUMBER)
    public EventResult {{REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        
        // Extract parameters
        String entityId = (String) params.get("{{ENTITY_NAME}} ID");
        String targetStatus = (String) params.get("Target Status");
        
        // Parse timeout (default 60 minutes)
        int timeoutMinutes = 60;
        String timeoutStr = (String) params.get("Timeout Minutes");
        if (timeoutStr != null && !timeoutStr.isBlank()) {
            timeoutMinutes = Integer.parseInt(timeoutStr);
        }
        
        // Parse poll interval (default 30 seconds)
        int pollIntervalSeconds = 30;
        String intervalStr = (String) params.get("Poll Interval Seconds");
        if (intervalStr != null && !intervalStr.isBlank()) {
            pollIntervalSeconds = Integer.parseInt(intervalStr);
        }
        
        // Validate inputs
        if (entityId == null || entityId.isBlank()) {
            return EventResult.error("INPUT_ERROR", "{{ENTITY_NAME}} ID is required");
        }
        
        if (targetStatus == null || targetStatus.isBlank()) {
            return EventResult.error("INPUT_ERROR", "Target Status is required");
        }
        
        // Create polling configuration
        PollingConfig config = PollingConfig.builder()
            .pollIntervalSeconds(pollIntervalSeconds)
            .timeoutMinutes(timeoutMinutes)
            .maxRetries(3)  // Retry on transient failures
            .build();
        
        // Create the polling event handler
        return EventResult.polling(config, () -> {
            return checkCondition(entityId, targetStatus);
        });
    }

    /**
     * Check if the target condition is met.
     * Called periodically by the polling mechanism.
     */
    private PollingResult checkCondition(String entityId, String targetStatus) {
        try {
            // Fetch current state from API
            ApiResponse response = client.get("{{API_ENDPOINT}}".replace("{id}", entityId));
            {{ENTITY_NAME}} entity = transformer.transform(response.getData());
            
            String currentStatus = entity.getStatus();
            
            // Check if target status is reached
            if (targetStatus.equalsIgnoreCase(currentStatus)) {
                // Condition met - return success with data
                Map<String, Object> result = new HashMap<>();
                result.put("Event Occurred", true);
                result.put("{{ENTITY_NAME}}", entity);
                result.put("Final Status", currentStatus);
                
                return PollingResult.complete(result);
            }
            
            // Check for terminal states that won't reach target
            if (isTerminalState(currentStatus) && !targetStatus.equalsIgnoreCase(currentStatus)) {
                Map<String, Object> result = new HashMap<>();
                result.put("Event Occurred", false);
                result.put("{{ENTITY_NAME}}", entity);
                result.put("Final Status", currentStatus);
                result.put("error", "{{ENTITY_NAME}} reached terminal state: " + currentStatus);
                
                return PollingResult.complete(result);
            }
            
            // Continue polling
            return PollingResult.continuePolling();
            
        } catch (NotFoundException e) {
            // Entity was deleted
            Map<String, Object> result = new HashMap<>();
            result.put("Event Occurred", false);
            result.put("error", "{{ENTITY_NAME}} not found - may have been deleted");
            return PollingResult.complete(result);
            
        } catch (Exception e) {
            // Transient error - let polling mechanism retry
            return PollingResult.retryableError(e.getMessage());
        }
    }

    /**
     * Check if a status is terminal (won't change further).
     */
    private boolean isTerminalState(String status) {
        Set<String> terminalStates = Set.of("closed", "deleted", "cancelled", "archived");
        return terminalStates.contains(status.toLowerCase());
    }
}
```

## 2. Create Polling Configuration Class

```java
package {{PACKAGE_NAME}}.config;

/**
 * Configuration for polling-based event waiting.
 */
public class PollingConfig {

    private final int pollIntervalSeconds;
    private final int timeoutMinutes;
    private final int maxRetries;

    private PollingConfig(Builder builder) {
        this.pollIntervalSeconds = builder.pollIntervalSeconds;
        this.timeoutMinutes = builder.timeoutMinutes;
        this.maxRetries = builder.maxRetries;
    }

    public int getPollIntervalSeconds() { return pollIntervalSeconds; }
    public int getTimeoutMinutes() { return timeoutMinutes; }
    public int getMaxRetries() { return maxRetries; }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private int pollIntervalSeconds = 30;
        private int timeoutMinutes = 60;
        private int maxRetries = 3;

        public Builder pollIntervalSeconds(int seconds) {
            this.pollIntervalSeconds = Math.max(10, seconds); // Minimum 10 seconds
            return this;
        }

        public Builder timeoutMinutes(int minutes) {
            this.timeoutMinutes = Math.max(1, Math.min(minutes, 1440)); // 1 min to 24 hours
            return this;
        }

        public Builder maxRetries(int retries) {
            this.maxRetries = Math.max(0, retries);
            return this;
        }

        public PollingConfig build() {
            return new PollingConfig(this);
        }
    }
}
```

## 3. Create Polling Result Class

```java
package {{PACKAGE_NAME}}.event;

import java.util.Map;

/**
 * Result of a polling check operation.
 */
public class PollingResult {

    public enum Status {
        COMPLETE,           // Condition met, stop polling
        CONTINUE_POLLING,   // Condition not met, continue
        RETRYABLE_ERROR     // Transient error, retry
    }

    private final Status status;
    private final Map<String, Object> data;
    private final String errorMessage;

    private PollingResult(Status status, Map<String, Object> data, String errorMessage) {
        this.status = status;
        this.data = data;
        this.errorMessage = errorMessage;
    }

    public Status getStatus() { return status; }
    public Map<String, Object> getData() { return data; }
    public String getErrorMessage() { return errorMessage; }

    public static PollingResult complete(Map<String, Object> data) {
        return new PollingResult(Status.COMPLETE, data, null);
    }

    public static PollingResult continuePolling() {
        return new PollingResult(Status.CONTINUE_POLLING, null, null);
    }

    public static PollingResult retryableError(String message) {
        return new PollingResult(Status.RETRYABLE_ERROR, null, message);
    }
}
```

## 4. Alternative: Simple Polling Loop (Without Framework)

If your extension doesn't use the event framework, implement polling manually:

```java
    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.WAIT_FOR_EVENT,
        description = "{{DESCRIPTION}}"
    )
    @Field.Text(name = "{{ENTITY_NAME}} ID", required = true)
    @Field.PickOne(name = "Target Status", required = true,
        values = {"pending", "open", "resolved", "closed"})
    @Field.Text(name = "Timeout Minutes", required = false)
    @Field.Output(name = "Event Occurred", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "{{ENTITY_NAME}}", type = Field.Output.Type.ENTITY,
        entityType = "{{ENTITY_NAME}}")
    public Map<String, Object> {{REQUEST_NAME_CAMEL}}Simple(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        String entityId = (String) params.get("{{ENTITY_NAME}} ID");
        String targetStatus = (String) params.get("Target Status");

        int timeoutMinutes = 60;
        String timeoutStr = (String) params.get("Timeout Minutes");
        if (timeoutStr != null && !timeoutStr.isBlank()) {
            timeoutMinutes = Integer.parseInt(timeoutStr);
        }

        long startTime = System.currentTimeMillis();
        long timeoutMs = timeoutMinutes * 60 * 1000L;
        int pollIntervalMs = 30 * 1000; // 30 seconds

        try {
            while (System.currentTimeMillis() - startTime < timeoutMs) {
                // Check current status
                ApiResponse response = client.get("{{API_ENDPOINT}}".replace("{id}", entityId));
                {{ENTITY_NAME}} entity = transformer.transform(response.getData());

                if (targetStatus.equalsIgnoreCase(entity.getStatus())) {
                    // Target status reached
                    result.put("Event Occurred", true);
                    result.put("{{ENTITY_NAME}}", entity);
                    result.put("Final Status", entity.getStatus());
                    result.put("Wait Duration Seconds",
                        (System.currentTimeMillis() - startTime) / 1000);
                    return result;
                }

                // Wait before next poll
                Thread.sleep(pollIntervalMs);
            }

            // Timeout reached
            result.put("Event Occurred", false);
            result.put("error", "Timeout waiting for status: " + targetStatus);
            result.put("Wait Duration Seconds", timeoutMinutes * 60);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            result.put("Event Occurred", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Polling interrupted");
        } catch (Exception e) {
            result.put("Event Occurred", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Error during polling: " + e.getMessage());
        }

        return result;
    }
```

## 5. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class {{REQUEST_NAME}}Test {

    @Mock
    private ApiClient mockClient;

    private {{DOMAIN_NAME}}Area area;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        area = new {{DOMAIN_NAME}}Area(mockClient);
    }

    @Test
    void testCheckCondition_whenStatusMatches_returnsComplete() {
        // Arrange
        {{ENTITY_NAME}} entity = new {{ENTITY_NAME}}();
        entity.setId("123");
        entity.setStatus("resolved");

        when(mockClient.get(anyString())).thenReturn(mockResponse(entity));

        // Act
        PollingResult result = area.checkCondition("123", "resolved");

        // Assert
        assertEquals(PollingResult.Status.COMPLETE, result.getStatus());
        assertTrue((Boolean) result.getData().get("Event Occurred"));
    }

    @Test
    void testCheckCondition_whenStatusDifferent_continuesPolling() {
        {{ENTITY_NAME}} entity = new {{ENTITY_NAME}}();
        entity.setId("123");
        entity.setStatus("open");

        when(mockClient.get(anyString())).thenReturn(mockResponse(entity));

        PollingResult result = area.checkCondition("123", "resolved");

        assertEquals(PollingResult.Status.CONTINUE_POLLING, result.getStatus());
    }

    @Test
    void testCheckCondition_whenTerminalState_returnsComplete() {
        {{ENTITY_NAME}} entity = new {{ENTITY_NAME}}();
        entity.setId("123");
        entity.setStatus("closed");

        when(mockClient.get(anyString())).thenReturn(mockResponse(entity));

        PollingResult result = area.checkCondition("123", "resolved");

        assertEquals(PollingResult.Status.COMPLETE, result.getStatus());
        assertFalse((Boolean) result.getData().get("Event Occurred"));
    }
}
```

## Validation Checklist

- [ ] `@CatalogRequest` annotation has `type = WAIT_FOR_EVENT`
- [ ] Entity ID is required input
- [ ] Target condition/status is clearly defined
- [ ] Timeout has reasonable default and maximum
- [ ] Poll interval has minimum to prevent API abuse
- [ ] Terminal states are handled (won't poll forever)
- [ ] Transient errors trigger retry, not failure
- [ ] Output includes whether event occurred
- [ ] Output includes wait duration for monitoring

## Best Practices

1. **Set reasonable defaults** - 30-60 second poll interval, 60 minute timeout
2. **Respect rate limits** - Don't poll too frequently
3. **Handle terminal states** - Stop polling if entity reaches a state that won't change
4. **Track duration** - Return how long the wait took for monitoring
5. **Allow cancellation** - Handle interrupts gracefully
6. **Log polling activity** - Track polls for debugging

## Related Prompts

- [08 - Add WAIT_FOR_EVENT with Webhook](08-add-wait-for-event-webhook.md)
- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
- [17 - Add Retry and Idempotency](17-add-retry-idempotency.md)
```

