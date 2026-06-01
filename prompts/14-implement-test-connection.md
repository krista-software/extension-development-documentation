# Prompt 14: Implement TEST_CONNECTION Invoker Request

## Purpose

Implement the TEST_CONNECTION invoker request to verify that the extension can successfully connect to the external service using the provided configuration. This gives users immediate feedback on whether their settings are correct.

## Prerequisites

- Existing extension with Setup tab fields configured
- VALIDATE_ATTRIBUTES already implemented
- Understanding of the external API's authentication mechanism

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |
| API Base Endpoint | `{{TEST_ENDPOINT}}` | `/api/v1/me` |

---

## Prompt

```
I need you to implement TEST_CONNECTION for my Krista extension to verify connectivity.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Test Endpoint**: {{TEST_ENDPOINT}}

## 1. Implement TEST_CONNECTION Handler

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.integration.ApiResponse;

import java.util.*;

@Extension(name = "{{EXTENSION_NAME}}")
public class {{EXTENSION_NAME}}Extension {

    private Map<String, Object> attributes;
    private ApiClient client;

    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        this.attributes = attributes;
        initializeClient();
    }

    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        this.attributes = newAttrs;
        initializeClient();
    }

    private void initializeClient() {
        String baseUrl = getString(AttributeKeys.BASE_URL);
        String clientId = getString(AttributeKeys.CLIENT_ID);
        String clientSecret = getString(AttributeKeys.CLIENT_SECRET);
        int timeout = getInt(AttributeKeys.TIMEOUT_SECONDS, 30);
        
        this.client = new ApiClient(baseUrl, clientId, clientSecret, timeout);
    }

    /**
     * Test connection to the external service.
     * 
     * Called when user clicks "Test Connection" button on Setup tab.
     * Returns a map with:
     * - "success": boolean indicating if connection succeeded
     * - "message": human-readable result message
     * - "details": (optional) additional connection details
     * 
     * @param attributes Current configuration attributes
     * @return Map with test results
     */
    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public Map<String, Object> testConnection(Map<String, Object> attributes) {
        Map<String, Object> result = new LinkedHashMap<>();
        
        try {
            // Step 1: Verify configuration is complete
            List<String> configErrors = validateConfiguration(attributes);
            if (!configErrors.isEmpty()) {
                result.put("success", false);
                result.put("message", "Configuration incomplete: " + String.join(", ", configErrors));
                return result;
            }
            
            // Step 2: Initialize client with provided attributes
            ApiClient testClient = createTestClient(attributes);
            
            // Step 3: Authenticate and get token
            AuthResult authResult = testClient.authenticate();
            if (!authResult.isSuccess()) {
                result.put("success", false);
                result.put("message", "Authentication failed: " + authResult.getError());
                result.put("errorCode", authResult.getErrorCode());
                return result;
            }
            
            // Step 4: Make test API call
            ConnectionTestResult testResult = performConnectionTest(testClient);
            
            if (testResult.isSuccess()) {
                result.put("success", true);
                result.put("message", "Connection successful!");
                result.put("details", testResult.getDetails());
            } else {
                result.put("success", false);
                result.put("message", testResult.getErrorMessage());
                result.put("errorCode", testResult.getErrorCode());
            }
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Connection test failed: " + e.getMessage());
            result.put("errorType", e.getClass().getSimpleName());
        }
        
        return result;
    }

    // ============================================================
    // CONNECTION TEST METHODS
    // ============================================================

    /**
     * Validate that required configuration is present.
     */
    private List<String> validateConfiguration(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();
        
        if (isBlank(getString(attributes, AttributeKeys.BASE_URL))) {
            errors.add("Base URL is required");
        }
        if (isBlank(getString(attributes, AttributeKeys.CLIENT_ID))) {
            errors.add("Client ID is required");
        }
        if (isBlank(getString(attributes, AttributeKeys.CLIENT_SECRET))) {
            errors.add("Client Secret is required");
        }
        
        return errors;
    }

    /**
     * Create a temporary client for testing.
     */
    private ApiClient createTestClient(Map<String, Object> attributes) {
        String baseUrl = getString(attributes, AttributeKeys.BASE_URL);
        String clientId = getString(attributes, AttributeKeys.CLIENT_ID);
        String clientSecret = getString(attributes, AttributeKeys.CLIENT_SECRET);
        int timeout = getInt(attributes, AttributeKeys.TIMEOUT_SECONDS, 30);
        
        return new ApiClient(baseUrl, clientId, clientSecret, timeout);
    }

    /**
     * Perform the actual connection test.
     */
    private ConnectionTestResult performConnectionTest(ApiClient testClient) {
        try {
            // Call a lightweight endpoint to verify connectivity
            // Common patterns: /me, /user, /account, /status, /health
            ApiResponse response = testClient.get("{{TEST_ENDPOINT}}");
            
            if (response.isSuccess()) {
                Map<String, Object> details = new LinkedHashMap<>();
                
                // Extract useful info from response
                if (response.hasField("name")) {
                    details.put("accountName", response.getString("name"));
                }
                if (response.hasField("email")) {
                    details.put("email", response.getString("email"));
                }
                if (response.hasField("organization")) {
                    details.put("organization", response.getString("organization"));
                }
                details.put("apiVersion", response.getHeader("X-API-Version"));
                details.put("responseTime", response.getResponseTimeMs() + "ms");

                return ConnectionTestResult.success(details);
            } else {
                return ConnectionTestResult.failure(
                    response.getStatusCode(),
                    "API returned error: " + response.getErrorMessage()
                );
            }
        } catch (AuthenticationException e) {
            return ConnectionTestResult.failure("AUTH_ERROR",
                "Authentication failed: " + e.getMessage());
        } catch (ConnectionException e) {
            return ConnectionTestResult.failure("CONNECTION_ERROR",
                "Cannot connect to server: " + e.getMessage());
        } catch (TimeoutException e) {
            return ConnectionTestResult.failure("TIMEOUT",
                "Connection timed out. Check network or increase timeout.");
        } catch (Exception e) {
            return ConnectionTestResult.failure("UNKNOWN_ERROR",
                "Unexpected error: " + e.getMessage());
        }
    }

    // ============================================================
    // UTILITY METHODS
    // ============================================================

    private String getString(String key) {
        return getString(attributes, key);
    }

    private String getString(Map<String, Object> attrs, String key) {
        Object value = attrs.get(key);
        return value != null ? value.toString() : null;
    }

    private int getInt(String key, int defaultValue) {
        return getInt(attributes, key, defaultValue);
    }

    private int getInt(Map<String, Object> attrs, String key, int defaultValue) {
        String value = getString(attrs, key);
        if (value == null || value.isBlank()) return defaultValue;
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
```

## 2. Create ConnectionTestResult Class

```java
package {{PACKAGE_NAME}}.integration;

import java.util.*;

/**
 * Result of a connection test operation.
 */
public class ConnectionTestResult {

    private final boolean success;
    private final String errorCode;
    private final String errorMessage;
    private final Map<String, Object> details;

    private ConnectionTestResult(boolean success, String errorCode,
                                  String errorMessage, Map<String, Object> details) {
        this.success = success;
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
        this.details = details != null ? details : Collections.emptyMap();
    }

    public static ConnectionTestResult success(Map<String, Object> details) {
        return new ConnectionTestResult(true, null, null, details);
    }

    public static ConnectionTestResult failure(String errorCode, String errorMessage) {
        return new ConnectionTestResult(false, errorCode, errorMessage, null);
    }

    public static ConnectionTestResult failure(int httpStatus, String errorMessage) {
        return new ConnectionTestResult(false, "HTTP_" + httpStatus, errorMessage, null);
    }

    public boolean isSuccess() { return success; }
    public String getErrorCode() { return errorCode; }
    public String getErrorMessage() { return errorMessage; }
    public Map<String, Object> getDetails() { return details; }
}
```

## 3. Enhanced Test Connection with Detailed Diagnostics

```java
    /**
     * Comprehensive connection test with detailed diagnostics.
     */
    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public Map<String, Object> testConnectionWithDiagnostics(Map<String, Object> attributes) {
        Map<String, Object> result = new LinkedHashMap<>();
        List<Map<String, Object>> steps = new ArrayList<>();

        try {
            // Step 1: Configuration Check
            Map<String, Object> configStep = new LinkedHashMap<>();
            configStep.put("step", "Configuration Validation");
            List<String> configErrors = validateConfiguration(attributes);
            if (configErrors.isEmpty()) {
                configStep.put("status", "PASSED");
                configStep.put("message", "All required fields are configured");
            } else {
                configStep.put("status", "FAILED");
                configStep.put("message", String.join(", ", configErrors));
                steps.add(configStep);
                result.put("success", false);
                result.put("message", "Configuration incomplete");
                result.put("steps", steps);
                return result;
            }
            steps.add(configStep);

            // Step 2: DNS Resolution
            Map<String, Object> dnsStep = new LinkedHashMap<>();
            dnsStep.put("step", "DNS Resolution");
            String baseUrl = getString(attributes, AttributeKeys.BASE_URL);
            try {
                URL url = new URL(baseUrl);
                InetAddress.getByName(url.getHost());
                dnsStep.put("status", "PASSED");
                dnsStep.put("message", "Host resolved successfully");
            } catch (Exception e) {
                dnsStep.put("status", "FAILED");
                dnsStep.put("message", "Cannot resolve host: " + e.getMessage());
                steps.add(dnsStep);
                result.put("success", false);
                result.put("message", "DNS resolution failed");
                result.put("steps", steps);
                return result;
            }
            steps.add(dnsStep);

            // Step 3: TCP Connection
            Map<String, Object> tcpStep = new LinkedHashMap<>();
            tcpStep.put("step", "TCP Connection");
            try {
                URL url = new URL(baseUrl);
                int port = url.getPort() > 0 ? url.getPort() :
                          ("https".equals(url.getProtocol()) ? 443 : 80);
                Socket socket = new Socket();
                socket.connect(new InetSocketAddress(url.getHost(), port), 5000);
                socket.close();
                tcpStep.put("status", "PASSED");
                tcpStep.put("message", "TCP connection established");
            } catch (Exception e) {
                tcpStep.put("status", "FAILED");
                tcpStep.put("message", "Cannot connect: " + e.getMessage());
                steps.add(tcpStep);
                result.put("success", false);
                result.put("message", "TCP connection failed");
                result.put("steps", steps);
                return result;
            }
            steps.add(tcpStep);

            // Step 4: Authentication
            Map<String, Object> authStep = new LinkedHashMap<>();
            authStep.put("step", "Authentication");
            ApiClient testClient = createTestClient(attributes);
            AuthResult authResult = testClient.authenticate();
            if (authResult.isSuccess()) {
                authStep.put("status", "PASSED");
                authStep.put("message", "Authentication successful");
            } else {
                authStep.put("status", "FAILED");
                authStep.put("message", authResult.getError());
                steps.add(authStep);
                result.put("success", false);
                result.put("message", "Authentication failed");
                result.put("steps", steps);
                return result;
            }
            steps.add(authStep);

            // Step 5: API Call
            Map<String, Object> apiStep = new LinkedHashMap<>();
            apiStep.put("step", "API Verification");
            ConnectionTestResult testResult = performConnectionTest(testClient);
            if (testResult.isSuccess()) {
                apiStep.put("status", "PASSED");
                apiStep.put("message", "API responding correctly");
                apiStep.put("details", testResult.getDetails());
            } else {
                apiStep.put("status", "FAILED");
                apiStep.put("message", testResult.getErrorMessage());
            }
            steps.add(apiStep);

            // Final result
            result.put("success", testResult.isSuccess());
            result.put("message", testResult.isSuccess() ?
                "All connection tests passed!" : "API verification failed");
            result.put("steps", steps);

        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Unexpected error: " + e.getMessage());
            result.put("steps", steps);
        }

        return result;
    }
```

## 4. Write Unit Tests

```java
package {{PACKAGE_NAME}};

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class {{EXTENSION_NAME}}ExtensionConnectionTest {

    private {{EXTENSION_NAME}}Extension extension;

    @Mock
    private ApiClient mockClient;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        extension = new {{EXTENSION_NAME}}Extension();
    }

    @Test
    void testConnection_withValidConfig_returnsSuccess() {
        Map<String, Object> attrs = createValidAttributes();

        // Mock successful authentication and API call
        when(mockClient.authenticate()).thenReturn(AuthResult.success("token"));
        when(mockClient.get(anyString())).thenReturn(ApiResponse.success(Map.of("name", "Test")));

        Map<String, Object> result = extension.testConnection(attrs);

        assertTrue((Boolean) result.get("success"));
        assertEquals("Connection successful!", result.get("message"));
    }

    @Test
    void testConnection_withMissingBaseUrl_returnsError() {
        Map<String, Object> attrs = createValidAttributes();
        attrs.remove("Base URL");

        Map<String, Object> result = extension.testConnection(attrs);

        assertFalse((Boolean) result.get("success"));
        assertTrue(result.get("message").toString().contains("Base URL"));
    }

    @Test
    void testConnection_withAuthFailure_returnsError() {
        Map<String, Object> attrs = createValidAttributes();

        when(mockClient.authenticate()).thenReturn(
            AuthResult.failure("Invalid credentials"));

        Map<String, Object> result = extension.testConnection(attrs);

        assertFalse((Boolean) result.get("success"));
        assertTrue(result.get("message").toString().contains("Authentication"));
    }

    @Test
    void testConnection_withTimeout_returnsError() {
        Map<String, Object> attrs = createValidAttributes();

        when(mockClient.authenticate()).thenReturn(AuthResult.success("token"));
        when(mockClient.get(anyString())).thenThrow(new TimeoutException("Timeout"));

        Map<String, Object> result = extension.testConnection(attrs);

        assertFalse((Boolean) result.get("success"));
        assertTrue(result.get("message").toString().contains("timeout"));
    }

    private Map<String, Object> createValidAttributes() {
        Map<String, Object> attrs = new HashMap<>();
        attrs.put("Base URL", "https://api.example.com");
        attrs.put("Client ID", "test-client-id-12345");
        attrs.put("Client Secret", "test-secret-key-abcdef");
        attrs.put("Timeout (seconds)", "30");
        return attrs;
    }
}
```

## Validation Checklist

- [ ] TEST_CONNECTION handler returns proper success/failure map
- [ ] Configuration is validated before attempting connection
- [ ] Authentication is tested before API calls
- [ ] Error messages are clear and actionable
- [ ] Timeout is respected during connection test
- [ ] Connection details are returned on success
- [ ] Unit tests cover success and failure scenarios

## Best Practices

1. **Validate first** - Check configuration before making network calls
2. **Use lightweight endpoint** - Test with /me, /status, or /health endpoints
3. **Set reasonable timeout** - Don't let test hang indefinitely
4. **Return useful details** - Show account name, email, or org on success
5. **Clear error messages** - Help users understand what went wrong
6. **Step-by-step diagnostics** - Show which step failed for troubleshooting

## Related Prompts

- [12 - Configure Setup Tab](12-configure-setup-tab.md)
- [13 - Implement VALIDATE_ATTRIBUTES](13-implement-validate-attributes.md)
- [15 - Implement Lifecycle Hooks](15-implement-lifecycle-hooks.md)
```

