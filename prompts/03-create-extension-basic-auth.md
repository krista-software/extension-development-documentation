# Prompt 03: Create New Extension with Username/Password Authentication

## Purpose

Create a complete Krista extension that integrates with an external service using Basic Authentication (username and password). This pattern is common for enterprise APIs and legacy systems.

## Prerequisites

- Empty or new project directory
- Gradle build environment
- Username and password credentials for the target service

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `ServiceNow` |
| Extension Display Name | `{{EXTENSION_DISPLAY_NAME}}` | `ServiceNow ITSM` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.servicenow` |
| Domain Name | `{{DOMAIN_NAME}}` | `Incidents` |
| API Base URL | `{{API_BASE_URL}}` | `https://instance.service-now.com/api/now` |

---

## Prompt

```
I need you to create a complete Krista extension with Username/Password (Basic) authentication.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Display Name**: {{EXTENSION_DISPLAY_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **API Base URL**: {{API_BASE_URL}}

## Required Project Structure

```
{{EXTENSION_NAME}}/
├── src/main/java/{{PACKAGE_PATH}}/
│   ├── {{EXTENSION_NAME}}Extension.java
│   ├── controller/
│   │   └── {{DOMAIN_NAME}}Area.java
│   ├── integration/
│   │   ├── {{EXTENSION_NAME}}Client.java
│   │   └── BasicAuthenticator.java
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
    
    // Authentication
    public static final String USERNAME = "Username";
    public static final String PASSWORD = "Password";
    public static final String INSTANCE_URL = "Instance URL";
    
    // Optional Configuration
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
import {{PACKAGE_NAME}}.integration.BasicAuthenticator;
import {{PACKAGE_NAME}}.integration.{{EXTENSION_NAME}}Client;

import java.util.*;

@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_DISPLAY_NAME}}",
    description = "Integration with {{EXTENSION_DISPLAY_NAME}} using Basic authentication"
)
@Domains({
    @Domain(name = "{{DOMAIN_NAME}}", description = "{{EXTENSION_DISPLAY_NAME}} operations")
})
@Field.Text(name = AttributeKeys.INSTANCE_URL, required = true,
    description = "Instance URL (e.g., https://instance.service-now.com)")
@Field.Text(name = AttributeKeys.USERNAME, required = true,
    description = "Username for authentication")
@Field.Text(name = AttributeKeys.PASSWORD, required = true, isSecured = true,
    description = "Password for authentication")
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
        String instanceUrl = (String) attributes.get(AttributeKeys.INSTANCE_URL);
        this.client = new {{EXTENSION_NAME}}Client(instanceUrl);
    }

    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();

        String instanceUrl = (String) attributes.get(AttributeKeys.INSTANCE_URL);
        if (instanceUrl == null || instanceUrl.isBlank()) {
            errors.add("Instance URL is required");
        } else if (!instanceUrl.startsWith("https://")) {
            errors.add("Instance URL must use HTTPS for security");
        }

        String username = (String) attributes.get(AttributeKeys.USERNAME);
        if (username == null || username.isBlank()) {
            errors.add("Username is required");
        }

        String password = (String) attributes.get(AttributeKeys.PASSWORD);
        if (password == null || password.isBlank()) {
            errors.add("Password is required");
        }

        return errors;
    }

    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public void testConnection() throws Exception {
        String username = (String) currentAttributes.get(AttributeKeys.USERNAME);
        String password = (String) currentAttributes.get(AttributeKeys.PASSWORD);

        if (username == null || password == null) {
            throw new IllegalStateException("Credentials not configured");
        }

        client.testConnection(username, password);
    }

    @InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
    public RequestAuthenticator getAuthenticator() {
        return new BasicAuthenticator(currentAttributes);
    }

    public {{EXTENSION_NAME}}Client getClient() {
        return client;
    }

    public Map<String, Object> getAttributes() {
        return currentAttributes;
    }
}
```

## 4. Create BasicAuthenticator.java

```java
package {{PACKAGE_NAME}}.integration;

import app.krista.extension.api.auth.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.util.Base64;
import java.util.Map;

/**
 * Basic authentication (username/password) implementation.
 */
public class BasicAuthenticator implements RequestAuthenticator {

    private final Map<String, Object> attributes;

    public BasicAuthenticator(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        String username = (String) attributes.get(AttributeKeys.USERNAME);
        String password = (String) attributes.get(AttributeKeys.PASSWORD);

        if (username == null || username.isBlank()) {
            return AuthenticationResult.failure("Username is not configured");
        }

        if (password == null || password.isBlank()) {
            return AuthenticationResult.failure("Password is not configured");
        }

        // Create Base64 encoded credentials
        String credentials = username + ":" + password;
        String encodedCredentials = Base64.getEncoder().encodeToString(credentials.getBytes());

        // Store for use in requests
        request.setCredential("basicAuth", "Basic " + encodedCredentials);
        request.setCredential("username", username);

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
import java.util.Base64;
import java.util.concurrent.TimeUnit;

/**
 * HTTP client for {{EXTENSION_DISPLAY_NAME}} API with Basic Auth.
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

    private String createBasicAuthHeader(String username, String password) {
        String credentials = username + ":" + password;
        return "Basic " + Base64.getEncoder().encodeToString(credentials.getBytes());
    }

    /**
     * Test connection with credentials.
     */
    public void testConnection(String username, String password) throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + "/api/now/table/sys_user?sysparm_limit=1")
            .header("Authorization", createBasicAuthHeader(username, password))
            .header("Accept", "application/json")
            .get()
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                if (response.code() == 401) {
                    throw new SecurityException("Invalid username or password");
                }
                throw new IOException("Connection test failed: " + response.code());
            }
        }
    }

    /**
     * Make authenticated GET request.
     */
    public <T> T get(String path, String username, String password, Class<T> responseType) throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("Authorization", createBasicAuthHeader(username, password))
            .header("Accept", "application/json")
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
    public <T> T post(String path, String username, String password, Object body, Class<T> responseType) throws IOException {
        RequestBody requestBody = RequestBody.create(GSON.toJson(body), JSON);

        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("Authorization", createBasicAuthHeader(username, password))
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .post(requestBody)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    /**
     * Make authenticated PATCH request.
     */
    public <T> T patch(String path, String username, String password, Object body, Class<T> responseType) throws IOException {
        RequestBody requestBody = RequestBody.create(GSON.toJson(body), JSON);

        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("Authorization", createBasicAuthHeader(username, password))
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .patch(requestBody)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    private void handleErrorResponse(Response response) throws IOException {
        if (!response.isSuccessful()) {
            int code = response.code();
            String body = response.body() != null ? response.body().string() : "";

            switch (code) {
                case 401:
                    throw new SecurityException("Unauthorized: Invalid credentials");
                case 403:
                    throw new SecurityException("Forbidden: Insufficient permissions");
                case 404:
                    throw new IllegalArgumentException("Resource not found");
                case 429:
                    throw new IOException("Rate limit exceeded");
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

import java.util.*;

public class {{DOMAIN_NAME}}Area {

    private final {{EXTENSION_NAME}}Extension extension;

    public {{DOMAIN_NAME}}Area({{EXTENSION_NAME}}Extension extension) {
        this.extension = extension;
    }

    private String getUsername() {
        return (String) extension.getAttributes().get(AttributeKeys.USERNAME);
    }

    private String getPassword() {
        return (String) extension.getAttributes().get(AttributeKeys.PASSWORD);
    }

    // Add catalog requests here
}
```

## Validation Checklist

- [ ] Password field is marked as `isSecured = true`
- [ ] Instance URL validation requires HTTPS
- [ ] Basic auth header is properly Base64 encoded
- [ ] Credentials are never logged
- [ ] Error handling covers authentication failures

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [02 - Create Extension with API Key](02-create-extension-apikey.md)
- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
```

