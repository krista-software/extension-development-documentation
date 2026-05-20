# Field Types Quick Reference Card

**🔥 CRITICAL PATTERNS - Copy these exactly!**

## FreeForm Fields (Most Common Issue)

### ✅ CORRECT Pattern
```java
// Field annotation - MUST use @Field with attributes and options
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})

// Response - MUST wrap with field name
public ExtensionResponse uploadFile() {
    Map<String, Object> result = new HashMap<>();
    result.put("success", true);
    result.put("fileName", "test.txt");
    
    // CRITICAL: Wrap with field name
    return ExtensionResponseFactory.create(Map.of("Upload Result", result));
}
```

### ❌ BROKEN Patterns (Will Show Empty)
```java
// BROKEN - Using @Field.Desc
@Field.Desc(name = "Upload Result", type = "FreeForm", required = false)

// BROKEN - Missing attributes/options
@Field(name = "Upload Result", type = "FreeForm", required = false)

// BROKEN - Not wrapping with field name
return ExtensionResponseFactory.create(result);

// BROKEN - Wrong response builder
return new ExtensionResponseBuilder().success(result).build();
```

---

## Simple Fields

### Text/Number/Boolean
```java
@Field.Desc(name = "Result", type = "Text", required = false)
public ExtensionResponse getText() {
    return ExtensionResponseFactory.create(Map.of("Result", "some text"));
}
```

### Lists
```java
@Field.Desc(name = "File Names", type = "[ Text ]", required = false)
public ExtensionResponse getFileNames() {
    List<String> files = Arrays.asList("file1.txt", "file2.txt");
    return ExtensionResponseFactory.create(Map.of("File Names", files));
}
```

---

## Multiple Fields
```java
@Field.Desc(name = "Success", type = "Boolean", required = false)
@Field.Desc(name = "Message", type = "Text", required = false)
@Field.Desc(name = "Count", type = "Number", required = false)
public ExtensionResponse getMultiple() {
    Map<String, Object> response = new HashMap<>();
    response.put("Success", true);
    response.put("Message", "Operation completed");
    response.put("Count", 5);
    
    return ExtensionResponseFactory.create(response);
}
```

---

## File Fields (Special Rules)
```java
// Single file - Return File directly (no ExtensionResponse wrapper)
@Field.File(name = "Downloaded File", required = false, attributes = {}, options = {})
public File downloadFile() {
    return fileObject;  // Return File directly
}

// File with metadata - Use FreeForm pattern
@Field(name = "Download Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse downloadWithMetadata() {
    Map<String, Object> result = new HashMap<>();
    result.put("success", true);
    result.put("fileName", "downloaded.txt");
    
    return ExtensionResponseFactory.create(Map.of("Download Result", result));
}
```

---

## Environment Configuration Issues

### ❌ Extension Using Wrong Credentials?
```java
// CORRECT - Environment-aware attributes
@ExtensionAttributes
public class YourAttributes {
    private final Invoker invoker;

    public YourAttributes(Invoker invoker) {
        this.invoker = invoker;
    }

    public String getServerUrl() {
        return invoker.getAttributes().get("serverUrl");  // Gets environment-specific config
    }
}
```

### Quick Environment Test
```java
@Field(name = "Config Check", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse checkConfig() {
    Map<String, Object> result = new HashMap<>();
    result.put("serverUrl", attributes.getServerUrl());
    result.put("username", attributes.getUsername());
    result.put("environment", "Verify these match current environment");

    return ExtensionResponseFactory.create(Map.of("Config Check", result));
}
```

## Common Mistakes Checklist

### ❌ FreeForm Not Displaying?
- [ ] Using `@Field` (not `@Field.Desc`)?
- [ ] Included `attributes = {}, options = {}`?
- [ ] Wrapping response with field name?
- [ ] Using `ExtensionResponseFactory.create()`?
- [ ] Field name matches exactly (case-sensitive)?

### ❌ Simple Fields Not Displaying?
- [ ] Field name in response Map matches annotation?
- [ ] Using correct field type (`"Text"`, `"[ Text ]"`, etc.)?
- [ ] Returning `ExtensionResponse`?
- [ ] Using `ExtensionResponseFactory.create()`?

### ❌ Multiple Fields Missing?
- [ ] All field names included in response Map?
- [ ] Field types match data types?
- [ ] No null values in response?

---

## Required Imports
```java
import app.krista.extension.executor.ExtensionResponse;
import app.krista.extension.executor.ExtensionResponseFactory;
import app.krista.extension.impl.anno.CatalogRequest;
import app.krista.extension.impl.anno.Field;
import app.krista.extension.impl.anno.Attribute;
import java.util.*;
```

---

## Test Pattern
```java
@CatalogRequest(
    id = "localDomainRequest_test-001",
    name = "Test Display",
    description = "Test field display",
    area = "Test",
    type = CatalogRequest.Type.QUERY_SYSTEM)
@Field(name = "Test Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse testDisplay() {
    Map<String, Object> result = new HashMap<>();
    result.put("message", "If you see this, it's working!");
    result.put("timestamp", new Date().toString());
    
    return ExtensionResponseFactory.create(Map.of("Test Result", result));
}
```

**🎯 Copy these patterns exactly - tiny syntax differences break everything!**
