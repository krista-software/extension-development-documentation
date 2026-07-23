# Prompt 38: Entity Relationship and CRM Field Mapping

## Purpose

Implement complex field mapping between external CRM systems and Krista entities. Covers custom field flattening (Salesforce __c), OData relationship binding (Dynamics), find-or-create patterns, field diff detection, and status/priority code mapping.

## Prerequisites

- Existing extension with entity definitions
- Understanding of the CRM's data model and field naming conventions
- API client configured for the CRM

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.salesforce` |
| Entity Name | `{{ENTITY_NAME}}` | `Account` |
| CRM Type | `{{CRM_TYPE}}` | `Salesforce` / `Dynamics` / `HubSpot` |

---

## Prompt

```
I need you to implement CRM field mapping for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Entity**: {{ENTITY_NAME}}
- **CRM**: {{CRM_TYPE}}

## 1. Catalog Type Converter

Map between CRM API models and Krista entity models:

```java
package {{PACKAGE_NAME}}.catalog.types;

public class {{ENTITY_NAME}}CatalogType {

    // CRM API model → Krista entity
    public static {{ENTITY_NAME}} fromApiModel(ApiModel model) {
        {{ENTITY_NAME}} entity = new {{ENTITY_NAME}}();
        entity.id = model.getId();
        entity.name = model.getName();
        entity.email = model.getEmail();
        entity.status = StatusMapping.toDisplayName(model.getStatusCode());
        entity.priority = PriorityMapping.toDisplayName(model.getPriorityCode());

        // Map custom fields
        if (model.getCustomFields() != null) {
            entity.customFields = model.getCustomFields();
        }
        return entity;
    }

    // Krista entity → CRM API payload
    public static Map<String, Object> toApiPayload({{ENTITY_NAME}} entity) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("Name", entity.name);
        payload.put("Email", entity.email);
        payload.put("StatusCode", StatusMapping.toCode(entity.status));

        // Flatten custom fields into root payload
        if (entity.customFields != null) {
            payload.putAll(entity.customFields);
        }
        return payload;
    }
}
```

## 2. Custom Field Flattening (Salesforce Pattern)

Salesforce custom fields end with `__c` and must be flattened into/out of the root JSON:

```java
package {{PACKAGE_NAME}}.util;

public class CustomFieldSerializer {

    // Flatten: { "customFields": {"PO__c": "123"} } → { "PO__c": "123" }
    public static Map<String, Object> flatten(Map<String, Object> entity) {
        Map<String, Object> flat = new HashMap<>(entity);
        Object custom = flat.remove("customFields");
        if (custom instanceof Map) {
            flat.putAll((Map<String, Object>) custom);
        }
        return flat;
    }

    // Inflate: { "PO__c": "123", "Name": "Acme" } → { "Name": "Acme", "customFields": {"PO__c": "123"} }
    public static Map<String, Object> inflate(Map<String, Object> flat) {
        Map<String, Object> standard = new HashMap<>();
        Map<String, Object> custom = new HashMap<>();
        for (var entry : flat.entrySet()) {
            if (entry.getKey().endsWith("__c")) {
                custom.put(entry.getKey(), entry.getValue());
            } else {
                standard.put(entry.getKey(), entry.getValue());
            }
        }
        if (!custom.isEmpty()) {
            standard.put("customFields", custom);
        }
        return standard;
    }
}
```

## 3. OData Relationship Binding (Dynamics Pattern)

Dynamics uses `@odata.bind` for entity relationships:

```java
package {{PACKAGE_NAME}}.util;

public class ODataBindingHelper {

    // Create a relationship binding: "/accounts(guid)"
    public static String createBinding(String entitySet, String entityId) {
        return "/" + entitySet + "(" + entityId + ")";
    }

    // Build a payload with relationship bindings
    public static Map<String, Object> withRelationships(
            Map<String, Object> payload, Map<String, String> bindings) {
        Map<String, Object> result = new HashMap<>(payload);
        for (var entry : bindings.entrySet()) {
            result.put(entry.getKey() + "@odata.bind", entry.getValue());
        }
        return result;
    }
}

// Usage:
Map<String, Object> casePayload = new HashMap<>();
casePayload.put("title", "Support Request");
casePayload = ODataBindingHelper.withRelationships(casePayload, Map.of(
    "customerid_contact", ODataBindingHelper.createBinding("contacts", contactId),
    "subjectid", ODataBindingHelper.createBinding("subjects", subjectId)
));
```

## 4. Status and Priority Code Mapping

```java
package {{PACKAGE_NAME}}.util;

public class StatusMapping {
    private static final Map<Integer, String> CODE_TO_NAME = Map.of(
        0, "Active",
        1, "Resolved",
        2, "Cancelled"
    );
    private static final Map<String, Integer> NAME_TO_CODE =
        CODE_TO_NAME.entrySet().stream()
            .collect(Collectors.toMap(Map.Entry::getValue, Map.Entry::getKey));

    public static String toDisplayName(int code) {
        return CODE_TO_NAME.getOrDefault(code, "Unknown (" + code + ")");
    }

    public static int toCode(String displayName) {
        Integer code = NAME_TO_CODE.get(displayName);
        if (code == null) throw new IllegalArgumentException("Unknown status: " + displayName);
        return code;
    }
}
```

## 5. Find-or-Create Pattern

```java
package {{PACKAGE_NAME}}.impl;

public class {{ENTITY_NAME}}Dao {

    public String findOrCreate(Map<String, Object> attributes) {
        // 1. Try to find by unique key
        String uniqueKey = (String) attributes.get("Email");
        List<ApiModel> existing = apiClient.search(
            "Email = '" + QueryBuilder.escape(uniqueKey) + "'");

        if (!existing.isEmpty()) {
            return existing.get(0).getId();
        }

        // 2. Create if not found
        return apiClient.create(attributes);
    }
}
```

## 6. Field Diff Detection

Detect which fields changed between old and new versions:

```java
package {{PACKAGE_NAME}}.util;

public class FieldDiffDetector {

    public static Map<String, Object> getChangedFields(
            Map<String, Object> oldValues, Map<String, Object> newValues) {
        Map<String, Object> diff = new HashMap<>();
        for (var entry : newValues.entrySet()) {
            Object oldValue = oldValues.get(entry.getKey());
            if (!Objects.equals(oldValue, entry.getValue())) {
                diff.put(entry.getKey(), entry.getValue());
            }
        }
        return diff;
    }
}

// Usage: Only send changed fields in PATCH/UPDATE
Map<String, Object> changes = FieldDiffDetector.getChangedFields(existing, updated);
if (!changes.isEmpty()) {
    apiClient.patch(entityId, changes);
}
```

## Best Practices

1. **Map field names explicitly** — use a registry, never assume naming conventions match
2. **Handle custom fields generically** — use the flatten/inflate pattern for extensibility
3. **Use code-to-name mapping** — never expose internal codes to users
4. **Find before create** — prevent duplicates in CRM systems
5. **Send only changed fields** — use diff detection for PATCH operations
6. **Validate relationship IDs** — confirm referenced entities exist before binding

## Related Prompts

- [Prompt 24: Entity Development](24-entity-development.md) — entity definitions
- [Prompt 35: Query Builder](35-api-query-builder.md) — SOQL/OData queries
- [Prompt 06: CHANGE_SYSTEM Request](06-add-change-system-request.md) — create/update patterns
```
