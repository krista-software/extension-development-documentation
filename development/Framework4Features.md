<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Framework 4 Features

# Framework 4 Features

## Overview

Krista Framework 4 (`Krista_4_O`) introduces several new annotations and capabilities for extensions. This page documents the key features available in Framework 4, based on real production implementations (e.g., Outlook 4 extension).

---

## 1. Implementation Model: Krista_4_O

Framework 4 extensions declare their implementation model in the `@Extension` annotation:

```java
@Extension(
    version = "4.0.5",
    name = "Outlook",
    description = "Outlook email, mail subscriptions, and real-time notifications via Microsoft Graph",
    implementationModel = Extension.ImplementationModel.Krista_4_O
)
public class OutlookExtension { ... }
```

### What `Krista_4_O` enables
- Constructor-based dependency injection (extension class is created per-request)
- Full KSDK integration (TelemetryMetrics, EventHandler, AuthorizationContext, AccountProvider)
- MCP (Model Context Protocol) tool exposure
- Containerized deployment
- Static resource hosting
- Changelog support

---

## 2. @Containerize — Container-Based Deployment

Extensions can declare containerization requirements:

```java
@Containerize(baseImageVersion = "3.5.8")
public class OutlookExtension { ... }
```

### Parameters
| Parameter | Description |
|-----------|-------------|
| `baseImageVersion` | The base container image version to use for packaging the extension |

This tells the platform to build and deploy the extension as a container rather than a standalone JAR.

---

## 3. @ChangeLog — Release Notes Integration

Extensions can provide built-in release notes that are accessible through the platform:

```java
@ChangeLog(file = "resources/docs/pages/release-notes.md")
public class OutlookExtension { ... }
```

### Parameters
| Parameter | Description |
|-----------|-------------|
| `file` | Path to the markdown file containing release notes, relative to the extension source |

### Release Notes Format

```markdown
# Release Notes

## Version 4.0.5 — Reset Auth Token catalog request

**Release Date**: May, 2026

### New Feature

**New catalog request: `Reset Auth Token` in the Messaging area.**

Description of the feature...

#### How it works

1. Step 1
2. Step 2

#### Output

| Field | Type | Description |
|---|---|---|
| Successful | Boolean | Description |

#### Files Changed

- `File1.java` — description of change
- `File2.java` — description of change

---

## Version 4.0.4 — Bug Fix Title

**Release Date**: May, 2026

### Bug Fix

Description...

### Backward Compatibility

**100% Backward Compatible** — description

### Breaking Changes

**None**
```

### Best Practices
- Use semantic versioning (X.Y.Z)
- Include release date
- Categorize changes: New Feature, Bug Fix, Performance Improvement, Removed
- Document backward compatibility and breaking changes
- List files changed for each version
- Include version information table (Extension Version, Developer, Krista Service APIs version, Global Catalog Version)

---

## 4. @StaticResource — Embedded Documentation

Extensions can bundle static web content (HTML documentation, images) served directly by the platform:

```java
@StaticResource(path = "docs", file = "docs")
public class OutlookExtension { ... }
```

### Parameters
| Parameter | Description |
|-----------|-------------|
| `path` | The URL path segment under which the static content is served |
| `file` | The resource directory containing the static files |

### Typical Documentation Structure

```
src/main/resources/docs/
├── index.html              # Docsify-powered documentation site
├── README.md               # Landing page
├── _sidebar.md             # Navigation sidebar
├── assets/
│   ├── docsify.js
│   ├── search-min.js
│   └── theme-simple.css
├── _media/                 # Screenshots and images
│   ├── screenshot1.png
│   └── screenshot2.png
└── pages/
    ├── overview.md
    ├── Authentication.md
    ├── FetchInbox.md
    ├── SendMail.md
    ├── release-notes.md    # Referenced by @ChangeLog
    └── ...
```

### Accessing Static Docs
The docs are available via the extension's custom tabs (see `@InvokerRequest(CUSTOM_TABS)` below).

---

## 5. @InvokerRequest(CUSTOM_TABS) — Custom Setup Tabs

Framework 4 extensions can add custom tabs to the Setup UI:

```java
@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
public Map<String, String> customTabs() {
    return Map.of(
        "Authentication", "rest/outlook/docs/",    // REST API endpoint
        "Documentation", "static/docs"              // Static resource path
    );
}
```

### Return Value
A `Map<String, String>` where:
- **Key** = Tab name displayed in the UI
- **Value** = URL path the tab loads (can be a REST endpoint or static resource path)

---

## 6. MCP Tool Exposure (`tool = true`)

Framework 4 introduces the ability to expose catalog requests as **MCP (Model Context Protocol) tools**, enabling AI agents to invoke them directly.

### Annotation

```java
@CatalogRequest(
    id = "localDomainRequest_...",
    name = "Fetch Inbox",
    description = "Accepts page number and page size as input and returns list of mail",
    area = "Messaging",
    type = CatalogRequest.Type.QUERY_SYSTEM,
    tool = true    // <-- Exposes this as an MCP tool
)
public ExtensionResponse fetchInbox(...) { ... }
```

### What `tool = true` Does
- Exposes the catalog request as an MCP-compatible tool
- AI clients (e.g., Krista Agent) can invoke it directly without manual workflow configuration
- The request participates in MCP authentication flows (`invokeAsUser`)

### Guidelines for MCP Tool Exposure

**DO mark as `tool = true`:**
- Query operations (list, fetch, search)
- Simple action operations (send mail, move message)
- Read-only catalog requests

**DO NOT mark as `tool = true`:**
- Async pair operations (e.g., `Fetch Inbox Async` + `Get Result`)
- Event-waiting operations (e.g., `Mail Received Alert`, `Receive Notification of Email Change`)
- Operations requiring complex multi-step workflows

### Example: Outlook 4 MCP Tools

**MessagingArea (9 tools):**

| Catalog Request | Type | tool=true |
|----------------|------|-----------|
| Fetch All Labels | QUERY_SYSTEM | Yes |
| Fetch Sent | QUERY_SYSTEM | Yes |
| Fetch Mail Details By Query | QUERY_SYSTEM | Yes |
| Send Mail | CHANGE_SYSTEM | Yes |
| Fetch Inbox | QUERY_SYSTEM | Yes |
| Fetch Inbox With Preferences | QUERY_SYSTEM | Yes |
| Fetch Mails By Label | QUERY_SYSTEM | Yes |
| Fetch Latest Mail | QUERY_SYSTEM | Yes |
| List Categories | QUERY_SYSTEM | Yes |

**SetupArea (1 tool):**

| Catalog Request | Type | tool=true |
|----------------|------|-----------|
| List All Folders | QUERY_SYSTEM | Yes |

### MCP Authentication Flow

When an MCP client calls a `tool = true` request before the user has authenticated:

1. MCP client calls catalog request via `invokeAsUser=true`
2. Extension detects no stored credentials
3. Extension throws `MustAuthorizeException` with OAuth redirect details
4. User is redirected to the identity provider (e.g., Microsoft) for authentication
5. On success, credentials are stored and subsequent MCP calls succeed without re-auth

### MCP Auth Architecture Rules

1. **Two hermetic keyspaces** — Per-user refresh tokens live under `<wsContact>` keys; operator tokens live under `<email>_<clientId>_<authType>` keys. The two never share a key shape.
2. **`invokeAsUser=true` always uses default Public OAuth client** — Setup's Public/Private fields are only consulted when `invokeAsUser=false` (operator-shared paths).
3. **`MustAuthorizeException` must propagate** through every catalog/DAO catch block.

```java
// CRITICAL: Always rethrow MustAuthorizeException in catch blocks
try {
    // ... operation logic
} catch (MustAuthorizeException e) {
    throw e;  // MUST rethrow — never swallow this
} catch (Exception e) {
    // Handle other errors
}
```

---

## 7. TelemetryMetrics — Observability

Framework 4 provides built-in telemetry support via `TelemetryMetrics`:

```java
@Inject
public OutlookExtension(... TelemetryMetrics telemetryMetrics ...) {
    this.telemetryMetrics = telemetryMetrics;
}

// Increment a counter
telemetryMetrics.incrementCounter("outlook4.custom_tabs.opened", 1, Map.of(
    "tab", "Documentation",
    "action", "open"
));
```

### TelemetryHelper Pattern

Create a helper class for consistent telemetry across catalog requests:

```java
// Record success with timing
telemetryHelper.recordSuccess("outlook4.fetchInbox", startTime,
    TelemetryHelper.safeTagMap("page", String.valueOf(pageNumber)));

// Record validation error
telemetryHelper.recordValidationError("outlook4.fetchInbox", startTime,
    "Validation failed", Map.of());

// Record system error
telemetryHelper.recordError("outlook4.fetchInbox", startTime, exception, Map.of());

// Record retry prompted
telemetryHelper.recordRetryPrompted("outlook4.fetchMailByMessageId", startTime,
    TelemetryHelper.safeTagMap("message_id", messageID));
```

### Recommended Metrics
- `{extension}.{operation}` — counter per catalog request
- Success/error/validation/retry breakdown
- Duration tracking via `startTime` pattern
- Tag with relevant parameters (sanitized, no secrets)

---

## 8. Complete Framework 4 Extension Class Example

```java
@Java(version = Java.Version.JAVA_21)
@StaticResource(path = "docs", file = "docs")
@Extension(
    version = "4.0.5",
    name = "My Extension",
    description = "Description of your extension",
    implementationModel = Extension.ImplementationModel.Krista_4_O
)
@Containerize(baseImageVersion = "3.5.8")
@ChangeLog(file = "resources/docs/pages/release-notes.md")
public class MyExtension {

    private final MyRequestAuthenticator requestAuthenticator;
    private final TelemetryMetrics telemetryMetrics;

    @Inject
    public MyExtension(Invoker invoker, TelemetryMetrics telemetryMetrics,
                       AuthorizationContext authorizationContext, EventHandler eventHandler) {
        this.telemetryMetrics = telemetryMetrics;
        this.requestAuthenticator = new MyRequestAuthenticator(invoker, authorizationContext);
    }

    @InvokerRequest(InvokerRequest.Type.AUTHENTICATOR)
    public RequestAuthenticator getRequestAuthenticator() {
        return requestAuthenticator;
    }

    @InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
    public Map<String, String> customTabs() {
        return Map.of("Documentation", "static/docs");
    }

    @InvokerRequest(InvokerRequest.Type.TEST_CONNECTION)
    public void testConnection() {
        // Validate connectivity
    }

    @InvokerRequest(InvokerRequest.Type.INVOKER_REMOVED)
    public void invokerRemoved() {
        // Cleanup resources
    }
}
```

---

## 9. Framework 4 Area Class with MCP Tools

```java
@Domain(
    id = "catEntryDomain_...",
    name = "YourDomain",
    ecosystemId = "catEntryEcosystem_...",
    ecosystemName = "Essentials",
    ecosystemVersion = "..."
)
public class MyArea {

    @Inject
    public MyArea(Account account, RequestContext requestContext,
                  AuthorizationContext authorizationContext, TelemetryHelper telemetryHelper) {
        // Store dependencies
    }

    // MCP-exposed tool
    @CatalogRequest(
        id = "localDomainRequest_...",
        name = "List Items",
        description = "Returns list of items",
        area = "MyArea",
        type = CatalogRequest.Type.QUERY_SYSTEM,
        tool = true)
    @Field.Desc(name = "Items", type = "[ Text ]", required = false)
    public ExtensionResponse listItems() {
        long startTime = System.currentTimeMillis();
        try {
            List<String> items = service.getItems();
            telemetryHelper.recordSuccess("myext.listItems", startTime, Map.of());
            return ExtensionResponseFactory.create(Map.of("Items", items));
        } catch (MustAuthorizeException e) {
            throw e;  // Always rethrow for MCP auth flow
        } catch (Exception e) {
            telemetryHelper.recordError("myext.listItems", startTime, e, Map.of());
            return ExtensionResponseFactory.create("Error listing items",
                ExtensionResponse.Error.ExceptionType.SYSTEM_ERROR, null, null, null);
        }
    }

    // Non-MCP catalog request (no tool=true)
    @CatalogRequest(
        id = "localDomainRequest_...",
        name = "Wait For Event",
        description = "Waits for an event notification",
        area = "MyArea",
        type = CatalogRequest.Type.WAIT_FOR_EVENT)
    public ExtensionResponse waitForEvent(...) {
        // Event-waiting operations should NOT be tool=true
    }
}
```

---

## See also

- [Extension annotations](../reference/ExtensionAnnotations.md)
- [Java 21 patterns](Java21Patterns.md)
- [Authentication patterns](../advanced/AuthPatterns.md)
- [Catalog request types](catalog-requests/CatalogRequestTypes.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
