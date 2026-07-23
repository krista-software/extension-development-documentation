# Prompt 27: MultiField Developer Guide

## Purpose

Guide developers through implementing MultiField composite fields in Krista extensions for grouping related fields without the overhead of full Entity definitions.

## Prerequisites

- Existing Krista extension project
- Understanding of Krista field types
- Familiarity with Map-based data structures

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `{MULTIFIELD_NAME}` | Name of the MultiField | `UserProfile` |
| `{FIELD_1_NAME}` | First sub-field name | `nickname` |
| `{FIELD_1_TYPE}` | First sub-field type | `Text` |
| `{FIELD_2_NAME}` | Second sub-field name | `luckyNumber` |
| `{FIELD_2_TYPE}` | Second sub-field type | `Number` |

---

## Prompt

```
I need to implement a MultiField composite field called {MULTIFIELD_NAME} in my Krista extension.

## MultiField Requirements

- Name: {MULTIFIELD_NAME}
- Sub-fields:
  - {FIELD_1_NAME}: {FIELD_1_TYPE}
  - {FIELD_2_NAME}: {FIELD_2_TYPE}
  [Add more fields as needed]

## When to Use MultiField

| Scenario | MultiField | Entity | FreeForm |
|----------|------------|--------|----------|
| Temporary data grouping | ✅ Perfect | ❌ Overkill | ⚠️ Less structured |
| Form data collection | ✅ Ideal | ❌ Too heavy | ⚠️ Less validation |
| API response formatting | ✅ Excellent | ❌ Unnecessary | ✅ Good for unknown |
| Persistent business objects | ❌ No persistence | ✅ Perfect | ❌ No schema |
| Unknown data structure | ❌ Requires known fields | ❌ Requires schema | ✅ Perfect |

## Implementation

### Creating MultiField Data

```java
// Use LinkedHashMap to preserve field order
Map<String, Object> {MULTIFIELD_NAME_LOWER} = new LinkedHashMap<>();
{MULTIFIELD_NAME_LOWER}.put("{FIELD_1_NAME}", "value1");
{MULTIFIELD_NAME_LOWER}.put("{FIELD_2_NAME}", 42);
```

### Using in Catalog Request Input

```java
@CatalogRequest(
    id = "unique-id",
    name = "Process {MULTIFIELD_NAME}",
    area = "YourArea",
    type = CatalogRequest.Type.CHANGE_SYSTEM)
public ExtensionResponse processMultiField(
        @Field(name = "{MULTIFIELD_NAME}", type = "MultiField", 
               attributes = {
                   @Field.Attribute(name = "fields", value = "[" +
                       "{\"name\":\"{FIELD_1_NAME}\",\"type\":\"{FIELD_1_TYPE}\"}," +
                       "{\"name\":\"{FIELD_2_NAME}\",\"type\":\"{FIELD_2_TYPE}\"}" +
                   "]")
               }) Map<String, Object> multiFieldData) {
    
    String field1Value = (String) multiFieldData.get("{FIELD_1_NAME}");
    Integer field2Value = (Integer) multiFieldData.get("{FIELD_2_NAME}");
    
    // Process the data
    return ExtensionResponseFactory.create(Map.of("success", true));
}
```

### Using in Catalog Request Output

```java
@CatalogRequest(
    id = "unique-id",
    name = "Get {MULTIFIELD_NAME}",
    area = "YourArea",
    type = CatalogRequest.Type.QUERY_SYSTEM)
@Field.Desc(name = "{MULTIFIELD_NAME}", type = "MultiField", required = false,
            attributes = {
                @Field.Attribute(name = "fields", value = "[" +
                    "{\"name\":\"{FIELD_1_NAME}\",\"type\":\"{FIELD_1_TYPE}\"}," +
                    "{\"name\":\"{FIELD_2_NAME}\",\"type\":\"{FIELD_2_TYPE}\"}" +
                "]")
            })
public ExtensionResponse getMultiField() {
    Map<String, Object> result = new LinkedHashMap<>();
    result.put("{FIELD_1_NAME}", "TechGuru");
    result.put("{FIELD_2_NAME}", 42);
    
    return ExtensionResponseFactory.create(Map.of("{MULTIFIELD_NAME}", result));
}
```

### Nested MultiFields

```java
// Parent MultiField containing child MultiField
Map<String, Object> address = new LinkedHashMap<>();
address.put("street", "123 Main St");
address.put("city", "Springfield");

Map<String, Object> userProfile = new LinkedHashMap<>();
userProfile.put("name", "John Doe");
userProfile.put("address", address);  // Nested MultiField
```

### MultiField in FreeForm

```java
FreeForm freeForm = new FreeForm();
Map<String, Object> multiFieldData = new LinkedHashMap<>();
multiFieldData.put("{FIELD_1_NAME}", "value");
multiFieldData.put("{FIELD_2_NAME}", 123);

freeForm.put("{MULTIFIELD_NAME}", "MultiField", multiFieldData);
```

Please implement the MultiField following these patterns.
```

---

## Key Characteristics

- **Lightweight**: No database schema requirements
- **Flexible**: Structure determined at runtime
- **Composable**: Can contain other MultiFields (nested)
- **Transformable**: Automatic conversion between formats
- **Order Preserved**: Uses LinkedHashMap structures

## Validation Checklist

- [ ] Use LinkedHashMap for field order preservation
- [ ] Define all sub-fields in attributes
- [ ] Match field names exactly in code and annotations
- [ ] Handle type conversion properly
- [ ] Test nested MultiFields if used

## Best Practices

1. **Always use LinkedHashMap** to preserve field order
2. **Define clear field schemas** in annotations
3. **Validate sub-field types** before processing
4. **Document MultiField structure** for API consumers
5. **Consider Entity** if persistence is needed

## Related Prompts

- [Prompt 21: Field Types Reference](21-field-types-reference.md)
- [Prompt 24: Entity Development](24-entity-development.md)

