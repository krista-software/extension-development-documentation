# Prompt 18: Write Unit Tests for Catalog Request

## Purpose

Write comprehensive unit tests for a catalog request, covering validation logic, payload transformation, error handling, and response mapping. This ensures the catalog request behaves correctly under all conditions.

## Prerequisites

- Existing catalog request implementation
- JUnit 5 and Mockito dependencies
- Understanding of the catalog request's behavior

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Request Name | `{{REQUEST_NAME}}` | `Create Ticket` |
| Area Class | `{{AREA_CLASS}}` | `TicketsArea` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.zendesk` |

---

## Prompt

```
I need you to write comprehensive unit tests for my catalog request.

## Request Details

- **Request Name**: {{REQUEST_NAME}}
- **Area Class**: {{AREA_CLASS}}
- **Package**: {{PACKAGE_NAME}}

## 1. Test Class Structure

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.integration.ApiResponse;
import {{PACKAGE_NAME}}.error.*;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.*;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("{{REQUEST_NAME}} Catalog Request Tests")
class {{AREA_CLASS}}Test {

    @Mock
    private ApiClient mockClient;

    @InjectMocks
    private {{AREA_CLASS}} area;

    // ============================================================
    // TEST DATA SETUP
    // ============================================================

    private Map<String, Object> createValidParams() {
        Map<String, Object> params = new HashMap<>();
        params.put("Title", "Test Ticket");
        params.put("Description", "Test description");
        params.put("Priority", "Normal");
        params.put("Type", "Problem");
        params.put("Email", "test@example.com");
        return params;
    }

    private ApiResponse createSuccessResponse() {
        return ApiResponse.success(Map.of(
            "id", "12345",
            "created_at", "2024-01-15T10:30:00Z",
            "status", "new"
        ));
    }

    private ApiResponse createErrorResponse(int status, String code, String message) {
        return ApiResponse.error(status, code, message);
    }

    // ============================================================
    // SUCCESS SCENARIOS
    // ============================================================

    @Nested
    @DisplayName("Success Scenarios")
    class SuccessScenarios {

        @Test
        @DisplayName("Should create ticket with all required fields")
        void createTicket_withValidParams_returnsSuccess() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertTrue((Boolean) result.get("success"));
            assertEquals("12345", result.get("ticketId"));
            assertNotNull(result.get("createdAt"));
        }

        @Test
        @DisplayName("Should create ticket with only required fields")
        void createTicket_withMinimalParams_returnsSuccess() {
            // Arrange
            Map<String, Object> params = new HashMap<>();
            params.put("Title", "Minimal Ticket");
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertTrue((Boolean) result.get("success"));
        }

        @Test
        @DisplayName("Should pass correct payload to API")
        void createTicket_withValidParams_sendsCorrectPayload() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            area.createTicket(params);

            // Assert
            ArgumentCaptor<Map<String, Object>> payloadCaptor = 
                ArgumentCaptor.forClass(Map.class);
            verify(mockClient).post(eq("/tickets"), payloadCaptor.capture());
            
            Map<String, Object> payload = payloadCaptor.getValue();
            assertEquals("Test Ticket", payload.get("subject"));
            assertEquals("Test description", payload.get("description"));
            assertEquals("normal", payload.get("priority"));
        }
    }

    // ============================================================
    // VALIDATION ERROR SCENARIOS
    // ============================================================

    @Nested
    @DisplayName("Validation Error Scenarios")
    class ValidationErrorScenarios {

        @ParameterizedTest
        @NullAndEmptySource
        @ValueSource(strings = {"  ", "\t", "\n"})
        @DisplayName("Should reject blank title")
        void createTicket_withBlankTitle_returnsInputError(String title) {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Title", title);

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
            assertTrue(result.get("error").toString().contains("Title"));
        }

        @Test
        @DisplayName("Should reject title that is too short")
        void createTicket_withShortTitle_returnsInputError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Title", "AB");

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
            assertTrue(result.get("error").toString().contains("at least"));
        }

        @Test
        @DisplayName("Should reject title that is too long")
        void createTicket_withLongTitle_returnsInputError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Title", "A".repeat(300));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
            assertTrue(result.get("error").toString().contains("exceed"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"invalid", "test@", "@test.com", "test@.com"})
        @DisplayName("Should reject invalid email format")
        void createTicket_withInvalidEmail_returnsInputError(String email) {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Email", email);

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
            assertTrue(result.get("error").toString().toLowerCase().contains("email"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"Invalid", "unknown", "CRITICAL"})
        @DisplayName("Should reject invalid priority values")
        void createTicket_withInvalidPriority_returnsInputError(String priority) {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Priority", priority);

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should return multiple validation errors")
        void createTicket_withMultipleErrors_returnsAllErrors() {
            // Arrange
            Map<String, Object> params = new HashMap<>();
            params.put("Title", ""); // Invalid
            params.put("Email", "invalid"); // Invalid

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));

            // Check that field errors are included
            @SuppressWarnings("unchecked")
            Map<String, List<String>> fieldErrors =
                (Map<String, List<String>>) result.get("fieldErrors");
            if (fieldErrors != null) {
                assertTrue(fieldErrors.containsKey("Title") || fieldErrors.containsKey("Email"));
            }
        }
    }

    // ============================================================
    // API ERROR SCENARIOS
    // ============================================================

    @Nested
    @DisplayName("API Error Scenarios")
    class ApiErrorScenarios {

        @Test
        @DisplayName("Should handle 400 Bad Request")
        void createTicket_with400Response_returnsInputError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(400, "INVALID_REQUEST", "Bad request"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle 401 Unauthorized")
        void createTicket_with401Response_returnsAuthError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(401, "INVALID_TOKEN", "Token expired"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("AUTHORIZATION_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle 403 Forbidden")
        void createTicket_with403Response_returnsAuthError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(403, "INSUFFICIENT_PERMISSIONS", "Access denied"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("AUTHORIZATION_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle 404 Not Found")
        void createTicket_with404Response_returnsLogicError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(404, "NOT_FOUND", "Resource not found"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("LOGIC_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle 409 Conflict")
        void createTicket_with409Response_returnsLogicError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(409, "DUPLICATE", "Record already exists"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("LOGIC_ERROR", result.get("errorType"));
        }

        @ParameterizedTest
        @ValueSource(ints = {500, 502, 503, 504})
        @DisplayName("Should handle 5xx server errors")
        void createTicket_with5xxResponse_returnsSystemError(int statusCode) {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(statusCode, null, "Server error"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("SYSTEM_ERROR", result.get("errorType"));
            assertTrue((Boolean) result.get("retryable"));
        }

        @Test
        @DisplayName("Should handle 429 Rate Limit")
        void createTicket_with429Response_returnsRetryableError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenReturn(createErrorResponse(429, "RATE_LIMIT_EXCEEDED", "Too many requests"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("SYSTEM_ERROR", result.get("errorType"));
            assertTrue((Boolean) result.get("retryable"));
        }
    }

    // ============================================================
    // EXCEPTION SCENARIOS
    // ============================================================

    @Nested
    @DisplayName("Exception Scenarios")
    class ExceptionScenarios {

        @Test
        @DisplayName("Should handle network timeout")
        void createTicket_withTimeout_returnsSystemError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenThrow(new java.net.SocketTimeoutException("Read timed out"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("SYSTEM_ERROR", result.get("errorType"));
            assertTrue(result.get("error").toString().contains("timeout"));
        }

        @Test
        @DisplayName("Should handle connection refused")
        void createTicket_withConnectionRefused_returnsSystemError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenThrow(new java.net.ConnectException("Connection refused"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("SYSTEM_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle unexpected exception")
        void createTicket_withUnexpectedException_returnsSystemError() {
            // Arrange
            Map<String, Object> params = createValidParams();
            when(mockClient.post(anyString(), any()))
                .thenThrow(new RuntimeException("Unexpected error"));

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("SYSTEM_ERROR", result.get("errorType"));
        }
    }

    // ============================================================
    // PAYLOAD TRANSFORMATION TESTS
    // ============================================================

    @Nested
    @DisplayName("Payload Transformation Tests")
    class PayloadTransformationTests {

        @Test
        @DisplayName("Should transform priority to lowercase")
        void createTicket_withPriority_transformsToLowercase() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Priority", "HIGH");
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            area.createTicket(params);

            // Assert
            ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
            verify(mockClient).post(anyString(), captor.capture());
            assertEquals("high", captor.getValue().get("priority"));
        }

        @Test
        @DisplayName("Should transform tags string to array")
        void createTicket_withTags_transformsToArray() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Tags", "tag1, tag2, tag3");
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            area.createTicket(params);

            // Assert
            ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
            verify(mockClient).post(anyString(), captor.capture());

            @SuppressWarnings("unchecked")
            List<String> tags = (List<String>) captor.getValue().get("tags");
            assertEquals(3, tags.size());
            assertTrue(tags.contains("tag1"));
            assertTrue(tags.contains("tag2"));
            assertTrue(tags.contains("tag3"));
        }

        @Test
        @DisplayName("Should omit null optional fields from payload")
        void createTicket_withNullOptionalFields_omitsFromPayload() {
            // Arrange
            Map<String, Object> params = new HashMap<>();
            params.put("Title", "Test");
            params.put("Description", null);
            params.put("Priority", null);
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            area.createTicket(params);

            // Assert
            ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
            verify(mockClient).post(anyString(), captor.capture());

            Map<String, Object> payload = captor.getValue();
            assertFalse(payload.containsKey("description"));
            assertFalse(payload.containsKey("priority"));
        }
    }

    // ============================================================
    // EDGE CASES
    // ============================================================

    @Nested
    @DisplayName("Edge Cases")
    class EdgeCases {

        @Test
        @DisplayName("Should handle empty params map")
        void createTicket_withEmptyParams_returnsInputError() {
            // Arrange
            Map<String, Object> params = new HashMap<>();

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertFalse((Boolean) result.get("success"));
            assertEquals("INPUT_ERROR", result.get("errorType"));
        }

        @Test
        @DisplayName("Should handle null params")
        void createTicket_withNullParams_returnsInputError() {
            // Act & Assert
            assertThrows(NullPointerException.class, () -> area.createTicket(null));
        }

        @Test
        @DisplayName("Should trim whitespace from string fields")
        void createTicket_withWhitespaceInTitle_trimsWhitespace() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Title", "  Test Title  ");
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            area.createTicket(params);

            // Assert
            ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
            verify(mockClient).post(anyString(), captor.capture());
            assertEquals("Test Title", captor.getValue().get("subject"));
        }

        @Test
        @DisplayName("Should handle special characters in title")
        void createTicket_withSpecialCharsInTitle_handlesCorrectly() {
            // Arrange
            Map<String, Object> params = createValidParams();
            params.put("Title", "Test <script>alert('xss')</script> & \"quotes\"");
            when(mockClient.post(anyString(), any())).thenReturn(createSuccessResponse());

            // Act
            Map<String, Object> result = area.createTicket(params);

            // Assert
            assertTrue((Boolean) result.get("success"));
        }
    }
}
```

## 2. Test Helper Methods

```java
    // ============================================================
    // TEST UTILITIES
    // ============================================================

    /**
     * Create params with specific field value for parameterized tests.
     */
    private static Stream<Arguments> invalidEmailProvider() {
        return Stream.of(
            Arguments.of("invalid", "missing @ symbol"),
            Arguments.of("test@", "missing domain"),
            Arguments.of("@test.com", "missing local part"),
            Arguments.of("test@.com", "missing domain name"),
            Arguments.of("test@test", "missing TLD"),
            Arguments.of("test test@test.com", "contains space")
        );
    }

    @ParameterizedTest(name = "Email ''{0}'' should fail: {1}")
    @MethodSource("invalidEmailProvider")
    @DisplayName("Should reject various invalid email formats")
    void createTicket_withVariousInvalidEmails_returnsInputError(
            String email, String reason) {
        Map<String, Object> params = createValidParams();
        params.put("Email", email);

        Map<String, Object> result = area.createTicket(params);

        assertFalse((Boolean) result.get("success"),
            "Expected failure for: " + reason);
    }
```

## Validation Checklist

- [ ] Success scenarios are tested
- [ ] All validation rules are tested
- [ ] API error codes are mapped correctly
- [ ] Exception handling is tested
- [ ] Payload transformation is verified
- [ ] Edge cases are covered
- [ ] Parameterized tests for similar scenarios
- [ ] Mocks are properly configured

## Best Practices

1. **Use descriptive test names** - Clearly state what is being tested
2. **Follow AAA pattern** - Arrange, Act, Assert
3. **Test one thing per test** - Keep tests focused
4. **Use parameterized tests** - For similar scenarios with different inputs
5. **Mock external dependencies** - Don't make real API calls
6. **Verify mock interactions** - Ensure correct payloads are sent
7. **Test edge cases** - Empty, null, special characters

## Related Prompts

- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [11 - Add Helper Class](11-add-helper-class.md)
- [16 - Implement Error Handling](16-implement-error-handling.md)
- [19 - Write Integration Tests](19-write-integration-tests.md)
```

