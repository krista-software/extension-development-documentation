# Prompt 04: Create Extension from Scratch (Minimal Starter)

## Purpose

Create a minimal Krista extension skeleton with the basic project structure, build configuration, and entry point class. This is the starting point for any new extension before adding authentication or catalog requests.

## Prerequisites

- Empty or new project directory
- Gradle build environment

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `MyService` |
| Extension Display Name | `{{EXTENSION_DISPLAY_NAME}}` | `My Service Integration` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.myservice` |
| Domain Name | `{{DOMAIN_NAME}}` | `Items` |
| Description | `{{DESCRIPTION}}` | `Integration with My Service API` |

---

## Prompt

```
I need you to create a minimal Krista extension skeleton.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Display Name**: {{EXTENSION_DISPLAY_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **Description**: {{DESCRIPTION}}

## Required Project Structure

Create this minimal structure:

```
{{EXTENSION_NAME}}/
├── src/main/java/{{PACKAGE_PATH}}/
│   ├── {{EXTENSION_NAME}}Extension.java      # Main extension class
│   ├── controller/
│   │   └── {{DOMAIN_NAME}}Area.java          # Area for catalog requests
│   ├── integration/                           # External API clients (empty)
│   ├── config/
│   │   └── AttributeKeys.java                # Configuration constants
│   ├── entity/                                # Entity classes (empty)
│   └── transformation/                        # Transformers (empty)
├── src/main/resources/
│   └── docs/
│       └── README.md
├── src/test/java/{{PACKAGE_PATH}}/
│   └── {{EXTENSION_NAME}}ExtensionTest.java
└── build.gradle
```

## 1. Create build.gradle

```groovy
plugins {
    id 'java'
}

group = '{{PACKAGE_NAME}}'
version = '1.0.0'

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

repositories {
    mavenCentral()
}

dependencies {
    // Krista SDK (provided by platform at runtime)
    compileOnly 'app.krista:krista-extension-sdk:+'
    
    // HTTP client for API calls
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    
    // JSON processing
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // Testing
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
    testImplementation 'org.mockito:mockito-core:5.5.0'
    testImplementation 'org.mockito:mockito-junit-jupiter:5.5.0'
}

test {
    useJUnitPlatform()
}

jar {
    manifest {
        attributes(
            'Implementation-Title': project.name,
            'Implementation-Version': project.version
        )
    }
}
```

## 2. Create AttributeKeys.java

```java
package {{PACKAGE_NAME}}.config;

/**
 * Constants for Setup tab attribute keys.
 * Add your configuration field names here.
 */
public final class AttributeKeys {
    
    private AttributeKeys() {
        // Prevent instantiation
    }
    
    // Add your attribute keys here
    // Example:
    // public static final String API_KEY = "API Key";
    // public static final String BASE_URL = "Base URL";
    
    // Common optional settings
    public static final String ALLOW_RETRY = "Allow Retry";
}
```

## 3. Create Main Extension Class

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.util.*;

/**
 * {{EXTENSION_DISPLAY_NAME}} - {{DESCRIPTION}}
 */
@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_DISPLAY_NAME}}",
    description = "{{DESCRIPTION}}"
)
@Domains({
    @Domain(name = "{{DOMAIN_NAME}}", description = "{{DOMAIN_NAME}} operations")
})
// Add your Setup tab fields here using @Field.* annotations
// Example:
// @Field.Text(name = "API Key", required = true, isSecured = true)
// @Field.Text(name = "Base URL", required = true)
@Field.Checkbox(name = AttributeKeys.ALLOW_RETRY, defaultValue = "true",
    description = "Allow retry on transient failures")
public class {{EXTENSION_NAME}}Extension {

    private Map<String, Object> currentAttributes;

    /**
     * Called when the extension invoker is loaded.
     * Initialize resources, clients, and caches here.
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        this.currentAttributes = attributes;
        // Initialize your clients and resources here
    }

    /**
     * Called when configuration is updated.
     * Reinitialize resources with new configuration.
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        this.currentAttributes = newAttrs;
        // Reinitialize your clients with new configuration
    }

    /**
     * Called when the extension invoker is unloaded.
     * Clean up resources here.
     */
    @InvokerRequest(InvokerRequest.Type.INVOKER_UNLOADED)
    public void onUnloaded() {
        this.currentAttributes = null;
        // Clean up your resources here
    }

    /**
     * Validate configuration before saving.
     * Return a list of error messages (empty if valid).
     */
    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();

        // Add your validation logic here
        // Example:
        // String apiKey = (String) attributes.get("API Key");
        // if (apiKey == null || apiKey.isBlank()) {
        //     errors.add("API Key is required");
        // }

        return errors;
    }

    /**
     * Test connection to external service.
     * Throw an exception if connection fails.
     */
    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public void testConnection() throws Exception {
        // Implement connection test logic here
        // Example: Make a lightweight API call to verify connectivity
    }

    /**
     * Get current configuration attributes.
     */
    public Map<String, Object> getAttributes() {
        return currentAttributes;
    }
}
```

## 4. Create Area Class

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.{{EXTENSION_NAME}}Extension;

import java.util.*;

/**
 * Area class containing catalog requests for {{DOMAIN_NAME}} domain.
 * Add your @CatalogRequest methods here.
 */
public class {{DOMAIN_NAME}}Area {

    private final {{EXTENSION_NAME}}Extension extension;

    public {{DOMAIN_NAME}}Area({{EXTENSION_NAME}}Extension extension) {
        this.extension = extension;
    }

    // Example QUERY_SYSTEM catalog request (read-only)
    // @CatalogRequest(
    //     name = "List Items",
    //     domain = "{{DOMAIN_NAME}}",
    //     type = CatalogRequest.Type.QUERY_SYSTEM,
    //     description = "List all items"
    // )
    // @Field.Text(name = "Search Query", required = false)
    // public Map<String, Object> listItems(Map<String, Object> params) {
    //     Map<String, Object> result = new HashMap<>();
    //     result.put("items", new ArrayList<>());
    //     return result;
    // }

    // Example CHANGE_SYSTEM catalog request (create/update/delete)
    // @CatalogRequest(
    //     name = "Create Item",
    //     domain = "{{DOMAIN_NAME}}",
    //     type = CatalogRequest.Type.CHANGE_SYSTEM,
    //     description = "Create a new item"
    // )
    // @Field.Text(name = "Name", required = true)
    // @Field.Text(name = "Description", required = false)
    // public Map<String, Object> createItem(Map<String, Object> params) {
    //     Map<String, Object> result = new HashMap<>();
    //     result.put("id", "new-item-id");
    //     result.put("success", true);
    //     return result;
    // }
}
```

## 5. Create Basic Test Class

```java
package {{PACKAGE_NAME}};

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {{EXTENSION_NAME}}Extension.
 */
class {{EXTENSION_NAME}}ExtensionTest {

    private {{EXTENSION_NAME}}Extension extension;

    @BeforeEach
    void setUp() {
        extension = new {{EXTENSION_NAME}}Extension();
    }

    @Test
    void testValidateAttributes_withValidConfig_returnsNoErrors() {
        Map<String, Object> attributes = new HashMap<>();
        // Add valid test attributes

        List<String> errors = extension.validateAttributes(attributes);

        assertTrue(errors.isEmpty(), "Should return no errors for valid config");
    }

    @Test
    void testOnLoaded_initializesAttributes() {
        Map<String, Object> attributes = new HashMap<>();
        attributes.put("Allow Retry", "true");

        extension.onLoaded(attributes);

        assertNotNull(extension.getAttributes());
        assertEquals("true", extension.getAttributes().get("Allow Retry"));
    }

    @Test
    void testOnUnloaded_clearsAttributes() {
        Map<String, Object> attributes = new HashMap<>();
        extension.onLoaded(attributes);

        extension.onUnloaded();

        assertNull(extension.getAttributes());
    }
}
```

## 6. Create Documentation README

```markdown
# {{EXTENSION_DISPLAY_NAME}}

## Overview

{{DESCRIPTION}}

## Configuration

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| Allow Retry | Checkbox | No | Allow retry on transient failures |

## Catalog Requests

### {{DOMAIN_NAME}}

(Add your catalog request documentation here)

## License

GNU General Public License v3.0
```

## Next Steps

After creating the minimal skeleton:

1. **Add Authentication**: Use prompts 01-03 to add your authentication pattern
2. **Add Catalog Requests**: Use prompts 05-09 to add catalog requests
3. **Add Tests**: Use prompt 18 to add comprehensive tests

## Validation Checklist

- [ ] Project compiles with `./gradlew build`
- [ ] Extension class has `@Extension` annotation
- [ ] At least one `@Domain` is declared
- [ ] Lifecycle hooks are implemented (LOADED, UPDATED, UNLOADED)
- [ ] VALIDATE_ATTRIBUTES returns empty list for valid config
- [ ] Basic test passes

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [02 - Create Extension with API Key](02-create-extension-apikey.md)
- [03 - Create Extension with Username/Password](03-create-extension-basic-auth.md)
- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
```

