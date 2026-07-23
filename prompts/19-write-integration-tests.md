# Prompt 19: Write Integration Tests for Authentication

## Purpose

Write integration tests for the extension's authentication flow, including OAuth 2.0 token acquisition, token refresh, and error handling. These tests verify the complete authentication lifecycle works correctly.

## Prerequisites

- Existing extension with authentication implementation
- Test credentials or mock server setup
- JUnit 5 and WireMock dependencies

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `com.krista.extension.salesforce` |
| Auth Type | `{{AUTH_TYPE}}` | `OAuth2` |

---

## Prompt

```
I need you to write integration tests for my extension's authentication flow.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Authentication Type**: {{AUTH_TYPE}}

## 1. Test Dependencies (build.gradle)

```groovy
dependencies {
    // Test dependencies
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
    testImplementation 'org.mockito:mockito-core:5.5.0'
    testImplementation 'org.mockito:mockito-junit-jupiter:5.5.0'
    
    // WireMock for HTTP mocking
    testImplementation 'org.wiremock:wiremock:3.3.1'
    
    // AssertJ for fluent assertions
    testImplementation 'org.assertj:assertj-core:3.24.2'
}

test {
    useJUnitPlatform()
}
```

## 2. OAuth 2.0 Authentication Integration Tests

```java
package {{PACKAGE_NAME}}.integration;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;

import {{PACKAGE_NAME}}.auth.OAuth2TokenManager;
import {{PACKAGE_NAME}}.auth.TokenResponse;
import {{PACKAGE_NAME}}.error.ExtensionException;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;

import java.util.*;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.*;

@DisplayName("OAuth 2.0 Authentication Integration Tests")
class OAuth2AuthenticationIntegrationTest {

    private static WireMockServer wireMockServer;
    private OAuth2TokenManager tokenManager;

    private static final String CLIENT_ID = "test-client-id";
    private static final String CLIENT_SECRET = "test-client-secret";

    @BeforeAll
    static void startWireMock() {
        wireMockServer = new WireMockServer(WireMockConfiguration.options()
            .dynamicPort());
        wireMockServer.start();
        WireMock.configureFor("localhost", wireMockServer.port());
    }

    @AfterAll
    static void stopWireMock() {
        wireMockServer.stop();
    }

    @BeforeEach
    void setUp() {
        wireMockServer.resetAll();
        
        String tokenUrl = "http://localhost:" + wireMockServer.port() + "/oauth/token";
        tokenManager = new OAuth2TokenManager(CLIENT_ID, CLIENT_SECRET, tokenUrl);
    }

    // ============================================================
    // TOKEN ACQUISITION TESTS
    // ============================================================

    @Nested
    @DisplayName("Token Acquisition")
    class TokenAcquisition {

        @Test
        @DisplayName("Should acquire access token with valid credentials")
        void getAccessToken_withValidCredentials_returnsToken() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .withRequestBody(containing("grant_type=client_credentials"))
                .withRequestBody(containing("client_id=" + CLIENT_ID))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "test-access-token-12345",
                            "token_type": "Bearer",
                            "expires_in": 3600,
                            "refresh_token": "test-refresh-token-67890"
                        }
                        """)));

            // Act
            TokenResponse response = tokenManager.getAccessToken();

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getAccessToken()).isEqualTo("test-access-token-12345");
            assertThat(response.getTokenType()).isEqualTo("Bearer");
            assertThat(response.getExpiresIn()).isEqualTo(3600);
            assertThat(response.getRefreshToken()).isEqualTo("test-refresh-token-67890");
        }

        @Test
        @DisplayName("Should include correct headers in token request")
        void getAccessToken_sendsCorrectHeaders() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("{\"access_token\":\"token\",\"expires_in\":3600}")));

            // Act
            tokenManager.getAccessToken();

            // Assert
            verify(postRequestedFor(urlEqualTo("/oauth/token"))
                .withHeader("Content-Type", equalTo("application/x-www-form-urlencoded"))
                .withHeader("Accept", equalTo("application/json")));
        }

        @Test
        @DisplayName("Should handle 401 Unauthorized response")
        void getAccessToken_with401Response_throwsAuthError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(401)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "error": "invalid_client",
                            "error_description": "Client authentication failed"
                        }
                        """)));

            // Act & Assert
            assertThatThrownBy(() -> tokenManager.getAccessToken())
                .isInstanceOf(ExtensionException.class)
                .hasMessageContaining("authentication failed");
        }

        @Test
        @DisplayName("Should handle 400 Bad Request response")
        void getAccessToken_with400Response_throwsError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(400)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "error": "invalid_grant",
                            "error_description": "Invalid grant type"
                        }
                        """)));

            // Act & Assert
            assertThatThrownBy(() -> tokenManager.getAccessToken())
                .isInstanceOf(ExtensionException.class);
        }

        @Test
        @DisplayName("Should handle server error with retry")
        void getAccessToken_with500Response_retriesAndFails() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(500)
                    .withBody("Internal Server Error")));

            // Act & Assert
            assertThatThrownBy(() -> tokenManager.getAccessToken())
                .isInstanceOf(ExtensionException.class)
                .hasMessageContaining("Server error");
        }

        @Test
        @DisplayName("Should handle network timeout")
        void getAccessToken_withTimeout_throwsError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withFixedDelay(10000))); // 10 second delay

            // Act & Assert (assuming 5 second timeout)
            assertThatThrownBy(() -> tokenManager.getAccessToken())
                .isInstanceOf(ExtensionException.class);
        }
    }

    // ============================================================
    // TOKEN REFRESH TESTS
    // ============================================================

    @Nested
    @DisplayName("Token Refresh")
    class TokenRefresh {

        @Test
        @DisplayName("Should refresh token with valid refresh token")
        void refreshToken_withValidRefreshToken_returnsNewToken() {
            // Arrange
            String refreshToken = "valid-refresh-token";

            stubFor(post(urlEqualTo("/oauth/token"))
                .withRequestBody(containing("grant_type=refresh_token"))
                .withRequestBody(containing("refresh_token=" + refreshToken))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "new-access-token",
                            "token_type": "Bearer",
                            "expires_in": 3600,
                            "refresh_token": "new-refresh-token"
                        }
                        """)));

            // Act
            TokenResponse response = tokenManager.refreshToken(refreshToken);

            // Assert
            assertThat(response.getAccessToken()).isEqualTo("new-access-token");
            assertThat(response.getRefreshToken()).isEqualTo("new-refresh-token");
        }

        @Test
        @DisplayName("Should handle expired refresh token")
        void refreshToken_withExpiredToken_throwsAuthError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .withRequestBody(containing("grant_type=refresh_token"))
                .willReturn(aResponse()
                    .withStatus(400)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "error": "invalid_grant",
                            "error_description": "Refresh token has expired"
                        }
                        """)));

            // Act & Assert
            assertThatThrownBy(() -> tokenManager.refreshToken("expired-token"))
                .isInstanceOf(ExtensionException.class)
                .hasMessageContaining("expired");
        }

        @Test
        @DisplayName("Should handle revoked refresh token")
        void refreshToken_withRevokedToken_throwsAuthError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(400)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "error": "invalid_grant",
                            "error_description": "Token has been revoked"
                        }
                        """)));

            // Act & Assert
            assertThatThrownBy(() -> tokenManager.refreshToken("revoked-token"))
                .isInstanceOf(ExtensionException.class);
        }
    }

    // ============================================================
    // TOKEN CACHING TESTS
    // ============================================================

    @Nested
    @DisplayName("Token Caching")
    class TokenCaching {

        @Test
        @DisplayName("Should cache token and reuse it")
        void getAccessToken_calledTwice_usesCache() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "cached-token",
                            "expires_in": 3600
                        }
                        """)));

            // Act
            tokenManager.getAccessToken();
            tokenManager.getAccessToken();

            // Assert - should only call token endpoint once
            verify(1, postRequestedFor(urlEqualTo("/oauth/token")));
        }

        @Test
        @DisplayName("Should refresh token when expired")
        void getAccessToken_withExpiredToken_refreshesAutomatically() {
            // Arrange - first call returns short-lived token
            stubFor(post(urlEqualTo("/oauth/token"))
                .inScenario("Token Expiry")
                .whenScenarioStateIs("Started")
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "short-lived-token",
                            "expires_in": 1,
                            "refresh_token": "refresh-token"
                        }
                        """))
                .willSetStateTo("Token Expired"));

            // Second call (refresh) returns new token
            stubFor(post(urlEqualTo("/oauth/token"))
                .inScenario("Token Expiry")
                .whenScenarioStateIs("Token Expired")
                .withRequestBody(containing("grant_type=refresh_token"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "new-token",
                            "expires_in": 3600
                        }
                        """)));

            // Act
            TokenResponse first = tokenManager.getAccessToken();
            Thread.sleep(2000); // Wait for token to expire
            TokenResponse second = tokenManager.getAccessToken();

            // Assert
            assertThat(first.getAccessToken()).isEqualTo("short-lived-token");
            assertThat(second.getAccessToken()).isEqualTo("new-token");
        }

        @Test
        @DisplayName("Should invalidate cache on demand")
        void invalidateTokens_clearsCache() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("{\"access_token\":\"token\",\"expires_in\":3600}")));

            // Act
            tokenManager.getAccessToken();
            tokenManager.invalidateTokens();
            tokenManager.getAccessToken();

            // Assert - should call token endpoint twice
            verify(2, postRequestedFor(urlEqualTo("/oauth/token")));
        }
    }

    // ============================================================
    // AUTHORIZATION CODE FLOW TESTS
    // ============================================================

    @Nested
    @DisplayName("Authorization Code Flow")
    class AuthorizationCodeFlow {

        @Test
        @DisplayName("Should exchange authorization code for tokens")
        void exchangeCode_withValidCode_returnsTokens() {
            // Arrange
            String authCode = "valid-auth-code";
            String redirectUri = "https://app.krista.ai/callback";

            stubFor(post(urlEqualTo("/oauth/token"))
                .withRequestBody(containing("grant_type=authorization_code"))
                .withRequestBody(containing("code=" + authCode))
                .withRequestBody(containing("redirect_uri=" + redirectUri))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "access_token": "user-access-token",
                            "token_type": "Bearer",
                            "expires_in": 3600,
                            "refresh_token": "user-refresh-token",
                            "scope": "read write"
                        }
                        """)));

            // Act
            TokenResponse response = tokenManager.exchangeAuthorizationCode(authCode, redirectUri);

            // Assert
            assertThat(response.getAccessToken()).isEqualTo("user-access-token");
            assertThat(response.getRefreshToken()).isEqualTo("user-refresh-token");
        }

        @Test
        @DisplayName("Should handle invalid authorization code")
        void exchangeCode_withInvalidCode_throwsError() {
            // Arrange
            stubFor(post(urlEqualTo("/oauth/token"))
                .willReturn(aResponse()
                    .withStatus(400)
                    .withHeader("Content-Type", "application/json")
                    .withBody("""
                        {
                            "error": "invalid_grant",
                            "error_description": "Authorization code is invalid or expired"
                        }
                        """)));

            // Act & Assert
            assertThatThrownBy(() ->
                tokenManager.exchangeAuthorizationCode("invalid-code", "https://callback"))
                .isInstanceOf(ExtensionException.class)
                .hasMessageContaining("invalid");
        }
    }
}
```

## 3. API Client Integration Tests

```java
package {{PACKAGE_NAME}}.integration;

import com.github.tomakehurst.wiremock.WireMockServer;
import {{PACKAGE_NAME}}.integration.ApiClient;
import {{PACKAGE_NAME}}.integration.ApiResponse;
import {{PACKAGE_NAME}}.auth.OAuth2TokenManager;

import org.junit.jupiter.api.*;

import java.util.*;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.*;

@DisplayName("API Client Integration Tests")
class ApiClientIntegrationTest {

    private static WireMockServer wireMockServer;
    private ApiClient apiClient;

    @BeforeAll
    static void startWireMock() {
        wireMockServer = new WireMockServer(8089);
        wireMockServer.start();
    }

    @AfterAll
    static void stopWireMock() {
        wireMockServer.stop();
    }

    @BeforeEach
    void setUp() {
        wireMockServer.resetAll();

        // Stub token endpoint
        stubFor(post(urlEqualTo("/oauth/token"))
            .willReturn(aResponse()
                .withStatus(200)
                .withHeader("Content-Type", "application/json")
                .withBody("{\"access_token\":\"test-token\",\"expires_in\":3600}")));

        OAuth2TokenManager tokenManager = new OAuth2TokenManager(
            "client-id", "client-secret",
            "http://localhost:8089/oauth/token");

        apiClient = new ApiClient("http://localhost:8089", tokenManager, 30);
    }

    @Test
    @DisplayName("Should include Bearer token in API requests")
    void get_includesBearerToken() {
        // Arrange
        stubFor(get(urlEqualTo("/api/records"))
            .willReturn(aResponse()
                .withStatus(200)
                .withBody("{\"data\":[]}")));

        // Act
        apiClient.get("/api/records");

        // Assert
        verify(getRequestedFor(urlEqualTo("/api/records"))
            .withHeader("Authorization", equalTo("Bearer test-token")));
    }

    @Test
    @DisplayName("Should refresh token on 401 and retry")
    void get_with401_refreshesTokenAndRetries() {
        // Arrange - first call returns 401
        stubFor(get(urlEqualTo("/api/records"))
            .inScenario("Token Refresh")
            .whenScenarioStateIs("Started")
            .willReturn(aResponse().withStatus(401))
            .willSetStateTo("Token Refreshed"));

        // Second call succeeds
        stubFor(get(urlEqualTo("/api/records"))
            .inScenario("Token Refresh")
            .whenScenarioStateIs("Token Refreshed")
            .willReturn(aResponse()
                .withStatus(200)
                .withBody("{\"data\":[]}")));

        // Act
        ApiResponse response = apiClient.get("/api/records");

        // Assert
        assertThat(response.isSuccess()).isTrue();
    }
}
```

## Validation Checklist

- [ ] Token acquisition is tested with valid credentials
- [ ] Token acquisition error handling is tested
- [ ] Token refresh flow is tested
- [ ] Token caching behavior is verified
- [ ] Authorization code exchange is tested
- [ ] API client includes auth headers
- [ ] Token refresh on 401 is tested
- [ ] WireMock is properly configured

## Best Practices

1. **Use WireMock** - Mock external HTTP services
2. **Test complete flows** - Not just individual methods
3. **Test error scenarios** - 401, 400, 500, timeouts
4. **Verify request details** - Headers, body, parameters
5. **Test caching behavior** - Verify tokens are reused
6. **Use scenarios** - For stateful test sequences
7. **Clean up between tests** - Reset WireMock state

## Related Prompts

- [01 - Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [14 - Implement TEST_CONNECTION](14-implement-test-connection.md)
- [18 - Write Unit Tests](18-write-unit-tests.md)
```

