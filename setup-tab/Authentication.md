<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Authentication

# Authentication

## Overview

The **Setup tab** is where you collect and validate the authentication inputs your extension needs (API keys, OAuth client secrets, tenant IDs, etc.). At runtime, your extension uses those saved values to authenticate outbound calls.

A good setup-time authentication experience:

1. stores secrets securely,
2. validates credentials early,
3. produces actionable error messages.

## Step-by-step: add authentication to your extension

1. **Decide the authentication model** (API key, username/password, OAuth 2.0, etc.).
2. **Declare Setup tab fields** for required credentials/settings.
3. **Implement setup-time validation** so users get fast feedback before saving.
4. **Implement runtime authentication** using `RequestAuthenticator`.
5. **Map failures to actionable errors** (missing config vs invalid creds vs insufficient permissions).
6. **Handle updates**: when the invoker is updated, rebuild any clients/token providers.

## What belongs in Setup tab vs runtime

- **Setup tab (configuration)**: credentials and settings that change rarely (client id/secret, base URL, scopes, tenant, auth mode).
- **Runtime (state)**: short-lived access tokens, session cookies, cached metadata.

See: [Configuration vs runtime behavior](../concepts/ConfigurationVsRuntimeBehavior.md)

## Declaring authentication fields

Common fields include:

- **API key / token** (secured)
- **Client ID** (text)
- **Client secret** (secured)
- **Tenant / account id** (text)
- **Base URL / audience** (text)
- **Auth mode** (pick-one)

Guidance:

- Mark secrets as **secured** so they are stored encrypted.
- Use stable field names to avoid breaking existing invoker configurations.
- Validate format (non-empty, URL shape, expected length) during setup validation.

Related: [Attributes](Attributes.md)

### Field examples

Use secured fields for secrets:

```java
@Field.Text(name = "Client ID", required = true)
@Field.Text(name = "Client Secret", required = true, isSecured = true)
@Field.Text(name = "Token URL", required = true)
@Field.PickOne(name = "Auth Mode", required = true, values = {"API_KEY", "OAUTH2"})
```

> **Note**: Field *names* become keys in the saved attribute map. Renaming a field can break existing invokers.

## Implementing an authenticator (runtime)

Krista supports custom authentication via the `RequestAuthenticator` interface.

Typically you:

1. implement `RequestAuthenticator`, and
2. expose it using an invoker request handler (AUTHENTICATOR).

This keeps authentication logic centralized and consistent across requests.

### Implement `RequestAuthenticator`

The `RequestAuthenticator` interface is defined in:

- `krista-service-apis-java/extension/authorization/api/src/main/java/app/krista/extension/authorization/RequestAuthenticator.java`

Example (from the monolithic guide):

```java
public class ExtensionRequestAuthenticator implements RequestAuthenticator {
    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        // Custom authentication logic
    }
}
```

### Register the authenticator (AUTHENTICATOR)

Expose your authenticator via an invoker request handler:

```java
@InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
public RequestAuthenticator getAuthenticator() {
    return new ExtensionRequestAuthenticator();
}
```

See also: [Authentication patterns](../advanced/AuthPatterns.md)

## Validating credentials during setup

During setup, validate what you can cheaply:

- required values are present
- URL and tenant values are well-formed
- auth mode selection is consistent (for example, if OAuth is selected then client id/secret are required)

When appropriate, also run a **test connection** to verify credentials and permissions. Keep the call fast and safe.

See: [Validation and troubleshooting](ValidationAndTroubleshooting.md)

### Recommended validation checklist

1. **Presence**: required fields are not null/blank.
2. **Format**: URLs parse; identifiers match expected patterns.
3. **Consistency**: if `Auth Mode = OAUTH2`, then client id/secret/token URL must be present.
4. **Optional connectivity check**: a safe, read-only call to confirm the credential works.

Return **all** validation issues at once so users can fix them in one save cycle.

## How this maps to Krista invoker lifecycle

Authentication spans **setup-time validation**, **invoker lifecycle initialization**, and **per-request use**:

1. **Before Save**: the user enters credentials in the Setup tab.
2. **On Save**: the platform calls `@InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)` (if implemented). Use this to verify:
   - required fields are present,
   - the selected auth mode is consistent,
   - optional connectivity checks (safe and fast).
3. **After Save**:
   - **`INVOKER_LOADED`**: initialize long-lived runtime resources derived from configuration (HTTP client, token provider, caches).
   - **`INVOKER_UPDATED`**: close/clear old resources and rebuild from the updated attributes (for example, reset cached tokens after secret rotation).
   - **`INVOKER_UNLOADED`**: cleanup any remaining resources.
4. **At runtime**: the platform calls your `@InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)` provider as needed; your `RequestAuthenticator` should rely on the per-invoker runtime state created in lifecycle hooks (not on mutable/global state).

See:

- [Invoker requests (`@InvokerRequest`)](../reference/InvokerRequests.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Validation and troubleshooting](ValidationAndTroubleshooting.md)

## Common authentication patterns (with code)

### Pattern 1: API key authentication

```java
public class ApiKeyAuthenticator implements RequestAuthenticator {
    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        String apiKey = request.getCredential("apiKey");
        if (apiKey == null || apiKey.isBlank()) {
            return AuthenticationResult.failure("Invalid API key");
        }
        return AuthenticationResult.success();
    }
}
```

### Pattern 2: username/password authentication

```java
public class PasswordAuthenticator implements RequestAuthenticator {
    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        String username = request.getCredential("username");
        String password = request.getCredential("password");
        if (username == null || password == null || username.isBlank() || password.isBlank()) {
            return AuthenticationResult.failure("Invalid credentials");
        }
        return AuthenticationResult.success().withUserId(username);
    }
}
```

### Pattern 3: OAuth 2.0 token authentication

```java
public class OAuth2Authenticator implements RequestAuthenticator {
    @Override
    public AuthenticationResult authenticate(AuthenticationRequest request) {
        String accessToken = request.getCredential("accessToken");
        if (accessToken == null || accessToken.isBlank()) {
            return AuthenticationResult.failure("Invalid or expired token");
        }
        return AuthenticationResult.success();
    }
}
```

## Error handling guidance

When authentication fails, return messages that tell the user exactly what to do:

- missing/blank: “Configure **API Key** in Setup tab.”
- invalid/revoked: “Rotate the API key and re-save the invoker.”
- insufficient permissions: “Grant the required scope/role: `<scope>`.”

See: [Error handling](../operations/ErrorHandling.md)

## Best practices

1. **Never log secrets** (including full headers like `Authorization`).
2. **Do not store runtime tokens** in Setup tab attributes.
3. **Rebuild auth clients on invoker updates**.
4. Prefer **least privilege** (minimal scopes/permissions).

Additional recommendations (from the monolithic guide):

5. **Implement rate limiting** for credential checks to prevent brute-force attacks.
6. **Validate thoroughly**: check every required credential component.
7. **Support session/token management** in runtime components (cache per-invoker; refresh safely).

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## Next steps

- If your integration needs custom certificates, see [Trust](Trust.md).
- Understand save-time behavior: [Save changes](SaveChanges.md).




## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
