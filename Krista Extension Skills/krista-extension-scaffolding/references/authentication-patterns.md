# Authentication patterns

Four distinct mechanisms appear across the branches. Pick by how the target system authenticates.

## Pattern A — Bearer token / API key (consumer)  ← simplest, start here

The admin pastes a pre-issued token or API key; there is no login flow. (slack, and the ServiceTrade
demo extension.)

- One secured connection field: `@Field.Text(value = KEY, isSecured = true)`.
- No `RequestAuthenticator`, no `jaxrsId`, no JAX-RS app.
- `@InvokerRequest(VALIDATE_ATTRIBUTES)` / `TEST_CONNECTION` hits the vendor's auth-check endpoint.
- The HTTP client reads the token from the `@Service` attributes and sends `Authorization: Bearer <token>`.

Templates: base set only (`ExtensionClass`, `Attributes`, `Area`).

## Pattern B — OAuth2 client-credentials (service-to-service)

Machine token from client id/secret; no user interaction. (ServiceTrade demo, salesforce
client-credentials flow.)

- Secured fields: client id + client secret (`isSecured=true`).
- A small token manager: `POST <tokenUrl>` with `grant_type=client_credentials` → cache `access_token`
  until `expires_in`. No `RequestAuthenticator` needed.
- `TEST_CONNECTION` acquires a token.

Templates: base set + a token-manager integration class (not templated; ~40 lines).

## Pattern C — OAuth2 interactive (authorization-code / 3-legged)

User authorizes in the browser; the extension exchanges a code and stores refresh tokens.
(salesforce_sales, servicenow, jira, oauth2-authentication.)

Framework pieces (all templated under `templates/authentication/`):
1. `@InvokerRequest(AUTHENTICATOR)` returns a `RequestAuthenticator` (9 methods to implement).
2. `getMustAuthorizeResponse(MustAuthorizeException)` builds the authorize URL (ScribeJava
   `OAuth20Service`) and returns `new AuthorizationResponse(url, List.of())`.
3. A JAX-RS `Application` (`@Service @ApplicationPath @ContractsProvided(Application.class)`) exposing
   a `@GET /callback` resource that exchanges the code and persists the refresh token via a
   `@Service RefreshTokenStore` (wraps `KeyValueStore`).
4. A transient `@Service *AttributeStore` (save→UUID `authContextId`, load, remove) to carry config
   through the browser round-trip.
5. `MustAuthorizeException` carries `NamedValuedField` userId/authContextId details.

Uses `com.github.scribejava:scribejava-apis:8.3.3`. servicenow additionally offers Basic auth
selected by a `@Field.PickOne(name="AuthType", values={"Oauth","BasicAuth"})`.

## Pattern D — Microsoft-auth-SDK (all Microsoft products)  ← do NOT hand-roll

Outlook/SharePoint/Teams/OneDrive migrate onto `app.krista.sdk:microsoft-auth-sdk:1.0.5`, which ships
the auth/audit/AI-Assistant tabs as pre-built HTML and abstract base classes. Auth is fully
declarative. Templates under `templates/msauth/`. Key pieces:

- `@MsAuthExtension(extensionType, callbackPathPrefix, supportedFlows={AuthFlow...}, defaultScopes={...}, ...)`
  + `@AuthScope(...)` (one per scope) + `@AuditConfig(...)` + `@AuditEventGroup`/`@AuditEvent` on an
  otherwise-empty `*AuthConfig` class.
- A `MsAuthExtensionDescriptor` impl returning that config class, registered via
  `META-INF/services/app.krista.sdk.msauth.extension.registry.MsAuthExtensionDescriptor`.
- `*RequestAuthenticator extends AbstractRequestAuthenticator` calling `super(invokerId, routingUrl, callbackPathPrefix)`.
- build.gradle: a non-transitive `sdkUi` configuration + `extractSDKResources` Copy task unzipping
  `auth/index.html`, `audit/index.html`, `mcp-setup/index.html` from the SDK jar into `build/resources/main`.
- `@Extension(implementationModel = Krista_4_O)` + `@Containerize(baseImageVersion = "3.6.2-sp3")`.

Deps: microsoft-auth-sdk 1.0.5, microsoft-graph 5.76.0+, microsoft-graph-auth 0.3.0, azure-identity 1.11.x,
krista-apis 1.0.125-sp1.

## Common auth traps (from the review history)

- **`jaxrsId` defaults to `"rest"`.** Tab/callback URLs resolve as `rest/<jaxrsId>/<path>`. Setting a
  custom `jaxrsId` without updating every URL string 404s the tabs.
- Never return a stored client secret in plaintext from a `getCredentials` endpoint — mask it.
- In the MS SDK attribute model, `authType "Private"` = app-only client credentials (S2S), NOT
  "customer's own app" (that's `Public` + `publicAuthMode "own"`).
