# Prompt 12: Configure Setup Tab with Custom Fields

## Purpose

Configure the Setup tab for an extension with various field types including text, password, dropdowns, checkboxes, and output fields. The Setup tab is where users configure the extension's connection settings.

## Prerequisites

- Existing extension class with `@Extension` annotation
- Understanding of required configuration parameters

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |

---

## Prompt

```
I need you to configure a comprehensive Setup tab for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Create AttributeKeys Constants

```java
package {{PACKAGE_NAME}}.config;

/**
 * Constants for Setup tab attribute keys.
 * Using constants prevents typos and enables IDE autocomplete.
 */
public final class AttributeKeys {
    
    private AttributeKeys() {
        // Prevent instantiation
    }
    
    // ============================================================
    // CONNECTION SETTINGS
    // ============================================================
    
    /** Base URL for API calls */
    public static final String BASE_URL = "Base URL";
    
    /** API version to use */
    public static final String API_VERSION = "API Version";
    
    /** Environment selection */
    public static final String ENVIRONMENT = "Environment";
    
    // ============================================================
    // AUTHENTICATION
    // ============================================================
    
    /** OAuth Client ID */
    public static final String CLIENT_ID = "Client ID";
    
    /** OAuth Client Secret */
    public static final String CLIENT_SECRET = "Client Secret";
    
    /** API Key for simple auth */
    public static final String API_KEY = "API Key";
    
    /** Username for basic auth */
    public static final String USERNAME = "Username";
    
    /** Password for basic auth */
    public static final String PASSWORD = "Password";
    
    // ============================================================
    // OPTIONAL SETTINGS
    // ============================================================
    
    /** Enable retry on failures */
    public static final String ALLOW_RETRY = "Allow Retry";
    
    /** Request timeout in seconds */
    public static final String TIMEOUT_SECONDS = "Timeout (seconds)";
    
    /** Enable debug logging */
    public static final String DEBUG_MODE = "Debug Mode";
    
    /** Maximum results per page */
    public static final String PAGE_SIZE = "Page Size";
    
    // ============================================================
    // OUTPUT FIELDS (Read-only)
    // ============================================================
    
    /** Webhook URL for external system */
    public static final String WEBHOOK_URL = "Webhook URL";
    
    /** Connection status */
    public static final String CONNECTION_STATUS = "Connection Status";
    
    /** Last sync timestamp */
    public static final String LAST_SYNC = "Last Sync";
}
```

## 2. Configure Extension Class with Field Annotations

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.util.*;

@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_NAME}} Integration",
    description = "Connect to {{EXTENSION_NAME}} for data synchronization"
)
@Domains({
    @Domain(name = "Records", description = "{{EXTENSION_NAME}} record operations")
})

// ============================================================
// CONNECTION SETTINGS SECTION
// ============================================================

@Field.Text(
    name = AttributeKeys.BASE_URL,
    required = true,
    description = "Base URL for {{EXTENSION_NAME}} API (e.g., https://api.example.com)",
    placeholder = "https://api.example.com"
)

@Field.PickOne(
    name = AttributeKeys.ENVIRONMENT,
    required = true,
    values = {"Production", "Sandbox", "Development"},
    defaultValue = "Production",
    description = "Select the environment to connect to"
)

@Field.PickOne(
    name = AttributeKeys.API_VERSION,
    required = false,
    values = {"v1", "v2", "v3"},
    defaultValue = "v2",
    description = "API version to use"
)

// ============================================================
// AUTHENTICATION SECTION
// ============================================================

@Field.Text(
    name = AttributeKeys.CLIENT_ID,
    required = true,
    description = "OAuth 2.0 Client ID from {{EXTENSION_NAME}}"
)

@Field.Text(
    name = AttributeKeys.CLIENT_SECRET,
    required = true,
    isSecured = true,
    description = "OAuth 2.0 Client Secret (stored securely)"
)

// Alternative: API Key authentication
// @Field.Text(
//     name = AttributeKeys.API_KEY,
//     required = true,
//     isSecured = true,
//     description = "API Key for authentication"
// )

// Alternative: Basic authentication
// @Field.Text(
//     name = AttributeKeys.USERNAME,
//     required = true,
//     description = "Username for authentication"
// )
// @Field.Text(
//     name = AttributeKeys.PASSWORD,
//     required = true,
//     isSecured = true,
//     description = "Password for authentication"
// )

// ============================================================
// OPTIONAL SETTINGS SECTION
// ============================================================

@Field.Checkbox(
    name = AttributeKeys.ALLOW_RETRY,
    defaultValue = "true",
    description = "Automatically retry failed requests on transient errors"
)

@Field.Text(
    name = AttributeKeys.TIMEOUT_SECONDS,
    required = false,
    defaultValue = "30",
    description = "Request timeout in seconds (default: 30)"
)

@Field.PickOne(
    name = AttributeKeys.PAGE_SIZE,
    required = false,
    values = {"25", "50", "100", "200"},
    defaultValue = "50",
    description = "Number of records per page for list operations"
)

@Field.Checkbox(
    name = AttributeKeys.DEBUG_MODE,
    defaultValue = "false",
    description = "Enable detailed logging for troubleshooting"
)

// ============================================================
// OUTPUT FIELDS (Read-only, shown to user)
// ============================================================

@Field.Output(
    name = AttributeKeys.WEBHOOK_URL,
    type = Field.Output.Type.TEXT,
    description = "Configure this URL in {{EXTENSION_NAME}} for webhooks"
)

@Field.Output(
    name = AttributeKeys.CONNECTION_STATUS,
    type = Field.Output.Type.TEXT,
    description = "Current connection status"
)

public class {{EXTENSION_NAME}}Extension {

    private Map<String, Object> attributes;

    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        this.attributes = newAttrs;
    }

    public Map<String, Object> getAttributes() {
        return attributes;
    }

    // Helper methods to get typed attribute values

    public String getBaseUrl() {
        return (String) attributes.get(AttributeKeys.BASE_URL);
    }

    public String getEnvironment() {
        return (String) attributes.get(AttributeKeys.ENVIRONMENT);
    }

    public boolean isAllowRetry() {
        String value = (String) attributes.get(AttributeKeys.ALLOW_RETRY);
        return "true".equalsIgnoreCase(value);
    }

    public int getTimeoutSeconds() {
        String value = (String) attributes.get(AttributeKeys.TIMEOUT_SECONDS);
        return value != null ? Integer.parseInt(value) : 30;
    }

    public boolean isDebugMode() {
        String value = (String) attributes.get(AttributeKeys.DEBUG_MODE);
        return "true".equalsIgnoreCase(value);
    }
}
```

## 3. Field Type Reference

### @Field.Text - Single-line text input

```java
@Field.Text(
    name = "Field Name",           // Display name
    required = true,               // Is field required?
    isSecured = false,             // Mask input (for passwords/secrets)
    defaultValue = "",             // Default value
    placeholder = "Enter value",   // Placeholder text
    description = "Help text"      // Description shown to user
)
```

### @Field.TextArea - Multi-line text input

```java
@Field.TextArea(
    name = "Description",
    required = false,
    description = "Enter detailed description"
)
```

### @Field.PickOne - Dropdown selection

```java
@Field.PickOne(
    name = "Priority",
    required = true,
    values = {"Low", "Normal", "High", "Urgent"},
    defaultValue = "Normal",
    description = "Select priority level"
)
```

### @Field.Checkbox - Boolean toggle

```java
@Field.Checkbox(
    name = "Enable Feature",
    defaultValue = "false",        // "true" or "false" as string
    description = "Enable this feature"
)
```

### @Field.Output - Read-only display field

```java
@Field.Output(
    name = "Status",
    type = Field.Output.Type.TEXT,  // TEXT, NUMBER, BOOLEAN, ENTITY, ENTITY_LIST
    description = "Current status"
)
```

## 4. Accessing Attributes in Code

```java
public class {{EXTENSION_NAME}}Extension {

    private Map<String, Object> attributes;

    /**
     * Get a string attribute with null safety.
     */
    protected String getString(String key) {
        Object value = attributes.get(key);
        return value != null ? value.toString() : null;
    }

    /**
     * Get a string attribute with default value.
     */
    protected String getString(String key, String defaultValue) {
        String value = getString(key);
        return value != null && !value.isBlank() ? value : defaultValue;
    }

    /**
     * Get a boolean attribute.
     */
    protected boolean getBoolean(String key) {
        return "true".equalsIgnoreCase(getString(key));
    }

    /**
     * Get an integer attribute with default.
     */
    protected int getInt(String key, int defaultValue) {
        String value = getString(key);
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    /**
     * Get a secured attribute (password, API key, etc.).
     * These are stored encrypted and decrypted when accessed.
     */
    protected String getSecuredString(String key) {
        return getString(key);  // Platform handles decryption
    }
}
```

## 5. Validation in VALIDATE_ATTRIBUTES

```java
    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();

        // Validate Base URL
        String baseUrl = (String) attributes.get(AttributeKeys.BASE_URL);
        if (baseUrl == null || baseUrl.isBlank()) {
            errors.add("Base URL is required");
        } else if (!baseUrl.startsWith("https://")) {
            errors.add("Base URL must use HTTPS");
        }

        // Validate timeout
        String timeout = (String) attributes.get(AttributeKeys.TIMEOUT_SECONDS);
        if (timeout != null && !timeout.isBlank()) {
            try {
                int value = Integer.parseInt(timeout);
                if (value < 1 || value > 300) {
                    errors.add("Timeout must be between 1 and 300 seconds");
                }
            } catch (NumberFormatException e) {
                errors.add("Timeout must be a valid number");
            }
        }

        // Validate credentials based on auth type
        String clientId = (String) attributes.get(AttributeKeys.CLIENT_ID);
        String clientSecret = (String) attributes.get(AttributeKeys.CLIENT_SECRET);

        if ((clientId == null || clientId.isBlank()) &&
            (clientSecret == null || clientSecret.isBlank())) {
            errors.add("Client ID and Client Secret are required");
        }

        return errors;
    }
```

## Validation Checklist

- [ ] All required fields have `required = true`
- [ ] Sensitive fields have `isSecured = true`
- [ ] Dropdown fields have valid `values` array
- [ ] Default values are appropriate
- [ ] Descriptions are clear and helpful
- [ ] AttributeKeys constants match field names exactly
- [ ] VALIDATE_ATTRIBUTES validates all fields

## Best Practices

1. **Use constants** - Define all attribute keys in AttributeKeys class
2. **Secure sensitive data** - Always use `isSecured = true` for passwords/keys
3. **Provide defaults** - Set sensible defaults for optional fields
4. **Clear descriptions** - Help users understand what each field does
5. **Validate thoroughly** - Check all fields in VALIDATE_ATTRIBUTES
6. **Group logically** - Organize fields by section (connection, auth, options)

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [13 - Implement VALIDATE_ATTRIBUTES](13-implement-validate-attributes.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
```

