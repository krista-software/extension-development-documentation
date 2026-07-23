# Prompt 10: Add Sub-Catalog Request

## Purpose

Add a sub-catalog request that provides helper operations for a parent catalog request. Sub-catalog requests are used for operations like fetching dropdown options, validating IDs, or providing autocomplete suggestions.

## Prerequisites

- Existing extension with project structure
- Parent catalog request that needs helper data
- Understanding of the relationship between parent and sub-catalog requests

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Sub-Request Name | `{{SUB_REQUEST_NAME}}` | `Get Available Calendars` |
| Parent Request Name | `{{PARENT_REQUEST_NAME}}` | `Schedule Meeting` |
| Domain Name | `{{DOMAIN_NAME}}` | `Calendar` |
| Description | `{{DESCRIPTION}}` | `Get list of calendars for selection` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.googlecalendar` |

---

## Prompt

```
I need you to add a sub-catalog request to my existing Krista extension.

## Request Details

- **Sub-Request Name**: {{SUB_REQUEST_NAME}}
- **Parent Request Name**: {{PARENT_REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **Package**: {{PACKAGE_NAME}}

## 1. Add Sub-Catalog Request to Area Class

Add this method to your `{{DOMAIN_NAME}}Area.java`:

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.integration.ApiClient;

import java.util.*;

public class {{DOMAIN_NAME}}Area {

    private final ApiClient client;

    public {{DOMAIN_NAME}}Area(ApiClient client) {
        this.client = client;
    }

    /**
     * {{DESCRIPTION}}
     * 
     * This is a sub-catalog request that provides data for the parent request.
     * It is typically used to populate dropdown fields or provide suggestions.
     */
    @SubCatalogRequest(
        name = "{{SUB_REQUEST_NAME}}",
        parentRequest = "{{PARENT_REQUEST_NAME}}",
        description = "{{DESCRIPTION}}"
    )
    // Optional filter inputs
    @Field.Text(name = "Search", required = false,
        description = "Filter results by name")
    @Field.Text(name = "Limit", required = false,
        description = "Maximum number of results (default: 50)")
    // Output fields
    @Field.Output(name = "Items", type = Field.Output.Type.ENTITY_LIST,
        entityType = "SelectOption")
    @Field.Output(name = "Total Count", type = Field.Output.Type.NUMBER)
    public Map<String, Object> {{SUB_REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Parse parameters
            String search = (String) params.get("Search");
            int limit = 50;
            String limitStr = (String) params.get("Limit");
            if (limitStr != null && !limitStr.isBlank()) {
                limit = Math.min(Integer.parseInt(limitStr), 100);
            }
            
            // Build API request
            StringBuilder endpoint = new StringBuilder("/calendars");
            List<String> queryParams = new ArrayList<>();
            
            if (search != null && !search.isBlank()) {
                queryParams.add("q=" + java.net.URLEncoder.encode(search, "UTF-8"));
            }
            queryParams.add("maxResults=" + limit);
            
            if (!queryParams.isEmpty()) {
                endpoint.append("?").append(String.join("&", queryParams));
            }
            
            // Make API call
            ApiResponse response = client.get(endpoint.toString());
            
            // Transform to SelectOption format for dropdowns
            List<SelectOption> options = transformToOptions(response.getItems());
            
            result.put("Items", options);
            result.put("Total Count", options.size());
            
        } catch (Exception e) {
            result.put("Items", Collections.emptyList());
            result.put("Total Count", 0);
            result.put("error", "Failed to fetch options: " + e.getMessage());
        }
        
        return result;
    }

    /**
     * Transform API response items to SelectOption format.
     */
    private List<SelectOption> transformToOptions(List<Map<String, Object>> items) {
        List<SelectOption> options = new ArrayList<>();
        
        for (Map<String, Object> item : items) {
            SelectOption option = new SelectOption();
            option.setValue((String) item.get("id"));
            option.setLabel((String) item.get("summary"));
            option.setDescription((String) item.get("description"));
            options.add(option);
        }
        
        return options;
    }
}
```

## 2. Create SelectOption Entity

Create a reusable entity for dropdown options:

```java
package {{PACKAGE_NAME}}.entity;

/**
 * Represents a selectable option for dropdowns and autocomplete.
 */
public class SelectOption {

    private String value;      // The ID/value to submit
    private String label;      // Display text
    private String description; // Optional description/subtitle
    private String icon;       // Optional icon URL
    private boolean disabled;  // Whether option is selectable
    private Map<String, Object> metadata; // Additional data

    // Default constructor
    public SelectOption() {}

    // Convenience constructor
    public SelectOption(String value, String label) {
        this.value = value;
        this.label = label;
    }

    // Full constructor
    public SelectOption(String value, String label, String description) {
        this.value = value;
        this.label = label;
        this.description = description;
    }

    // Getters and setters
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public boolean isDisabled() { return disabled; }
    public void setDisabled(boolean disabled) { this.disabled = disabled; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}
```

## 3. Common Sub-Catalog Request Patterns

### Pattern A: Get Users/Assignees

```java
    @SubCatalogRequest(
        name = "Get Users",
        parentRequest = "Create Ticket",
        description = "Get list of users for assignment"
    )
    @Field.Text(name = "Search", required = false)
    @Field.Output(name = "Items", type = Field.Output.Type.ENTITY_LIST,
        entityType = "SelectOption")
    public Map<String, Object> getUsers(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        String search = (String) params.get("Search");
        List<Map<String, Object>> users = client.get("/users?role=agent");

        List<SelectOption> options = users.stream()
            .filter(u -> search == null ||
                ((String) u.get("name")).toLowerCase().contains(search.toLowerCase()))
            .map(u -> new SelectOption(
                (String) u.get("id"),
                (String) u.get("name"),
                (String) u.get("email")
            ))
            .collect(Collectors.toList());

        result.put("Items", options);
        return result;
    }
```

### Pattern B: Get Categories/Types

```java
    @SubCatalogRequest(
        name = "Get Ticket Types",
        parentRequest = "Create Ticket",
        description = "Get available ticket types"
    )
    @Field.Output(name = "Items", type = Field.Output.Type.ENTITY_LIST,
        entityType = "SelectOption")
    public Map<String, Object> getTicketTypes(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        // These might be static or fetched from API
        List<SelectOption> options = Arrays.asList(
            new SelectOption("incident", "Incident", "Report a problem"),
            new SelectOption("question", "Question", "Ask a question"),
            new SelectOption("task", "Task", "Request a task"),
            new SelectOption("problem", "Problem", "Report a recurring issue")
        );

        result.put("Items", options);
        return result;
    }
```

### Pattern C: Validate ID Exists

```java
    @SubCatalogRequest(
        name = "Validate Ticket ID",
        parentRequest = "Update Ticket",
        description = "Validate that a ticket ID exists"
    )
    @Field.Text(name = "Ticket ID", required = true)
    @Field.Output(name = "Valid", type = Field.Output.Type.BOOLEAN)
    @Field.Output(name = "Ticket", type = Field.Output.Type.ENTITY,
        entityType = "Ticket")
    public Map<String, Object> validateTicketId(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        String ticketId = (String) params.get("Ticket ID");

        try {
            ApiResponse response = client.get("/tickets/" + ticketId);
            Ticket ticket = transformer.transform(response.getData());

            result.put("Valid", true);
            result.put("Ticket", ticket);

        } catch (NotFoundException e) {
            result.put("Valid", false);
            result.put("error", "Ticket not found: " + ticketId);
        }

        return result;
    }
```

### Pattern D: Dependent Dropdown (Cascading)

```java
    @SubCatalogRequest(
        name = "Get Subcategories",
        parentRequest = "Create Ticket",
        description = "Get subcategories based on selected category"
    )
    @Field.Text(name = "Category ID", required = true,
        description = "Parent category ID")
    @Field.Output(name = "Items", type = Field.Output.Type.ENTITY_LIST,
        entityType = "SelectOption")
    public Map<String, Object> getSubcategories(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();

        String categoryId = (String) params.get("Category ID");

        if (categoryId == null || categoryId.isBlank()) {
            result.put("Items", Collections.emptyList());
            return result;
        }

        List<Map<String, Object>> subcategories =
            client.get("/categories/" + categoryId + "/subcategories");

        List<SelectOption> options = subcategories.stream()
            .map(s -> new SelectOption(
                (String) s.get("id"),
                (String) s.get("name")
            ))
            .collect(Collectors.toList());

        result.put("Items", options);
        return result;
    }
```

## 4. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class {{SUB_REQUEST_NAME}}Test {

    @Mock
    private ApiClient mockClient;

    private {{DOMAIN_NAME}}Area area;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        area = new {{DOMAIN_NAME}}Area(mockClient);
    }

    @Test
    void testGetOptions_returnsFormattedList() {
        // Arrange
        List<Map<String, Object>> apiResponse = Arrays.asList(
            Map.of("id", "cal1", "summary", "Work Calendar"),
            Map.of("id", "cal2", "summary", "Personal Calendar")
        );
        when(mockClient.get(anyString())).thenReturn(new ApiResponse(apiResponse));

        // Act
        Map<String, Object> result = area.{{SUB_REQUEST_NAME_CAMEL}}(new HashMap<>());

        // Assert
        List<SelectOption> items = (List<SelectOption>) result.get("Items");
        assertEquals(2, items.size());
        assertEquals("cal1", items.get(0).getValue());
        assertEquals("Work Calendar", items.get(0).getLabel());
    }

    @Test
    void testGetOptions_withSearch_filtersResults() {
        Map<String, Object> params = new HashMap<>();
        params.put("Search", "work");

        // Mock and test filtering
        Map<String, Object> result = area.{{SUB_REQUEST_NAME_CAMEL}}(params);

        assertNotNull(result.get("Items"));
    }

    @Test
    void testGetOptions_withLimit_respectsMaxResults() {
        Map<String, Object> params = new HashMap<>();
        params.put("Limit", "10");

        Map<String, Object> result = area.{{SUB_REQUEST_NAME_CAMEL}}(params);

        List<SelectOption> items = (List<SelectOption>) result.get("Items");
        assertTrue(items.size() <= 10);
    }

    @Test
    void testGetOptions_onError_returnsEmptyList() {
        when(mockClient.get(anyString())).thenThrow(new RuntimeException("API Error"));

        Map<String, Object> result = area.{{SUB_REQUEST_NAME_CAMEL}}(new HashMap<>());

        List<SelectOption> items = (List<SelectOption>) result.get("Items");
        assertTrue(items.isEmpty());
        assertNotNull(result.get("error"));
    }
}
```

## Validation Checklist

- [ ] `@SubCatalogRequest` annotation used (not `@CatalogRequest`)
- [ ] `parentRequest` references valid parent catalog request
- [ ] Returns `SelectOption` entities for dropdown compatibility
- [ ] Search/filter parameter is optional
- [ ] Limit parameter has reasonable default and maximum
- [ ] Error handling returns empty list (not null)
- [ ] Response is fast (sub-catalog requests should be quick)

## Best Practices

1. **Keep it fast** - Sub-catalog requests are called frequently; cache when possible
2. **Return SelectOption format** - Consistent format for all dropdown data
3. **Support search** - Allow filtering for large datasets
4. **Limit results** - Don't return thousands of options
5. **Handle errors gracefully** - Return empty list on error, not exception
6. **Cache static data** - Categories/types that don't change often

## Common Use Cases

| Use Case | Sub-Request Name | Returns |
|----------|------------------|---------|
| User selection | Get Users | List of users |
| Category dropdown | Get Categories | List of categories |
| Dependent dropdown | Get Subcategories | Filtered by parent |
| ID validation | Validate Entity ID | Boolean + entity |
| Autocomplete | Search Items | Filtered list |

## Related Prompts

- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [09 - Add Request with Complex Validation](09-add-request-complex-validation.md)
```

