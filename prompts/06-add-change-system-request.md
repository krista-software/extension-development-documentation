# Prompt 06: Add CHANGE_SYSTEM Catalog Request

## Purpose

Add a catalog request that modifies data in the external system (create, update, or delete operations). CHANGE_SYSTEM requests have side effects and should support retry mechanisms.

## Prerequisites

- Existing extension with project structure
- Area class for the domain
- API client configured

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Create Ticket` |
| Domain Name | `{{DOMAIN_NAME}}` | `Tickets` |
| Description | `{{DESCRIPTION}}` | `Create a new support ticket` |
| API Endpoint | `{{API_ENDPOINT}}` | `/tickets` |
| HTTP Method | `{{HTTP_METHOD}}` | `POST` |
| Entity Name | `{{ENTITY_NAME}}` | `Ticket` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.zendesk` |

---

## Prompt

```
I need you to add a CHANGE_SYSTEM catalog request to my existing Krista extension.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **API Endpoint**: {{API_ENDPOINT}}
- **HTTP Method**: {{HTTP_METHOD}}
- **Entity Name**: {{ENTITY_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Add Catalog Request to Area Class

Add this method to your `{{DOMAIN_NAME}}Area.java`:

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.controller.helper.{{REQUEST_NAME}}Helper;
import {{PACKAGE_NAME}}.entity.{{ENTITY_NAME}};
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.transformation.{{ENTITY_NAME}}Transformer;

import java.util.*;

public class {{DOMAIN_NAME}}Area {

    private final ApiClient client;
    private final {{ENTITY_NAME}}Transformer transformer;
    private final {{REQUEST_NAME}}Helper helper;

    public {{DOMAIN_NAME}}Area(ApiClient client) {
        this.client = client;
        this.transformer = new {{ENTITY_NAME}}Transformer();
        this.helper = new {{REQUEST_NAME}}Helper();
    }

    /**
     * {{DESCRIPTION}}
     * 
     * This is a CHANGE_SYSTEM request that modifies data in the external system.
     * It supports retry on transient failures when Allow Retry is enabled.
     */
    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        description = "{{DESCRIPTION}}"
    )
    // Required input fields
    @Field.Text(name = "Subject", required = true,
        description = "Subject/title of the {{ENTITY_NAME}}")
    @Field.TextArea(name = "Description", required = true,
        description = "Detailed description")
    // Optional input fields
    @Field.PickOne(name = "Priority", required = false,
        values = {"Low", "Normal", "High", "Urgent"},
        description = "Priority level")
    @Field.Text(name = "Assignee", required = false,
        description = "User to assign to")
    @Field.Text(name = "Tags", required = false,
        description = "Comma-separated tags")
    // Output fields
    @Field.Output(name = "{{ENTITY_NAME}} ID", type = Field.Output.Type.TEXT)
    @Field.Output(name = "{{ENTITY_NAME}}", type = Field.Output.Type.ENTITY,
        entityType = "{{ENTITY_NAME}}")
    @Field.Output(name = "Success", type = Field.Output.Type.BOOLEAN)
    public Map<String, Object> {{REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Step 1: Validate input parameters
            List<String> validationErrors = helper.validate(params);
            if (!validationErrors.isEmpty()) {
                result.put("Success", false);
                result.put("errorType", "INPUT_ERROR");
                result.put("error", String.join("; ", validationErrors));
                return result;
            }
            
            // Step 2: Build request payload
            Map<String, Object> payload = helper.buildPayload(params);
            
            // Step 3: Make API call
            ApiResponse response = client.post("{{API_ENDPOINT}}", payload);
            
            // Step 4: Transform response to entity
            {{ENTITY_NAME}} entity = transformer.transform(response.getData());
            
            // Step 5: Build success result
            result.put("{{ENTITY_NAME}} ID", entity.getId());
            result.put("{{ENTITY_NAME}}", entity);
            result.put("Success", true);
            
        } catch (IllegalArgumentException e) {
            // Input validation error - do not retry
            result.put("Success", false);
            result.put("errorType", "INPUT_ERROR");
            result.put("error", e.getMessage());
            result.put("retryable", false);
            
        } catch (SecurityException e) {
            // Authentication/authorization error - do not retry
            result.put("Success", false);
            result.put("errorType", "AUTHORIZATION_ERROR");
            result.put("error", e.getMessage());
            result.put("retryable", false);
            
        } catch (RateLimitException e) {
            // Rate limit - can retry
            result.put("Success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Rate limit exceeded. Please try again later.");
            result.put("retryable", true);
            
        } catch (Exception e) {
            // System error - may be retryable
            result.put("Success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Failed to create {{ENTITY_NAME}}: " + e.getMessage());
            result.put("retryable", isRetryableError(e));
        }
        
        return result;
    }

    private boolean isRetryableError(Exception e) {
        // Network errors, timeouts, and 5xx errors are typically retryable
        String message = e.getMessage();
        if (message == null) return false;
        
        return message.contains("timeout") ||
               message.contains("connection") ||
               message.contains("503") ||
               message.contains("502") ||
               message.contains("504");
    }
}
```

## 2. Create Helper Class

Create `{{REQUEST_NAME}}Helper.java`:

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.util.*;

/**
 * Helper class for {{REQUEST_NAME}} catalog request.
 * Handles validation, payload building, and telemetry.
 */
public class {{REQUEST_NAME}}Helper {

    // Telemetry metrics
    public static final String METRIC_REQUEST_COUNT = "{{REQUEST_NAME_SNAKE}}_request_count";
    public static final String METRIC_SUCCESS_COUNT = "{{REQUEST_NAME_SNAKE}}_success_count";
    public static final String METRIC_ERROR_COUNT = "{{REQUEST_NAME_SNAKE}}_error_count";
    public static final String METRIC_RETRY_COUNT = "{{REQUEST_NAME_SNAKE}}_retry_count";

    // Validation constants
    private static final int MAX_SUBJECT_LENGTH = 255;
    private static final int MAX_DESCRIPTION_LENGTH = 10000;

    /**
     * Validate input parameters.
     * @return List of validation errors (empty if valid)
     */
    public List<String> validate(Map<String, Object> params) {
        List<String> errors = new ArrayList<>();

        // Validate required: Subject
        String subject = (String) params.get("Subject");
        if (subject == null || subject.isBlank()) {
            errors.add("Subject is required");
        } else if (subject.length() > MAX_SUBJECT_LENGTH) {
            errors.add("Subject cannot exceed " + MAX_SUBJECT_LENGTH + " characters");
        }

        // Validate required: Description
        String description = (String) params.get("Description");
        if (description == null || description.isBlank()) {
            errors.add("Description is required");
        } else if (description.length() > MAX_DESCRIPTION_LENGTH) {
            errors.add("Description cannot exceed " + MAX_DESCRIPTION_LENGTH + " characters");
        }

        // Validate optional: Priority
        String priority = (String) params.get("Priority");
        if (priority != null && !priority.isBlank()) {
            Set<String> validPriorities = Set.of("Low", "Normal", "High", "Urgent");
            if (!validPriorities.contains(priority)) {
                errors.add("Priority must be one of: Low, Normal, High, Urgent");
            }
        }

        return errors;
    }

    /**
     * Build API request payload from input parameters.
     */
    public Map<String, Object> buildPayload(Map<String, Object> params) {
        Map<String, Object> payload = new HashMap<>();

        // Required fields
        payload.put("subject", params.get("Subject"));
        payload.put("description", params.get("Description"));

        // Optional fields
        String priority = (String) params.get("Priority");
        if (priority != null && !priority.isBlank()) {
            payload.put("priority", priority.toLowerCase());
        }

        String assignee = (String) params.get("Assignee");
        if (assignee != null && !assignee.isBlank()) {
            payload.put("assignee_id", assignee);
        }

        String tags = (String) params.get("Tags");
        if (tags != null && !tags.isBlank()) {
            List<String> tagList = Arrays.stream(tags.split(","))
                .map(String::trim)
                .filter(t -> !t.isEmpty())
                .collect(Collectors.toList());
            payload.put("tags", tagList);
        }

        return payload;
    }
}
```

## 3. Update Operation Variation

For update operations, modify the catalog request:

```java
    /**
     * Update an existing {{ENTITY_NAME}}.
     */
    @CatalogRequest(
        name = "Update {{ENTITY_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        description = "Update an existing {{ENTITY_NAME}}"
    )
    @Field.Text(name = "{{ENTITY_NAME}} ID", required = true,
        description = "ID of the {{ENTITY_NAME}} to update")
    @Field.Text(name = "Subject", required = false,
        description = "New subject (leave empty to keep current)")
    @Field.TextArea(name = "Description", required = false,
        description = "New description (leave empty to keep current)")
    @Field.PickOne(name = "Priority", required = false,
        values = {"Low", "Normal", "High", "Urgent"})
    @Field.Output(name = "Success", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "{{ENTITY_NAME}}", type = Field.Output.Type.ENTITY,
        entityType = "{{ENTITY_NAME}}")
    public Map<String, Object> update{{ENTITY_NAME}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        try {
            String entityId = (String) params.get("{{ENTITY_NAME}} ID");
            if (entityId == null || entityId.isBlank()) {
                throw new IllegalArgumentException("{{ENTITY_NAME}} ID is required");
            }

            // Build update payload (only include fields that have values)
            Map<String, Object> payload = new HashMap<>();

            String subject = (String) params.get("Subject");
            if (subject != null && !subject.isBlank()) {
                payload.put("subject", subject);
            }

            String description = (String) params.get("Description");
            if (description != null && !description.isBlank()) {
                payload.put("description", description);
            }

            String priority = (String) params.get("Priority");
            if (priority != null && !priority.isBlank()) {
                payload.put("priority", priority.toLowerCase());
            }

            if (payload.isEmpty()) {
                throw new IllegalArgumentException("At least one field must be provided for update");
            }

            // Make API call
            ApiResponse response = client.patch("{{API_ENDPOINT}}/" + entityId, payload);

            {{ENTITY_NAME}} entity = transformer.transform(response.getData());
            result.put("{{ENTITY_NAME}}", entity);
            result.put("Success", true);

        } catch (IllegalArgumentException e) {
            result.put("Success", false);
            result.put("errorType", "INPUT_ERROR");
            result.put("error", e.getMessage());
        } catch (Exception e) {
            result.put("Success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Failed to update: " + e.getMessage());
        }

        return result;
    }
```

## 4. Delete Operation Variation

```java
    /**
     * Delete a {{ENTITY_NAME}}.
     */
    @CatalogRequest(
        name = "Delete {{ENTITY_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        description = "Delete a {{ENTITY_NAME}}"
    )
    @Field.Text(name = "{{ENTITY_NAME}} ID", required = true,
        description = "ID of the {{ENTITY_NAME}} to delete")
    @Field.Checkbox(name = "Confirm Delete", required = true,
        description = "Confirm you want to delete this {{ENTITY_NAME}}")
    @Field.Output(name = "Success", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "Deleted ID", type = Field.Output.Type.TEXT)
    public Map<String, Object> delete{{ENTITY_NAME}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        try {
            String entityId = (String) params.get("{{ENTITY_NAME}} ID");
            if (entityId == null || entityId.isBlank()) {
                throw new IllegalArgumentException("{{ENTITY_NAME}} ID is required");
            }

            String confirmDelete = (String) params.get("Confirm Delete");
            if (!"true".equalsIgnoreCase(confirmDelete)) {
                throw new IllegalArgumentException("You must confirm deletion");
            }

            // Make delete API call
            client.delete("{{API_ENDPOINT}}/" + entityId);

            result.put("Deleted ID", entityId);
            result.put("Success", true);

        } catch (IllegalArgumentException e) {
            result.put("Success", false);
            result.put("errorType", "INPUT_ERROR");
            result.put("error", e.getMessage());
        } catch (NotFoundException e) {
            result.put("Success", false);
            result.put("errorType", "LOGIC_ERROR");
            result.put("error", "{{ENTITY_NAME}} not found: " + e.getMessage());
        } catch (Exception e) {
            result.put("Success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Failed to delete: " + e.getMessage());
        }

        return result;
    }
```

## 5. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.controller.helper.{{REQUEST_NAME}}Helper;
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
    private {{REQUEST_NAME}}Helper helper;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        area = new {{DOMAIN_NAME}}Area(mockClient);
        helper = new {{REQUEST_NAME}}Helper();
    }

    @Test
    void testValidate_withValidParams_returnsNoErrors() {
        Map<String, Object> params = new HashMap<>();
        params.put("Subject", "Test Subject");
        params.put("Description", "Test Description");
        params.put("Priority", "Normal");

        List<String> errors = helper.validate(params);

        assertTrue(errors.isEmpty());
    }

    @Test
    void testValidate_withMissingSubject_returnsError() {
        Map<String, Object> params = new HashMap<>();
        params.put("Description", "Test Description");

        List<String> errors = helper.validate(params);

        assertEquals(1, errors.size());
        assertTrue(errors.get(0).contains("Subject"));
    }

    @Test
    void testValidate_withInvalidPriority_returnsError() {
        Map<String, Object> params = new HashMap<>();
        params.put("Subject", "Test");
        params.put("Description", "Test");
        params.put("Priority", "InvalidPriority");

        List<String> errors = helper.validate(params);

        assertEquals(1, errors.size());
        assertTrue(errors.get(0).contains("Priority"));
    }

    @Test
    void testBuildPayload_mapsFieldsCorrectly() {
        Map<String, Object> params = new HashMap<>();
        params.put("Subject", "Test Subject");
        params.put("Description", "Test Description");
        params.put("Priority", "High");
        params.put("Tags", "tag1, tag2, tag3");

        Map<String, Object> payload = helper.buildPayload(params);

        assertEquals("Test Subject", payload.get("subject"));
        assertEquals("Test Description", payload.get("description"));
        assertEquals("high", payload.get("priority"));
        List<String> tags = (List<String>) payload.get("tags");
        assertEquals(3, tags.size());
    }

    @Test
    void test{{REQUEST_NAME}}_withValidParams_createsEntity() {
        Map<String, Object> params = new HashMap<>();
        params.put("Subject", "Test Subject");
        params.put("Description", "Test Description");

        // Mock successful API response
        // when(mockClient.post(eq("{{API_ENDPOINT}}"), any())).thenReturn(...);

        Map<String, Object> result = area.{{REQUEST_NAME_CAMEL}}(params);

        assertTrue((Boolean) result.get("Success"));
        assertNotNull(result.get("{{ENTITY_NAME}} ID"));
    }

    @Test
    void test{{REQUEST_NAME}}_withMissingRequired_returnsInputError() {
        Map<String, Object> params = new HashMap<>();
        // Missing Subject and Description

        Map<String, Object> result = area.{{REQUEST_NAME_CAMEL}}(params);

        assertFalse((Boolean) result.get("Success"));
        assertEquals("INPUT_ERROR", result.get("errorType"));
    }
}
```

## Validation Checklist

- [ ] `@CatalogRequest` annotation has `type = CHANGE_SYSTEM`
- [ ] All required input fields have `required = true`
- [ ] Output fields include Success boolean
- [ ] Helper class validates all required fields
- [ ] Helper class validates field lengths and formats
- [ ] Error handling distinguishes INPUT_ERROR, LOGIC_ERROR, SYSTEM_ERROR
- [ ] Retryable flag is set appropriately for each error type
- [ ] Update operation only sends changed fields
- [ ] Delete operation requires confirmation
- [ ] Unit tests cover validation, success, and error cases

## Best Practices

1. **Validate before API calls** - Always validate input before making external calls
2. **Use appropriate error types**:
   - INPUT_ERROR: Invalid user input
   - LOGIC_ERROR: Business rule violations (e.g., not found)
   - SYSTEM_ERROR: External system failures
   - AUTHORIZATION_ERROR: Permission issues
3. **Mark retryable errors** - Only network/timeout errors should be retryable
4. **Confirm destructive operations** - Require confirmation for deletes
5. **Partial updates** - Only send changed fields in update operations

## Related Prompts

- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
- [09 - Add Request with Complex Validation](09-add-request-complex-validation.md)
- [11 - Add Helper Class](11-add-helper-class.md)
- [17 - Add Retry and Idempotency](17-add-retry-idempotency.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

