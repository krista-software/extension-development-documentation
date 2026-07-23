<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Custom agents](README.md) > Domain registration

# Domain registration

## Overview

Krista uses a catalog system to discover and register agent extensions. Your extension must be correctly associated with the official **Krista Ecosystem** and **Agent Domain** to appear in the platform's agent management interface.

## Required identifiers

### Ecosystem and domain values

Your custom agent extension must use these exact values:

| Field | Value |
|-------|-------|
| **Ecosystem Name** | `Krista` |
| **Ecosystem ID** | `catEntryEcosystem_d3b05047-07b0-4b06-95a3-9fb8f7f608d9` |
| **Domain Name** | `Agent` |
| **Domain ID** | `catEntryDomain_c54d9930-ea03-4c58-bee6-26f90939171d` |
| **Ecosystem Version** | `9bc82a31-a79a-4dc8-bdbd-1ed7e576f7c1` |

> **⚠️ Warning**: These values are platform-specific and must match exactly. Using incorrect values will prevent your extension from being discovered.

## Implementation

### Domain annotation

Use the `@Domain` annotation to register your extension with the Agent domain:

```java
@Domain(
    id = "catEntryDomain_c54d9930-ea03-4c58-bee6-26f90939171d",
    name = "Agent",
    ecosystemId = "catEntryEcosystem_d3b05047-07b0-4b06-95a3-9fb8f7f608d9",
    ecosystemName = "Krista",
    ecosystemVersion = "9bc82a31-a79a-4dc8-bdbd-1ed7e576f7c1"
)
public class CustomAgentExtension {
    // Extension implementation
}
```

### Catalog request annotation

Each action or capability your agent exposes must be annotated with `@CatalogRequest`:

```java
@CatalogRequest(
    id = "custom_agent_action_001",
    name = "Process User Query",
    description = "Processes user queries and returns intelligent responses",
    area = "Agent",
    type = CatalogRequest.Type.CHANGE_SYSTEM
)
public ExtensionResponse handleUserQuery(QueryRequest request) {
    // Implementation here
}
```

## Catalog request types

Choose the appropriate request type based on your agent's functionality:

| Type | Use Case | Example |
|------|----------|---------|
| `CHANGE_SYSTEM` | Modifies state or triggers actions | Process query, update settings |
| `QUERY_SYSTEM` | Reads data without modification | Retrieve agent status, list conversations |
| `WAIT_FOR_EVENT` | Waits for external events | Monitor for user input, webhook notifications |

See: [Catalog request types](../development/catalog-requests/CatalogRequestTypes.md)

## Best practices

### 1. Use unique identifiers

Every `@CatalogRequest` must have a unique ID:

```java
// Good: Clear, unique identifier
@CatalogRequest(
    id = "conversation_agent_process_query_v1",
    name = "Process Query",
    // ...
)

// Bad: Generic or duplicate ID
@CatalogRequest(
    id = "action1",  // Too generic
    name = "Process Query",
    // ...
)
```

### 2. Provide meaningful names and descriptions

Use clear, user-friendly names and detailed descriptions:

```java
@CatalogRequest(
    id = "conversation_agent_analyze_sentiment",
    name = "Analyze Conversation Sentiment",
    description = "Analyzes the sentiment of user conversations and provides emotional context for better response generation",
    area = "Agent",
    type = CatalogRequest.Type.QUERY_SYSTEM
)
```

### 3. Organize by functional area

Group related catalog requests by setting the `area` parameter:

```java
// All agent-related requests use "Agent" area
@CatalogRequest(
    area = "Agent",
    // ...
)
```

## Multiple catalog requests

A single extension can expose multiple catalog requests:

```java
@Domain(
    id = "catEntryDomain_c54d9930-ea03-4c58-bee6-26f90939171d",
    name = "Agent",
    ecosystemId = "catEntryEcosystem_d3b05047-07b0-4b06-95a3-9fb8f7f608d9",
    ecosystemName = "Krista",
    ecosystemVersion = "9bc82a31-a79a-4dc8-bdbd-1ed7e576f7c1"
)
public class ConversationAgentExtension {
    
    @CatalogRequest(
        id = "conversation_agent_process_query",
        name = "Process User Query",
        description = "Processes and responds to user queries",
        area = "Agent",
        type = CatalogRequest.Type.CHANGE_SYSTEM
    )
    public ExtensionResponse processQuery(QueryRequest request) {
        // Implementation
    }
    
    @CatalogRequest(
        id = "conversation_agent_get_history",
        name = "Get Conversation History",
        description = "Retrieves conversation history for a user",
        area = "Agent",
        type = CatalogRequest.Type.QUERY_SYSTEM
    )
    public ExtensionResponse getHistory(HistoryRequest request) {
        // Implementation
    }
}
```

## Unsupported operations

If your extension doesn't support a method from a required interface, throw `UnsupportedOperationException`:

```java
@Override
public ExtensionResponse unsupportedOperation() {
    throw new UnsupportedOperationException(
        "This operation is not supported by the Conversation Agent extension"
    );
}
```

## Troubleshooting

### Extension not appearing in Agent List

**Cause**: Incorrect domain or ecosystem IDs

**Resolution**:
1. Verify all IDs match the required values exactly
2. Check for typos in the `@Domain` annotation
3. Rebuild and repackage the extension

### Catalog request not discovered

**Cause**: Missing or invalid `@CatalogRequest` annotation

**Resolution**:
1. Ensure the method is public
2. Verify the `id` is unique across all catalog requests
3. Check that the `area` is set to `"Agent"`

### Registration fails during import

**Cause**: Duplicate IDs or invalid ecosystem version

**Resolution**:
1. Use unique IDs for all `@CatalogRequest` annotations
2. Verify ecosystem version matches the platform version
3. Check platform logs for specific error messages

## See also

- [Extension annotations](../reference/ExtensionAnnotations.md)
- [Catalog requests](../development/catalog-requests/README.md)
- [Hosting URL endpoint](HostingUrlEndpoint.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).

