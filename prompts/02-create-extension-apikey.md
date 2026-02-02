# Prompt 02: Create New Extension with API Key Authentication

## Purpose

Create a complete Krista extension that integrates with an external service using API key authentication. This is the simplest authentication pattern, suitable for services that use static API keys or tokens.

## Prerequisites

- Empty or new project directory
- Gradle build environment
- API key from the target service

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Zendesk` |
| Extension Display Name | `{{EXTENSION_DISPLAY_NAME}}` | `Zendesk Support` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.zendesk` |
| Domain Name | `{{DOMAIN_NAME}}` | `Tickets` |
| API Base URL | `{{API_BASE_URL}}` | `https://yourcompany.zendesk.com/api/v2` |
| API Key Header | `{{API_KEY_HEADER}}` | `Authorization` |
| API Key Prefix | `{{API_KEY_PREFIX}}` | `Bearer` or `Basic` or empty |

---

## Prompt

```
I need you to create a complete Krista extension with API Key authentication.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Display Name**: {{EXTENSION_DISPLAY_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **API Base URL**: {{API_BASE_URL}}
- **API Key Header**: {{API_KEY_HEADER}}
- **API Key Prefix**: {{API_KEY_PREFIX}}

## Required Project Structure

```
{{EXTENSION_NAME}}/
├── src/main/java/{{PACKAGE_PATH}}/
│   ├── {{EXTENSION_NAME}}Extension.java
│   ├── controller/
│   │   └── {{DOMAIN_NAME}}Area.java
│   ├── integration/
│   │   ├── {{EXTENSION_NAME}}Client.java
│   │   └── ApiKeyAuthenticator.java
│   ├── config/
│   │   └── AttributeKeys.java
│   ├── entity/
│   └── transformation/
├── src/main/resources/docs/
├── src/test/java/{{PACKAGE_PATH}}/
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
    compileOnly 'app.krista:krista-extension-sdk:+'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
    testImplementation 'org.mockito:mockito-core:5.5.0'
}

test {
    useJUnitPlatform()
}
```

## 2. Create AttributeKeys.java

```java
package {{PACKAGE_NAME}}.config;

public final class AttributeKeys {
    
    private AttributeKeys() {}
    
    // Required Configuration
    public static final String API_KEY = "API Key";
    public static final String BASE_URL = "Base URL";
    
    // Optional Configuration
    public static final String SUBDOMAIN = "Subdomain";
    public static final String ALLOW_RETRY = "Allow Retry";
    public static final String TIMEOUT_SECONDS = "Timeout (seconds)";
}
```

## 3. Create Main Extension Class

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.config.AttributeKeys;
import {{PACKAGE_NAME}}.integration.ApiKeyAuthenticator;
import {{PACKAGE_NAME}}.integration.{{EXTENSION_NAME}}Client;

import java.util.*;

@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_DISPLAY_NAME}}",
    description = "Integration with {{EXTENSION_DISPLAY_NAME}} using API Key authentication"
)
@Domains({
    @Domain(name = "{{DOMAIN_NAME}}", description = "{{EXTENSION_DISPLAY_NAME}} operations")
})
@Field.Text(name = AttributeKeys.API_KEY, required = true, isSecured = true,
    description = "API Key for authentication")
@Field.Text(name = AttributeKeys.BASE_URL, required = true,
    description = "Base URL for the API (e.g., {{API_BASE_URL}})")
@Field.Checkbox(name = AttributeKeys.ALLOW_RETRY, defaultValue = "true",
    description = "Allow retry on transient failures")
public class {{EXTENSION_NAME}}Extension {

    private {{EXTENSION_NAME}}Client client;
    private Map<String, Object> currentAttributes;

    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        this.currentAttributes = attributes;
        initializeClient(attributes);
    }

    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        this.currentAttributes = newAttrs;
        initializeClient(newAttrs);
    }

    @InvokerRequest(InvokerRequest.Type.INVOKER_UNLOADED)
    public void onUnloaded() {
        this.client = null;
        this.currentAttributes = null;
    }

    private void initializeClient(Map<String, Object> attributes) {
        String baseUrl = (String) attributes.get(AttributeKeys.BASE_URL);
        this.client = new {{EXTENSION_NAME}}Client(baseUrl);
    }

    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();
        
        String apiKey = (String) attributes.get(AttributeKeys.API_KEY);
        if (apiKey == null || apiKey.isBlank()) {
            errors.add("API Key is required");
        }
        
        String baseUrl = (String) attributes.get(AttributeKeys.BASE_URL);
        if (baseUrl == null || baseUrl.isBlank()) {
            errors.add("Base URL is required");
        } else if (!baseUrl.startsWith("https://")) {
            errors.add("Base URL must use HTTPS");
        }
        
        return errors;
    }

    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public void testConnection() throws Exception {
        String apiKey = (String) currentAttributes.get(AttributeKeys.API_KEY);
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("API Key is not configured");
        }

        // Make a lightweight API call to verify connectivity
        client.testConnection(apiKey);
    }

    @InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
    public RequestAuthenticator getAuthenticator() {
        return new ApiKeyAuthenticator(currentAttributes);
    }

    public {{EXTENSION_NAME}}Client getClient() {
        return client;
    }

    public Map<String, Object> getAttributes() {
        return currentAttributes;
    }
}
```

## 4. Create ApiKeyAuthenticator.java

```java
package {{PACKAGE_NAME}}.integration;

import app.krista.extension.api.auth.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.util.Map;

/**
 * API Key authenticator implementation.
 */
public class ApiKeyAuthenticator implements RequestAuthenticator {

    private final Map<String, Object> attributes;

    public ApiKeyAuthenticator(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        String apiKey = (String) attributes.get(AttributeKeys.API_KEY);

        if (apiKey == null || apiKey.isBlank()) {
            return AuthenticationResult.failure("API Key is not configured");
        }

        // Store API key for use in requests
        request.setCredential("apiKey", apiKey);

        return AuthenticationResult.success();
    }
}
```

## 5. Create API Client

```java
package {{PACKAGE_NAME}}.integration;

import com.google.gson.Gson;
import okhttp3.*;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * HTTP client for {{EXTENSION_DISPLAY_NAME}} API.
 */
public class {{EXTENSION_NAME}}Client {

    private static final OkHttpClient HTTP_CLIENT = new OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build();

    private static final Gson GSON = new Gson();
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

    private final String baseUrl;

    public {{EXTENSION_NAME}}Client(String baseUrl) {
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    /**
     * Test connection with a lightweight API call.
     */
    public void testConnection(String apiKey) throws IOException {
        // Make a simple GET request to verify API key works
        // Adjust the endpoint based on your API
        Request request = new Request.Builder()
            .url(baseUrl + "/me")  // or another lightweight endpoint
            .header("{{API_KEY_HEADER}}", "{{API_KEY_PREFIX}} " + apiKey)
            .get()
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Connection test failed: " + response.code());
            }
        }
    }

    /**
     * Make authenticated GET request.
     */
    public <T> T get(String path, String apiKey, Class<T> responseType) throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("{{API_KEY_HEADER}}", "{{API_KEY_PREFIX}} " + apiKey)
            .header("Content-Type", "application/json")
            .get()
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    /**
     * Make authenticated POST request.
     */
    public <T> T post(String path, String apiKey, Object body, Class<T> responseType) throws IOException {
        RequestBody requestBody = RequestBody.create(GSON.toJson(body), JSON);

        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("{{API_KEY_HEADER}}", "{{API_KEY_PREFIX}} " + apiKey)
            .header("Content-Type", "application/json")
            .post(requestBody)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    /**
     * Make authenticated PUT request.
     */
    public <T> T put(String path, String apiKey, Object body, Class<T> responseType) throws IOException {
        RequestBody requestBody = RequestBody.create(GSON.toJson(body), JSON);

        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("{{API_KEY_HEADER}}", "{{API_KEY_PREFIX}} " + apiKey)
            .header("Content-Type", "application/json")
            .put(requestBody)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    /**
     * Make authenticated DELETE request.
     */
    public void delete(String path, String apiKey) throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("{{API_KEY_HEADER}}", "{{API_KEY_PREFIX}} " + apiKey)
            .delete()
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
        }
    }

    private void handleErrorResponse(Response response) throws IOException {
        if (!response.isSuccessful()) {
            int code = response.code();
            String body = response.body() != null ? response.body().string() : "";

            switch (code) {
                case 401:
                    throw new SecurityException("Unauthorized: Invalid API key");
                case 403:
                    throw new SecurityException("Forbidden: Insufficient permissions");
                case 404:
                    throw new IllegalArgumentException("Resource not found");
                case 429:
                    throw new IOException("Rate limit exceeded. Please retry later.");
                default:
                    throw new IOException("API error " + code + ": " + body);
            }
        }
    }
}
```

## 6. Create Area Class

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.{{EXTENSION_NAME}}Extension;
import {{PACKAGE_NAME}}.config.AttributeKeys;
import {{PACKAGE_NAME}}.integration.{{EXTENSION_NAME}}Client;

import java.util.*;

/**
 * Area class containing catalog requests for {{DOMAIN_NAME}} domain.
 */
public class {{DOMAIN_NAME}}Area {

    private final {{EXTENSION_NAME}}Extension extension;

    public {{DOMAIN_NAME}}Area({{EXTENSION_NAME}}Extension extension) {
        this.extension = extension;
    }

    private String getApiKey() {
        return (String) extension.getAttributes().get(AttributeKeys.API_KEY);
    }

    // Example QUERY_SYSTEM catalog request
    @CatalogRequest(
        name = "List Items",
        domain = "{{DOMAIN_NAME}}",
        type = CatalogRequest.Type.QUERY_SYSTEM,
        description = "List all items"
    )
    @Field.Text(name = "Page", required = false, description = "Page number")
    @Field.Text(name = "Page Size", required = false, description = "Items per page")
    public Map<String, Object> listItems(Map<String, Object> params) {
        try {
            String apiKey = getApiKey();
            // Implementation here

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            // Add your response data
            return result;

        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("error", e.getMessage());
            return error;
        }
    }
}
```

## Validation Checklist

After generating the code, verify:

- [ ] Project structure matches the recommended layout
- [ ] `build.gradle` has all required dependencies
- [ ] Main extension class has `@Extension` and `@Domains` annotations
- [ ] API Key field is marked as `isSecured = true`
- [ ] All lifecycle hooks are implemented
- [ ] `VALIDATE_ATTRIBUTES` validates API Key and Base URL
- [ ] `TEST_CONNECTION` verifies API connectivity
- [ ] `AUTHENTICATOR` returns a valid `RequestAuthenticator`
- [ ] API client handles all HTTP methods (GET, POST, PUT, DELETE)
- [ ] Error handling covers 401, 403, 404, 429 status codes
- [ ] No secrets are logged

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [03 - Create Extension with Username/Password](03-create-extension-basic-auth.md)
- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
```

