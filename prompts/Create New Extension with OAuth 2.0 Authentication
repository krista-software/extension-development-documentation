# Prompt 01: Create New Extension with OAuth 2.0 Authentication

## Purpose

Create a complete Krista extension that integrates with an external service using OAuth 2.0 authentication, including token refresh capability, Setup tab configuration, and proper project structure.

## Prerequisites

- Empty or new project directory
- Gradle build environment
- Knowledge of target API's OAuth 2.0 endpoints (token URL, authorization URL, scopes)

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `GoogleCalendar` |
| Extension Display Name | `{{EXTENSION_DISPLAY_NAME}}` | `Google Calendar` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.googlecalendar` |
| Domain Name | `{{DOMAIN_NAME}}` | `Calendar` |
| OAuth Token URL | `{{TOKEN_URL}}` | `https://oauth2.googleapis.com/token` |
| OAuth Authorization URL | `{{AUTH_URL}}` | `https://accounts.google.com/o/oauth2/v2/auth` |
| OAuth Scopes | `{{SCOPES}}` | `https://www.googleapis.com/auth/calendar` |
| API Base URL | `{{API_BASE_URL}}` | `https://www.googleapis.com/calendar/v3` |

---

## Prompt

```
I need you to create a complete Krista extension with OAuth 2.0 authentication.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Display Name**: {{EXTENSION_DISPLAY_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Domain**: {{DOMAIN_NAME}}
- **OAuth Token URL**: {{TOKEN_URL}}
- **OAuth Authorization URL**: {{AUTH_URL}}
- **OAuth Scopes**: {{SCOPES}}
- **API Base URL**: {{API_BASE_URL}}

## Required Project Structure

Create the following directory structure:

```
{{EXTENSION_NAME}}/
├── src/main/java/{{PACKAGE_PATH}}/
│   ├── {{EXTENSION_NAME}}Extension.java          # Main extension class
│   ├── controller/
│   │   └── {{DOMAIN_NAME}}Area.java              # Area class for catalog requests
│   ├── integration/
│   │   ├── {{EXTENSION_NAME}}Client.java         # HTTP client for API calls
│   │   ├── OAuth2Authenticator.java              # OAuth 2.0 authenticator
│   │   └── OAuth2TokenManager.java               # Token management and refresh
│   ├── config/
│   │   └── AttributeKeys.java                    # Configuration attribute keys
│   ├── entity/
│   │   └── (entity classes as needed)
│   └── transformation/
│       └── (transformer classes as needed)
├── src/main/resources/
│   └── docs/
│       └── README.md
├── src/test/java/{{PACKAGE_PATH}}/
│   └── (test classes)
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
    // Krista SDK dependencies (provided by platform)
    compileOnly 'app.krista:krista-extension-sdk:+'
    
    // HTTP client
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    
    // JSON processing
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // Testing
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

/**
 * Constants for Setup tab attribute keys.
 */
public final class AttributeKeys {
    
    private AttributeKeys() {}
    
    // OAuth 2.0 Configuration
    public static final String CLIENT_ID = "Client ID";
    public static final String CLIENT_SECRET = "Client Secret";
    public static final String REDIRECT_URI = "Redirect URI";
    
    // Authentication Mode
    public static final String AUTH_TYPE = "Authentication Type";
    public static final String AUTH_TYPE_SERVICE_ACCOUNT = "Service Account";
    public static final String AUTH_TYPE_USER_ACCOUNT = "User Account";
    
    // Token Storage (managed by platform)
    public static final String ACCESS_TOKEN = "Access Token";
    public static final String REFRESH_TOKEN = "Refresh Token";
    public static final String TOKEN_EXPIRY = "Token Expiry";
    
    // Optional Configuration
    public static final String ALLOW_RETRY = "Allow Retry";
}
```

## 3. Create Main Extension Class

```java
package {{PACKAGE_NAME}};

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.anno.Field;
import {{PACKAGE_NAME}}.config.AttributeKeys;
import {{PACKAGE_NAME}}.integration.OAuth2Authenticator;
import {{PACKAGE_NAME}}.integration.OAuth2TokenManager;

import java.util.*;

@Extension(
    name = "{{EXTENSION_NAME}}",
    displayName = "{{EXTENSION_DISPLAY_NAME}}",
    description = "Integration with {{EXTENSION_DISPLAY_NAME}} using OAuth 2.0"
)
@Domains({
    @Domain(name = "{{DOMAIN_NAME}}", description = "{{EXTENSION_DISPLAY_NAME}} operations")
})
// Setup Tab Fields
@Field.Text(name = AttributeKeys.CLIENT_ID, required = true, 
    description = "OAuth 2.0 Client ID from your application")
@Field.Text(name = AttributeKeys.CLIENT_SECRET, required = true, isSecured = true,
    description = "OAuth 2.0 Client Secret")
@Field.Text(name = AttributeKeys.REDIRECT_URI, required = true,
    description = "OAuth 2.0 Redirect URI configured in your application")
@Field.PickOne(name = AttributeKeys.AUTH_TYPE, required = true,
    values = {AttributeKeys.AUTH_TYPE_SERVICE_ACCOUNT, AttributeKeys.AUTH_TYPE_USER_ACCOUNT},
    description = "Authentication mode")
@Field.Checkbox(name = AttributeKeys.ALLOW_RETRY, defaultValue = "true",
    description = "Allow retry on transient failures")
public class {{EXTENSION_NAME}}Extension {

    private OAuth2TokenManager tokenManager;
    private Map<String, Object> currentAttributes;
```

    // Lifecycle: Initialize on load
    @InvokerRequest(InvokerRequest.Type.INVOKER_LOADED)
    public void onLoaded(Map<String, Object> attributes) {
        this.currentAttributes = attributes;
        this.tokenManager = new OAuth2TokenManager(
            (String) attributes.get(AttributeKeys.CLIENT_ID),
            (String) attributes.get(AttributeKeys.CLIENT_SECRET),
            "{{TOKEN_URL}}"
        );
    }

    // Lifecycle: Handle configuration updates
    @InvokerRequest(InvokerRequest.Type.INVOKER_UPDATED)
    public void onUpdated(Map<String, Object> oldAttrs, Map<String, Object> newAttrs) {
        this.currentAttributes = newAttrs;
        this.tokenManager = new OAuth2TokenManager(
            (String) newAttrs.get(AttributeKeys.CLIENT_ID),
            (String) newAttrs.get(AttributeKeys.CLIENT_SECRET),
            "{{TOKEN_URL}}"
        );
    }

    // Lifecycle: Cleanup on unload
    @InvokerRequest(InvokerRequest.Type.INVOKER_UNLOADED)
    public void onUnloaded() {
        this.tokenManager = null;
        this.currentAttributes = null;
    }

    // Validate configuration before save
    @InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)
    public List<String> validateAttributes(Map<String, Object> attributes) {
        List<String> errors = new ArrayList<>();

        String clientId = (String) attributes.get(AttributeKeys.CLIENT_ID);
        if (clientId == null || clientId.isBlank()) {
            errors.add("Client ID is required");
        }

        String clientSecret = (String) attributes.get(AttributeKeys.CLIENT_SECRET);
        if (clientSecret == null || clientSecret.isBlank()) {
            errors.add("Client Secret is required");
        }

        String redirectUri = (String) attributes.get(AttributeKeys.REDIRECT_URI);
        if (redirectUri == null || redirectUri.isBlank()) {
            errors.add("Redirect URI is required");
        }

        return errors;
    }

    // Test connection to external service
    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public void testConnection() throws Exception {
        String accessToken = (String) currentAttributes.get(AttributeKeys.ACCESS_TOKEN);
        if (accessToken == null || accessToken.isBlank()) {
            throw new IllegalStateException("Not authenticated. Please complete OAuth flow first.");
        }

        // Validate token by making a test API call
        tokenManager.validateToken(accessToken);
    }

    // Register the authenticator
    @InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
    public RequestAuthenticator getAuthenticator() {
        return new OAuth2Authenticator(tokenManager, currentAttributes);
    }

    // Getter for token manager (used by Area classes)
    public OAuth2TokenManager getTokenManager() {
        return tokenManager;
    }

    // Getter for attributes (used by Area classes)
    public Map<String, Object> getAttributes() {
        return currentAttributes;
    }
}
```

## 4. Create OAuth2TokenManager.java

```java
package {{PACKAGE_NAME}}.integration;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import okhttp3.*;

import java.io.IOException;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

/**
 * Manages OAuth 2.0 tokens including refresh logic.
 */
public class OAuth2TokenManager {

    private static final OkHttpClient HTTP_CLIENT = new OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build();

    private static final Gson GSON = new Gson();
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
    private static final MediaType FORM = MediaType.parse("application/x-www-form-urlencoded");

    private final String clientId;
    private final String clientSecret;
    private final String tokenUrl;

    private String cachedAccessToken;
    private Instant tokenExpiry;

    public OAuth2TokenManager(String clientId, String clientSecret, String tokenUrl) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.tokenUrl = tokenUrl;
    }

    /**
     * Exchange authorization code for tokens.
     */
    public TokenResponse exchangeAuthorizationCode(String code, String redirectUri) throws IOException {
        RequestBody body = new FormBody.Builder()
            .add("grant_type", "authorization_code")
            .add("code", code)
            .add("client_id", clientId)
            .add("client_secret", clientSecret)
            .add("redirect_uri", redirectUri)
            .build();

        Request request = new Request.Builder()
            .url(tokenUrl)
            .post(body)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Token exchange failed: " + response.code());
            }

            String responseBody = response.body().string();
            JsonObject json = GSON.fromJson(responseBody, JsonObject.class);

            return new TokenResponse(
                json.get("access_token").getAsString(),
                json.has("refresh_token") ? json.get("refresh_token").getAsString() : null,
                json.has("expires_in") ? json.get("expires_in").getAsInt() : 3600
            );
        }
    }

    /**
     * Refresh access token using refresh token.
     */
    public TokenResponse refreshAccessToken(String refreshToken) throws IOException {
        RequestBody body = new FormBody.Builder()
            .add("grant_type", "refresh_token")
            .add("refresh_token", refreshToken)
            .add("client_id", clientId)
            .add("client_secret", clientSecret)
            .build();

        Request request = new Request.Builder()
            .url(tokenUrl)
            .post(body)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Token refresh failed: " + response.code());
            }

            String responseBody = response.body().string();
            JsonObject json = GSON.fromJson(responseBody, JsonObject.class);

            return new TokenResponse(
                json.get("access_token").getAsString(),
                json.has("refresh_token") ? json.get("refresh_token").getAsString() : refreshToken,
                json.has("expires_in") ? json.get("expires_in").getAsInt() : 3600
            );
        }
    }

    /**
     * Get valid access token, refreshing if necessary.
     */
    public String getValidAccessToken(String currentAccessToken, String refreshToken) throws IOException {
        // Check if cached token is still valid
        if (cachedAccessToken != null && tokenExpiry != null && Instant.now().isBefore(tokenExpiry)) {
            return cachedAccessToken;
        }

        // Try to refresh
        if (refreshToken != null && !refreshToken.isBlank()) {
            TokenResponse newTokens = refreshAccessToken(refreshToken);
            cachedAccessToken = newTokens.getAccessToken();
            tokenExpiry = Instant.now().plusSeconds(newTokens.getExpiresIn() - 60); // 60s buffer
            return cachedAccessToken;
        }

        return currentAccessToken;
    }

    /**
     * Validate token by making a test request.
     */
    public void validateToken(String accessToken) throws IOException {
        // Override this method to make a lightweight API call to validate the token
        // For example, call a /userinfo or /me endpoint
    }

    /**
     * Token response holder.
     */
    public static class TokenResponse {
        private final String accessToken;
        private final String refreshToken;
        private final int expiresIn;

        public TokenResponse(String accessToken, String refreshToken, int expiresIn) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.expiresIn = expiresIn;
        }

        public String getAccessToken() { return accessToken; }
        public String getRefreshToken() { return refreshToken; }
        public int getExpiresIn() { return expiresIn; }
    }
}
```

## 5. Create OAuth2Authenticator.java

```java
package {{PACKAGE_NAME}}.integration;

import app.krista.extension.api.auth.*;
import {{PACKAGE_NAME}}.config.AttributeKeys;

import java.util.Map;

/**
 * OAuth 2.0 request authenticator implementation.
 */
public class OAuth2Authenticator implements RequestAuthenticator {

    private final OAuth2TokenManager tokenManager;
    private final Map<String, Object> attributes;

    public OAuth2Authenticator(OAuth2TokenManager tokenManager, Map<String, Object> attributes) {
        this.tokenManager = tokenManager;
        this.attributes = attributes;
    }

    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        try {
            String accessToken = (String) attributes.get(AttributeKeys.ACCESS_TOKEN);
            String refreshToken = (String) attributes.get(AttributeKeys.REFRESH_TOKEN);

            if (accessToken == null || accessToken.isBlank()) {
                return AuthenticationResult.failure("Not authenticated. Please complete OAuth flow.");
            }

            // Get valid token (refresh if needed)
            String validToken = tokenManager.getValidAccessToken(accessToken, refreshToken);

            // Store token for use in requests
            request.setCredential("accessToken", validToken);

            return AuthenticationResult.success();

        } catch (Exception e) {
            return AuthenticationResult.failure("Authentication failed: " + e.getMessage());
        }
    }
}
```

## 6. Create Area Class (Controller)

```java
package {{PACKAGE_NAME}}.controller;

import app.krista.extension.impl.anno.*;
import {{PACKAGE_NAME}}.{{EXTENSION_NAME}}Extension;
import {{PACKAGE_NAME}}.integration.{{EXTENSION_NAME}}Client;

/**
 * Area class containing catalog requests for {{DOMAIN_NAME}} domain.
 */
public class {{DOMAIN_NAME}}Area {

    private final {{EXTENSION_NAME}}Extension extension;
    private final {{EXTENSION_NAME}}Client client;

    public {{DOMAIN_NAME}}Area({{EXTENSION_NAME}}Extension extension) {
        this.extension = extension;
        this.client = new {{EXTENSION_NAME}}Client("{{API_BASE_URL}}");
    }

    // Add your catalog requests here
    // Example:
    // @CatalogRequest(
    //     name = "List Items",
    //     domain = "{{DOMAIN_NAME}}",
    //     type = CatalogRequest.Type.QUERY_SYSTEM,
    //     description = "List all items"
    // )
    // public Map<String, Object> listItems(Map<String, Object> params) {
    //     // Implementation
    // }
}
```

## 7. Create API Client

```java
package {{PACKAGE_NAME}}.integration;

import com.google.gson.Gson;
import okhttp3.*;

import java.io.IOException;
import java.util.Map;
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
        this.baseUrl = baseUrl;
    }

    /**
     * Make authenticated GET request.
     */
    public <T> T get(String path, String accessToken, Class<T> responseType) throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("Authorization", "Bearer " + accessToken)
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
    public <T> T post(String path, String accessToken, Object body, Class<T> responseType) throws IOException {
        RequestBody requestBody = RequestBody.create(GSON.toJson(body), JSON);

        Request request = new Request.Builder()
            .url(baseUrl + path)
            .header("Authorization", "Bearer " + accessToken)
            .post(requestBody)
            .build();

        try (Response response = HTTP_CLIENT.newCall(request).execute()) {
            handleErrorResponse(response);
            return GSON.fromJson(response.body().string(), responseType);
        }
    }

    /**
     * Handle error responses.
     */
    private void handleErrorResponse(Response response) throws IOException {
        if (!response.isSuccessful()) {
            int code = response.code();
            String body = response.body() != null ? response.body().string() : "";

            switch (code) {
                case 401:
                    throw new SecurityException("Unauthorized: Token expired or invalid");
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

## Validation Checklist

After generating the code, verify:

- [ ] Project structure matches the recommended layout
- [ ] `build.gradle` has all required dependencies
- [ ] Main extension class has `@Extension` and `@Domains` annotations
- [ ] Setup tab fields are properly annotated with `@Field.*`
- [ ] All lifecycle hooks are implemented (`INVOKER_LOADED`, `INVOKER_UPDATED`, `INVOKER_UNLOADED`)
- [ ] `VALIDATE_ATTRIBUTES` validates all required fields
- [ ] `TEST_CONNECTION` verifies external connectivity
- [ ] `AUTHENTICATOR` returns a valid `RequestAuthenticator`
- [ ] OAuth2TokenManager handles token refresh
- [ ] API client includes proper error handling
- [ ] No secrets are logged

## Related Prompts

- [02 - Create Extension with API Key](02-create-extension-apikey.md)
- [05 - Add QUERY_SYSTEM Catalog Request](05-add-query-system-request.md)
- [06 - Add CHANGE_SYSTEM Catalog Request](06-add-change-system-request.md)
- [13 - Implement VALIDATE_ATTRIBUTES](13-implement-validate-attributes.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
```

