# Prompt 22: Architecture and Design Patterns

## Purpose

Establish proper architectural patterns, package structure, and design principles for Krista extensions. Following these patterns ensures maintainable, consistent, and high-quality extension code.

## Prerequisites

- Understanding of Java package conventions
- Familiarity with design patterns (Template Method, Factory, etc.)
- Basic knowledge of Krista extension structure

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `ECOSYSTEM` | Ecosystem name | `essentials` |
| `DOMAIN` | Domain name | `cloudfiles` |
| `EXTENSION_NAME` | Extension identifier | `ftp` |

## Package Structure Convention

### Standard Package Hierarchy

```
app.krista.extensions.{ecosystem}.{domain}.{extension}/
├── {Extension}.java                    # Main extension class
├── {Extension}Attributes.java          # Extension attributes/config
├── catalog/
│   ├── {Area}Area.java                 # Catalog area definitions
│   ├── helper/
│   │   ├── {Request}Helper.java        # Request-specific helpers
│   │   └── ValidationHelper.java       # Validation utilities
│   └── extresp/
│       └── ExtensionResponseFactory.java  # Response factory
├── service/
│   ├── {Service}Service.java           # Business logic services
│   └── impl/
│       └── {Service}ServiceImpl.java   # Service implementations
├── connection/
│   ├── ConnectionManager.java          # Connection lifecycle
│   └── {Protocol}Client.java           # Protocol-specific clients
├── model/
│   ├── {Entity}.java                   # Data models
│   └── dto/
│       └── {DataTransfer}.java         # DTOs for external APIs
├── util/
│   ├── Constants.java                  # Extension constants
│   └── {Utility}Utils.java             # Utility classes
└── exception/
    └── {Extension}Exception.java       # Custom exceptions
```

### Example: FTP Extension

```
app.krista.extensions.essentials.cloudfiles.ftp/
├── FtpExtension.java
├── FtpExtensionAttributes.java
├── catalog/
│   ├── FilesArea.java
│   ├── helper/
│   │   ├── UploadFileHelper.java
│   │   ├── DownloadFileHelper.java
│   │   └── ListFilesHelper.java
│   └── extresp/
│       └── ExtensionResponseFactory.java
├── service/
│   ├── FtpService.java
│   └── impl/
│       └── FtpServiceImpl.java
├── connection/
│   ├── FtpConnectionManager.java
│   └── FtpClientFactory.java
└── util/
    └── FtpConstants.java
```

## Design Patterns

### 1. Template Method Pattern (Connection Management)

```java
public abstract class ConnectionManager<T> {
    
    public <R> R executeWithConnection(ConnectionConfig config, 
            ConnectionOperation<T, R> operation) {
        T connection = null;
        try {
            connection = createConnection(config);
            connect(connection, config);
            return operation.execute(connection);
        } finally {
            closeConnection(connection);
        }
    }
    
    protected abstract T createConnection(ConnectionConfig config);
    protected abstract void connect(T connection, ConnectionConfig config);
    protected abstract void closeConnection(T connection);
}

// Usage
public class FtpConnectionManager extends ConnectionManager<FTPClient> {
    
    public static <R> R executeWithConnectionAndDirectory(
            FtpAttributes attrs, String remotePath, 
            FtpOperation<R> operation) {
        return new FtpConnectionManager().executeWithConnection(attrs, client -> {
            changeWorkingDirectory(client, remotePath);
            return operation.execute(client);
        });
    }
    
    @Override
    protected FTPClient createConnection(ConnectionConfig config) {
        return new FTPClient();
    }
    
    @Override
    protected void connect(FTPClient client, ConnectionConfig config) {
        client.connect(config.getHost(), config.getPort());
        client.login(config.getUsername(), config.getPassword());
    }
    
    @Override
    protected void closeConnection(FTPClient client) {
        if (client != null && client.isConnected()) {
            try {
                client.logout();
                client.disconnect();
            } catch (IOException e) {
                LOGGER.warn("Error closing FTP connection", e);
            }
        }
    }
}
```

### 2. Factory Pattern (Response Creation)

```java
public class ExtensionResponseFactory {
    
    public static ExtensionResponse create(Map<String, Object> responseData) {
        return new ExtensionResponse(
            ExtensionResponse.Result.SUCCESS,
            responseData,
            null, null, null
        );
    }
    
    public static ExtensionResponse createError(String message, 
            ExtensionResponse.Error.ExceptionType type) {
        return new ExtensionResponse(
            ExtensionResponse.Result.ERROR,
            null,
            new ExtensionResponse.Error(type, message),
            null, null
        );
    }
    
    public static ExtensionResponse createWithRemediation(
            Map<String, Object> data, List<RemediationAction> actions) {
        return new ExtensionResponse(
            ExtensionResponse.Result.SUCCESS,
            data,
            null,
            actions,
            null
        );
    }
}
```

### 3. Helper Class Pattern (Request Processing)

```java
public class UploadFileHelper {
    
    private final FtpService ftpService;
    private final ValidationHelper validationHelper;
    
    public UploadFileHelper(FtpService ftpService, ValidationHelper validationHelper) {
        this.ftpService = ftpService;
        this.validationHelper = validationHelper;
    }
    
    public Map<String, Object> execute(File file, String remotePath) {
        // 1. Validate inputs
        validationHelper.validateFile(file);
        validationHelper.validatePath(remotePath);
        
        // 2. Execute operation
        UploadResult result = ftpService.uploadFile(file, remotePath);
        
        // 3. Build response
        return buildResponse(result);
    }
    
    private Map<String, Object> buildResponse(UploadResult result) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", result.isSuccess());
        response.put("fileName", result.getFileName());
        response.put("remotePath", result.getRemotePath());
        response.put("fileSize", result.getFileSize());
        response.put("uploadTime", result.getUploadTime());
        return response;
    }
}
```

## Error Handling Best Practices

### Fail-Fast Principle

```java
public class FileOperationHelper {

    public boolean deleteFiles(List<String> fileNames) {
        for (String fileName : fileNames) {
            if (!deleteFile(fileName)) {
                // FAIL FAST - Stop on first failure
                LOGGER.error("Failed to delete file: {}", fileName);
                return false;  // Don't continue with remaining files
            }
        }
        return true;
    }
}
```

### Error Categorization

```java
public enum ErrorCategory {
    INPUT_ERROR,      // Invalid user input
    LOGIC_ERROR,      // Business rule violation
    SYSTEM_ERROR,     // Infrastructure/system failure
    AUTH_ERROR        // Authentication/authorization failure
}

public ExtensionResponse handleError(Exception e, ErrorCategory category) {
    LOGGER.error("Error occurred: {} - {}", category, e.getMessage(), e);

    return ExtensionResponseFactory.createError(
        e.getMessage(),
        mapToExceptionType(category)
    );
}
```

## Testing Requirements

### No Mocks Policy

```java
// ❌ WRONG - Don't use mocks
@Test
public void testUploadFile_WithMock() {
    FtpService mockService = mock(FtpService.class);
    when(mockService.uploadFile(any(), any())).thenReturn(true);
    // This hides real issues!
}

// ✅ CORRECT - Use real integration tests
@Test
public void testUploadFile_Integration() {
    // Use embedded FTP server or test environment
    FakeFtpServer ftpServer = new FakeFtpServer();
    ftpServer.addUserAccount(new UserAccount("user", "password", "/"));
    ftpServer.start();

    try {
        FtpService service = new FtpServiceImpl(createTestConfig(ftpServer.getServerControlPort()));
        boolean result = service.uploadFile(testFile, "/upload");
        assertTrue(result);
    } finally {
        ftpServer.stop();
    }
}
```

## Validation Checklist

- [ ] Package structure follows `app.krista.extensions.{ecosystem}.{domain}.{extension}` convention
- [ ] Connection management uses Template Method pattern
- [ ] Response creation uses Factory pattern
- [ ] Helper classes separate business logic from catalog requests
- [ ] Error handling follows fail-fast principle
- [ ] Tests use real integration testing (no mocks)

## Best Practices

1. **Research existing extensions** before creating new packages
2. **Keep catalog request methods under 30 lines** - delegate to helpers
3. **Use dependency injection** for services and helpers
4. **Document architectural decisions** in code comments
5. **Follow consistent naming conventions** across the extension

## Related Prompts

- [Prompt 11: Add Helper Class](11-add-helper-class.md)
- [Prompt 16: Implement Error Handling](16-implement-error-handling.md)
- [Prompt 18: Write Unit Tests](18-write-unit-tests.md)
- [Prompt 28: PR Requirements](28-pr-requirements.md)
```

