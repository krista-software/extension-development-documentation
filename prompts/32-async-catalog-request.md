# Prompt 32: Async Catalog Request with Task ID

## Purpose

Implement an asynchronous catalog request that returns a task ID immediately and processes the operation in a background thread. The caller retrieves results later through a separate "Get Result" request. Use this for long-running operations (bulk exports, large data processing, external operations with unpredictable latency).

## Prerequisites

- Existing extension with Area class
- `EventHandler` available via dependency injection
- `ExecutorService` for background thread management

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Export Report` |
| Result Request Name | `{{RESULT_REQUEST_NAME}}` | `Get Export Result` |
| Domain Name | `{{DOMAIN_NAME}}` | `Reports` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.reports` |
| Area Name | `{{AREA_NAME}}` | `ReportsArea` |

---

## Prompt

```
I need you to implement an async catalog request pair (start + get result) for my Krista extension.

## Request Details

- **Async Request**: {{REQUEST_NAME}}
- **Result Request**: {{RESULT_REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Area Class with Async Request

```java
package {{PACKAGE_NAME}}.catalog;

import app.krista.extension.executor.ExtensionResponse;
import app.krista.extension.executor.ExtensionResponseBuilder;
import app.krista.extension.impl.anno.*;
import app.krista.extensions.util.EventHandler;
import app.krista.model.base.FreeForm;
import com.kristasoft.common.holders.ThreadLocalProxy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Domain(id = "{{DOMAIN_ID}}", name = "{{DOMAIN_NAME}}", ...)
public class {{AREA_NAME}} {
    private static final Logger LOGGER = LoggerFactory.getLogger({{AREA_NAME}}.class);

    private final EventHandler eventHandler;
    private final YourService service;
    final ExecutorService executorService = Executors.newFixedThreadPool(5);

    @Inject
    public {{AREA_NAME}}(EventHandler eventHandler, YourService service) {
        this.eventHandler = eventHandler;
        this.service = service;
    }

    // --- Async start request ---
    @CatalogRequest(
        id = "localDomainRequest_{{UUID}}",
        name = "{{REQUEST_NAME}}",
        description = "Starts async processing and returns a task ID",
        area = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.CHANGE_SYSTEM)
    @Field.Desc(name = "Task ID", type = "Text", required = false)
    public ExtensionResponse startAsyncOperation(
            @Field.Text(name = "Input Parameter", required = true,
                attributes = {@Attribute(name = "visualWidth", value = "L")},
                options = {}) String inputParam) {

        String taskId = UUID.randomUUID().toString();

        // CRITICAL: Capture ThreadLocal context before submitting to background thread
        Map<String, Object> threadContext = ThreadLocalProxy.getAll();

        executorService.submit(() -> {
            try {
                // Restore ThreadLocal context on background thread
                ThreadLocalProxy.setAll(threadContext);

                // Perform the long-running operation
                Map<String, Object> result = service.processLongRunningOperation(inputParam);

                // Deliver result via EventHandler
                FreeForm freeForm = new FreeForm();
                for (Map.Entry<String, Object> entry : result.entrySet()) {
                    freeForm.put(entry.getKey(), FreeForm.FieldType.TEXT, entry.getValue());
                }
                eventHandler.handleEvent(taskId, freeForm);

                LOGGER.info("Async operation completed for taskId: {}", taskId);
            } catch (Exception e) {
                LOGGER.error("Async operation failed for taskId: {}", taskId, e);

                FreeForm errorResult = new FreeForm();
                errorResult.put("error", FreeForm.FieldType.TEXT, e.getMessage());
                eventHandler.handleEvent(taskId, errorResult);
            }
        });

        // Return task ID immediately
        return new ExtensionResponseBuilder()
            .success(Map.of("Task ID", taskId))
            .build();
    }

    // --- Result retrieval request ---
    @CatalogRequest(
        id = "localDomainRequest_{{UUID_2}}",
        name = "{{RESULT_REQUEST_NAME}}",
        description = "Retrieve results of an async operation by task ID",
        area = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.WAIT_FOR_EVENT)
    @Field(name = "Result", type = "FreeForm", required = false,
        attributes = {}, options = {})
    public ExtensionResponse getAsyncResult(
            @Field.Text(name = "Task ID", required = true,
                attributes = {@Attribute(name = "visualWidth", value = "S")},
                options = {}) String taskId) {
        // Platform handles event matching by task ID
        // This method body may not execute — the WAIT_FOR_EVENT framework
        // intercepts when eventHandler.handleEvent(taskId, ...) is called
        return new ExtensionResponseBuilder()
            .success(Map.of("Result", Map.of("status", "waiting")))
            .build();
    }
}
```

## 2. ThreadLocal Context Preservation

Background threads lose the request-scoped context (AuthorizationContext, RequestContext). Preserve it:

```java
// Before submitting to executor (on request thread)
Map<String, Object> threadContext = ThreadLocalProxy.getAll();

executorService.submit(() -> {
    // First line in background thread — restore context
    ThreadLocalProxy.setAll(threadContext);

    try {
        // Now AuthorizationContext and other request-scoped objects work
        result = service.callExternalApi();
    } finally {
        // Optional: clean up to prevent leaks
        ThreadLocalProxy.clearAll();
    }
});
```

Without this, any code that accesses `AuthorizationContext`, `RequestContext`, or file operations will fail with null context errors.

## 3. Event Delivery Timing

Add a small delay before event delivery to allow the event subscription system to initialize:

```java
executorService.submit(() -> {
    ThreadLocalProxy.setAll(threadContext);
    try {
        // Small delay for event system initialization
        Thread.sleep(2000);

        Map<String, Object> result = service.process(inputParam);
        FreeForm freeForm = buildFreeForm(result);
        eventHandler.handleEvent(taskId, freeForm);
    } catch (Exception e) {
        // Handle error...
    }
});
```

## Best Practices

1. **Always preserve ThreadLocal context** — background threads lose request-scoped state
2. **Use FreeForm for event results** — the EventHandler expects FreeForm payloads
3. **Handle errors in background thread** — deliver error results instead of swallowing exceptions
4. **Add startup delay** — allow 1-2 seconds for event subscription initialization
5. **Use bounded thread pools** — `newFixedThreadPool(5)` prevents unbounded thread creation
6. **Log task IDs** — essential for debugging async operations
7. **Do NOT mark async requests as `tool = true`** — MCP tools should return results synchronously

## Related Prompts

- [Prompt 07: WAIT_FOR_EVENT Polling](07-add-wait-for-event-polling.md) — alternative polling approach
- [Prompt 15: Lifecycle Hooks](15-implement-lifecycle-hooks.md) — executor cleanup on unload
- [Prompt 31: KeyValueStore](31-keyvaluestore-patterns.md) — persisting async state
```
