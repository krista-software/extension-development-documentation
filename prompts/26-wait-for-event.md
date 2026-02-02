# Prompt 26: WAIT_FOR_EVENT Implementation

## Purpose

Implement the WAIT_FOR_EVENT pattern for asynchronous event-driven architecture in Krista extensions, enabling processes to pause execution, wait for external events, and resume with event data.

## Prerequisites

- Existing Krista extension project
- Understanding of event-driven architecture
- Familiarity with webhook or polling patterns

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `{EVENT_NAME}` | Name of the event | `MAIL_RECEIVED` |
| `{AREA_NAME}` | Catalog area name | `Messaging` |
| `{METHOD_NAME}` | Method name | `mailReceivedAlert` |
| `{OUTPUT_ENTITY}` | Output entity type | `Mail Details` |

---

## Prompt

```
I need to implement a WAIT_FOR_EVENT catalog request for {EVENT_NAME} in my Krista extension.

## Event Requirements

- Event Name: {EVENT_NAME}
- Area: {AREA_NAME}
- Method: {METHOD_NAME}
- Output: {OUTPUT_ENTITY}

## Architecture Overview

The WAIT_FOR_EVENT pattern flow:

```
1. Process calls WAIT_FOR_EVENT method → Krista registers it as event listener
2. External event occurs → Event producer calls eventHandler.handleEvent()
3. Krista routes event to registered WAIT_FOR_EVENT method
4. Method processes event data and returns response
5. Original process continues with the response data
```

## Implementation Requirements

### 1. EventHandler Interface

Inject the EventHandler for event routing:

```java
public interface EventHandler {
    void handleEvent(String eventName, FreeForm eventData);
}
```

### 2. WAIT_FOR_EVENT Method

```java
@CatalogRequest(
    id = "localDomainRequest_{UUID}",
    name = "{METHOD_NAME}",
    description = "Waits for {EVENT_NAME} event",
    area = "{AREA_NAME}",
    type = CatalogRequest.Type.WAIT_FOR_EVENT)
@Field.Desc(name = "{OUTPUT_ENTITY}", type = "Entity({OUTPUT_ENTITY})", required = false)
public ExtensionResponse {METHOD_NAME}(
        @Field(name = "eventName", type = "Text") String eventName,
        @Field(name = "eventData", type = "FreeForm") FreeForm eventData) {
    
    if (eventName.equalsIgnoreCase("{EVENT_NAME}")) {
        // Process the event data
        String dataId = (String) eventData.get("dataId");
        
        // Fetch and transform the data
        {OUTPUT_ENTITY} result = processEvent(dataId);
        
        return ExtensionResponseFactory.create(Map.of("{OUTPUT_ENTITY}", result));
    }
    throw new IllegalStateException("Unexpected event: " + eventName);
}
```

### 3. Event Producer (Webhook Handler)

```java
@POST
@Path("/notification")
@Consumes(MediaType.APPLICATION_JSON)
public Response handleNotification(JsonObject notification) {
    // Extract event data from webhook payload
    String dataId = notification.get("id").getAsString();
    
    // Create event data
    FreeForm freeForm = new FreeForm();
    freeForm.put("dataId", "Text", dataId);
    
    // Trigger the event
    eventHandler.handleEvent("{EVENT_NAME}", freeForm);
    
    return Response.status(200).build();
}
```

### 4. Bootstrap Initialization (for webhook-based events)

```java
@Bootstrap
public class EventBootstrap {
    
    @Inject
    private EventHandler eventHandler;
    
    @Inject
    private WebhookService webhookService;
    
    public void initialize() {
        // Register webhook subscription
        webhookService.createSubscription(
            callbackUrl,
            eventTypes,
            expirationTime
        );
    }
}
```

## Event Types

### Real-time Events (Webhooks)
- External system pushes notifications
- Requires webhook endpoint and subscription management
- Best for: Email notifications, system alerts

### Task-based Events (Async Processing)
- Internal async task completion
- Uses ExecutorService for background processing
- Best for: Long-running operations, batch processing

### Polling Events
- Periodic checks for changes
- Uses scheduled tasks
- Best for: Systems without webhook support

Please implement the WAIT_FOR_EVENT pattern following these guidelines.
```

---

## Key Benefits

- **Non-blocking**: System doesn't hold connections while waiting
- **Scalable**: Handles many concurrent waiting processes
- **Flexible**: Works with webhooks, polling, database changes
- **Reliable**: Built-in state management and error handling

## Validation Checklist

- [ ] WAIT_FOR_EVENT method has correct signature
- [ ] EventHandler properly injected
- [ ] Event producer triggers events correctly
- [ ] Event data properly structured in FreeForm
- [ ] Error handling for unexpected events
- [ ] Bootstrap initialization for webhooks (if needed)

## Related Prompts

- [Prompt 07: WAIT_FOR_EVENT with Polling](07-add-wait-for-event-polling.md)
- [Prompt 08: WAIT_FOR_EVENT with Webhooks](08-add-wait-for-event-webhook.md)
- [Prompt 20: Add Webhook Handler](20-add-webhook-handler.md)

