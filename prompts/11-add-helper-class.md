# Prompt 11: Add Helper Class with Validation and Telemetry

## Purpose

Create a helper class that encapsulates validation logic, telemetry tracking, and business rules for a catalog request. This pattern promotes separation of concerns and testability.

## Prerequisites

- Existing extension with catalog request
- Understanding of validation requirements
- Telemetry/metrics requirements

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Create Ticket` |
| Helper Class Name | `{{HELPER_NAME}}` | `CreateTicketHelper` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.zendesk` |

---

## Prompt

```
I need you to create a comprehensive helper class for my catalog request.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Helper Class Name**: {{HELPER_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Create Helper Class

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.time.*;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Helper class for {{REQUEST_NAME}} catalog request.
 * 
 * Responsibilities:
 * - Input validation
 * - Payload building
 * - Telemetry tracking
 * - Business rule enforcement
 */
public class {{HELPER_NAME}} {

    // ============================================================
    // TELEMETRY METRICS
    // ============================================================
    
    public static final String METRIC_REQUEST_COUNT = "{{REQUEST_NAME_SNAKE}}_request_count";
    public static final String METRIC_SUCCESS_COUNT = "{{REQUEST_NAME_SNAKE}}_success_count";
    public static final String METRIC_ERROR_COUNT = "{{REQUEST_NAME_SNAKE}}_error_count";
    public static final String METRIC_VALIDATION_ERROR_COUNT = "{{REQUEST_NAME_SNAKE}}_validation_error_count";
    public static final String METRIC_DURATION_MS = "{{REQUEST_NAME_SNAKE}}_duration_ms";
    public static final String METRIC_RETRY_COUNT = "{{REQUEST_NAME_SNAKE}}_retry_count";

    // ============================================================
    // VALIDATION CONSTANTS
    // ============================================================
    
    private static final int MIN_TITLE_LENGTH = 3;
    private static final int MAX_TITLE_LENGTH = 255;
    private static final int MAX_DESCRIPTION_LENGTH = 10000;
    private static final int MAX_TAGS = 20;
    
    // Regex patterns
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PHONE_PATTERN = 
        Pattern.compile("^\\+?[1-9]\\d{1,14}$");

    // ============================================================
    // VALIDATION METHODS
    // ============================================================

    /**
     * Validate all input parameters.
     * 
     * @param params Input parameters from catalog request
     * @return ValidationResult with field-level errors
     */
    public ValidationResult validate(Map<String, Object> params) {
        ValidationResult result = new ValidationResult();
        
        validateRequiredFields(params, result);
        
        if (result.isValid()) {
            validateFieldFormats(params, result);
        }
        
        if (result.isValid()) {
            validateBusinessRules(params, result);
        }
        
        return result;
    }

    private void validateRequiredFields(Map<String, Object> params, ValidationResult result) {
        // Title is required
        String title = getString(params, "Title");
        if (isBlank(title)) {
            result.addError("Title", "Title is required");
        }
        
        // Add more required field validations...
    }

    private void validateFieldFormats(Map<String, Object> params, ValidationResult result) {
        // Title length
        String title = getString(params, "Title");
        if (!isBlank(title)) {
            if (title.length() < MIN_TITLE_LENGTH) {
                result.addError("Title", 
                    String.format("Title must be at least %d characters", MIN_TITLE_LENGTH));
            }
            if (title.length() > MAX_TITLE_LENGTH) {
                result.addError("Title", 
                    String.format("Title cannot exceed %d characters", MAX_TITLE_LENGTH));
            }
        }
        
        // Description length
        String description = getString(params, "Description");
        if (!isBlank(description) && description.length() > MAX_DESCRIPTION_LENGTH) {
            result.addError("Description", 
                String.format("Description cannot exceed %d characters", MAX_DESCRIPTION_LENGTH));
        }
        
        // Email format
        String email = getString(params, "Email");
        if (!isBlank(email) && !EMAIL_PATTERN.matcher(email).matches()) {
            result.addError("Email", "Invalid email format");
        }
        
        // Tags count
        String tags = getString(params, "Tags");
        if (!isBlank(tags)) {
            long tagCount = Arrays.stream(tags.split(","))
                .map(String::trim)
                .filter(t -> !t.isEmpty())
                .count();
            if (tagCount > MAX_TAGS) {
                result.addError("Tags", 
                    String.format("Cannot have more than %d tags", MAX_TAGS));
            }
        }
    }

    private void validateBusinessRules(Map<String, Object> params, ValidationResult result) {
        // Add business-specific validation rules
        // Example: Priority escalation rules, assignment rules, etc.
    }

    // ============================================================
    // PAYLOAD BUILDING
    // ============================================================

    /**
     * Build API request payload from validated parameters.
     * 
     * @param params Validated input parameters
     * @return Map suitable for API request body
     */
    public Map<String, Object> buildPayload(Map<String, Object> params) {
        Map<String, Object> payload = new LinkedHashMap<>();
        
        // Required fields
        payload.put("subject", getString(params, "Title"));
        
        // Optional fields (only include if present)
        addIfPresent(payload, "description", getString(params, "Description"));
        addIfPresent(payload, "priority", mapPriority(getString(params, "Priority")));
        addIfPresent(payload, "type", getString(params, "Type"));
        
        // Transform tags to array
        String tags = getString(params, "Tags");
        if (!isBlank(tags)) {
            List<String> tagList = Arrays.stream(tags.split(","))
                .map(String::trim)
                .filter(t -> !t.isEmpty())
                .collect(Collectors.toList());
            payload.put("tags", tagList);
        }

        return payload;
    }

    // ============================================================
    // TELEMETRY METHODS
    // ============================================================

    /**
     * Record request start for duration tracking.
     */
    public TelemetryContext startRequest() {
        return new TelemetryContext(System.currentTimeMillis());
    }

    /**
     * Record successful request completion.
     */
    public void recordSuccess(TelemetryContext context, Map<String, Object> metrics) {
        long duration = System.currentTimeMillis() - context.getStartTime();

        metrics.put(METRIC_REQUEST_COUNT, 1);
        metrics.put(METRIC_SUCCESS_COUNT, 1);
        metrics.put(METRIC_DURATION_MS, duration);
    }

    /**
     * Record request failure.
     */
    public void recordError(TelemetryContext context, String errorType, Map<String, Object> metrics) {
        long duration = System.currentTimeMillis() - context.getStartTime();

        metrics.put(METRIC_REQUEST_COUNT, 1);
        metrics.put(METRIC_ERROR_COUNT, 1);
        metrics.put(METRIC_DURATION_MS, duration);

        if ("INPUT_ERROR".equals(errorType)) {
            metrics.put(METRIC_VALIDATION_ERROR_COUNT, 1);
        }
    }

    /**
     * Record retry attempt.
     */
    public void recordRetry(Map<String, Object> metrics) {
        metrics.merge(METRIC_RETRY_COUNT, 1, (old, val) -> ((Integer) old) + 1);
    }

    // ============================================================
    // UTILITY METHODS
    // ============================================================

    private String getString(Map<String, Object> params, String key) {
        Object value = params.get(key);
        return value != null ? value.toString() : null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void addIfPresent(Map<String, Object> map, String key, Object value) {
        if (value != null && (!(value instanceof String) || !((String) value).isBlank())) {
            map.put(key, value);
        }
    }

    private String mapPriority(String priority) {
        if (priority == null) return null;

        switch (priority.toLowerCase()) {
            case "low": return "low";
            case "normal": return "normal";
            case "high": return "high";
            case "urgent": return "urgent";
            default: return "normal";
        }
    }

    // ============================================================
    // INNER CLASSES
    // ============================================================

    /**
     * Context for tracking request telemetry.
     */
    public static class TelemetryContext {
        private final long startTime;
        private int retryCount = 0;

        public TelemetryContext(long startTime) {
            this.startTime = startTime;
        }

        public long getStartTime() { return startTime; }
        public int getRetryCount() { return retryCount; }
        public void incrementRetry() { retryCount++; }
    }
}
```

## 2. Create ValidationResult Class

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.util.*;

/**
 * Holds validation results with field-level error details.
 */
public class ValidationResult {

    private final Map<String, List<String>> errors = new LinkedHashMap<>();

    public void addError(String field, String message) {
        errors.computeIfAbsent(field, k -> new ArrayList<>()).add(message);
    }

    public boolean isValid() {
        return errors.isEmpty();
    }

    public boolean hasError(String field) {
        return errors.containsKey(field);
    }

    public List<String> getErrors(String field) {
        return errors.getOrDefault(field, Collections.emptyList());
    }

    public Map<String, List<String>> getAllErrors() {
        return Collections.unmodifiableMap(errors);
    }

    public String getErrorMessage() {
        if (errors.isEmpty()) return null;

        return errors.values().stream()
            .flatMap(List::stream)
            .collect(Collectors.joining("; "));
    }

    public int getErrorCount() {
        return errors.values().stream()
            .mapToInt(List::size)
            .sum();
    }
}
```

## 3. Use Helper in Catalog Request

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.controller.helper.{{HELPER_NAME}};
import {{PACKAGE_NAME}}.controller.helper.{{HELPER_NAME}}.TelemetryContext;
import {{PACKAGE_NAME}}.controller.helper.ValidationResult;

public class TicketsArea {

    private final ApiClient client;
    private final {{HELPER_NAME}} helper;

    public TicketsArea(ApiClient client) {
        this.client = client;
        this.helper = new {{HELPER_NAME}}();
    }

    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "Tickets",
        type = CatalogRequest.Type.CHANGE_SYSTEM
    )
    public Map<String, Object> createTicket(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        Map<String, Object> metrics = new HashMap<>();

        // Start telemetry tracking
        TelemetryContext telemetry = helper.startRequest();

        try {
            // Step 1: Validate
            ValidationResult validation = helper.validate(params);
            if (!validation.isValid()) {
                result.put("success", false);
                result.put("errorType", "INPUT_ERROR");
                result.put("error", validation.getErrorMessage());
                result.put("fieldErrors", validation.getAllErrors());
                helper.recordError(telemetry, "INPUT_ERROR", metrics);
                return result;
            }

            // Step 2: Build payload
            Map<String, Object> payload = helper.buildPayload(params);

            // Step 3: Make API call
            ApiResponse response = client.post("/tickets", payload);

            // Step 4: Success
            result.put("success", true);
            result.put("ticketId", response.getId());
            helper.recordSuccess(telemetry, metrics);

        } catch (Exception e) {
            result.put("success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", e.getMessage());
            helper.recordError(telemetry, "SYSTEM_ERROR", metrics);
        }

        // Attach metrics to result for platform to collect
        result.put("_metrics", metrics);

        return result;
    }
}
```

## 4. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller.helper;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class {{HELPER_NAME}}Test {

    private {{HELPER_NAME}} helper;

    @BeforeEach
    void setUp() {
        helper = new {{HELPER_NAME}}();
    }

    // ============================================================
    // VALIDATION TESTS
    // ============================================================

    @Test
    void validate_withValidParams_returnsNoErrors() {
        Map<String, Object> params = createValidParams();

        ValidationResult result = helper.validate(params);

        assertTrue(result.isValid());
        assertEquals(0, result.getErrorCount());
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  ", "\t", "\n"})
    void validate_withBlankTitle_returnsError(String title) {
        Map<String, Object> params = createValidParams();
        params.put("Title", title);

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.hasError("Title"));
    }

    @Test
    void validate_withShortTitle_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Title", "AB");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getErrors("Title").get(0).contains("at least"));
    }

    @Test
    void validate_withLongTitle_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Title", "A".repeat(300));

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getErrors("Title").get(0).contains("exceed"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"invalid", "test@", "@test.com", "test@.com"})
    void validate_withInvalidEmail_returnsError(String email) {
        Map<String, Object> params = createValidParams();
        params.put("Email", email);

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.hasError("Email"));
    }

    // ============================================================
    // PAYLOAD BUILDING TESTS
    // ============================================================

    @Test
    void buildPayload_mapsRequiredFields() {
        Map<String, Object> params = createValidParams();

        Map<String, Object> payload = helper.buildPayload(params);

        assertEquals("Test Title", payload.get("subject"));
    }

    @Test
    void buildPayload_omitsNullOptionalFields() {
        Map<String, Object> params = new HashMap<>();
        params.put("Title", "Test");

        Map<String, Object> payload = helper.buildPayload(params);

        assertFalse(payload.containsKey("description"));
        assertFalse(payload.containsKey("priority"));
    }

    @Test
    void buildPayload_transformsTagsToList() {
        Map<String, Object> params = createValidParams();
        params.put("Tags", "tag1, tag2, tag3");

        Map<String, Object> payload = helper.buildPayload(params);

        List<String> tags = (List<String>) payload.get("tags");
        assertEquals(3, tags.size());
        assertTrue(tags.contains("tag1"));
    }

    // ============================================================
    // TELEMETRY TESTS
    // ============================================================

    @Test
    void recordSuccess_setsCorrectMetrics() {
        TelemetryContext context = helper.startRequest();
        Map<String, Object> metrics = new HashMap<>();

        // Simulate some work
        try { Thread.sleep(10); } catch (InterruptedException e) {}

        helper.recordSuccess(context, metrics);

        assertEquals(1, metrics.get({{HELPER_NAME}}.METRIC_REQUEST_COUNT));
        assertEquals(1, metrics.get({{HELPER_NAME}}.METRIC_SUCCESS_COUNT));
        assertTrue((Long) metrics.get({{HELPER_NAME}}.METRIC_DURATION_MS) >= 10);
    }

    @Test
    void recordError_setsCorrectMetrics() {
        TelemetryContext context = helper.startRequest();
        Map<String, Object> metrics = new HashMap<>();

        helper.recordError(context, "INPUT_ERROR", metrics);

        assertEquals(1, metrics.get({{HELPER_NAME}}.METRIC_ERROR_COUNT));
        assertEquals(1, metrics.get({{HELPER_NAME}}.METRIC_VALIDATION_ERROR_COUNT));
    }

    // ============================================================
    // HELPER METHODS
    // ============================================================

    private Map<String, Object> createValidParams() {
        Map<String, Object> params = new HashMap<>();
        params.put("Title", "Test Title");
        params.put("Description", "Test description");
        params.put("Priority", "Normal");
        return params;
    }
}
```

## Validation Checklist

- [ ] Helper class is stateless (no instance variables that change)
- [ ] Validation methods are separated by concern
- [ ] All telemetry metrics have consistent naming
- [ ] Payload builder only includes non-null values
- [ ] Unit tests cover all validation rules
- [ ] Unit tests cover payload building
- [ ] Unit tests cover telemetry recording

## Best Practices

1. **Keep helpers stateless** - No mutable instance state
2. **Separate concerns** - Validation, payload building, telemetry
3. **Consistent metric names** - Use snake_case with request name prefix
4. **Fail fast** - Stop validation after required field errors
5. **Clear error messages** - Include field name and constraint
6. **Test thoroughly** - Cover all validation paths

## Related Prompts

- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [09 - Add Request with Complex Validation](09-add-request-complex-validation.md)
- [16 - Implement Error Handling](16-implement-error-handling.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

