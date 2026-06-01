<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Save changes

# Save changes

## Overview

When a user clicks **Save** in the Setup tab, Krista persists the invoker’s configuration (attributes, dependency wiring, and related setup metadata). This page explains what “save” means for extension developers and how to design for safe updates.

## Step-by-step: design for safe saves

1. **Validate before save**: return clear, actionable validation messages.
2. **Assume configuration changes over time** (secret rotation, new base URL, changed dependency).
3. **Handle invoker update lifecycle** and rebuild runtime resources.
4. **Keep saves idempotent**: saving the same config twice should not change behavior.
5. **Avoid configuration-driven state**: do not store runtime state in Setup tab fields.

## What the platform saves

Saved configuration typically includes:

- attribute values from fields you declare (see: [Attributes](Attributes.md))
- dependency selections (see: [Dependencies](Dependencies.md))

For **secured** fields, the platform stores values **encrypted at rest**.

## What typically happens when the user clicks Save

While the platform performs the persistence operation, a practical mental model is:

1. The platform collects the user-entered values for your declared fields.
2. Your extension’s setup-time validation runs (if implemented).
3. The platform persists values (encrypting secured fields).
4. The invoker is updated and lifecycle hooks run (so you can rebuild clients/resources).

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## What your extension should implement

Even though the platform performs the persistence operation, your extension should provide:

1. **Setup-time validation** (fail fast with actionable messages)
2. **Update-safe behavior** when configuration changes
3. **Backward compatibility** if you evolve field names and formats

See: [Validation and troubleshooting](ValidationAndTroubleshooting.md)

## Save implementation patterns (from the monolithic guide)

The guide references `InvokerStore` and an update flow via `FnInvokerUpdateSetup`.

### InvokerStore

The `InvokerStore` implementation is referenced as:

- `kristagrand/servers/src/main/java/com/krista/services/ksdk/invokers/InvokerStoreImpl.java`

### FnInvokerUpdateSetup

```java
public class FnInvokerUpdateSetup {
    // Updates invoker setup with encryption for secured fields
}
```

### Example pattern: validate → encrypt → persist

```java
@Inject
private InvokerStore invokerStore;

public void saveConfiguration(Map<String, Object> attributes) {
    // 1. Validate attributes
    List<String> errors = validateAttributes(attributes);
    if (!errors.isEmpty()) {
        throw new IllegalArgumentException("Invalid configuration: " + String.join(", ", errors));
    }

    // 2. Encrypt secured fields (conceptual)
    Map<String, Object> encryptedAttributes = encryptSecuredFields(attributes);

    // 3. Save to database
    invokerStore.updateSetup(encryptedAttributes);
}
```

### Loading configuration (and decrypting)

```java
public Map<String, Object> loadConfiguration() {
    Map<String, Object> attributes = invokerStore.getSetup();
    return decryptSecuredFields(attributes);
}
```

## Handling updates safely

Configuration can change over time (rotated secrets, new base URL, different dependency invoker). Treat this as a normal event:

- rebuild cached clients/tokens when the invoker is updated
- avoid global singletons that mix configurations across invokers
- keep changes idempotent: applying the same configuration twice should be safe

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

### Practical guidance

- If you cache HTTP clients, token providers, or dependency references, rebuild them on invoker update.
- Keep caches **per invoker** (never global across invokers/environments).
- If a dependency invoker changes, re-resolve any adapters and validate capabilities again.

## How this maps to Krista invoker lifecycle

Clicking **Save** in the Setup tab triggers two important phases:

1. **Validate before persistence**
   - The platform calls `@InvokerRequest(InvokerRequest.Type.VALIDATE_ATTRIBUTES)` (if implemented).
   - Return actionable messages for missing/invalid fields.
2. **Persist configuration and refresh runtime resources**
   - After a successful save, the invoker is created/updated.
   - The platform can call lifecycle hooks:
     - **`INVOKER_LOADED`**: initialize runtime resources from the saved attributes.
     - **`INVOKER_UPDATED`**: tear down old resources and re-initialize from the new attributes.
     - **`INVOKER_UNLOADED`**: cleanup resources when the invoker is unloaded.

Practical implication: every time you change a Setup field (base URL, credentials, trust material, dependency invoker), ensure your runtime clients are rebuilt in `INVOKER_UPDATED` so the change takes effect immediately.

See:

- [Invoker requests (`@InvokerRequest`)](../reference/InvokerRequests.md)
- [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)
- [Validation and troubleshooting](ValidationAndTroubleshooting.md)

## Migrating or renaming fields

Changing a field name changes the key used in the stored attribute map.

Recommendations:

- avoid renames whenever possible
- if you must rename, read both the old and new keys for a transition period
- document migration steps for operators

## Storage shape (conceptual)

The monolithic guide describes storage in PostgreSQL using JSONB:

```sql
CREATE TABLE invoker_config (
    invoker_id UUID PRIMARY KEY,
    setup_attributes JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

Example stored data (values may be encrypted for secured fields):

```json
{
  "API Key": "encrypted_value_here",
  "Host URL": "https://api.example.com",
  "Port": 443,
  "Use SSL": true,
  "Environment": "Production"
}
```

## Troubleshooting

- **Save fails**: review setup-time validation messages and server logs.
- **Saved but runtime fails**: confirm you are using the correct invoker; re-check auth and trust settings.

See:

- [Error handling](../operations/ErrorHandling.md)
- [Troubleshooting](../operations/Troubleshooting.md)




## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
