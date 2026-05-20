# Extension Architecture and Design Patterns Guide

## Overview

This guide documents the architectural patterns, design principles, and best practices for developing Krista extensions. These patterns have been proven through real implementations and code reviews.

---

## Package Structure Conventions

### Standard Package Hierarchy

Follow the established pattern used across all Krista extensions:

```
app.krista.extensions.{ecosystem}.{domain}.{extension}.{subpackage}
```

**Examples:**
- `app.krista.extensions.essentials.cloudfiles.ftp.catalog.FTPArea`
- `app.krista.extensions.essentials.cloudfiles.ftp.catalog.extresp.ExtensionResponseFactory`
- `app.krista.extensions.essentials.cloudfiles.ftp.connection.FtpConnectionManager`

### Research Before Creating

**ALWAYS** research existing extensions before creating new packages:

```bash
# Check MS Excel extension structure
git ls-tree -r --name-only origin/release/msexcel | grep "\.java$"

# Check other extensions for patterns
git ls-tree -r --name-only origin/release/salesforce_customer_service | grep "\.java$"
```

### Common Subpackages

| Subpackage | Purpose | Example |
|------------|---------|---------|
| `catalog` | Main catalog request classes | `FTPArea.java` |
| `catalog.extresp` | Response factories and builders | `ExtensionResponseFactory.java` |
| `catalog.helpers` | Helper classes for catalog logic | `UploadRequestValidator.java` |
| `connection` | Connection management utilities | `FtpConnectionManager.java` |
| `impl` | Service implementations | `FtpServiceImpl.java` |
| `utils` | Utility classes and constants | `Constants.java`, `FtpResponseBuilder.java` |

---

## Connection Management Patterns

### Template Method Pattern

Use the template method pattern to eliminate boilerplate connection code:

```java
// BAD - Repeated boilerplate
public List<String> getFiles() {
    FTPClient ftpClient = null;
    try {
        ftpClient = createFtpClient(ftpAttributes);
        connectToFTPServer(ftpClient, ftpAttributes);
        changeWorkingDirectory(remotePath);
        // ... actual operation
    } finally {
        closeFtpConnection(ftpClient);
    }
}

// GOOD - Template method pattern
public List<String> getFiles() {
    return FtpConnectionManager.executeWithConnectionAndDirectory(
        ftpAttributes, remotePath, 
        ftpClient -> {
            // Just the actual operation logic
            return ftpClient.listFiles();
        }
    );
}
```

### Connection Manager Implementation

```java
public class FtpConnectionManager {
    @FunctionalInterface
    public interface FtpOperation<T> {
        T execute(FTPClient ftpClient) throws Exception;
    }

    public static <T> T executeWithConnection(FtpAttributes ftpAttributes, 
                                            FtpOperation<T> operation) throws Exception {
        FTPClient ftpClient = null;
        try {
            ftpClient = createFtpClient(ftpAttributes);
            connectToFTPServer(ftpClient, ftpAttributes);
            return operation.execute(ftpClient);
        } finally {
            closeFtpConnection(ftpClient);
        }
    }
}
```

### Benefits

- **DRY Principle**: Eliminates repeated connection setup code
- **Consistent Error Handling**: Centralized connection cleanup
- **Maintainability**: Changes to connection logic in one place
- **Testability**: Connection logic can be tested separately

---

## Error Handling Best Practices

### Fail-Fast Principle

**ALWAYS** stop on first failure for file system operations:

```java
// CORRECT - Fail fast
private boolean deleteDirectoryContents(FTPClient ftpClient, String path) {
    for (FTPFile file : ftpClient.listFiles(path)) {
        if (!ftpClient.deleteFile(file.getName())) {
            LOGGER.error("Failed to delete file: {}", file.getName());
            return false; // Stop here - don't continue
        }
    }
    return true;
}

// WRONG - Continue on failure (masks problems)
private boolean deleteDirectoryContents(FTPClient ftpClient, String path) {
    boolean allSuccess = true;
    for (FTPFile file : ftpClient.listFiles(path)) {
        if (!ftpClient.deleteFile(file.getName())) {
            allSuccess = false; // Continue anyway - BAD!
        }
    }
    return allSuccess;
}
```

### Error Response Standards

Provide detailed, actionable error information:

```java
public static Map<String, Object> failure(String operation, String message, 
                                        String code, String protocol, 
                                        String path, long duration) {
    Map<String, Object> result = new HashMap<>();
    result.put("success", false);
    result.put("operation", operation);
    result.put("message", message);
    result.put("errorCode", code);
    result.put("protocol", protocol);
    result.put("path", path);
    result.put("duration", duration);
    result.put("timestamp", System.currentTimeMillis());
    return result;
}
```

### Logging Standards

- **ERROR**: For actual failures that stop operations
- **WARN**: For recoverable issues or unexpected but handled conditions
- **INFO**: For successful operations and major workflow steps
- **DEBUG**: For detailed tracing and troubleshooting

---

## Separation of Concerns

### Break Down Large Methods

**Maximum method sizes:**
- Catalog request methods: 30 lines
- Private helper methods: 50 lines
- If longer: Break into focused helper classes

### Helper Class Pattern

```java
// Before: 80-line monolithic method
public ExtensionResponse uploadFile(File file, String path, Boolean overwrite) {
    // 80 lines of mixed validation, logging, business logic, response handling
}

// After: Clean separation with helper classes
public ExtensionResponse uploadFile(File file, String path, Boolean overwrite) {
    // Validate inputs
    ValidationResult validation = UploadRequestValidator.validateUploadRequest(file, path);
    if (!validation.isValid()) {
        return ExtensionResponseFactory.create(Map.of("result", validation.getErrorResult()));
    }

    // Log operation start
    FtpDebugLogger.logUploadStart(file.getFileName(), path, overwrite, ftpAttributes);

    // Execute operation
    Map<String, Object> result = ftpService.uploadFile(file, uploadDetails, ftpAttributes);

    // Enhance response
    Map<String, Object> enhanced = UploadResponseEnhancer.enhanceUploadResult(result, file, path, overwrite);
    return ExtensionResponseFactory.create(Map.of("result", enhanced));
}
```

### Helper Class Organization

| Helper Type | Purpose | Example |
|-------------|---------|---------|
| Validators | Input validation and error responses | `UploadRequestValidator` |
| Enhancers | Response processing and metadata | `UploadResponseEnhancer` |
| Loggers | Debug and operational logging | `FtpDebugLogger` |
| Builders | Complex object construction | `FtpResponseBuilder` |

---

## Testing Requirements

### No Mocks Policy

**NEVER use mocks** - they hide real issues and don't test actual behavior:

```java
// WRONG - Mocked test
@Test
public void testUpload() {
    FTPClient mockClient = mock(FTPClient.class);
    when(mockClient.storeFile(any(), any())).thenReturn(true);
    // This doesn't test real FTP behavior!
}

// CORRECT - Integration test
@Test
public void testUpload() {
    // Use embedded FTP server or test container
    FtpTestServer testServer = new FtpTestServer();
    testServer.start();
    
    // Test against real FTP implementation
    Map<String, Object> result = ftpService.uploadFile(testFile, uploadDetails, ftpAttributes);
    
    // Verify actual file was uploaded
    assertTrue(testServer.fileExists("/test/uploaded-file.txt"));
}
```

### Test Categories

1. **Integration Tests**: End-to-end workflows with real services
2. **Logic Tests**: Business rules and validation without external dependencies
3. **Performance Tests**: Realistic data sizes and scenarios

### Test Environment Setup

```java
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class FtpServiceIntegrationTest {
    private FtpTestServer ftpServer;
    
    @BeforeAll
    void setupTestServer() {
        ftpServer = new FtpTestServer();
        ftpServer.addUser("testuser", "testpass");
        ftpServer.start();
    }
    
    @AfterAll
    void teardownTestServer() {
        ftpServer.stop();
    }
}
```

---

## Version Management

### Manual Version Control

Disable auto-increment when manual control is needed:

```gradle
// Comment out auto-update dependencies
// NOTE: Auto-update disabled to maintain manual version control
// tasks.compileJava {
//     dependsOn 'updateVersion'
// }
```

### Version Consistency

Ensure all files have matching versions:
- `@Extension(version = "X.Y.Z")` in main extension class
- `patch=Z` in `version.properties`
- `extension.version=X.Y.Z` in `release.properties`

---

## Common Anti-Patterns to Avoid

### ❌ Test Methods in Production
```java
// NEVER do this
@CatalogRequest(name = "Test Connection")
public ExtensionResponse testConnection() { ... }
```

### ❌ Boilerplate Duplication
```java
// Don't repeat connection setup in every method
ftpClient = createFtpClient(ftpAttributes);
connectToFTPServer(ftpClient, ftpAttributes);
```

### ❌ Large Monolithic Methods
```java
// Don't create 80+ line methods with mixed concerns
public ExtensionResponse doEverything() {
    // validation + logging + business logic + response handling
}
```

### ❌ Continue on Failure
```java
// Don't mask failures by continuing operations
if (!deleteFile(fileName)) {
    continue; // BAD - hides the problem
}
```

---

## Summary

Following these patterns will result in:
- ✅ Maintainable, testable code
- ✅ Consistent architecture across extensions
- ✅ Faster code reviews and approvals
- ✅ Reduced technical debt
- ✅ Better error handling and debugging

**Remember: Quality over speed. Take time to implement these patterns correctly.**
