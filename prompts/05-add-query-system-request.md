# Prompt 05: Add QUERY_SYSTEM Catalog Request

## Purpose

Add a read-only catalog request to an existing extension. QUERY_SYSTEM requests are used for operations that retrieve data without modifying the external system (list, search, get-by-id).

## Prerequisites

- Existing extension with project structure
- Area class for the domain
- API client configured

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `List Events` |
| Domain Name | `{{DOMAIN_NAME}}` | `Calendar` |
| Description | `{{DESCRIPTION}}` | `Retrieve upcoming calendar events` |
| API Endpoint | `{{API_ENDPOINT}}` | `/calendars/primary/events` |
| Entity Name | `{{ENTITY_NAME}}` | `Event` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.googlecalendar` |

---

## Prompt

```
I need you to add a QUERY_SYSTEM catalog request to my existing Krista extension.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **API Endpoint**: {{API_ENDPOINT}}
- **Entity Name**: {{ENTITY_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Add Catalog Request to Area Class

Add this method to your `{{DOMAIN_NAME}}Area.java`:

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
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
     */
    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.QUERY_SYSTEM,
        description = "{{DESCRIPTION}}"
    )
    // Input fields
    @Field.Text(name = "Page Token", required = false,
        description = "Token for pagination (leave empty for first page)")
    @Field.Text(name = "Page Size", required = false,
        description = "Number of items per page (default: 25, max: 100)")
    @Field.Text(name = "Search Query", required = false,
        description = "Optional search filter")
    // Output fields
    @Field.Output(name = "Items", type = Field.Output.Type.ENTITY_LIST,
        entityType = "{{ENTITY_NAME}}")
    @Field.Output(name = "Next Page Token", type = Field.Output.Type.TEXT)
    @Field.Output(name = "Total Count", type = Field.Output.Type.NUMBER)
    public Map<String, Object> {{REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Extract and validate input parameters
            String pageToken = (String) params.get("Page Token");
            String pageSizeStr = (String) params.get("Page Size");
            String searchQuery = (String) params.get("Search Query");
            
            // Parse page size with defaults
            int pageSize = 25;
            if (pageSizeStr != null && !pageSizeStr.isBlank()) {
                pageSize = Math.min(Integer.parseInt(pageSizeStr), 100);
            }
            
            // Build API request
            StringBuilder endpoint = new StringBuilder("{{API_ENDPOINT}}");
            endpoint.append("?maxResults=").append(pageSize);
            
            if (pageToken != null && !pageToken.isBlank()) {
                endpoint.append("&pageToken=").append(pageToken);
            }
            
            if (searchQuery != null && !searchQuery.isBlank()) {
                endpoint.append("&q=").append(java.net.URLEncoder.encode(searchQuery, "UTF-8"));
            }
            
            // Make API call
            ApiResponse response = client.get(endpoint.toString());
            
            // Transform response to entities
            List<{{ENTITY_NAME}}> items = transformer.transformList(response.getItems());
            
            // Build result
            result.put("Items", items);
            result.put("Next Page Token", response.getNextPageToken());
            result.put("Total Count", response.getTotalItems());
            result.put("success", true);
            
        } catch (IllegalArgumentException e) {
            // Input validation error
            result.put("success", false);
            result.put("errorType", "INPUT_ERROR");
            result.put("error", e.getMessage());
        } catch (SecurityException e) {
            // Authentication/authorization error
            result.put("success", false);
            result.put("errorType", "AUTHORIZATION_ERROR");
            result.put("error", e.getMessage());
        } catch (Exception e) {
            // System error
            result.put("success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", "Failed to retrieve items: " + e.getMessage());
        }
        
        return result;
    }
}
```

## 2. Create Entity Class

Create `{{ENTITY_NAME}}.java` in the entity package:

```java
package {{PACKAGE_NAME}}.entity;

import java.time.Instant;
import java.util.Map;

/**
 * Entity representing a {{ENTITY_NAME}} from the external system.
 */
public class {{ENTITY_NAME}} {

    private String id;
    private String name;
    private String description;
    private Instant createdAt;
    private Instant updatedAt;
    private Map<String, Object> metadata;

    // Default constructor
    public {{ENTITY_NAME}}() {}

    // Constructor with required fields
    public {{ENTITY_NAME}}(String id, String name) {
        this.id = id;
        this.name = name;
    }

    // Getters and setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}
```

## 3. Create Transformer Class

Create `{{ENTITY_NAME}}Transformer.java` in the transformation package:

```java
package {{PACKAGE_NAME}}.transformation;

import {{PACKAGE_NAME}}.entity.{{ENTITY_NAME}};
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.time.Instant;
import java.util.*;

/**
 * Transforms external API responses to {{ENTITY_NAME}} entities.
 */
public class {{ENTITY_NAME}}Transformer {

    /**
     * Transform a list of items from API response.
     */
    public List<{{ENTITY_NAME}}> transformList(JsonArray items) {
        List<{{ENTITY_NAME}}> result = new ArrayList<>();

        if (items == null) {
            return result;
        }

        for (JsonElement element : items) {
            if (element.isJsonObject()) {
                result.add(transform(element.getAsJsonObject()));
            }
        }

        return result;
    }

    /**
     * Transform a single item from API response.
     */
    public {{ENTITY_NAME}} transform(JsonObject json) {
        {{ENTITY_NAME}} entity = new {{ENTITY_NAME}}();

        // Map required fields
        if (json.has("id")) {
            entity.setId(json.get("id").getAsString());
        }

        if (json.has("name") || json.has("title") || json.has("summary")) {
            String name = getFirstNonNull(json, "name", "title", "summary");
            entity.setName(name);
        }

        // Map optional fields
        if (json.has("description")) {
            entity.setDescription(json.get("description").getAsString());
        }

        // Map timestamps
        if (json.has("created") || json.has("createdAt") || json.has("created_at")) {
            String timestamp = getFirstNonNull(json, "created", "createdAt", "created_at");
            if (timestamp != null) {
                entity.setCreatedAt(Instant.parse(timestamp));
            }
        }

        if (json.has("updated") || json.has("updatedAt") || json.has("updated_at")) {
            String timestamp = getFirstNonNull(json, "updated", "updatedAt", "updated_at");
            if (timestamp != null) {
                entity.setUpdatedAt(Instant.parse(timestamp));
            }
        }

        return entity;
    }

    private String getFirstNonNull(JsonObject json, String... keys) {
        for (String key : keys) {
            if (json.has(key) && !json.get(key).isJsonNull()) {
                return json.get(key).getAsString();
            }
        }
        return null;
    }
}
```

## 4. Create Helper Class (Optional but Recommended)

Create `{{REQUEST_NAME}}Helper.java` for validation and telemetry:

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.util.*;

/**
 * Helper class for {{REQUEST_NAME}} catalog request.
 * Handles validation, telemetry, and business logic.
 */
public class {{REQUEST_NAME}}Helper {

    // Telemetry metric names
    public static final String METRIC_REQUEST_COUNT = "{{REQUEST_NAME_SNAKE}}_request_count";
    public static final String METRIC_SUCCESS_COUNT = "{{REQUEST_NAME_SNAKE}}_success_count";
    public static final String METRIC_ERROR_COUNT = "{{REQUEST_NAME_SNAKE}}_error_count";

    /**
     * Validate input parameters.
     * @return List of validation errors (empty if valid)
     */
    public List<String> validate(Map<String, Object> params) {
        List<String> errors = new ArrayList<>();

        // Validate page size if provided
        String pageSizeStr = (String) params.get("Page Size");
        if (pageSizeStr != null && !pageSizeStr.isBlank()) {
            try {
                int pageSize = Integer.parseInt(pageSizeStr);
                if (pageSize < 1) {
                    errors.add("Page Size must be at least 1");
                }
                if (pageSize > 100) {
                    errors.add("Page Size cannot exceed 100");
                }
            } catch (NumberFormatException e) {
                errors.add("Page Size must be a valid number");
            }
        }

        return errors;
    }

    /**
     * Build the API endpoint with query parameters.
     */
    public String buildEndpoint(String baseEndpoint, Map<String, Object> params) {
        StringBuilder endpoint = new StringBuilder(baseEndpoint);
        List<String> queryParams = new ArrayList<>();

        // Add pagination
        String pageSizeStr = (String) params.get("Page Size");
        int pageSize = (pageSizeStr != null && !pageSizeStr.isBlank())
            ? Integer.parseInt(pageSizeStr) : 25;
        queryParams.add("maxResults=" + pageSize);

        String pageToken = (String) params.get("Page Token");
        if (pageToken != null && !pageToken.isBlank()) {
            queryParams.add("pageToken=" + pageToken);
        }

        // Add search query
        String searchQuery = (String) params.get("Search Query");
        if (searchQuery != null && !searchQuery.isBlank()) {
            try {
                queryParams.add("q=" + java.net.URLEncoder.encode(searchQuery, "UTF-8"));
            } catch (Exception e) {
                // Ignore encoding errors
            }
        }

        if (!queryParams.isEmpty()) {
            endpoint.append("?").append(String.join("&", queryParams));
        }

        return endpoint.toString();
    }
}
```

## 5. Write Unit Tests

Create `{{REQUEST_NAME}}Test.java`:

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
    void test{{REQUEST_NAME}}_withValidParams_returnsItems() {
        // Arrange
        Map<String, Object> params = new HashMap<>();
        params.put("Page Size", "10");

        // Mock API response
        // when(mockClient.get(anyString())).thenReturn(...);

        // Act
        Map<String, Object> result = area.{{REQUEST_NAME_CAMEL}}(params);

        // Assert
        assertTrue((Boolean) result.get("success"));
        assertNotNull(result.get("Items"));
    }

    @Test
    void test{{REQUEST_NAME}}_withInvalidPageSize_returnsError() {
        Map<String, Object> params = new HashMap<>();
        params.put("Page Size", "invalid");

        Map<String, Object> result = area.{{REQUEST_NAME_CAMEL}}(params);

        assertFalse((Boolean) result.get("success"));
        assertEquals("INPUT_ERROR", result.get("errorType"));
    }
}
```

## Validation Checklist

- [ ] `@CatalogRequest` annotation has `type = QUERY_SYSTEM`
- [ ] All input fields have `@Field.*` annotations
- [ ] Output fields are declared with `@Field.Output`
- [ ] Pagination is supported (Page Token, Page Size)
- [ ] Error handling covers INPUT_ERROR, AUTHORIZATION_ERROR, SYSTEM_ERROR
- [ ] Transformer handles null/missing fields gracefully
- [ ] Unit tests cover success and error cases

## Best Practices

1. **Always validate input** before making API calls
2. **Use pagination** for list operations to avoid timeouts
3. **Transform data** to Krista entities (don't return raw API responses)
4. **Handle errors gracefully** with appropriate error types
5. **Log telemetry metrics** for monitoring

## Related Prompts

- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [09 - Add Request with Complex Validation](09-add-request-complex-validation.md)
- [11 - Add Helper Class](11-add-helper-class.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

