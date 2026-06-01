# Prompt 16: Implement Comprehensive Error Handling

## Purpose

Implement a comprehensive error handling strategy for a Krista extension, including proper error categorization (INPUT_ERROR, LOGIC_ERROR, SYSTEM_ERROR, AUTHORIZATION_ERROR), error mapping from external APIs, and consistent error response formatting.

## Prerequisites

- Existing extension with catalog requests
- Understanding of external API error responses

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |

---

## Prompt

```
I need you to implement comprehensive error handling for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Create Error Types Enum

```java
package {{PACKAGE_NAME}}.error;

/**
 * Krista extension error types.
 * 
 * These map to how the Krista platform handles errors:
 * - INPUT_ERROR: User provided invalid input, show validation message
 * - LOGIC_ERROR: Business logic failure, operation cannot proceed
 * - SYSTEM_ERROR: Technical failure, may be retryable
 * - AUTHORIZATION_ERROR: Authentication/permission failure
 */
public enum ErrorType {
    
    /**
     * Invalid input from user.
     * Examples: missing required field, invalid format, value out of range
     */
    INPUT_ERROR("INPUT_ERROR"),
    
    /**
     * Business logic failure.
     * Examples: duplicate record, invalid state transition, constraint violation
     */
    LOGIC_ERROR("LOGIC_ERROR"),
    
    /**
     * System/technical failure.
     * Examples: network error, timeout, service unavailable
     */
    SYSTEM_ERROR("SYSTEM_ERROR"),
    
    /**
     * Authentication or authorization failure.
     * Examples: invalid token, expired credentials, insufficient permissions
     */
    AUTHORIZATION_ERROR("AUTHORIZATION_ERROR");

    private final String code;

    ErrorType(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
```

## 2. Create ExtensionException Class

```java
package {{PACKAGE_NAME}}.error;

import java.util.*;

/**
 * Base exception for extension errors.
 * Carries error type and additional context for proper error handling.
 */
public class ExtensionException extends RuntimeException {

    private final ErrorType errorType;
    private final String errorCode;
    private final Map<String, Object> context;
    private final boolean retryable;

    public ExtensionException(ErrorType errorType, String message) {
        this(errorType, null, message, null, false);
    }

    public ExtensionException(ErrorType errorType, String errorCode, String message) {
        this(errorType, errorCode, message, null, false);
    }

    public ExtensionException(ErrorType errorType, String errorCode, String message, 
                              Throwable cause, boolean retryable) {
        super(message, cause);
        this.errorType = errorType;
        this.errorCode = errorCode;
        this.context = new HashMap<>();
        this.retryable = retryable;
    }

    public ExtensionException withContext(String key, Object value) {
        this.context.put(key, value);
        return this;
    }

    public ErrorType getErrorType() { return errorType; }
    public String getErrorCode() { return errorCode; }
    public Map<String, Object> getContext() { return Collections.unmodifiableMap(context); }
    public boolean isRetryable() { return retryable; }

    // Factory methods for common error types
    
    public static ExtensionException inputError(String message) {
        return new ExtensionException(ErrorType.INPUT_ERROR, message);
    }

    public static ExtensionException inputError(String field, String message) {
        return new ExtensionException(ErrorType.INPUT_ERROR, "INVALID_" + field.toUpperCase(), message)
            .withContext("field", field);
    }

    public static ExtensionException logicError(String message) {
        return new ExtensionException(ErrorType.LOGIC_ERROR, message);
    }

    public static ExtensionException logicError(String errorCode, String message) {
        return new ExtensionException(ErrorType.LOGIC_ERROR, errorCode, message, null, false);
    }

    public static ExtensionException systemError(String message, Throwable cause) {
        return new ExtensionException(ErrorType.SYSTEM_ERROR, "SYSTEM_ERROR", message, cause, true);
    }

    public static ExtensionException systemError(String message, Throwable cause, boolean retryable) {
        return new ExtensionException(ErrorType.SYSTEM_ERROR, "SYSTEM_ERROR", message, cause, retryable);
    }

    public static ExtensionException authorizationError(String message) {
        return new ExtensionException(ErrorType.AUTHORIZATION_ERROR, "AUTH_ERROR", message, null, false);
    }

    public static ExtensionException authorizationError(String errorCode, String message) {
        return new ExtensionException(ErrorType.AUTHORIZATION_ERROR, errorCode, message, null, false);
    }
}
```

## 3. Create API Error Mapper

```java
package {{PACKAGE_NAME}}.error;

import {{PACKAGE_NAME}}.integration.ApiResponse;
import java.util.*;

/**
 * Maps external API errors to extension error types.
 */
public class ApiErrorMapper {

    // HTTP status code to error type mapping
    private static final Map<Integer, ErrorType> STATUS_CODE_MAP = Map.of(
        400, ErrorType.INPUT_ERROR,
        401, ErrorType.AUTHORIZATION_ERROR,
        403, ErrorType.AUTHORIZATION_ERROR,
        404, ErrorType.LOGIC_ERROR,
        409, ErrorType.LOGIC_ERROR,
        422, ErrorType.INPUT_ERROR,
        429, ErrorType.SYSTEM_ERROR,  // Rate limit - retryable
        500, ErrorType.SYSTEM_ERROR,
        502, ErrorType.SYSTEM_ERROR,
        503, ErrorType.SYSTEM_ERROR,
        504, ErrorType.SYSTEM_ERROR
    );

    // API-specific error codes to extension error mapping
    private static final Map<String, ErrorMapping> ERROR_CODE_MAP = new HashMap<>();
    
    static {
        // Authentication errors
        ERROR_CODE_MAP.put("INVALID_TOKEN", new ErrorMapping(
            ErrorType.AUTHORIZATION_ERROR, "AUTH_INVALID_TOKEN", 
            "Authentication token is invalid or expired", false));
        ERROR_CODE_MAP.put("TOKEN_EXPIRED", new ErrorMapping(
            ErrorType.AUTHORIZATION_ERROR, "AUTH_TOKEN_EXPIRED", 
            "Authentication token has expired", false));
        ERROR_CODE_MAP.put("INSUFFICIENT_PERMISSIONS", new ErrorMapping(
            ErrorType.AUTHORIZATION_ERROR, "AUTH_INSUFFICIENT_PERMISSIONS",
            "Insufficient permissions for this operation", false));

        // Validation errors
        ERROR_CODE_MAP.put("REQUIRED_FIELD_MISSING", new ErrorMapping(
            ErrorType.INPUT_ERROR, "VALIDATION_REQUIRED",
            "Required field is missing", false));
        ERROR_CODE_MAP.put("INVALID_FORMAT", new ErrorMapping(
            ErrorType.INPUT_ERROR, "VALIDATION_FORMAT",
            "Field format is invalid", false));
        ERROR_CODE_MAP.put("VALUE_OUT_OF_RANGE", new ErrorMapping(
            ErrorType.INPUT_ERROR, "VALIDATION_RANGE",
            "Value is out of allowed range", false));

        // Business logic errors
        ERROR_CODE_MAP.put("DUPLICATE_RECORD", new ErrorMapping(
            ErrorType.LOGIC_ERROR, "DUPLICATE",
            "A record with this identifier already exists", false));
        ERROR_CODE_MAP.put("RECORD_NOT_FOUND", new ErrorMapping(
            ErrorType.LOGIC_ERROR, "NOT_FOUND",
            "The requested record was not found", false));
        ERROR_CODE_MAP.put("INVALID_STATE", new ErrorMapping(
            ErrorType.LOGIC_ERROR, "INVALID_STATE",
            "Operation not allowed in current state", false));

        // System errors
        ERROR_CODE_MAP.put("RATE_LIMIT_EXCEEDED", new ErrorMapping(
            ErrorType.SYSTEM_ERROR, "RATE_LIMITED",
            "API rate limit exceeded. Please try again later.", true));
        ERROR_CODE_MAP.put("SERVICE_UNAVAILABLE", new ErrorMapping(
            ErrorType.SYSTEM_ERROR, "SERVICE_UNAVAILABLE",
            "Service is temporarily unavailable", true));
    }

    /**
     * Map an API response to an ExtensionException.
     */
    public static ExtensionException mapApiError(ApiResponse response) {
        int statusCode = response.getStatusCode();
        String apiErrorCode = response.getErrorCode();
        String apiErrorMessage = response.getErrorMessage();

        // First, try to map by API error code
        if (apiErrorCode != null && ERROR_CODE_MAP.containsKey(apiErrorCode)) {
            ErrorMapping mapping = ERROR_CODE_MAP.get(apiErrorCode);
            return new ExtensionException(
                mapping.errorType,
                mapping.extensionErrorCode,
                mapping.message + (apiErrorMessage != null ? ": " + apiErrorMessage : ""),
                null,
                mapping.retryable
            ).withContext("apiErrorCode", apiErrorCode)
             .withContext("httpStatus", statusCode);
        }

        // Fall back to HTTP status code mapping
        ErrorType errorType = STATUS_CODE_MAP.getOrDefault(statusCode, ErrorType.SYSTEM_ERROR);
        boolean retryable = statusCode >= 500 || statusCode == 429;

        String message = apiErrorMessage != null ? apiErrorMessage :
            "API request failed with status " + statusCode;

        return new ExtensionException(errorType, "HTTP_" + statusCode, message, null, retryable)
            .withContext("httpStatus", statusCode);
    }

    /**
     * Map a Java exception to an ExtensionException.
     */
    public static ExtensionException mapException(Exception e) {
        if (e instanceof ExtensionException) {
            return (ExtensionException) e;
        }

        // Network errors
        if (e instanceof java.net.SocketTimeoutException) {
            return ExtensionException.systemError("Request timed out", e, true);
        }
        if (e instanceof java.net.ConnectException) {
            return ExtensionException.systemError("Cannot connect to server", e, true);
        }
        if (e instanceof java.net.UnknownHostException) {
            return ExtensionException.systemError("Cannot resolve server hostname", e, false);
        }

        // SSL errors
        if (e instanceof javax.net.ssl.SSLException) {
            return ExtensionException.systemError("SSL/TLS error: " + e.getMessage(), e, false);
        }

        // JSON parsing errors
        if (e instanceof com.fasterxml.jackson.core.JsonProcessingException) {
            return ExtensionException.systemError("Invalid JSON response", e, false);
        }

        // Default to system error
        return ExtensionException.systemError("Unexpected error: " + e.getMessage(), e, false);
    }

    /**
     * Internal class for error mapping configuration.
     */
    private static class ErrorMapping {
        final ErrorType errorType;
        final String extensionErrorCode;
        final String message;
        final boolean retryable;

        ErrorMapping(ErrorType errorType, String extensionErrorCode, String message, boolean retryable) {
            this.errorType = errorType;
            this.extensionErrorCode = extensionErrorCode;
            this.message = message;
            this.retryable = retryable;
        }
    }
}
```

## 4. Create Error Response Builder

```java
package {{PACKAGE_NAME}}.error;

import java.util.*;

/**
 * Builds consistent error responses for catalog requests.
 */
public class ErrorResponseBuilder {

    /**
     * Build error response map from ExtensionException.
     */
    public static Map<String, Object> buildErrorResponse(ExtensionException e) {
        Map<String, Object> response = new LinkedHashMap<>();

        response.put("success", false);
        response.put("errorType", e.getErrorType().getCode());
        response.put("error", e.getMessage());

        if (e.getErrorCode() != null) {
            response.put("errorCode", e.getErrorCode());
        }

        if (!e.getContext().isEmpty()) {
            response.put("errorContext", e.getContext());
        }

        response.put("retryable", e.isRetryable());

        return response;
    }

    /**
     * Build error response with field-level errors.
     */
    public static Map<String, Object> buildValidationErrorResponse(
            Map<String, List<String>> fieldErrors) {
        Map<String, Object> response = new LinkedHashMap<>();

        response.put("success", false);
        response.put("errorType", ErrorType.INPUT_ERROR.getCode());

        // Build combined error message
        String message = fieldErrors.values().stream()
            .flatMap(List::stream)
            .collect(java.util.stream.Collectors.joining("; "));
        response.put("error", message);

        response.put("fieldErrors", fieldErrors);
        response.put("retryable", false);

        return response;
    }

    /**
     * Build success response.
     */
    public static Map<String, Object> buildSuccessResponse() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", true);
        return response;
    }

    /**
     * Build success response with data.
     */
    public static Map<String, Object> buildSuccessResponse(Map<String, Object> data) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", true);
        response.putAll(data);
        return response;
    }
}
```

## 5. Use Error Handling in Catalog Request

```java
package {{PACKAGE_NAME}}.controller;

import {{PACKAGE_NAME}}.error.*;
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.integration.ApiResponse;

import java.util.*;

public class RecordsArea {

    private final ApiClient client;

    public RecordsArea(ApiClient client) {
        this.client = client;
    }

    @CatalogRequest(
        name = "Create Record",
        domain = "Records",
        type = CatalogRequest.Type.CHANGE_SYSTEM
    )
    public Map<String, Object> createRecord(Map<String, Object> params) {
        try {
            // Step 1: Validate input
            validateInput(params);

            // Step 2: Build payload
            Map<String, Object> payload = buildPayload(params);

            // Step 3: Make API call
            ApiResponse response = client.post("/records", payload);

            // Step 4: Handle response
            if (response.isSuccess()) {
                return ErrorResponseBuilder.buildSuccessResponse(Map.of(
                    "recordId", response.getString("id"),
                    "createdAt", response.getString("created_at")
                ));
            } else {
                throw ApiErrorMapper.mapApiError(response);
            }

        } catch (ExtensionException e) {
            // Already an extension exception, just build response
            return ErrorResponseBuilder.buildErrorResponse(e);

        } catch (Exception e) {
            // Map unknown exception to extension exception
            ExtensionException mapped = ApiErrorMapper.mapException(e);
            return ErrorResponseBuilder.buildErrorResponse(mapped);
        }
    }

    private void validateInput(Map<String, Object> params) {
        Map<String, List<String>> fieldErrors = new LinkedHashMap<>();

        String name = (String) params.get("Name");
        if (name == null || name.isBlank()) {
            fieldErrors.computeIfAbsent("Name", k -> new ArrayList<>())
                .add("Name is required");
        }

        String email = (String) params.get("Email");
        if (email != null && !email.isBlank() && !email.contains("@")) {
            fieldErrors.computeIfAbsent("Email", k -> new ArrayList<>())
                .add("Invalid email format");
        }

        if (!fieldErrors.isEmpty()) {
            throw ExtensionException.inputError(
                fieldErrors.values().stream()
                    .flatMap(List::stream)
                    .collect(java.util.stream.Collectors.joining("; "))
            ).withContext("fieldErrors", fieldErrors);
        }
    }

    private Map<String, Object> buildPayload(Map<String, Object> params) {
        // Build API payload
        return Map.of(
            "name", params.get("Name"),
            "email", params.get("Email")
        );
    }
}
```

## 6. Write Unit Tests

```java
package {{PACKAGE_NAME}}.error;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.net.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class ApiErrorMapperTest {

    @Test
    void mapApiError_with401_returnsAuthorizationError() {
        ApiResponse response = ApiResponse.error(401, "INVALID_TOKEN", "Token expired");

        ExtensionException result = ApiErrorMapper.mapApiError(response);

        assertEquals(ErrorType.AUTHORIZATION_ERROR, result.getErrorType());
        assertFalse(result.isRetryable());
    }

    @Test
    void mapApiError_with429_returnsRetryableSystemError() {
        ApiResponse response = ApiResponse.error(429, "RATE_LIMIT_EXCEEDED", "Too many requests");

        ExtensionException result = ApiErrorMapper.mapApiError(response);

        assertEquals(ErrorType.SYSTEM_ERROR, result.getErrorType());
        assertTrue(result.isRetryable());
    }

    @ParameterizedTest
    @ValueSource(ints = {500, 502, 503, 504})
    void mapApiError_with5xx_returnsRetryableSystemError(int statusCode) {
        ApiResponse response = ApiResponse.error(statusCode, null, "Server error");

        ExtensionException result = ApiErrorMapper.mapApiError(response);

        assertEquals(ErrorType.SYSTEM_ERROR, result.getErrorType());
        assertTrue(result.isRetryable());
    }

    @Test
    void mapException_withTimeout_returnsRetryableError() {
        SocketTimeoutException e = new SocketTimeoutException("Read timed out");

        ExtensionException result = ApiErrorMapper.mapException(e);

        assertEquals(ErrorType.SYSTEM_ERROR, result.getErrorType());
        assertTrue(result.isRetryable());
    }

    @Test
    void mapException_withUnknownHost_returnsNonRetryableError() {
        UnknownHostException e = new UnknownHostException("api.example.com");

        ExtensionException result = ApiErrorMapper.mapException(e);

        assertEquals(ErrorType.SYSTEM_ERROR, result.getErrorType());
        assertFalse(result.isRetryable());
    }
}

class ErrorResponseBuilderTest {

    @Test
    void buildErrorResponse_includesAllFields() {
        ExtensionException e = ExtensionException.inputError("Name", "Name is required");

        Map<String, Object> response = ErrorResponseBuilder.buildErrorResponse(e);

        assertFalse((Boolean) response.get("success"));
        assertEquals("INPUT_ERROR", response.get("errorType"));
        assertTrue(response.get("error").toString().contains("Name"));
    }

    @Test
    void buildValidationErrorResponse_combinesFieldErrors() {
        Map<String, List<String>> fieldErrors = Map.of(
            "Name", List.of("Name is required"),
            "Email", List.of("Invalid email format")
        );

        Map<String, Object> response = ErrorResponseBuilder.buildValidationErrorResponse(fieldErrors);

        assertFalse((Boolean) response.get("success"));
        assertEquals("INPUT_ERROR", response.get("errorType"));
        assertNotNull(response.get("fieldErrors"));
    }
}
```

## Validation Checklist

- [ ] All error types are properly categorized
- [ ] API errors are mapped to appropriate extension errors
- [ ] Java exceptions are mapped to extension errors
- [ ] Error responses include all required fields
- [ ] Retryable errors are correctly identified
- [ ] Field-level validation errors are supported
- [ ] Unit tests cover all error mapping scenarios

## Best Practices

1. **Categorize correctly** - Use INPUT_ERROR for user mistakes, SYSTEM_ERROR for technical issues
2. **Be specific** - Include error codes and context for debugging
3. **Mark retryable** - Help the platform know which errors can be retried
4. **Include field info** - For validation errors, specify which field failed
5. **Log appropriately** - Log system errors, not input errors
6. **Don't expose internals** - Sanitize error messages for users

## Related Prompts

- [09 - Add Request with Complex Validation](09-add-request-complex-validation.md)
- [11 - Add Helper Class](11-add-helper-class.md)
- [17 - Add Retry and Idempotency](17-add-retry-idempotency.md)
```

