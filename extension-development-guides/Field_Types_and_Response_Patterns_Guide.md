# Field Types and Response Patterns - Complete Guide

**🎯 CRITICAL:** This guide documents the exact patterns required for proper field display in Krista extensions. Wrong patterns result in empty/broken displays.

## Table of Contents
1. [Field Annotation Patterns](#field-annotation-patterns)
2. [Response Patterns](#response-patterns)
3. [FreeForm Fields (Critical)](#freeform-fields-critical)
4. [Common Mistakes](#common-mistakes)
5. [Complete Examples](#complete-examples)

---

## Field Annotation Patterns

### Simple Field Types

#### **Text Fields:**
```java
@Field.Desc(name = "Field Name", type = "Text", required = false)
@Field.Text(name = "Field Name", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})
```

#### **Number Fields:**
```java
@Field.Desc(name = "Field Name", type = "Number", required = false)
@Field(name = "Field Name", type = "Number", required = false, attributes = {}, options = {})
```

#### **Boolean Fields:**
```java
@Field.Desc(name = "Field Name", type = "Boolean", required = false)
@Field.Boolean(name = "Field Name", required = false, attributes = {}, options = {})
```

#### **Date Fields:**
```java
@Field.Desc(name = "Field Name", type = "Date", required = false)
@Field.Date(name = "Field Name", required = true, includeTimeOfDay = true, allowPast = true, allowToday = true, allowFuture = true, attributes = {}, options = {})
```

### List Field Types

#### **Text Lists:**
```java
@Field.Desc(name = "Field Name", type = "[ Text ]", required = false)
```

#### **Number Lists:**
```java
@Field.Desc(name = "Field Name", type = "[ Number ]", required = false)
```

#### **Date Lists:**
```java
@Field.Desc(name = "Field Name", type = "[ Date ]", required = false)
```

### Complex Field Types

#### **FreeForm (Complex Objects) - CRITICAL SYNTAX:**
```java
@Field(name = "Field Name", type = "FreeForm", required = false, attributes = {}, options = {})
```

#### **Composite Lists:**
```java
@Field.Desc(name = "Field Name", type = "[ Composite ]", required = false)
```

#### **Rich Text:**
```java
@Field(name = "Field Name", type = "RichText", required = false, attributes = {}, options = {})
```

#### **Paragraph:**
```java
@Field(name = "Field Name", type = "Paragraph", required = false, attributes = {}, options = {})
```

#### **Selection Fields:**
```java
@Field.PickOne(name = "Field Name", values = {"Option1", "Option2", "Option3"}, required = false, attributes = {}, options = {})
```

---

## Response Patterns

### Simple Response Pattern
```java
@Field.Desc(name = "Result", type = "Text", required = false)
public ExtensionResponse getSimpleData() {
    String result = "some data";
    return ExtensionResponseFactory.create(Map.of("Result", result));
}
```

### List Response Pattern
```java
@Field.Desc(name = "File Names", type = "[ Text ]", required = false)
public ExtensionResponse getFileNames() {
    List<String> fileNames = Arrays.asList("file1.txt", "file2.txt");
    return ExtensionResponseFactory.create(Map.of("File Names", fileNames));
}
```

### Multiple Field Response Pattern
```java
@Field.Desc(name = "Success", type = "Boolean", required = false)
@Field.Desc(name = "Message", type = "Text", required = false)
@Field.Desc(name = "File Count", type = "Number", required = false)
public ExtensionResponse getMultipleFields() {
    Map<String, Object> response = new HashMap<>();
    response.put("Success", true);
    response.put("Message", "Operation completed");
    response.put("File Count", 5);
    
    return ExtensionResponseFactory.create(response);
}
```

---

## FreeForm Fields (Critical)

### ✅ CORRECT FreeForm Pattern

#### **Field Annotation:**
```java
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
```

#### **Response Pattern:**
```java
public ExtensionResponse uploadFile() {
    // Build your complex result object
    Map<String, Object> result = new HashMap<>();
    result.put("success", true);
    result.put("fileName", "test.txt");
    result.put("fileSize", 1024);
    result.put("uploadTime", new Date().toString());
    result.put("remotePath", "/upload");
    result.put("metadata", Map.of("type", "document", "encrypted", false));
    
    // CRITICAL: Wrap result with field name as key
    return ExtensionResponseFactory.create(Map.of("Upload Result", result));
}
```

#### **What This Displays:**

**Form View:**
```
Upload Result
success: true
fileName: test.txt
fileSize: 1024
uploadTime: Sat Sep 07 10:00:00 PDT 2025
remotePath: /upload
metadata: {type=document, encrypted=false}
```

**JSON View:**
```json
{
  "success": true,
  "fileName": "test.txt",
  "fileSize": 1024,
  "uploadTime": "Sat Sep 07 10:00:00 PDT 2025",
  "remotePath": "/upload",
  "metadata": {
    "type": "document",
    "encrypted": false
  }
}
```

### ❌ WRONG FreeForm Patterns (Will Show Empty Results)

#### **Wrong Field Annotation:**
```java
// BROKEN - Missing attributes and options
@Field.Desc(name = "Upload Result", type = "FreeForm", required = false)

// BROKEN - Using @Field.Desc instead of @Field
@Field.Desc(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
```

#### **Wrong Response Patterns:**
```java
// BROKEN - Missing field name wrapper
return ExtensionResponseFactory.create(result);

// BROKEN - Wrong response builder
return new ExtensionResponseBuilder().success(result).build();

// BROKEN - Wrong field name wrapper
return ExtensionResponseFactory.create(Map.of("Wrong Name", result));
```

---

## Common Mistakes

### 1. FreeForm Field Annotation Mistakes
```java
// ❌ WRONG - Will not display
@Field.Desc(name = "Result", type = "FreeForm", required = false)

// ✅ CORRECT - Will display properly
@Field(name = "Result", type = "FreeForm", required = false, attributes = {}, options = {})
```

### 2. Response Wrapping Mistakes
```java
// ❌ WRONG - Missing field name wrapper
return ExtensionResponseFactory.create(result);

// ✅ CORRECT - Wrapped with field name
return ExtensionResponseFactory.create(Map.of("Field Name", result));
```

### 3. Field Name Mismatch
```java
// Field annotation
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})

// ❌ WRONG - Field name doesn't match
return ExtensionResponseFactory.create(Map.of("Result", data));

// ✅ CORRECT - Field name matches exactly
return ExtensionResponseFactory.create(Map.of("Upload Result", data));
```

### 4. Response Builder Confusion
```java
// ❌ WRONG for FreeForm - Use ExtensionResponseFactory
return new ExtensionResponseBuilder().success(result).build();

// ✅ CORRECT for FreeForm - Use ExtensionResponseFactory
return ExtensionResponseFactory.create(Map.of("Field Name", result));
```

---

## Complete Examples

### Example 1: File Upload with Detailed Results
```java
@CatalogRequest(
    id = "localDomainRequest_upload-001",
    name = "Upload File",
    description = "Upload a file with detailed results",
    area = "Files",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse uploadFile(
        @Field.File(name = "File", required = true, attributes = {}, options = {}) File file,
        @Field.Text(name = "Path", required = true, attributes = {}, options = {}) String path) {
    
    try {
        // Perform upload logic here
        
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("fileName", file.getFileName());
        result.put("remotePath", path);
        result.put("uploadTime", new Date().toString());
        result.put("fileSize", "Available after upload");
        result.put("status", "COMPLETED");
        
        return ExtensionResponseFactory.create(Map.of("Upload Result", result));
        
    } catch (Exception e) {
        Map<String, Object> errorResult = new HashMap<>();
        errorResult.put("success", false);
        errorResult.put("error", e.getMessage());
        errorResult.put("fileName", file.getFileName());
        errorResult.put("uploadTime", new Date().toString());
        
        return ExtensionResponseFactory.create(Map.of("Upload Result", errorResult));
    }
}
```

### Example 2: Multiple Field Response
```java
@CatalogRequest(
    id = "localDomainRequest_list-001",
    name = "List Files",
    description = "List files in directory",
    area = "Files",
    type = CatalogRequest.Type.QUERY_SYSTEM)
@Field.Desc(name = "Success", type = "Boolean", required = false)
@Field.Desc(name = "File Count", type = "Number", required = false)
@Field.Desc(name = "File Names", type = "[ Text ]", required = false)
@Field(name = "Directory Info", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse listFiles(
        @Field.Text(name = "Directory Path", required = true, attributes = {}, options = {}) String path) {
    
    try {
        List<String> fileNames = Arrays.asList("file1.txt", "file2.txt", "file3.txt");
        
        Map<String, Object> dirInfo = new HashMap<>();
        dirInfo.put("path", path);
        dirInfo.put("totalSize", 1024000);
        dirInfo.put("lastModified", new Date().toString());
        dirInfo.put("permissions", "rwxr-xr-x");
        
        Map<String, Object> response = new HashMap<>();
        response.put("Success", true);
        response.put("File Count", fileNames.size());
        response.put("File Names", fileNames);
        response.put("Directory Info", dirInfo);
        
        return ExtensionResponseFactory.create(response);
        
    } catch (Exception e) {
        Map<String, Object> response = new HashMap<>();
        response.put("Success", false);
        response.put("File Count", 0);
        response.put("File Names", new ArrayList<String>());
        response.put("Directory Info", Map.of("error", e.getMessage()));
        
        return ExtensionResponseFactory.create(response);
    }
}
```

---

## Key Rules Summary

1. **FreeForm fields MUST use `@Field`** (not `@Field.Desc`)
2. **FreeForm fields MUST include `attributes = {}, options = {}`**
3. **FreeForm responses MUST wrap result with field name**: `Map.of("Field Name", result)`
4. **FreeForm responses MUST use `ExtensionResponseFactory.create()`**
5. **Field names in annotations MUST match response Map keys exactly**
6. **Simple fields can use `@Field.Desc` with `ExtensionResponseFactory.create()`**
7. **Multiple field responses use a single Map with all field names as keys**

**🔥 Remember: Wrong patterns = Empty displays. Follow these patterns exactly!**

---

## Advanced Field Types

### File Fields (Special Rules)
```java
// Single file return - Return File directly (no ExtensionResponse wrapper)
@Field.File(name = "Downloaded File", required = false, attributes = {}, options = {})
public File downloadFile() {
    return fileObject;  // Return File directly
}

// Multiple files return - Return List<File> directly
@Field.File(name = "Downloaded Files", required = false, attributes = {}, options = {})
public List<File> downloadFiles() {
    return fileList;  // Return List<File> directly
}

// File operation with metadata - Use ExtensionResponse
@Field(name = "Download Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse downloadFileWithMetadata() {
    Map<String, Object> result = new HashMap<>();
    result.put("success", true);
    result.put("fileName", "downloaded.txt");
    result.put("downloadTime", new Date().toString());

    return ExtensionResponseFactory.create(Map.of("Download Result", result));
}
```

### Complex Inline Object Types
```java
@Field.Desc(name = "File Changes", type = "[ { Path: Text, Date: Date, Update: PickOne(Created|Updated|Deleted) } ]", required = false)
public ExtensionResponse getFileChanges() {
    List<Map<String, Object>> changes = new ArrayList<>();

    Map<String, Object> change1 = new HashMap<>();
    change1.put("Path", "/documents/file1.txt");
    change1.put("Date", System.currentTimeMillis());
    change1.put("Update", "Created");
    changes.add(change1);

    return ExtensionResponseFactory.create(Map.of("File Changes", changes));
}
```

### Entity Fields
```java
@Field.Desc(name = "User Info", type = "Entity(User)", required = false)
@Field.Desc(name = "User List", type = "[ Entity(User) ]", required = false)
```

---

## Troubleshooting Guide

### Problem: Extension Using Wrong Environment Configuration
**Symptoms:** Extension works in one environment but uses wrong credentials in Draft/Test/Live

**Solutions:**
1. ✅ Check extension attributes class uses `invoker.getAttributes()`
2. ✅ Verify attributes constructor takes `Invoker` parameter
3. ✅ Test configuration in each environment (Draft/Test/Live)
4. ✅ Add debugging method to verify current configuration

**Example Debug Method:**
```java
@CatalogRequest(...)
@Field(name = "Environment Test", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse testEnvironmentConfig() {
    Map<String, Object> result = new HashMap<>();
    result.put("serverUrl", attributes.getServerUrl());
    result.put("username", attributes.getUsername());
    result.put("passwordSet", attributes.getPassword() != null ? "YES" : "NO");
    result.put("currentEnvironment", "Verify these match your current environment");

    return ExtensionResponseFactory.create(Map.of("Environment Test", result));
}
```

### Problem: FreeForm Field Shows Empty
**Symptoms:** Field shows "Field Name" but no content below it

**Solutions:**
1. ✅ Check field annotation uses `@Field` (not `@Field.Desc`)
2. ✅ Check field annotation includes `attributes = {}, options = {}`
3. ✅ Check response wraps result: `Map.of("Field Name", result)`
4. ✅ Check field name matches exactly (case-sensitive)

### Problem: Field Not Showing At All
**Symptoms:** Field doesn't appear in results

**Solutions:**
1. ✅ Check method returns `ExtensionResponse`
2. ✅ Check field annotation syntax is correct
3. ✅ Check response includes the field name as a key
4. ✅ Check for compilation errors

### Problem: List Fields Show Empty
**Symptoms:** List field shows but no items

**Solutions:**
1. ✅ Check list is not null or empty
2. ✅ Check field type matches: `"[ Text ]"` for `List<String>`
3. ✅ Check response Map key matches field name exactly

### Problem: Multiple Fields Not All Showing
**Symptoms:** Some fields show, others don't

**Solutions:**
1. ✅ Check all field names are included in response Map
2. ✅ Check field types match data types in response
3. ✅ Check for null values in response Map

---

## Testing Your Field Types

### Quick Test Method
```java
@CatalogRequest(
    id = "localDomainRequest_test-fields-001",
    name = "Test Field Types",
    description = "Test various field type displays",
    area = "Testing",
    type = CatalogRequest.Type.QUERY_SYSTEM)
@Field.Desc(name = "Text Field", type = "Text", required = false)
@Field.Desc(name = "Number Field", type = "Number", required = false)
@Field.Desc(name = "Boolean Field", type = "Boolean", required = false)
@Field.Desc(name = "Text List", type = "[ Text ]", required = false)
@Field(name = "Complex Object", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse testFieldTypes() {
    Map<String, Object> complexObject = new HashMap<>();
    complexObject.put("nested", "value");
    complexObject.put("number", 42);
    complexObject.put("timestamp", new Date().toString());

    Map<String, Object> response = new HashMap<>();
    response.put("Text Field", "Hello World");
    response.put("Number Field", 123);
    response.put("Boolean Field", true);
    response.put("Text List", Arrays.asList("item1", "item2", "item3"));
    response.put("Complex Object", complexObject);

    return ExtensionResponseFactory.create(response);
}
```

This test method will help you verify that all field types are displaying correctly.

---

## Required Imports

```java
import app.krista.extension.executor.ExtensionResponse;
import app.krista.extension.executor.ExtensionResponseFactory;
import app.krista.extension.executor.ExtensionResponseBuilder;
import app.krista.extension.impl.anno.CatalogRequest;
import app.krista.extension.impl.anno.Field;
import app.krista.extension.impl.anno.Attribute;
import app.krista.model.base.File;
import java.util.*;
```

---

**🎯 Final Reminder:** The difference between working and broken field displays often comes down to tiny syntax details. Copy these patterns exactly, and test thoroughly!
