# Prompt 23: Dynamic Log Level Configuration

## Purpose

Implement dynamic log level configuration in Krista extensions, allowing runtime adjustment of logging verbosity for debugging and troubleshooting without code changes or redeployment.

## Prerequisites

- Existing Krista extension
- Understanding of SLF4J and Logback
- Extension attributes configuration

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `EXTENSION_NAME` | Name of the extension | `FtpExtension` |
| `PACKAGE_NAME` | Base package for logging | `app.krista.extensions.essentials.cloudfiles.ftp` |

## Implementation

### Step 1: Create LogLevelManager

```java
package app.krista.extensions.{ecosystem}.{domain}.{extension}.util;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import org.slf4j.LoggerFactory;

public class LogLevelManager {
    
    private static final org.slf4j.Logger LOGGER = LoggerFactory.getLogger(LogLevelManager.class);
    
    public enum LogLevel {
        TRACE, DEBUG, INFO, WARN, ERROR, OFF
    }
    
    /**
     * Sets the log level for a specific package or class.
     * 
     * @param loggerName The fully qualified logger name (package or class)
     * @param level The desired log level
     */
    public static void setLogLevel(String loggerName, LogLevel level) {
        try {
            LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
            Logger logger = loggerContext.getLogger(loggerName);
            
            Level logbackLevel = mapToLogbackLevel(level);
            logger.setLevel(logbackLevel);
            
            LOGGER.info("Log level for '{}' set to '{}'", loggerName, level);
        } catch (Exception e) {
            LOGGER.error("Failed to set log level for '{}': {}", loggerName, e.getMessage());
        }
    }
    
    /**
     * Sets the log level for the entire extension package.
     */
    public static void setExtensionLogLevel(String basePackage, LogLevel level) {
        setLogLevel(basePackage, level);
    }
    
    /**
     * Resets log level to default (inherits from parent).
     */
    public static void resetLogLevel(String loggerName) {
        try {
            LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
            Logger logger = loggerContext.getLogger(loggerName);
            logger.setLevel(null); // Inherit from parent
            
            LOGGER.info("Log level for '{}' reset to inherit from parent", loggerName);
        } catch (Exception e) {
            LOGGER.error("Failed to reset log level for '{}': {}", loggerName, e.getMessage());
        }
    }
    
    private static Level mapToLogbackLevel(LogLevel level) {
        return switch (level) {
            case TRACE -> Level.TRACE;
            case DEBUG -> Level.DEBUG;
            case INFO -> Level.INFO;
            case WARN -> Level.WARN;
            case ERROR -> Level.ERROR;
            case OFF -> Level.OFF;
        };
    }
}
```

### Step 2: Add Log Level to Extension Attributes

```java
@ExtensionAttributes
public class {EXTENSION_NAME}Attributes {
    
    private final Invoker invoker;
    
    public {EXTENSION_NAME}Attributes(Invoker invoker) {
        this.invoker = invoker;
    }
    
    // ... other attribute methods ...
    
    /**
     * Gets the configured log level for debugging.
     * Default: INFO
     */
    public LogLevelManager.LogLevel getLogLevel() {
        String level = invoker.getAttributes().get("logLevel");
        if (level == null || level.isEmpty()) {
            return LogLevelManager.LogLevel.INFO;
        }
        try {
            return LogLevelManager.LogLevel.valueOf(level.toUpperCase());
        } catch (IllegalArgumentException e) {
            return LogLevelManager.LogLevel.INFO;
        }
    }
}
```

### Step 3: Initialize Log Level in Extension Constructor

```java
@Extension(version = "1.0.0", name = "{extension-name}")
public class {EXTENSION_NAME} {
    
    private static final Logger LOGGER = LoggerFactory.getLogger({EXTENSION_NAME}.class);
    private static final String BASE_PACKAGE = "app.krista.extensions.{ecosystem}.{domain}.{extension}";
    
    private final {EXTENSION_NAME}Attributes attributes;
    
    @Inject
    public {EXTENSION_NAME}(Invoker invoker) {
        this.attributes = new {EXTENSION_NAME}Attributes(invoker);
        
        // Initialize log level from configuration
        initializeLogLevel();
    }
    
    private void initializeLogLevel() {
        LogLevelManager.LogLevel configuredLevel = attributes.getLogLevel();
        LogLevelManager.setExtensionLogLevel(BASE_PACKAGE, configuredLevel);
        LOGGER.info("Extension initialized with log level: {}", configuredLevel);
    }
}
```

### Step 4: Add Catalog Request for Runtime Log Level Change

```java
@CatalogRequest(
    id = "localDomainRequest_set-log-level",
    name = "Set Log Level",
    description = "Dynamically set the extension log level for debugging",
    area = "Administration",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field.Desc(name = "Result", type = "Text", required = false)
public ExtensionResponse setLogLevel(
        @Field.PickOne(name = "Log Level", 
            values = {"TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF"}, 
            required = true) String logLevel) {
    
    try {
        LogLevelManager.LogLevel level = LogLevelManager.LogLevel.valueOf(logLevel);
        LogLevelManager.setExtensionLogLevel(BASE_PACKAGE, level);
        
        return ExtensionResponseFactory.create(
            Map.of("Result", "Log level set to: " + logLevel));
    } catch (Exception e) {
        return ExtensionResponseFactory.createError(
            "Failed to set log level: " + e.getMessage(),
            ExtensionResponse.Error.ExceptionType.INPUT_ERROR);
    }
}
```

## Validation Checklist

- [ ] LogLevelManager class created with proper Logback integration
- [ ] Extension attributes includes logLevel configuration
- [ ] Extension constructor initializes log level on startup
- [ ] Optional: Catalog request added for runtime log level changes
- [ ] Log statements use appropriate levels (TRACE for detailed, DEBUG for flow, INFO for operations)

## Best Practices

1. **Use appropriate log levels**: TRACE for detailed diagnostics, DEBUG for flow, INFO for operations
2. **Don't log sensitive data**: Never log passwords, tokens, or PII
3. **Include context**: Log operation names, IDs, and relevant parameters
4. **Default to INFO**: Use INFO as the default level for production

## Related Prompts

- [Prompt 1: Create Extension with OAuth 2.0](01-create-extension-oauth2.md)
- [Prompt 16: Implement Error Handling](16-implement-error-handling.md)
- [Prompt 22: Architecture and Design Patterns](22-architecture-design-patterns.md)

