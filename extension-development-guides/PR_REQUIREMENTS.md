# Pull Request Requirements and Quality Standards

## Overview

This document outlines the mandatory requirements and quality standards that must be met before submitting a pull request. These standards are based on real code review feedback and common issues that cause PR rejections.

**Failure to meet these requirements will result in PR rejection and potential demotion.**

---

## 1. Code Quality Standards

### 1.1 No Test Methods in Production Code ❌ CRITICAL
- **NEVER** include catalog requests marked as "test", "debug", or "connection test" in production code
- Remove any methods with names like `testConnection()`, `debugMethod()`, etc.
- Keep all test code in proper test directories (`src/test/`)
- **Example of what NOT to do:**
  ```java
  @CatalogRequest(name = "Test Connection", description = "Simple test method...")
  public ExtensionResponse testConnection() { ... }
  ```

### 1.2 Follow Established Package Structure Conventions ❌ CRITICAL
- **ALWAYS** research existing extensions before creating new packages
- Check `origin/release/msexcel` or similar for proper package hierarchy
- **Correct pattern:** `app.krista.extensions.{ecosystem}.{domain}.{extension}.{subpackage}`
- **Example:** `app.krista.extensions.essentials.cloudfiles.ftp.catalog.extresp.ExtensionResponseFactory`
- **NOT:** `app.krista.extension.executor.ExtensionResponseFactory`

### 1.3 Version Management ❌ CRITICAL
- **Check release branch versioning** before setting version numbers
- Use `git show origin/release/{extension-name}` to find current version
- **Disable auto-increment** when manual version control is needed
- **Ensure consistency** across ALL files:
  - `@Extension(version = "X.Y.Z")` in main extension class
  - `patch=Z` in `version.properties`
  - `extension.version=X.Y.Z` in `release.properties`
- **Comment out auto-update dependencies** in `build.gradle`:
  ```gradle
  // NOTE: Auto-update disabled to maintain manual version control
  // tasks.compileJava {
  //     dependsOn 'updateVersion'
  // }
  ```

---

## 2. Code Organization & Architecture

### 2.1 Eliminate Boilerplate Code ⚠️ MAJOR
- **Identify repeated patterns** across methods (connection setup, error handling)
- **Create utility classes** or use template method pattern
- **Example of boilerplate to eliminate:**
  ```java
  // BAD - Repeated in every method
  ftpClient = createFtpClient(ftpAttributes);
  connectToFTPServer(ftpClient, ftpAttributes);
  changeWorkingDirectory(remotePath);
  // ... operation ...
  closeFtpConnection(ftpClient);
  ```
- **GOOD - Use connection manager:**
  ```java
  return FtpConnectionManager.executeWithConnectionAndDirectory(
      ftpAttributes, remotePath, ftpClient -> {
          // Just the actual operation logic
      });
  ```

### 2.2 Separation of Concerns ⚠️ MAJOR
- **Break down large methods** (>50 lines) using helper classes
- **Separate business logic** from infrastructure concerns
- **Use appropriate design patterns:**
  - Template Method for connection lifecycle
  - Factory for object creation
  - Builder for complex responses
- **Create helper classes** in appropriate subpackages

### 2.3 Method Size Limits
- **Catalog request methods:** Maximum 30 lines
- **Private helper methods:** Maximum 50 lines
- **If longer:** Break into smaller, focused methods with helper classes

---

## 3. Error Handling Best Practices

### 3.1 Fail-Fast Principle ✅ RECOMMENDED
- **Stop on first failure** for file system operations
- **Provide clear, actionable error messages**
- **Maintain predictable system state** after failures
- **DO NOT** continue operations after encountering errors
- **Example:**
  ```java
  if (!deleteFile(fileName)) {
      LOGGER.error("Failed to delete file: {}", fileName);
      return false; // Stop here, don't continue
  }
  ```

### 3.2 Error Reporting Standards
- **Log specific failure points** with context
- **Return detailed error responses** with operation codes
- **Include timing information** for performance analysis
- **Use appropriate log levels** (ERROR for failures, WARN for recoverable issues)

---

## 4. Testing Requirements

### 4.1 No Mocks Policy ❌ CRITICAL
- **NEVER use mocks** in tests - they hide real issues
- **Use integration tests** for final mile testing
- **Test real behavior** against actual services
- **Set up proper test environments:**
  - Embedded FTP servers for FTP testing
  - Test databases for database operations
  - Real file systems for file operations

### 4.2 Test Coverage Requirements
- **Test all new catalog requests** with real scenarios
- **Test error conditions** with actual failure cases
- **Test edge cases** (empty files, special characters, etc.)
- **Separate logic tests** from integration tests

### 4.3 Test Organization
- **Integration tests:** Test complete workflows end-to-end
- **Logic tests:** Test business rules and validation
- **Performance tests:** Test with realistic data sizes

---

## 5. Documentation Standards

### 5.1 Implementation Documentation ⚠️ MAJOR
- **Maintain IMPLEMENTATION_DOC.md** with every commit
- **Document architectural decisions** and reasoning
- **Include before/after comparisons** for refactoring
- **Required format:**
  ```markdown
  Commit: [Brief Description]
  Overview: [What was changed and why]
  
  Changes:
  File: [path] ([MODIFIED/NEW/DELETED])
  - [Specific change description]
  - [Impact and benefits]
  
  Benefits:
  - [Technical benefits]
  - [Maintainability improvements]
  
  Technical Details:
  - [Implementation specifics]
  - [Design patterns used]
  ```

### 5.2 Code Comments
- **Document complex business logic**
- **Explain non-obvious design decisions**
- **Include examples for public APIs**
- **Keep comments up-to-date** with code changes

---

## 6. Build & Deployment

### 6.1 Compilation Verification ❌ CRITICAL
- **ALWAYS run `./gradlew compileJava`** before submitting PR
- **Fix all compilation errors** and warnings
- **Test build process** after major refactoring
- **Verify extension loads** in runtime environment

### 6.2 Dependency Management
- **Use package managers** for dependency changes
- **NEVER manually edit** package.json, requirements.txt, etc.
- **Use appropriate commands:**
  - `npm install/uninstall`
  - `pip install/uninstall`
  - `gradle add/remove`

### 6.3 Gradle Wrapper Guidelines
- **Keep build configuration files** (build.gradle, version.properties, release.properties) in repository
- **Remove gradle wrapper executables** (gradlew, gradlew.bat) from version control if requested
- **Preserve gradle wrapper properties** (gradle/wrapper/gradle-wrapper.properties) for version consistency
- **Regenerate wrapper** using `gradle wrapper` command when needed

---

## 7. Pre-Submission Checklist

### Before Creating PR:
- [ ] All test methods removed from production code
- [ ] Package structure follows established conventions
- [ ] Version numbers consistent across all files
- [ ] Auto-increment versioning disabled if needed
- [ ] Boilerplate code eliminated with utility classes
- [ ] Large methods broken down with helper classes
- [ ] No mocks in tests - real integration testing
- [ ] All code compiles successfully
- [ ] IMPLEMENTATION_DOC.md updated with changes
- [ ] Error handling follows fail-fast principle
- [ ] Gradle wrapper executables removed if requested (keep build.gradle)

### During Code Review:
- [ ] Address feedback with technical reasoning
- [ ] Don't blindly follow suggestions - analyze if they're correct
- [ ] Maintain architectural integrity
- [ ] Document any decisions to reject feedback

---

## 8. Common Rejection Reasons

### Immediate Rejection:
1. Test methods in production code
2. Wrong package structure
3. Version inconsistencies
4. Compilation failures
5. Missing implementation documentation

### Major Revision Required:
1. Excessive boilerplate code
2. Large, monolithic methods
3. Poor separation of concerns
4. Mocked tests instead of integration tests
5. Inadequate error handling

### Minor Revision Required:
1. Missing code comments
2. Inconsistent naming
3. Performance concerns
4. Documentation gaps

---

## Remember: Quality Over Speed

**It's better to take time and get it right than to rush and face rejection.**

These standards exist to maintain code quality, ensure maintainability, and prevent technical debt. Following them will lead to faster PR approvals and better software architecture.
