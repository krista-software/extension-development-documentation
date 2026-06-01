# Prompt 31: KeyValueStore Patterns (Tokens, Cursors, State)

## Purpose

Implement persistent state management using the Krista `KeyValueStore` for common scenarios: OAuth refresh tokens, delta sync cursors, and cached configuration. The KeyValueStore is a per-invoker encrypted key-value store that persists across restarts.

## Prerequisites

- Existing extension with dependency injection
- Understanding of what state needs to survive restarts
- `KeyValueStore` available via HK2 injection

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Outlook` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.outlook` |
| Store Purpose | `{{STORE_PURPOSE}}` | `RefreshToken` / `DeltaCursor` / `AttributeCache` |

---

## Prompt

```
I need you to implement a KeyValueStore-backed persistence layer for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Store Purpose**: {{STORE_PURPOSE}}

## 1. Refresh Token Store

Store and retrieve OAuth refresh tokens keyed by user identity:

```java
package {{PACKAGE_NAME}}.impl.stores;

import app.krista.ksdk.store.KeyValueStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;

public class RefreshTokenStore {
    private static final Logger LOGGER = LoggerFactory.getLogger(RefreshTokenStore.class);
    private static final String TOKEN_PREFIX = "rt_";

    private final KeyValueStore kvStore;

    @Inject
    public RefreshTokenStore(KeyValueStore kvStore) {
        this.kvStore = kvStore;
    }

    public void store(String userId, String refreshToken) {
        kvStore.put(TOKEN_PREFIX + userId, refreshToken);
        LOGGER.info("Stored refresh token for user: {}", userId);
    }

    public String retrieve(String userId) {
        return kvStore.get(TOKEN_PREFIX + userId);
    }

    public void remove(String userId) {
        kvStore.remove(TOKEN_PREFIX + userId);
        LOGGER.info("Removed refresh token for user: {}", userId);
    }
}
```

### Key design rules for token stores:

- **Prefix keys** to avoid collisions with other stores (`rt_`, `dt_`, `attr_`)
- **Never log token values** — log the user ID only
- **Use `remove()` instead of `put(null)`** to avoid deserialization errors
- **Separate per-user vs operator keys** — per-user tokens use `<wsContactId>`, operator tokens use `<email>_<clientId>_<authType>`

## 2. Delta Sync Cursor Store

Store cursor/checkpoint for incremental data synchronization:

```java
package {{PACKAGE_NAME}}.impl.stores;

import app.krista.ksdk.store.KeyValueStore;

import javax.inject.Inject;

public class DeltaCursorStore {
    private static final String CURSOR_PREFIX = "cursor_";

    private final KeyValueStore kvStore;

    @Inject
    public DeltaCursorStore(KeyValueStore kvStore) {
        this.kvStore = kvStore;
    }

    public void saveCursor(String resourceKey, String cursor) {
        kvStore.put(CURSOR_PREFIX + resourceKey, cursor);
    }

    public String loadCursor(String resourceKey) {
        return kvStore.get(CURSOR_PREFIX + resourceKey);
    }

    public void clearCursor(String resourceKey) {
        kvStore.remove(CURSOR_PREFIX + resourceKey);
    }
}
```

### Usage in delta sync:

```java
// First sync — no cursor, fetch everything
String cursor = cursorStore.loadCursor(folderId);
if (cursor == null) {
    List<Item> allItems = api.listAll(folderId);
    cursor = api.getLatestCursor(folderId);
    cursorStore.saveCursor(folderId, cursor);
    return allItems;
}

// Incremental sync — use cursor, get only changes
List<Change> changes = api.getChangesSince(cursor);
String newCursor = api.getLatestCursor(folderId);
cursorStore.saveCursor(folderId, newCursor);
return changes;
```

## 3. Attribute Cache Store

Cache resolved configuration that is expensive to compute:

```java
package {{PACKAGE_NAME}}.impl.stores;

import app.krista.ksdk.store.KeyValueStore;
import com.google.gson.Gson;

import javax.inject.Inject;

public class AttributeStore {
    private static final String ATTR_KEY = "attr_config";
    private static final Gson GSON = new Gson();

    private final KeyValueStore kvStore;

    @Inject
    public AttributeStore(KeyValueStore kvStore) {
        this.kvStore = kvStore;
    }

    public void save({{EXTENSION_NAME}}Attributes attributes, String invokerId) {
        kvStore.put(ATTR_KEY + "_" + invokerId, GSON.toJson(attributes));
    }

    public {{EXTENSION_NAME}}Attributes load(String invokerId) {
        String json = kvStore.get(ATTR_KEY + "_" + invokerId);
        if (json == null) return null;
        try {
            return GSON.fromJson(json, {{EXTENSION_NAME}}Attributes.class);
        } catch (Exception e) {
            // Graceful fallback — value may be corrupted or from a different format
            return null;
        }
    }
}
```

### Graceful deserialization:

Always wrap `fromJson()` in try/catch — the stored value may be from a previous extension version or corrupted by a parallel write.

## 4. Cleanup on INVOKER_REMOVED

Clear all stored state when the invoker is deleted:

```java
@InvokerRequest(InvokerRequest.Type.INVOKER_REMOVED)
public void onRemoved() {
    refreshTokenStore.remove(invokerId);
    cursorStore.clearCursor(invokerId);
    attributeStore.remove(invokerId);
    LOGGER.info("Cleaned up all stored state for invoker: {}", invokerId);
}
```

## Best Practices

1. **Prefix all keys** — prevents collisions between stores
2. **Never log stored values** — they may contain tokens or secrets
3. **Use `remove()` not `put(null)`** — null values cause deserialization failures
4. **Wrap deserialization in try/catch** — graceful handling of format changes
5. **Clean up on INVOKER_REMOVED** — prevent orphaned data
6. **Keep values small** — KeyValueStore is not a database; store references, not bulk data

## Related Prompts

- [Prompt 01: OAuth 2.0 Extension](01-create-extension-oauth2.md) — uses token store
- [Prompt 15: Lifecycle Hooks](15-implement-lifecycle-hooks.md) — cleanup patterns
- [Prompt 33: Delta Sync](33-delta-sync-change-detection.md) — uses cursor store
```
