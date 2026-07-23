# Prompt 35: API Query Builder (SOQL, OData, REST Filters)

## Purpose

Implement a type-aware query builder for external APIs. Covers SOQL (Salesforce), OData (Microsoft Dynamics), and REST filter parameters (HubSpot, generic REST). The builder maps Krista field types to the correct query syntax and prevents injection.

## Prerequisites

- Existing extension with API client
- Understanding of the target API's query language
- Entity definitions with field type metadata

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `Salesforce` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.salesforce` |
| Query Language | `{{QUERY_LANG}}` | `SOQL` / `OData` / `REST` |

---

## Prompt

```
I need you to implement a query builder for my Krista extension's API.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Query Language**: {{QUERY_LANG}}

## 1. Field Type Classification

```java
package {{PACKAGE_NAME}}.util;

public enum FieldType {
    TEXT,        // String fields — use LIKE / contains
    EXACT,       // ID fields, enums — use = / equals
    COMPARABLE,  // Numbers — use =, >, <, >=, <=
    DATE,        // Date fields — use range queries
    BOOLEAN,     // Boolean fields — use = true/false
    IDENTITY     // Primary key — use = only
}
```

## 2. Field Mapping Registry

```java
package {{PACKAGE_NAME}}.util;

import java.util.Map;

public class FieldMapping {
    // Map Krista field names to API field names and types
    private static final Map<String, FieldMeta> FIELDS = Map.of(
        "Name",       new FieldMeta("Name", FieldType.TEXT),
        "Email",      new FieldMeta("Email", FieldType.EXACT),
        "Status",     new FieldMeta("Status__c", FieldType.EXACT),
        "Amount",     new FieldMeta("Amount", FieldType.COMPARABLE),
        "Created",    new FieldMeta("CreatedDate", FieldType.DATE),
        "Active",     new FieldMeta("IsActive", FieldType.BOOLEAN),
        "Id",         new FieldMeta("Id", FieldType.IDENTITY)
    );

    public static FieldMeta resolve(String kristaFieldName) {
        return FIELDS.get(kristaFieldName);
    }

    public record FieldMeta(String apiFieldName, FieldType type) {}
}
```

## 3. Query Builder (SOQL)

```java
package {{PACKAGE_NAME}}.util;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

public class QueryBuilder {

    public static String buildSelect(String objectName, List<String> fields,
            Map<String, Object> filters, String sortBy, int limit, int offset) {

        StringBuilder query = new StringBuilder("SELECT ");
        query.append(String.join(", ", fields));
        query.append(" FROM ").append(objectName);

        List<String> conditions = buildConditions(filters);
        if (!conditions.isEmpty()) {
            query.append(" WHERE ").append(String.join(" AND ", conditions));
        }

        if (sortBy != null) {
            query.append(" ORDER BY ").append(escape(sortBy));
        }
        query.append(" LIMIT ").append(limit);
        if (offset > 0) {
            query.append(" OFFSET ").append(offset);
        }

        return query.toString();
    }

    private static List<String> buildConditions(Map<String, Object> filters) {
        List<String> conditions = new ArrayList<>();

        for (var entry : filters.entrySet()) {
            FieldMapping.FieldMeta meta = FieldMapping.resolve(entry.getKey());
            if (meta == null || entry.getValue() == null) continue;

            switch (meta.type()) {
                case TEXT ->
                    conditions.add(meta.apiFieldName() + " LIKE '%" + escape(entry.getValue().toString()) + "%'");
                case EXACT, IDENTITY ->
                    conditions.add(meta.apiFieldName() + " = '" + escape(entry.getValue().toString()) + "'");
                case COMPARABLE ->
                    conditions.add(meta.apiFieldName() + " = " + entry.getValue());
                case DATE ->
                    conditions.add(meta.apiFieldName() + " >= " + formatDate(entry.getValue()));
                case BOOLEAN ->
                    conditions.add(meta.apiFieldName() + " = " + entry.getValue());
            }
        }
        return conditions;
    }

    public static String escape(String value) {
        return value.replace("'", "\\'").replace("\\", "\\\\");
    }

    private static String formatDate(Object value) {
        if (value instanceof Long) {
            return LocalDate.ofEpochDay((Long) value / 86400000)
                .format(DateTimeFormatter.ISO_LOCAL_DATE);
        }
        return value.toString();
    }
}
```

## 4. Query Builder (OData)

```java
package {{PACKAGE_NAME}}.util;

public class ODataQueryBuilder {

    public static String buildFilter(Map<String, Object> filters) {
        return filters.entrySet().stream()
            .filter(e -> e.getValue() != null)
            .map(e -> {
                FieldMapping.FieldMeta meta = FieldMapping.resolve(e.getKey());
                if (meta == null) return null;
                return switch (meta.type()) {
                    case TEXT -> "contains(" + meta.apiFieldName() + ",'" + e.getValue() + "')";
                    case EXACT, IDENTITY -> meta.apiFieldName() + " eq '" + e.getValue() + "'";
                    case COMPARABLE -> meta.apiFieldName() + " eq " + e.getValue();
                    case DATE -> meta.apiFieldName() + " ge " + e.getValue();
                    case BOOLEAN -> meta.apiFieldName() + " eq " + e.getValue();
                };
            })
            .filter(Objects::nonNull)
            .collect(Collectors.joining(" and "));
    }

    public static Map<String, String> buildParams(String filter, String orderBy,
            int top, int skip) {
        Map<String, String> params = new LinkedHashMap<>();
        if (filter != null && !filter.isEmpty()) params.put("$filter", filter);
        if (orderBy != null) params.put("$orderby", orderBy);
        params.put("$top", String.valueOf(top));
        if (skip > 0) params.put("$skip", String.valueOf(skip));
        return params;
    }
}
```

## 5. Query Builder (REST Filter Params)

```java
package {{PACKAGE_NAME}}.util;

public class RestFilterBuilder {

    public static Map<String, String> buildParams(Map<String, Object> filters,
            int page, int pageSize) {
        Map<String, String> params = new LinkedHashMap<>();
        params.put("page", String.valueOf(page));
        params.put("pageSize", String.valueOf(pageSize));

        for (var entry : filters.entrySet()) {
            if (entry.getValue() != null) {
                params.put(entry.getKey(), entry.getValue().toString());
            }
        }
        return params;
    }
}
```

## Best Practices

1. **Always escape user input** — prevent SOQL/OData injection
2. **Map field types explicitly** — use a registry, never guess
3. **Cap pagination limits** — enforce safe maximums (1000 for SOQL, 5000 for OData)
4. **Format dates per API spec** — SOQL uses yyyy-MM-dd, OData uses ISO 8601
5. **Use parameterized queries where possible** — prefer API-native filtering over client-side
6. **Log queries without sensitive filter values** — redact PII from query logs

## Related Prompts

- [Prompt 05: QUERY_SYSTEM Request](05-add-query-system-request.md) — pagination patterns
- [Prompt 34: Database SQL](34-database-sql-integration.md) — SQL query patterns
- [Prompt 38: CRM Field Mapping](38-crm-field-mapping.md) — entity field mapping
```
