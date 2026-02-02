# Prompt 29: Getting Started with Catalog Requests

## Purpose

Guide new developers through creating their first Krista catalog request, from understanding the concepts to implementing and building the extension.

## Prerequisites

- Java IDE (IntelliJ IDEA recommended)
- Access to Krista Studio
- Basic Java knowledge

---

## Prompt

```
I'm new to Krista extension development and need to create my first catalog request.

## Understanding Catalog Requests

A Catalog Request binds an Extension to the Krista Catalog. Each request has:
- **Name**: Human-readable identifier
- **Description**: What the request does
- **Type**: CHANGE_SYSTEM, QUERY_SYSTEM, or WAIT_FOR_EVENT
- **Inputs**: Parameters the request accepts
- **Outputs**: Data the request returns

### Request Types

| Type | Purpose | Use Case |
|------|---------|----------|
| **CHANGE_SYSTEM** | Modify system state | POST/PUT operations, create/update/delete |
| **QUERY_SYSTEM** | Read system data | GET operations, search, list |
| **WAIT_FOR_EVENT** | Trigger conversations | Webhooks, async notifications |

## Step-by-Step Implementation

### Step 1: Create Project Structure

```
my-extension/
├── src/
│   └── main/
│       └── java/
│           └── app/krista/extensions/{ecosystem}/{domain}/{extension}/
│               ├── {ExtensionName}.java          # Main extension class
│               └── catalog/
│                   ├── {AreaName}Area.java       # Area class
│                   └── helper/
│                       └── {RequestName}Helper.java  # Helper class
├── build.gradle
└── version.properties
```

### Step 2: Create Main Extension Class

```java
package app.krista.extensions.{ecosystem}.{domain}.{extension};

import app.krista.extension.impl.anno.Extension;

@Extension(version = "1.0.0", name = "{extension-name}")
public class {ExtensionName} {
    // Extension configuration and setup
}
```

### Step 3: Create Area Class

```java
package app.krista.extensions.{ecosystem}.{domain}.{extension}.catalog;

import app.krista.extension.impl.anno.*;
import app.krista.extension.impl.response.*;
import java.util.Map;

@Area(name = "{AreaName}")
public class {AreaName}Area {

    @CatalogRequest(
        id = "localDomainRequest_{UUID}",
        name = "My First Request",
        description = "Description of what this request does",
        area = "{AreaName}",
        type = CatalogRequest.Type.QUERY_SYSTEM)
    @Field.Desc(name = "Result", type = "Text", required = false)
    public ExtensionResponse myFirstRequest(
            @Field.Text(name = "Input Parameter", required = true) String inputParam) {
        
        // Your business logic here
        String result = "Processed: " + inputParam;
        
        return ExtensionResponseFactory.create(Map.of("Result", result));
    }
}
```

### Step 4: Environment Configuration

**⚠️ CRITICAL:** Extensions MUST read configuration from the correct environment.

```java
@ExtensionAttributes
public class {ExtensionName}Attributes {

    private final Invoker invoker;

    public {ExtensionName}Attributes(Invoker invoker) {
        this.invoker = invoker;
    }

    // Use invoker.getAttributes() for environment-specific config
    public String getServerUrl() {
        return invoker.getAttributes().get("serverUrl");
    }
}
```

### Step 5: Build and Deploy

```bash
# Compile the extension
./gradlew compileJava

# Build the JAR
./gradlew build

# The JAR will be in build/libs/
```

## Field Types Quick Reference

| Type | Annotation | Example |
|------|------------|---------|
| Text | `@Field.Text` | `@Field.Text(name = "Name", required = true)` |
| Number | `@Field.Number` | `@Field.Number(name = "Count", required = false)` |
| Boolean | `@Field.Boolean` | `@Field.Boolean(name = "Active")` |
| Date | `@Field.Date` | `@Field.Date(name = "Created")` |
| FreeForm | `@Field` | `@Field(name = "Data", type = "FreeForm", attributes = {}, options = {})` |
| Entity | `@Field` | `@Field(name = "Contact", type = "Entity(Contact)")` |
| List | `@Field` | `@Field(name = "Items", type = "[ Text ]")` |

## Response Patterns

```java
// Single value
return ExtensionResponseFactory.create(Map.of("Result", value));

// Multiple values
return ExtensionResponseFactory.create(Map.of(
    "Name", name,
    "Count", count,
    "Active", isActive
));

// Entity
return ExtensionResponseFactory.create(Map.of("Contact", contactEntity));

// List
return ExtensionResponseFactory.create(Map.of("Items", itemsList));
```

Please help me create my first catalog request following these patterns.
```

---

## Validation Checklist

- [ ] Package structure follows conventions
- [ ] @Extension annotation on main class
- [ ] @Area annotation on area class
- [ ] @CatalogRequest with all required attributes
- [ ] Input parameters properly annotated
- [ ] Output fields described with @Field.Desc
- [ ] Response uses ExtensionResponseFactory
- [ ] Environment configuration uses Invoker

## Best Practices

1. **Start simple** - Create a basic QUERY_SYSTEM first
2. **Use helper classes** - Keep catalog methods under 30 lines
3. **Test locally** - Verify compilation before deploying
4. **Read field types guide** - Understand annotation patterns

## Related Prompts

- [Prompt 05: Add QUERY_SYSTEM Request](05-add-query-system-request.md)
- [Prompt 06: Add CHANGE_SYSTEM Request](06-add-change-system-request.md)
- [Prompt 21: Field Types Reference](21-field-types-reference.md)

