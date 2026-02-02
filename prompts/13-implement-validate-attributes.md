# Prompt 13: Implement VALIDATE_ATTRIBUTES Invoker Request

## Purpose

Implement the VALIDATE_ATTRIBUTES invoker request to validate extension configuration before it's saved. This ensures users provide valid configuration values.

## Prerequisites

- Existing extension with Setup tab fields
- Understanding of validation requirements for each field

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |

---

## Prompt

```
I need you to implement comprehensive VALIDATE_ATTRIBUTES for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Implement VALIDATE_ATTRIBUTES Handler

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.net.URL;
import java.util.*;
import java.util.regex.Pattern;

@Extension(name = "{{EXTENSION_NAME}}")
public class {{EXTENSION_NAME}}Extension {

    // Validation patterns
    private static final Pattern URL_PATTERN = 
        Pattern.compile("^https://[a-zA-Z0-9][a-zA-Z0-9-]*(\\.[a-zA-Z0-9-]+)+(/.*)?$");
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern CLIENT_ID_PATTERN = 
        Pattern.compile("^[a-zA-Z0-9_-]{10,}$");

    /**
     * Validate configuration attributes before saving.
     * 
     * Called by the Krista platform when user clicks Save on Setup tab.
     * Return empty list if valid, or list of error messages if invalid.
     * 
     * @param attributes Map of attribute name to value
     * @return List of validation error messages (empty if valid)
     */
    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();
        
        // Validate connection settings
        validateConnectionSettings(attributes, errors);
        
        // Validate authentication
        validateAuthentication(attributes, errors);
        
        // Validate optional settings
        validateOptionalSettings(attributes, errors);
        
        // Validate cross-field rules
        validateCrossFieldRules(attributes, errors);
        
        return errors;
    }

    // ============================================================
    // CONNECTION VALIDATION
    // ============================================================

    private void validateConnectionSettings(Map<String, Object> attributes, List<String> errors) {
        // Base URL validation
        String baseUrl = getString(attributes, AttributeKeys.BASE_URL);
        
        if (isBlank(baseUrl)) {
            errors.add("Base URL is required");
        } else {
            // Must be HTTPS
            if (!baseUrl.startsWith("https://")) {
                errors.add("Base URL must use HTTPS for security");
            }
            
            // Must be valid URL format
            if (!URL_PATTERN.matcher(baseUrl).matches()) {
                errors.add("Base URL is not a valid URL format");
            }
            
            // Must not have trailing slash
            if (baseUrl.endsWith("/")) {
                errors.add("Base URL should not end with a trailing slash");
            }
            
            // Validate URL is reachable (optional - may slow down validation)
            // validateUrlReachable(baseUrl, errors);
        }
        
        // Environment validation
        String environment = getString(attributes, AttributeKeys.ENVIRONMENT);
        if (isBlank(environment)) {
            errors.add("Environment is required");
        } else {
            Set<String> validEnvironments = Set.of("Production", "Sandbox", "Development");
            if (!validEnvironments.contains(environment)) {
                errors.add("Environment must be one of: " + String.join(", ", validEnvironments));
            }
        }
    }

    // ============================================================
    // AUTHENTICATION VALIDATION
    // ============================================================

    private void validateAuthentication(Map<String, Object> attributes, List<String> errors) {
        String clientId = getString(attributes, AttributeKeys.CLIENT_ID);
        String clientSecret = getString(attributes, AttributeKeys.CLIENT_SECRET);
        
        // Client ID validation
        if (isBlank(clientId)) {
            errors.add("Client ID is required");
        } else {
            if (clientId.length() < 10) {
                errors.add("Client ID appears to be too short");
            }
            if (!CLIENT_ID_PATTERN.matcher(clientId).matches()) {
                errors.add("Client ID contains invalid characters");
            }
        }
        
        // Client Secret validation
        if (isBlank(clientSecret)) {
            errors.add("Client Secret is required");
        } else {
            if (clientSecret.length() < 20) {
                errors.add("Client Secret appears to be too short");
            }
            // Check for common mistakes
            if (clientSecret.contains(" ")) {
                errors.add("Client Secret should not contain spaces");
            }
        }
    }

    // ============================================================
    // OPTIONAL SETTINGS VALIDATION
    // ============================================================

    private void validateOptionalSettings(Map<String, Object> attributes, List<String> errors) {
        // Timeout validation
        String timeoutStr = getString(attributes, AttributeKeys.TIMEOUT_SECONDS);
        if (!isBlank(timeoutStr)) {
            try {
                int timeout = Integer.parseInt(timeoutStr);
                if (timeout < 1) {
                    errors.add("Timeout must be at least 1 second");
                }
                if (timeout > 300) {
                    errors.add("Timeout cannot exceed 300 seconds (5 minutes)");
                }
            } catch (NumberFormatException e) {
                errors.add("Timeout must be a valid number");
            }
        }
        
        // Page size validation
        String pageSizeStr = getString(attributes, AttributeKeys.PAGE_SIZE);
        if (!isBlank(pageSizeStr)) {
            Set<String> validSizes = Set.of("25", "50", "100", "200");
            if (!validSizes.contains(pageSizeStr)) {
                errors.add("Page Size must be one of: " + String.join(", ", validSizes));
            }
        }
    }

    // ============================================================
    // CROSS-FIELD VALIDATION
    // ============================================================

    private void validateCrossFieldRules(Map<String, Object> attributes, List<String> errors) {
        String environment = getString(attributes, AttributeKeys.ENVIRONMENT);
        String baseUrl = getString(attributes, AttributeKeys.BASE_URL);

        // Validate URL matches environment
        if (!isBlank(environment) && !isBlank(baseUrl)) {
            if ("Production".equals(environment) && baseUrl.contains("sandbox")) {
                errors.add("Base URL appears to be a sandbox URL but Production environment is selected");
            }
            if ("Sandbox".equals(environment) && !baseUrl.contains("sandbox") && !baseUrl.contains("test")) {
                errors.add("Base URL appears to be a production URL but Sandbox environment is selected");
            }
        }

        // Validate debug mode warning
        String debugMode = getString(attributes, AttributeKeys.DEBUG_MODE);
        if ("true".equalsIgnoreCase(debugMode) && "Production".equals(environment)) {
            // This is a warning, not an error - could log it instead
            // errors.add("Warning: Debug mode is enabled in Production environment");
        }
    }

    // ============================================================
    // UTILITY METHODS
    // ============================================================

    private String getString(Map<String, Object> attributes, String key) {
        Object value = attributes.get(key);
        return value != null ? value.toString() : null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
```

## 2. Advanced Validation Patterns

### Pattern A: Async URL Validation

```java
    /**
     * Validate that a URL is reachable (use sparingly - slows validation).
     */
    private void validateUrlReachable(String url, List<String> errors) {
        try {
            URL urlObj = new URL(url);
            HttpURLConnection connection = (HttpURLConnection) urlObj.openConnection();
            connection.setRequestMethod("HEAD");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);

            int responseCode = connection.getResponseCode();
            if (responseCode >= 400) {
                errors.add("Base URL returned error: " + responseCode);
            }
        } catch (Exception e) {
            errors.add("Cannot connect to Base URL: " + e.getMessage());
        }
    }
```

### Pattern B: Conditional Required Fields

```java
    private void validateConditionalFields(Map<String, Object> attributes, List<String> errors) {
        String authType = getString(attributes, "Authentication Type");

        if ("OAuth".equals(authType)) {
            if (isBlank(getString(attributes, "Client ID"))) {
                errors.add("Client ID is required for OAuth authentication");
            }
            if (isBlank(getString(attributes, "Client Secret"))) {
                errors.add("Client Secret is required for OAuth authentication");
            }
        } else if ("API Key".equals(authType)) {
            if (isBlank(getString(attributes, "API Key"))) {
                errors.add("API Key is required for API Key authentication");
            }
        } else if ("Basic".equals(authType)) {
            if (isBlank(getString(attributes, "Username"))) {
                errors.add("Username is required for Basic authentication");
            }
            if (isBlank(getString(attributes, "Password"))) {
                errors.add("Password is required for Basic authentication");
            }
        }
    }
```

### Pattern C: Format-Specific Validation

```java
    private void validateFormats(Map<String, Object> attributes, List<String> errors) {
        // Email validation
        String email = getString(attributes, "Notification Email");
        if (!isBlank(email) && !EMAIL_PATTERN.matcher(email).matches()) {
            errors.add("Notification Email is not a valid email address");
        }

        // Phone validation
        String phone = getString(attributes, "Phone Number");
        if (!isBlank(phone)) {
            String digitsOnly = phone.replaceAll("[^0-9]", "");
            if (digitsOnly.length() < 10 || digitsOnly.length() > 15) {
                errors.add("Phone Number must be 10-15 digits");
            }
        }

        // Date validation
        String date = getString(attributes, "Start Date");
        if (!isBlank(date)) {
            try {
                LocalDate.parse(date);
            } catch (DateTimeParseException e) {
                errors.add("Start Date must be in YYYY-MM-DD format");
            }
        }
    }
```

## 3. Write Unit Tests

```java
package {{PACKAGE_NAME}};

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class {{EXTENSION_NAME}}ExtensionValidationTest {

    private {{EXTENSION_NAME}}Extension extension;

    @BeforeEach
    void setUp() {
        extension = new {{EXTENSION_NAME}}Extension();
    }

    @Test
    void validateAttributes_withValidConfig_returnsNoErrors() {
        Map<String, Object> attrs = createValidAttributes();

        List<String> errors = extension.validateAttributes(attrs);

        assertTrue(errors.isEmpty(), "Expected no errors but got: " + errors);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  ", "\t"})
    void validateAttributes_withBlankBaseUrl_returnsError(String baseUrl) {
        Map<String, Object> attrs = createValidAttributes();
        attrs.put("Base URL", baseUrl);

        List<String> errors = extension.validateAttributes(attrs);

        assertTrue(errors.stream().anyMatch(e -> e.contains("Base URL")));
    }

    @Test
    void validateAttributes_withHttpUrl_returnsError() {
        Map<String, Object> attrs = createValidAttributes();
        attrs.put("Base URL", "http://api.example.com");

        List<String> errors = extension.validateAttributes(attrs);

        assertTrue(errors.stream().anyMatch(e -> e.contains("HTTPS")));
    }

    @Test
    void validateAttributes_withInvalidTimeout_returnsError() {
        Map<String, Object> attrs = createValidAttributes();
        attrs.put("Timeout (seconds)", "500");

        List<String> errors = extension.validateAttributes(attrs);

        assertTrue(errors.stream().anyMatch(e -> e.contains("Timeout")));
    }

    @Test
    void validateAttributes_withMismatchedEnvironment_returnsError() {
        Map<String, Object> attrs = createValidAttributes();
        attrs.put("Environment", "Production");
        attrs.put("Base URL", "https://sandbox.api.example.com");

        List<String> errors = extension.validateAttributes(attrs);

        assertTrue(errors.stream().anyMatch(e -> e.contains("sandbox")));
    }

    private Map<String, Object> createValidAttributes() {
        Map<String, Object> attrs = new HashMap<>();
        attrs.put("Base URL", "https://api.example.com");
        attrs.put("Environment", "Production");
        attrs.put("Client ID", "abcdefghij1234567890");
        attrs.put("Client Secret", "secretkey1234567890abcdef");
        attrs.put("Timeout (seconds)", "30");
        attrs.put("Page Size", "50");
        return attrs;
    }
}
```

## Validation Checklist

- [ ] All required fields validated for presence
- [ ] URL fields validated for HTTPS and format
- [ ] Numeric fields validated for range
- [ ] Dropdown values validated against allowed list
- [ ] Cross-field dependencies validated
- [ ] Error messages are clear and actionable
- [ ] Unit tests cover all validation rules

## Best Practices

1. **Validate early** - Check required fields first
2. **Clear messages** - Tell user exactly what's wrong and how to fix
3. **Don't over-validate** - Avoid blocking valid edge cases
4. **Test thoroughly** - Cover all validation paths
5. **Consider UX** - Group related errors together
6. **Avoid slow validation** - Don't make network calls unless necessary

## Related Prompts

- [12 - Configure Setup Tab](12-configure-setup-tab.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
- [15 - Implement Lifecycle Hooks](15-implement-lifecycle-hooks.md)
```

