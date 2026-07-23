# Prompt 40: Batch Operations and Bulk Processing

## Purpose

Implement batch/bulk catalog requests that process multiple items in a single operation. Covers batch parameter binding, partial failure handling, progress tracking, and chunked processing for large datasets.

## Prerequisites

- Existing extension with single-item CRUD operations
- API client that supports bulk operations or iteration
- Understanding of the external API's batch limits

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.salesforce` |
| Entity Name | `{{ENTITY_NAME}}` | `Contact` |
| Batch Limit | `{{BATCH_LIMIT}}` | `200` |

---

## Prompt

```
I need you to implement batch/bulk operations for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Entity**: {{ENTITY_NAME}}
- **Max Batch Size**: {{BATCH_LIMIT}}

## 1. Batch Result Model

```java
package {{PACKAGE_NAME}}.catalog.entities;

public class BatchResult {
    public int totalItems;
    public int successCount;
    public int failureCount;
    public List<Map<String, Object>> failures; // Items that failed with error details

    public static BatchResult empty() {
        BatchResult r = new BatchResult();
        r.totalItems = 0;
        r.successCount = 0;
        r.failureCount = 0;
        r.failures = new ArrayList<>();
        return r;
    }

    public void recordSuccess() { successCount++; totalItems++; }

    public void recordFailure(String itemId, String error) {
        failureCount++;
        totalItems++;
        failures.add(Map.of("id", itemId, "error", error));
    }
}
```

## 2. Batch Processor (Chunked)

```java
package {{PACKAGE_NAME}}.impl;

import java.util.List;
import java.util.ArrayList;

public class BatchProcessor<T> {
    private final int chunkSize;

    public BatchProcessor(int chunkSize) {
        this.chunkSize = chunkSize;
    }

    public BatchResult process(List<T> items, ItemProcessor<T> processor) {
        BatchResult result = BatchResult.empty();

        for (List<T> chunk : partition(items, chunkSize)) {
            for (T item : chunk) {
                try {
                    processor.process(item);
                    result.recordSuccess();
                } catch (Exception e) {
                    result.recordFailure(
                        processor.getItemId(item),
                        e.getMessage());
                }
            }
        }
        return result;
    }

    private <E> List<List<E>> partition(List<E> list, int size) {
        List<List<E>> partitions = new ArrayList<>();
        for (int i = 0; i < list.size(); i += size) {
            partitions.add(list.subList(i, Math.min(i + size, list.size())));
        }
        return partitions;
    }

    @FunctionalInterface
    public interface ItemProcessor<T> {
        void process(T item) throws Exception;
        default String getItemId(T item) { return item.toString(); }
    }
}
```

## 3. Bulk Create Catalog Request

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Bulk Create {{ENTITY_NAME}}s",
    description = "Create multiple records in a single operation",
    area = "{{ENTITY_NAME}}s",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field(name = "Batch Result", type = "FreeForm", required = false,
    attributes = {}, options = {})
public ExtensionResponse bulkCreate(
        @Field.Desc(name = "Items", type = "[ Composite ]", required = true) 
            List<Map<String, Object>> items) {

    if (items == null || items.isEmpty()) {
        return errorResponse("No items provided");
    }

    if (items.size() > {{BATCH_LIMIT}}) {
        return errorResponse("Batch size exceeds limit of {{BATCH_LIMIT}}");
    }

    BatchProcessor<Map<String, Object>> processor = new BatchProcessor<>(50);
    BatchResult result = processor.process(items, new BatchProcessor.ItemProcessor<>() {
        @Override
        public void process(Map<String, Object> item) throws Exception {
            apiClient.create({{ENTITY_NAME}}CatalogType.toApiPayload(item));
        }

        @Override
        public String getItemId(Map<String, Object> item) {
            return String.valueOf(item.getOrDefault("Name", "unknown"));
        }
    });

    Map<String, Object> response = new HashMap<>();
    response.put("Batch Result", Map.of(
        "total", result.totalItems,
        "success", result.successCount,
        "failed", result.failureCount,
        "failures", result.failures
    ));
    return ExtensionResponseFactory.create(response);
}
```

## 4. Bulk Update (Diff-Based)

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Bulk Update {{ENTITY_NAME}}s",
    description = "Update multiple records, sending only changed fields",
    area = "{{ENTITY_NAME}}s",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field(name = "Batch Result", type = "FreeForm", required = false,
    attributes = {}, options = {})
public ExtensionResponse bulkUpdate(
        @Field.Desc(name = "Updates", type = "[ Composite ]", required = true)
            List<Map<String, Object>> updates) {

    BatchProcessor<Map<String, Object>> processor = new BatchProcessor<>(50);
    BatchResult result = processor.process(updates, new BatchProcessor.ItemProcessor<>() {
        @Override
        public void process(Map<String, Object> update) throws Exception {
            String id = (String) update.get("Id");
            if (id == null) throw new IllegalArgumentException("Id is required");

            // Fetch current, compute diff, send only changes
            Map<String, Object> current = apiClient.get(id);
            Map<String, Object> diff = FieldDiffDetector.getChangedFields(current, update);
            if (!diff.isEmpty()) {
                apiClient.patch(id, diff);
            }
        }

        @Override
        public String getItemId(Map<String, Object> item) {
            return (String) item.getOrDefault("Id", "unknown");
        }
    });

    return ExtensionResponseFactory.create(Map.of("Batch Result", result));
}
```

## 5. Async Bulk with Progress

For very large batches, combine with the async pattern:

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Bulk Import {{ENTITY_NAME}}s (Async)",
    description = "Import large dataset asynchronously",
    area = "{{ENTITY_NAME}}s",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.Desc(name = "Task ID", type = "Text", required = false)
public ExtensionResponse asyncBulkImport(
        @Field.File(name = "Data File", multipleFileUpload = false, required = true,
            attributes = {}, options = {}) File dataFile) {

    String taskId = UUID.randomUUID().toString();
    Map<String, Object> threadContext = ThreadLocalProxy.getAll();

    executorService.submit(() -> {
        ThreadLocalProxy.setAll(threadContext);
        try {
            List<Map<String, Object>> items = parseFile(dataFile);
            BatchProcessor<Map<String, Object>> processor = new BatchProcessor<>(50);
            BatchResult result = processor.process(items, item -> apiClient.create(item));

            FreeForm freeForm = new FreeForm();
            freeForm.put("total", FreeForm.FieldType.TEXT, String.valueOf(result.totalItems));
            freeForm.put("success", FreeForm.FieldType.TEXT, String.valueOf(result.successCount));
            freeForm.put("failed", FreeForm.FieldType.TEXT, String.valueOf(result.failureCount));
            eventHandler.handleEvent(taskId, freeForm);
        } catch (Exception e) {
            FreeForm error = new FreeForm();
            error.put("error", FreeForm.FieldType.TEXT, e.getMessage());
            eventHandler.handleEvent(taskId, error);
        }
    });

    return new ExtensionResponseBuilder()
        .success(Map.of("Task ID", taskId))
        .build();
}
```

## Best Practices

1. **Enforce batch size limits** — reject oversized batches with a clear error
2. **Process per-item, report per-batch** — don't let one failure abort the entire batch
3. **Return failure details** — include item ID and error message for each failed item
4. **Use chunking** — process in chunks of 50-200 to avoid memory pressure
5. **Send only changed fields** — use diff detection for bulk updates
6. **Use async for large imports** — files with 1000+ items should use the task ID pattern
7. **Log batch summary, not item details** — "Processed 150/200 items" not each item

## Related Prompts

- [Prompt 06: CHANGE_SYSTEM Request](06-add-change-system-request.md) — single-item operations
- [Prompt 32: Async Catalog Request](32-async-catalog-request.md) — for large batch async
- [Prompt 38: CRM Field Mapping](38-crm-field-mapping.md) — field diff detection
```
