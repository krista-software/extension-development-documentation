# Prompt 36: Input Sanitization and Security

## Purpose

Implement input sanitization, log sanitization, and security best practices for Krista extensions. Covers SQL injection prevention, path traversal protection, credential handling, and safe logging.

## Prerequisites

- Existing extension that accepts user input
- Understanding of the attack vectors relevant to your integration

## Input Parameters

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Extension Name | `{{EXTENSION_NAME}}` | `SQL` |
| Package Name | `{{PACKAGE_NAME}}` | `app.krista.extensions.sql` |

---

## Prompt

```
I need you to implement input sanitization and security patterns for my Krista extension.

## Extension Details

- **Extension Name**: {{EXTENSION_NAME}}
- **Package**: {{PACKAGE_NAME}}

## 1. Input Sanitizer

```java
package {{PACKAGE_NAME}}.util;

public class InputSanitizer {

    // --- Text input sanitization ---

    public static String sanitizeText(String input, int maxLength) {
        if (input == null) return null;
        String cleaned = input.trim();
        if (cleaned.length() > maxLength) {
            throw new IllegalArgumentException(
                "Input exceeds maximum length of " + maxLength);
        }
        return cleaned;
    }

    // --- Identifier sanitization (table names, field names, keys) ---

    public static String sanitizeIdentifier(String input, int maxLength) {
        if (input == null || !input.matches("^[a-zA-Z][a-zA-Z0-9_]{0," + maxLength + "}$")) {
            throw new IllegalArgumentException("Invalid identifier: " + input);
        }
        return input;
    }

    // --- Path sanitization (prevent traversal) ---

    public static String sanitizePath(String path) {
        if (path == null) return "";
        String normalized = path.trim()
            .replace("\\", "/")
            .replaceAll("/+", "/");

        // Block path traversal
        if (normalized.contains("..")) {
            throw new IllegalArgumentException("Path traversal not allowed");
        }
        return normalized;
    }

    // --- HTML entity decoding (before validation) ---

    public static String decodeHtmlEntities(String input) {
        if (input == null) return null;
        return input
            .replace("&gt;", ">").replace("&lt;", "<")
            .replace("&amp;", "&").replace("&quot;", "\"")
            .replace("&#39;", "'");
    }

    // --- SQL-specific sanitization ---

    public static String sanitizeQuery(String query, int maxLength) {
        String decoded = decodeHtmlEntities(sanitizeText(query, maxLength));
        detectDangerousPatterns(decoded);
        return decoded;
    }

    private static void detectDangerousPatterns(String input) {
        String upper = input.toUpperCase();

        // Dangerous functions
        String[] blocked = {"XP_CMDSHELL", "SP_EXECUTESQL", "OPENROWSET",
            "EXEC(", "EXECUTE(", "DBCC"};
        for (String fn : blocked) {
            if (upper.contains(fn))
                throw new IllegalArgumentException("Disallowed function: " + fn);
        }

        // Comment injection
        if (input.contains("--") || input.contains("/*") || input.contains("#"))
            throw new IllegalArgumentException("SQL comments not allowed");

        // Multi-statement injection
        if (input.contains(";")) {
            String afterSemicolon = upper.substring(upper.indexOf(';') + 1).trim();
            if (afterSemicolon.matches("^(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE).*"))
                throw new IllegalArgumentException("Multi-statement queries not allowed");
        }
    }
}
```

## 2. Log Sanitizer

```java
package {{PACKAGE_NAME}}.util;

public class LogSanitizer {

    public static String sanitizeForLog(String value) {
        if (value == null) return "[null]";
        // Truncate long values
        if (value.length() > 200) {
            return value.substring(0, 200) + "...[truncated]";
        }
        // Remove newlines to prevent log injection
        return value.replace("\n", " ").replace("\r", " ");
    }

    public static String redactSecret(String value) {
        if (value == null || value.length() < 8) return "***";
        return value.substring(0, 4) + "***" + value.substring(value.length() - 2);
    }

    public static String sanitizeErrorMessage(String message) {
        if (message == null) return "Unknown error";
        // Remove potential credential fragments
        return message.replaceAll("password=[^&\\s]+", "password=***")
            .replaceAll("token=[^&\\s]+", "token=***")
            .replaceAll("secret=[^&\\s]+", "secret=***");
    }
}
```

## 3. Security Checklist for Extensions

Apply these rules throughout your extension:

### Credentials
- Mark all credential fields with `isSecured = true`
- Store tokens in `KeyValueStore` (encrypted at rest)
- Use `remove()` not `put(null)` when clearing tokens
- Never log credential values — use `LogSanitizer.redactSecret()`

### User input
- Sanitize all text inputs before using in queries or paths
- Validate identifiers against allowlist patterns
- Decode HTML entities before validation
- Cap input lengths to prevent memory abuse
- Use parameterized queries — never concatenate input into SQL

### Logging
- Redact secrets in error messages
- Truncate long values to prevent log flooding
- Strip newlines to prevent log injection
- Never log entire attribute maps (may contain secrets)
- Log operation names and outcomes, not request payloads

### API communication
- Use HTTPS exclusively
- Validate TLS certificates (do not disable verification)
- Set connection and read timeouts
- Sanitize error responses before returning to users

### Webhook handlers
- Validate signatures before processing
- Return 200/202 quickly — process async if needed
- Treat all webhook payloads as untrusted input

## Best Practices

1. **Validate at system boundaries** — sanitize inputs at the Area class level
2. **Fail closed** — reject input on any validation failure
3. **Defense in depth** — sanitize at multiple layers (input, query, log)
4. **Log the attempt** — record sanitization rejections for security monitoring
5. **Keep sanitizers stateless** — use static utility methods
6. **Test with adversarial inputs** — include injection attempts in unit tests

## Related Prompts

- [Prompt 34: Database SQL](34-database-sql-integration.md) — SQL injection prevention
- [Prompt 35: Query Builder](35-api-query-builder.md) — query escaping
- [Prompt 16: Error Handling](16-implement-error-handling.md) — safe error messages
```
