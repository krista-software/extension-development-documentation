# Prompt 34: Database Connection Pooling and SQL Execution

## Purpose

Implement a database integration extension with connection pooling, parameterized queries, batch execution, result set mapping, and async query support. Covers both single-database and multi-database configurations.

## Prerequisites

- Existing extension project with Gradle
- JDBC driver for your target database
- HikariCP for connection pooling

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `SQL` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.sql` |
| Database Type | `{{DB_TYPE}}` | `PostgreSQL` / `MySQL` / `SQLServer` |

---

## Prompt

```
I need you to implement a database integration for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}
- **Database**: {{DB_TYPE}}

## 1. Connection Pool Manager

```java
package {{PACKAGE_NAME}}.impl;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.util.concurrent.ConcurrentHashMap;

public class ConnectionPoolManager {
    private final ConcurrentHashMap<String, HikariDataSource> pools = new ConcurrentHashMap<>();

    public Connection getConnection(String connectionKey, DatabaseConfig config) throws Exception {
        HikariDataSource pool = pools.computeIfAbsent(connectionKey, key -> {
            HikariConfig hikariConfig = new HikariConfig();
            hikariConfig.setJdbcUrl(config.getJdbcUrl());
            hikariConfig.setUsername(config.getUsername());
            hikariConfig.setPassword(config.getPassword());
            hikariConfig.setMaximumPoolSize(10);
            hikariConfig.setConnectionTimeout(30000);
            hikariConfig.setIdleTimeout(600000);
            return new HikariDataSource(hikariConfig);
        });
        return pool.getConnection();
    }

    public void shutdown() {
        pools.values().forEach(HikariDataSource::close);
        pools.clear();
    }
}
```

## 2. Input Sanitization

```java
package {{PACKAGE_NAME}}.util;

public class InputSanitizer {
    private static final int MAX_QUERY_LENGTH = 50_000;
    private static final int MAX_TABLE_NAME_LENGTH = 128;

    public static String sanitizeQuery(String query) {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");
        String decoded = decodeHtmlEntities(query);
        if (decoded.length() > MAX_QUERY_LENGTH)
            throw new IllegalArgumentException("Query exceeds maximum length");
        detectDangerousPatterns(decoded);
        return decoded.trim();
    }

    public static String sanitizeTableName(String name) {
        if (name == null || !name.matches("^[a-zA-Z][a-zA-Z0-9_.]{0," + MAX_TABLE_NAME_LENGTH + "}$"))
            throw new IllegalArgumentException("Invalid table name: " + name);
        return name;
    }

    private static void detectDangerousPatterns(String input) {
        String upper = input.toUpperCase();
        String[] dangerous = {"XP_CMDSHELL", "SP_EXECUTESQL", "OPENROWSET", "EXEC("};
        for (String pattern : dangerous) {
            if (upper.contains(pattern))
                throw new IllegalArgumentException("Query contains disallowed function: " + pattern);
        }
        // Detect multi-statement injection
        if (input.contains(";") && upper.matches(".*;\\s*(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER).*"))
            throw new IllegalArgumentException("Multi-statement queries are not allowed");
    }

    private static String decodeHtmlEntities(String input) {
        return input.replace("&gt;", ">").replace("&lt;", "<")
            .replace("&amp;", "&").replace("&quot;", "\"");
    }
}
```

## 3. Result Set Mapper

```java
package {{PACKAGE_NAME}}.util;

import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class ResultSetMapper {
    private static final SimpleDateFormat TIMESTAMP_FORMAT =
        new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");

    public static List<Map<String, Object>> map(ResultSet rs, int maxRows) throws Exception {
        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();
        List<String> columns = new ArrayList<>();
        for (int i = 1; i <= columnCount; i++) {
            columns.add(meta.getColumnLabel(i));
        }

        List<Map<String, Object>> rows = new ArrayList<>();
        int count = 0;
        while (rs.next() && count < maxRows) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 0; i < columns.size(); i++) {
                Object value = rs.getObject(i + 1);
                if (value instanceof Timestamp) {
                    value = TIMESTAMP_FORMAT.format(value);
                } else if (value instanceof java.sql.Date) {
                    value = value.toString();
                }
                row.put(columns.get(i), value);
            }
            rows.add(row);
            count++;
        }
        return rows;
    }
}
```

## 4. Batch Executor

```java
package {{PACKAGE_NAME}}.impl;

import java.sql.*;
import java.util.List;

public class BatchExecutor {
    public int[] executeBatch(Connection conn, String sql,
            List<List<Object>> batchParameters) throws Exception {
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (List<Object> params : batchParameters) {
                for (int i = 0; i < params.size(); i++) {
                    stmt.setObject(i + 1, params.get(i));
                }
                stmt.addBatch();
            }
            return stmt.executeBatch();
        }
    }
}
```

## 5. Catalog Requests

### Execute Query (sync)

```java
@CatalogRequest(
    id = "localDomainRequest_{{UUID}}",
    name = "Execute SQL Query",
    description = "Execute a read-only SQL query and return results",
    area = "SQL",
    type = CatalogRequest.Type.QUERY_SYSTEM, tool = true)
@Field(name = "Query Results", type = "FreeForm", required = false,
    attributes = {}, options = {})
public ExtensionResponse executeQuery(
        @Field(name = "SQL Query", type = "Paragraph", required = true,
            attributes = {@Attribute(name = "visualWidth", value = "XL")},
            options = {}) String query,
        @Field(name = "Max Rows", type = "Number", required = false,
            attributes = {@Attribute(name = "visualWidth", value = "S")},
            options = {}) Double maxRows) {

    String sanitized = InputSanitizer.sanitizeQuery(query);
    int limit = maxRows != null ? maxRows.intValue() : 1000;

    try (Connection conn = poolManager.getConnection(connectionKey, config);
         PreparedStatement stmt = conn.prepareStatement(sanitized);
         ResultSet rs = stmt.executeQuery()) {

        List<Map<String, Object>> results = ResultSetMapper.map(rs, limit);
        return ExtensionResponseFactory.create(Map.of("Query Results", results));

    } catch (Exception e) {
        return ExtensionResponseFactory.create(e, "Query failed", SYSTEM_ERROR);
    }
}
```

## 6. Cleanup

```java
@InvokerRequest(InvokerRequest.Type.INVOKER_REMOVED)
public void onRemoved() {
    poolManager.shutdown();
}
```

## Best Practices

1. **Always use parameterized queries** — never concatenate user input into SQL
2. **Sanitize all inputs** — detect dangerous functions, multi-statement injection, HTML entities
3. **Cap result sizes** — enforce max rows to prevent memory exhaustion
4. **Use connection pooling** — never create connections per request
5. **Close resources in finally/try-with-resources** — prevent connection leaks
6. **Sanitize log output** — redact connection keys and credentials
7. **Shutdown pools on INVOKER_REMOVED** — prevent orphaned connections

## Related Prompts

- [Prompt 31: KeyValueStore](31-keyvaluestore-patterns.md) — credential storage
- [Prompt 32: Async Catalog Request](32-async-catalog-request.md) — for long-running queries
- [Prompt 36: Input Sanitization](36-input-sanitization-security.md) — sanitization patterns
```
