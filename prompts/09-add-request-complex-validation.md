# Prompt 09: Add Catalog Request with Complex Validation

## Purpose

Add a catalog request with comprehensive multi-field validation rules, including cross-field validation, conditional requirements, and business rule enforcement.

## Prerequisites

- Existing extension with project structure
- Understanding of business rules and validation requirements
- Helper class pattern knowledge

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Schedule Meeting` |
| Domain Name | `{{DOMAIN_NAME}}` | `Calendar` |
| Description | `{{DESCRIPTION}}` | `Schedule a new meeting with attendees` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.googlecalendar` |

---

## Prompt

```
I need you to add a catalog request with complex multi-field validation to my Krista extension.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}
- **Package**: {{PACKAGE_NAME}}

## 1. Add Catalog Request to Area Class

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.controller.helper.{{REQUEST_NAME}}Helper;
import {{PACKAGE_NAME}}.entity.Meeting;
import {{PACKAGE_NAME}}.integration.ApiClient;

import java.util.*;

public class {{DOMAIN_NAME}}Area {

    private final ApiClient client;
    private final {{REQUEST_NAME}}Helper helper;

    public {{DOMAIN_NAME}}Area(ApiClient client) {
        this.client = client;
        this.helper = new {{REQUEST_NAME}}Helper();
    }

    /**
     * {{DESCRIPTION}}
     */
    @CatalogRequest(
        name = "{{REQUEST_NAME}}",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.CHANGE_SYSTEM,
        description = "{{DESCRIPTION}}"
    )
    // Required fields
    @Field.Text(name = "Title", required = true,
        description = "Meeting title (3-100 characters)")
    @Field.Text(name = "Start Time", required = true,
        description = "Start time in ISO 8601 format (e.g., 2024-01-15T09:00:00Z)")
    @Field.Text(name = "End Time", required = true,
        description = "End time in ISO 8601 format")
    // Conditional fields
    @Field.Text(name = "Attendees", required = false,
        description = "Comma-separated email addresses")
    @Field.PickOne(name = "Meeting Type", required = true,
        values = {"In-Person", "Virtual", "Hybrid"},
        description = "Type of meeting")
    @Field.Text(name = "Location", required = false,
        description = "Physical location (required for In-Person/Hybrid)")
    @Field.Text(name = "Video Link", required = false,
        description = "Video conference link (required for Virtual/Hybrid)")
    // Optional fields
    @Field.TextArea(name = "Description", required = false,
        description = "Meeting description")
    @Field.PickOne(name = "Reminder", required = false,
        values = {"None", "5 minutes", "15 minutes", "30 minutes", "1 hour", "1 day"},
        description = "Reminder before meeting")
    @Field.Checkbox(name = "Send Invites", required = false,
        description = "Send calendar invites to attendees")
    // Output fields
    @Field.Output(name = "Meeting ID", type = Field.Output.Type.TEXT)
    @Field.Output(name = "Meeting", type = Field.Output.Type.ENTITY, entityType = "Meeting")
    @Field.Output(name = "Success", type = Field.Output.Type.BOOLEAN)
    public Map<String, Object> {{REQUEST_NAME_CAMEL}}(Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Step 1: Run comprehensive validation
            ValidationResult validation = helper.validate(params);
            
            if (!validation.isValid()) {
                result.put("Success", false);
                result.put("errorType", "INPUT_ERROR");
                result.put("error", validation.getErrorMessage());
                result.put("fieldErrors", validation.getFieldErrors());
                return result;
            }
            
            // Step 2: Build and send request
            Map<String, Object> payload = helper.buildPayload(params);
            ApiResponse response = client.post("/calendar/events", payload);
            
            // Step 3: Return success
            Meeting meeting = transformer.transform(response.getData());
            result.put("Meeting ID", meeting.getId());
            result.put("Meeting", meeting);
            result.put("Success", true);
            
        } catch (Exception e) {
            result.put("Success", false);
            result.put("errorType", "SYSTEM_ERROR");
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
```

## 2. Create Comprehensive Validation Helper

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.time.*;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.regex.Pattern;

/**
 * Helper class with comprehensive validation for {{REQUEST_NAME}}.
 */
public class {{REQUEST_NAME}}Helper {

    // Validation constants
    private static final int MIN_TITLE_LENGTH = 3;
    private static final int MAX_TITLE_LENGTH = 100;
    private static final int MAX_DESCRIPTION_LENGTH = 5000;
    private static final int MAX_ATTENDEES = 100;
    private static final int MAX_MEETING_DURATION_HOURS = 24;
    private static final int MIN_MEETING_DURATION_MINUTES = 5;
    
    // Regex patterns
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");
    private static final Pattern URL_PATTERN = 
        Pattern.compile("^https?://.*$");

    /**
     * Comprehensive validation with field-level errors.
     */
    public ValidationResult validate(Map<String, Object> params) {
        ValidationResult result = new ValidationResult();

        // 1. Validate required fields
        validateRequiredFields(params, result);

        // 2. Validate field formats
        validateFieldFormats(params, result);

        // 3. Validate cross-field rules
        validateCrossFieldRules(params, result);

        // 4. Validate business rules
        validateBusinessRules(params, result);

        return result;
    }

    /**
     * Validate that all required fields are present and non-empty.
     */
    private void validateRequiredFields(Map<String, Object> params, ValidationResult result) {
        // Title is required
        String title = (String) params.get("Title");
        if (title == null || title.isBlank()) {
            result.addFieldError("Title", "Title is required");
        }

        // Start Time is required
        String startTime = (String) params.get("Start Time");
        if (startTime == null || startTime.isBlank()) {
            result.addFieldError("Start Time", "Start Time is required");
        }

        // End Time is required
        String endTime = (String) params.get("End Time");
        if (endTime == null || endTime.isBlank()) {
            result.addFieldError("End Time", "End Time is required");
        }

        // Meeting Type is required
        String meetingType = (String) params.get("Meeting Type");
        if (meetingType == null || meetingType.isBlank()) {
            result.addFieldError("Meeting Type", "Meeting Type is required");
        }
    }

    /**
     * Validate field formats (length, pattern, etc.).
     */
    private void validateFieldFormats(Map<String, Object> params, ValidationResult result) {
        // Title length
        String title = (String) params.get("Title");
        if (title != null && !title.isBlank()) {
            if (title.length() < MIN_TITLE_LENGTH) {
                result.addFieldError("Title",
                    "Title must be at least " + MIN_TITLE_LENGTH + " characters");
            }
            if (title.length() > MAX_TITLE_LENGTH) {
                result.addFieldError("Title",
                    "Title cannot exceed " + MAX_TITLE_LENGTH + " characters");
            }
        }

        // Description length
        String description = (String) params.get("Description");
        if (description != null && description.length() > MAX_DESCRIPTION_LENGTH) {
            result.addFieldError("Description",
                "Description cannot exceed " + MAX_DESCRIPTION_LENGTH + " characters");
        }

        // Start Time format (ISO 8601)
        String startTime = (String) params.get("Start Time");
        if (startTime != null && !startTime.isBlank()) {
            try {
                Instant.parse(startTime);
            } catch (DateTimeParseException e) {
                result.addFieldError("Start Time",
                    "Start Time must be in ISO 8601 format (e.g., 2024-01-15T09:00:00Z)");
            }
        }

        // End Time format
        String endTime = (String) params.get("End Time");
        if (endTime != null && !endTime.isBlank()) {
            try {
                Instant.parse(endTime);
            } catch (DateTimeParseException e) {
                result.addFieldError("End Time",
                    "End Time must be in ISO 8601 format");
            }
        }

        // Attendees email format
        String attendees = (String) params.get("Attendees");
        if (attendees != null && !attendees.isBlank()) {
            String[] emails = attendees.split(",");
            if (emails.length > MAX_ATTENDEES) {
                result.addFieldError("Attendees",
                    "Cannot have more than " + MAX_ATTENDEES + " attendees");
            }
            for (String email : emails) {
                String trimmed = email.trim();
                if (!trimmed.isEmpty() && !EMAIL_PATTERN.matcher(trimmed).matches()) {
                    result.addFieldError("Attendees",
                        "Invalid email format: " + trimmed);
                    break;
                }
            }
        }

        // Video Link URL format
        String videoLink = (String) params.get("Video Link");
        if (videoLink != null && !videoLink.isBlank()) {
            if (!URL_PATTERN.matcher(videoLink).matches()) {
                result.addFieldError("Video Link",
                    "Video Link must be a valid URL starting with http:// or https://");
            }
        }
    }

    /**
     * Validate cross-field dependencies and conditional requirements.
     */
    private void validateCrossFieldRules(Map<String, Object> params, ValidationResult result) {
        String meetingType = (String) params.get("Meeting Type");
        String location = (String) params.get("Location");
        String videoLink = (String) params.get("Video Link");

        // In-Person meetings require Location
        if ("In-Person".equals(meetingType)) {
            if (location == null || location.isBlank()) {
                result.addFieldError("Location",
                    "Location is required for In-Person meetings");
            }
        }

        // Virtual meetings require Video Link
        if ("Virtual".equals(meetingType)) {
            if (videoLink == null || videoLink.isBlank()) {
                result.addFieldError("Video Link",
                    "Video Link is required for Virtual meetings");
            }
        }

        // Hybrid meetings require both
        if ("Hybrid".equals(meetingType)) {
            if (location == null || location.isBlank()) {
                result.addFieldError("Location",
                    "Location is required for Hybrid meetings");
            }
            if (videoLink == null || videoLink.isBlank()) {
                result.addFieldError("Video Link",
                    "Video Link is required for Hybrid meetings");
            }
        }

        // Send Invites requires Attendees
        String sendInvites = (String) params.get("Send Invites");
        String attendees = (String) params.get("Attendees");
        if ("true".equalsIgnoreCase(sendInvites)) {
            if (attendees == null || attendees.isBlank()) {
                result.addFieldError("Attendees",
                    "Attendees are required when Send Invites is enabled");
            }
        }
    }

    /**
     * Validate business rules and constraints.
     */
    private void validateBusinessRules(Map<String, Object> params, ValidationResult result) {
        String startTimeStr = (String) params.get("Start Time");
        String endTimeStr = (String) params.get("End Time");

        if (startTimeStr != null && endTimeStr != null) {
            try {
                Instant startTime = Instant.parse(startTimeStr);
                Instant endTime = Instant.parse(endTimeStr);

                // End time must be after start time
                if (!endTime.isAfter(startTime)) {
                    result.addFieldError("End Time",
                        "End Time must be after Start Time");
                }

                // Meeting duration constraints
                Duration duration = Duration.between(startTime, endTime);

                if (duration.toMinutes() < MIN_MEETING_DURATION_MINUTES) {
                    result.addFieldError("End Time",
                        "Meeting must be at least " + MIN_MEETING_DURATION_MINUTES + " minutes");
                }

                if (duration.toHours() > MAX_MEETING_DURATION_HOURS) {
                    result.addFieldError("End Time",
                        "Meeting cannot exceed " + MAX_MEETING_DURATION_HOURS + " hours");
                }

                // Start time must be in the future
                if (startTime.isBefore(Instant.now())) {
                    result.addFieldError("Start Time",
                        "Start Time must be in the future");
                }

            } catch (DateTimeParseException e) {
                // Already handled in format validation
            }
        }
    }

    /**
     * Build API payload from validated parameters.
     */
    public Map<String, Object> buildPayload(Map<String, Object> params) {
        Map<String, Object> payload = new HashMap<>();

        payload.put("summary", params.get("Title"));
        payload.put("description", params.get("Description"));

        // Time fields
        Map<String, String> start = new HashMap<>();
        start.put("dateTime", (String) params.get("Start Time"));
        payload.put("start", start);

        Map<String, String> end = new HashMap<>();
        end.put("dateTime", (String) params.get("End Time"));
        payload.put("end", end);

        // Location
        String location = (String) params.get("Location");
        if (location != null && !location.isBlank()) {
            payload.put("location", location);
        }

        // Video conferencing
        String videoLink = (String) params.get("Video Link");
        if (videoLink != null && !videoLink.isBlank()) {
            Map<String, Object> conferenceData = new HashMap<>();
            conferenceData.put("entryPoints", List.of(
                Map.of("entryPointType", "video", "uri", videoLink)
            ));
            payload.put("conferenceData", conferenceData);
        }

        // Attendees
        String attendeesStr = (String) params.get("Attendees");
        if (attendeesStr != null && !attendeesStr.isBlank()) {
            List<Map<String, String>> attendees = Arrays.stream(attendeesStr.split(","))
                .map(String::trim)
                .filter(e -> !e.isEmpty())
                .map(email -> Map.of("email", email))
                .collect(Collectors.toList());
            payload.put("attendees", attendees);
        }

        return payload;
    }
}
```

## 3. Create ValidationResult Class

```java
package {{PACKAGE_NAME}}.controller.helper;

import java.util.*;

/**
 * Holds validation results with field-level error details.
 */
public class ValidationResult {

    private final Map<String, List<String>> fieldErrors = new LinkedHashMap<>();

    public void addFieldError(String field, String error) {
        fieldErrors.computeIfAbsent(field, k -> new ArrayList<>()).add(error);
    }

    public boolean isValid() {
        return fieldErrors.isEmpty();
    }

    public Map<String, List<String>> getFieldErrors() {
        return Collections.unmodifiableMap(fieldErrors);
    }

    public String getErrorMessage() {
        if (fieldErrors.isEmpty()) {
            return null;
        }

        StringBuilder sb = new StringBuilder("Validation failed: ");
        List<String> allErrors = new ArrayList<>();

        for (Map.Entry<String, List<String>> entry : fieldErrors.entrySet()) {
            for (String error : entry.getValue()) {
                allErrors.add(error);
            }
        }

        sb.append(String.join("; ", allErrors));
        return sb.toString();
    }

    public int getErrorCount() {
        return fieldErrors.values().stream()
            .mapToInt(List::size)
            .sum();
    }
}
```

## 4. Write Unit Tests

```java
package {{PACKAGE_NAME}}.controller.helper;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class {{REQUEST_NAME}}HelperTest {

    private {{REQUEST_NAME}}Helper helper;

    @BeforeEach
    void setUp() {
        helper = new {{REQUEST_NAME}}Helper();
    }

    @Test
    void testValidate_withValidParams_returnsNoErrors() {
        Map<String, Object> params = createValidParams();

        ValidationResult result = helper.validate(params);

        assertTrue(result.isValid());
        assertEquals(0, result.getErrorCount());
    }

    @Test
    void testValidate_withMissingTitle_returnsError() {
        Map<String, Object> params = createValidParams();
        params.remove("Title");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().containsKey("Title"));
    }

    @Test
    void testValidate_withShortTitle_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Title", "AB");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().get("Title").get(0).contains("at least"));
    }

    @Test
    void testValidate_withInvalidEmail_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Attendees", "valid@email.com, invalid-email");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().containsKey("Attendees"));
    }

    @Test
    void testValidate_inPersonWithoutLocation_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Meeting Type", "In-Person");
        params.remove("Location");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().containsKey("Location"));
    }

    @Test
    void testValidate_virtualWithoutVideoLink_returnsError() {
        Map<String, Object> params = createValidParams();
        params.put("Meeting Type", "Virtual");
        params.remove("Video Link");

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().containsKey("Video Link"));
    }

    @Test
    void testValidate_endTimeBeforeStartTime_returnsError() {
        Map<String, Object> params = createValidParams();
        Instant now = Instant.now().plus(1, ChronoUnit.HOURS);
        params.put("Start Time", now.plus(2, ChronoUnit.HOURS).toString());
        params.put("End Time", now.toString());

        ValidationResult result = helper.validate(params);

        assertFalse(result.isValid());
        assertTrue(result.getFieldErrors().containsKey("End Time"));
    }

    private Map<String, Object> createValidParams() {
        Map<String, Object> params = new HashMap<>();
        Instant now = Instant.now().plus(1, ChronoUnit.HOURS);

        params.put("Title", "Team Meeting");
        params.put("Start Time", now.toString());
        params.put("End Time", now.plus(1, ChronoUnit.HOURS).toString());
        params.put("Meeting Type", "Virtual");
        params.put("Video Link", "https://meet.google.com/abc-defg-hij");
        params.put("Attendees", "user1@example.com, user2@example.com");

        return params;
    }
}
```

## Validation Checklist

- [ ] All required fields validated for presence
- [ ] Field length constraints enforced
- [ ] Format validation (email, URL, date/time)
- [ ] Cross-field conditional requirements
- [ ] Business rule validation (time ranges, limits)
- [ ] Field-level error messages returned
- [ ] Validation runs before any API calls
- [ ] Unit tests cover all validation scenarios

## Best Practices

1. **Validate early** - Check all inputs before making API calls
2. **Field-level errors** - Return specific errors for each field
3. **Clear messages** - Error messages should explain how to fix the issue
4. **Consistent patterns** - Use regex patterns for format validation
5. **Business rules** - Enforce domain-specific constraints
6. **Test thoroughly** - Cover all validation paths

## Related Prompts

- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [11 - Add Helper Class](11-add-helper-class.md)
- [16 - Implement Error Handling](16-implement-error-handling.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

