# Prompt 28: PR Requirements & Quality Standards

## Purpose

Ensure pull requests meet Krista's quality standards before submission, covering code quality, architecture, testing, and documentation requirements.

## Prerequisites

- Completed extension implementation
- Access to run Gradle builds
- Understanding of Krista coding standards

---

## Prompt

```
I need to review my Krista extension code before submitting a pull request. Please verify it meets all quality standards.

## Pre-Submission Checklist

### 1. Code Quality Standards

#### ❌ CRITICAL: No Test Methods in Production Code
- [ ] No catalog requests marked as "test", "debug", or "connection test"
- [ ] All test code in `src/test/` directory
- [ ] Remove methods like `testConnection()`, `debugMethod()`

**Bad Example:**
```java
@CatalogRequest(name = "Test Connection", description = "Simple test method...")
public ExtensionResponse testConnection() { ... }  // ❌ REMOVE THIS
```

#### ❌ CRITICAL: Package Structure Conventions
- [ ] Package follows: `app.krista.extensions.{ecosystem}.{domain}.{extension}.{subpackage}`
- [ ] Researched existing extensions for proper hierarchy
- [ ] No custom package structures like `app.krista.extension.executor`

**Correct:** `app.krista.extensions.essentials.cloudfiles.ftp.catalog.helper`
**Wrong:** `app.krista.extension.executor.ExtensionResponseFactory`

#### ❌ CRITICAL: Version Consistency
- [ ] `@Extension(version = "X.Y.Z")` matches version.properties
- [ ] `patch=Z` in version.properties is correct
- [ ] `extension.version=X.Y.Z` in release.properties matches
- [ ] Auto-increment disabled if manual control needed

### 2. Code Organization

#### ⚠️ MAJOR: Eliminate Boilerplate
- [ ] Repeated patterns extracted to utility classes
- [ ] Connection management uses Template Method pattern
- [ ] No copy-paste code across methods

**Bad:**
```java
// Repeated in every method
ftpClient = createFtpClient(ftpAttributes);
connectToFTPServer(ftpClient, ftpAttributes);
// ... operation ...
closeFtpConnection(ftpClient);
```

**Good:**
```java
return FtpConnectionManager.executeWithConnection(ftpAttributes, ftpClient -> {
    // Just the actual operation logic
});
```

#### ⚠️ MAJOR: Method Size Limits
- [ ] Catalog request methods: Maximum 30 lines
- [ ] Private helper methods: Maximum 50 lines
- [ ] Large methods broken down with helper classes

### 3. Error Handling

#### ✅ RECOMMENDED: Fail-Fast Principle
- [ ] Stop on first failure for file system operations
- [ ] Clear, actionable error messages
- [ ] Appropriate log levels (ERROR for failures, WARN for recoverable)

```java
if (!deleteFile(fileName)) {
    LOGGER.error("Failed to delete file: {}", fileName);
    return false;  // Stop here, don't continue
}
```

### 4. Testing Requirements

#### ❌ CRITICAL: No Mocks Policy
- [ ] No mocks in tests - they hide real issues
- [ ] Integration tests for final mile testing
- [ ] Real behavior tested against actual services

**Bad:**
```java
FtpService mockService = mock(FtpService.class);  // ❌ NO MOCKS
```

**Good:**
```java
FakeFtpServer ftpServer = new FakeFtpServer();  // ✅ Real embedded server
```

### 5. Documentation

#### ⚠️ MAJOR: Implementation Documentation
- [ ] IMPLEMENTATION_DOC.md updated with changes
- [ ] Architectural decisions documented
- [ ] Complex business logic commented

### 6. Build Verification

#### ❌ CRITICAL: Compilation
- [ ] `./gradlew compileJava` runs successfully
- [ ] All compilation errors and warnings fixed
- [ ] Extension loads in runtime environment

## Common Rejection Reasons

### Immediate Rejection:
1. Test methods in production code
2. Wrong package structure
3. Version inconsistencies
4. Compilation failures

### Major Revision Required:
1. Excessive boilerplate code
2. Large, monolithic methods
3. Mocked tests instead of integration tests

Please review my code against these standards and identify any issues.
```

---

## Validation Checklist Summary

- [ ] All test methods removed from production code
- [ ] Package structure follows established conventions
- [ ] Version numbers consistent across all files
- [ ] Boilerplate code eliminated with utility classes
- [ ] Large methods broken down with helper classes
- [ ] No mocks in tests - real integration testing
- [ ] All code compiles successfully
- [ ] IMPLEMENTATION_DOC.md updated with changes
- [ ] Error handling follows fail-fast principle

## Related Prompts

- [Prompt 22: Architecture & Design Patterns](22-architecture-design-patterns.md)
- [Prompt 18: Write Unit Tests](18-write-unit-tests.md)
- [Prompt 19: Write Integration Tests](19-write-integration-tests.md)

