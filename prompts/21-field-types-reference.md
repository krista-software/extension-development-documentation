# Prompt 21: Field Types and Response Patterns Reference

## Purpose

Provide a comprehensive reference for all Krista field types, their annotations, and the exact response patterns required for proper display. This is critical knowledge - wrong patterns result in empty or broken displays.

## Prerequisites

- Basic understanding of Krista extension development
- Familiarity with Java annotations
- Understanding of ExtensionResponse patterns

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `FIELD_NAME` | Display name for the field | `"Upload Result"` |
| `FIELD_TYPE` | Type of field (Text, Number, FreeForm, etc.) | `"FreeForm"` |
| `REQUIRED` | Whether field is required | `true` or `false` |

## Field Annotation Patterns

### Simple Field Types

```java
// Text Fields
@Field.Desc(name = "Field Name", type = "Text", required = false)
@Field.Text(name = "Field Name", required = true, attributes = {@Attribute(name = "visualWidth", value = "S")}, options = {})

// Number Fields
@Field.Desc(name = "Field Name", type = "Number", required = false)
@Field(name = "Field Name", type = "Number", required = false, attributes = {}, options = {})

// Boolean Fields
@Field.Desc(name = "Field Name", type = "Boolean", required = false)
@Field.Boolean(name = "Field Name", required = false, attributes = {}, options = {})

// Date Fields
@Field.Desc(name = "Field Name", type = "Date", required = false)
@Field.Date(name = "Field Name", required = true, includeTimeOfDay = true, allowPast = true, allowToday = true, allowFuture = true, attributes = {}, options = {})
```

### List Field Types

```java
// Text Lists
@Field.Desc(name = "Field Name", type = "[ Text ]", required = false)

// Number Lists
@Field.Desc(name = "Field Name", type = "[ Number ]", required = false)

// Date Lists
@Field.Desc(name = "Field Name", type = "[ Date ]", required = false)

// Composite Lists
@Field.Desc(name = "Field Name", type = "[ Composite ]", required = false)
```

### FreeForm Fields (CRITICAL)

```java
// ✅ CORRECT - Must use @Field with attributes and options
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})

// ❌ WRONG - Will NOT display
@Field.Desc(name = "Upload Result", type = "FreeForm", required = false)
```

### Selection and Rich Text Fields

```java
// PickOne (Dropdown)
@Field.PickOne(name = "Status", values = {"Active", "Inactive", "Pending"}, required = false, attributes = {}, options = {})

// Rich Text
@Field(name = "Content", type = "RichText", required = false, attributes = {}, options = {})

// Paragraph (Multi-line)
@Field(name = "Description", type = "Paragraph", required = false, attributes = {}, options = {})
```

### File Fields (Special Rules)

```java
// Single file - Return File directly (NO ExtensionResponse wrapper)
@Field.File(name = "Downloaded File", required = false, attributes = {}, options = {})
public File downloadFile() {
    return fileObject;  // Return File directly
}

// Multiple files - Return List<File> directly
@Field.File(name = "Downloaded Files", multipleFileUpload = true, required = false)
public List<File> downloadFiles() {
    return fileList;  // Return List<File> directly
}
```

## Response Patterns

### Simple Response

```java
@Field.Desc(name = "Result", type = "Text", required = false)
public ExtensionResponse getSimpleData() {
    String result = "some data";
    return ExtensionResponseFactory.create(Map.of("Result", result));
}
```

### FreeForm Response (CRITICAL)

```java
@Field(name = "Upload Result", type = "FreeForm", required = false, attributes = {}, options = {})
public ExtensionResponse uploadFile() {
    Map<String, Object> result = new HashMap<>();
    result.put("success", true);
    result.put("fileName", "test.txt");
    result.put("fileSize", 1024);
    result.put("uploadTime", new Date().toString());
    
    // CRITICAL: Wrap result with field name as key
    return ExtensionResponseFactory.create(Map.of("Upload Result", result));
}
```

### Multiple Fields Response

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

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Using `@Field.Desc` for FreeForm | Empty display | Use `@Field` with `attributes = {}, options = {}` |
| Missing field name wrapper | Empty display | Use `Map.of("Field Name", result)` |
| Field name mismatch | Field not showing | Ensure annotation name matches response key exactly |
| Using ExtensionResponseBuilder for FreeForm | Incorrect display | Use `ExtensionResponseFactory.create()` |

## Validation Checklist

- [ ] FreeForm fields use `@Field` (not `@Field.Desc`)
- [ ] FreeForm fields include `attributes = {}, options = {}`
- [ ] Response wraps result with field name: `Map.of("Field Name", result)`
- [ ] Field names in annotations match response Map keys exactly (case-sensitive)
- [ ] File fields return `File` or `List<File>` directly (no ExtensionResponse wrapper)
- [ ] ExtensionResponseFactory.create() used for complex responses

## Best Practices

1. **Always test field displays** after implementation
2. **Use consistent field naming** across your extension
3. **Document field types** in your code comments
4. **Copy patterns exactly** - small syntax differences cause failures

## Related Prompts

- [Prompt 5: Add QUERY_SYSTEM Request](05-add-query-system-request.md)
- [Prompt 6: Add CHANGE_SYSTEM Request](06-add-change-system-request.md)
- [Prompt 11: Add Helper Class](11-add-helper-class.md)

