# Prompt 33: Delta Sync and Change Detection

## Purpose

Implement incremental data synchronization that detects and reports changes (created, updated, deleted, moved) since the last sync. Three strategies are covered: cursor-based, webhook subscription, and snapshot comparison.

## Prerequisites

- Existing extension with KeyValueStore access
- Understanding of the external API's change tracking capabilities
- EventHandler for delivering change notifications

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Dropbox` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.dropbox` |
| Resource Name | `{{RESOURCE_NAME}}` | `File` |
| Sync Strategy | `{{STRATEGY}}` | `cursor` / `webhook` / `snapshot` |

---

## Prompt

```
I need you to implement delta sync / change detection for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Resource**: {{RESOURCE_NAME}}
- **Strategy**: {{STRATEGY}}

## Strategy 1: Cursor-Based Delta Sync

Use when the external API provides a cursor/token for incremental fetching (Dropbox, Microsoft Graph delta).

### 1a. Cursor Store

```java
package {{PACKAGE_NAME}}.impl.stores;

import app.krista.ksdk.store.KeyValueStore;
import javax.inject.Inject;

public class DeltaCursorStore {
    private static final String PREFIX = "cursor_";
    private final KeyValueStore kvStore;

    @Inject
    public DeltaCursorStore(KeyValueStore kvStore) {
        this.kvStore = kvStore;
    }

    public void save(String resourceId, String cursor) {
        kvStore.put(PREFIX + resourceId, cursor);
    }

    public String load(String resourceId) {
        return kvStore.get(PREFIX + resourceId);
    }

    public void clear(String resourceId) {
        kvStore.remove(PREFIX + resourceId);
    }
}
```

### 1b. Sync Service

```java
package {{PACKAGE_NAME}}.impl;

public class DeltaSyncService {
    private final ApiClient apiClient;
    private final DeltaCursorStore cursorStore;

    public List<ChangeEvent> sync(String resourceId) {
        String cursor = cursorStore.load(resourceId);

        if (cursor == null) {
            // First sync — full state capture
            List<Item> allItems = apiClient.listAll(resourceId);
            String newCursor = apiClient.getLatestCursor(resourceId);
            cursorStore.save(resourceId, newCursor);
            return allItems.stream()
                .map(item -> new ChangeEvent("CREATED", item))
                .collect(Collectors.toList());
        }

        // Incremental sync — changes since cursor
        try {
            DeltaResult delta = apiClient.getChangesSince(cursor);
            cursorStore.save(resourceId, delta.getNewCursor());
            return delta.getChanges();
        } catch (CursorExpiredException e) {
            // Cursor expired (e.g., HTTP 410 Gone) — reset and full sync
            cursorStore.clear(resourceId);
            return sync(resourceId);
        }
    }
}
```

### 1c. Change Event Model

```java
public class ChangeEvent {
    public enum Type { CREATED, UPDATED, DELETED, MOVED }

    private final Type type;
    private final String itemId;
    private final String path;
    private final Map<String, Object> metadata;
}
```

### 1d. Move Detection (Advanced)

Store metadata by both ID and path to detect moves vs delete+create:

```java
// If an item appears at a new path but has the same ID → MOVED
// If an item ID disappears and a new ID appears at same path → DELETED + CREATED
// If an item ID disappears and no replacement → DELETED
```

## Strategy 2: Webhook Subscription

Use when the external API supports push notifications (Microsoft Graph, Slack).

### 2a. Subscription Lifecycle

```java
package {{PACKAGE_NAME}}.impl;

public class SubscriptionManager {
    private static final int EXPIRY_DAYS = 28;

    public boolean createOrRenew(String resourceId, String callbackUrl) {
        Subscription existing = getExisting(resourceId);
        if (existing != null && !isExpiringSoon(existing)) {
            return true; // Still valid
        }

        if (existing != null) {
            return renew(existing.getId());
        }

        return create(resourceId, callbackUrl, EXPIRY_DAYS);
    }

    private boolean isExpiringSoon(Subscription sub) {
        return sub.getExpiry().isBefore(Instant.now().plus(Duration.ofDays(2)));
    }
}
```

### 2b. Webhook Handler

```java
@ApiRequest(pathElement = "webhook", protocol = {"http", "https"})
public ProtoResponse handleWebhook(String pathElement, ProtoRequest request) {
    // 1. Validate signature/token
    if (!validateSignature(request)) {
        return ProtoResponse.error(401, "Invalid signature");
    }

    // 2. Handle validation handshake (some APIs require echo-back)
    if (isValidationRequest(request)) {
        return ProtoResponse.success(request.getParam("validationToken"));
    }

    // 3. Parse change notifications
    List<ChangeNotification> notifications = parseNotifications(request.getBody());

    // 4. Process each notification
    for (ChangeNotification notification : notifications) {
        eventHandler.handleEvent(notification.getResourceId(), notification.toFreeForm());
    }

    // 5. Return 202 Accepted quickly (process async if needed)
    return ProtoResponse.success();
}
```

### 2c. WAIT_FOR_EVENT Catalog Request

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "When {{RESOURCE_NAME}} Changes",
    description = "Triggered when a change is detected",
    area = "Sync",
    type = CatalogRequest.Type.WAIT_FOR_EVENT)
@Field(name = "Change Details", type = "FreeForm", required = false,
    attributes = {}, options = {})
public ExtensionResponse onResourceChanged(
        @Field.PickOne(name = "Event Type", required = false,
            values = {"Created", "Updated", "Deleted", "All"},
            attributes = {}, options = {}) String eventType) {
    // Framework handles event delivery from webhook handler
    return null;
}
```

## Strategy 3: Snapshot Comparison

Use when the API has no cursor or webhook support — poll and compare full state.

### 3a. Snapshot Store

```java
package {{PACKAGE_NAME}}.impl;

public class SnapshotStore {
    private final KeyValueStore kvStore;
    private static final Gson GSON = new Gson();

    public void saveSnapshot(String resourceId, Map<String, ItemState> state) {
        kvStore.put("snapshot_" + resourceId, GSON.toJson(state));
    }

    public Map<String, ItemState> loadSnapshot(String resourceId) {
        String json = kvStore.get("snapshot_" + resourceId);
        if (json == null) return Collections.emptyMap();
        return GSON.fromJson(json, new TypeToken<Map<String, ItemState>>(){}.getType());
    }
}
```

### 3b. Change Detector

```java
public class ChangeDetector {

    public List<ChangeEvent> detectChanges(
            Map<String, ItemState> previous, Map<String, ItemState> current) {

        List<ChangeEvent> changes = new ArrayList<>();

        // Detect created and updated
        for (var entry : current.entrySet()) {
            ItemState prev = previous.get(entry.getKey());
            if (prev == null) {
                changes.add(new ChangeEvent(CREATED, entry.getKey(), entry.getValue()));
            } else if (!prev.equals(entry.getValue())) {
                changes.add(new ChangeEvent(UPDATED, entry.getKey(), entry.getValue()));
            }
        }

        // Detect deleted
        for (String key : previous.keySet()) {
            if (!current.containsKey(key)) {
                changes.add(new ChangeEvent(DELETED, key, previous.get(key)));
            }
        }

        return changes;
    }
}
```

## Best Practices

1. **Handle cursor expiration gracefully** — reset and full-sync instead of crashing
2. **Validate webhook signatures** — never trust unverified push notifications
3. **Make change handlers idempotent** — the same change may be delivered multiple times
4. **Store snapshots efficiently** — only store fields needed for comparison, not full payloads
5. **Log change counts, not content** — avoid logging sensitive file names or user data
6. **Clean up on INVOKER_REMOVED** — delete cursors and snapshots from KeyValueStore

## Related Prompts

- [Prompt 08: Webhook Handler](08-add-wait-for-event-webhook.md) — webhook signature validation
- [Prompt 31: KeyValueStore Patterns](31-keyvaluestore-patterns.md) — cursor persistence
- [Prompt 37: File Operations](37-file-operations.md) — file CRUD that triggers change events
```
