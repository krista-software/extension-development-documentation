# Prompt 24: Entity Development Guide

## Purpose

Guide developers through implementing Entities in Krista extensions, covering entity definition, transformation pipeline, EntityReference vs EntityValue patterns, and integration with the ExtensionEntityParser.

## Prerequisites

- Existing Krista extension project
- Understanding of Java annotations
- Familiarity with domain modeling concepts

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `{ENTITY_NAME}` | Name of the entity | `Contact` |
| `{DOMAIN_ID}` | Domain identifier | `your-domain-id` |
| `{DOMAIN_NAME}` | Human-readable domain name | `Your Domain` |
| `{ECOSYSTEM_ID}` | Ecosystem identifier | `your-ecosystem-id` |
| `{ECOSYSTEM_NAME}` | Ecosystem name | `Your Ecosystem` |
| `{PRIMARY_KEY}` | Primary key field name | `Email` |

---

## Prompt

```
I need to implement an Entity in my Krista extension for {ENTITY_NAME}.

## Entity Requirements

1. **Entity Definition**
   - Domain: {DOMAIN_NAME} (ID: {DOMAIN_ID})
   - Ecosystem: {ECOSYSTEM_NAME} (ID: {ECOSYSTEM_ID})
   - Primary Key: {PRIMARY_KEY}
   - Make it searchable

2. **Entity Fields**
   [List your fields here with types and requirements]

3. **Usage Pattern**
   - [ ] EntityReference (lazy loading)
   - [ ] EntityValue (concrete data)
   - [ ] Domain Object (custom class)

## Implementation Requirements

### Entity Class Structure

Create the entity class with proper annotations:

```java
package {PACKAGE}.entities;

import app.krista.extension.impl.anno.*;

@Domain(id = "{DOMAIN_ID}",
        name = "{DOMAIN_NAME}",
        ecosystemId = "{ECOSYSTEM_ID}",
        ecosystemName = "{ECOSYSTEM_NAME}",
        ecosystemVersion = "your-version-id")
@Entity(name = "{ENTITY_NAME}", id = "your-entity-id", primaryKey = "{PRIMARY_KEY}")
@Searchable
public class {ENTITY_NAME} {

    @Searchable
    @ToString
    @Field(name = "{PRIMARY_KEY}", type = "Text")
    public String primaryKeyField;

    @Field.Text(name = "Name", required = true)
    public String name;

    @Field.Text(name = "Description", required = false)
    public String description;

    // Constructor
    public {ENTITY_NAME}(String primaryKey, String name) {
        this.primaryKeyField = primaryKey;
        this.name = name;
    }

    // Factory method
    public static {ENTITY_NAME} create(String primaryKey, String name) {
        return new {ENTITY_NAME}(primaryKey, name);
    }

    @Override
    public String toString() {
        return "{ENTITY_NAME}{" +
                "{PRIMARY_KEY}:'" + primaryKeyField + "', " +
                "Name:'" + name + "'" +
                "}";
    }
}
```

### Entity Relationship Patterns

Entities can reference other entities to model one-to-many and many-to-one
relationships. Use the `"[ Entity(Child) ]"` type syntax for collections and
a plain `"Entity(Child)"` for single references. Always reference related
entities by their primary key (ID field) rather than embedding the full object.

```java
// One-to-many: an Account has many Contacts
@Field(name = "Contacts", type = "[ Entity(Contact) ]")
public List<Contact> contacts;

// Many-to-one reference by ID: a Contact belongs to an Account
@Field(name = "Account ID", type = "Text")
public String accountId;

// Single entity reference (loaded on demand)
@Field(name = "Primary Contact", type = "Entity(Contact)")
public EntityReference<Contact> primaryContact;
```

### Entity Versioning

When evolving an entity across extension versions, keep field names stable.
Renaming a `@Field` annotation breaks existing conversation flows and stored
entity data. Instead, add new fields alongside the old ones and deprecate
gracefully. Always use `@Field` annotations consistently so the platform can
track the schema.

```java
// Good: add a new field, keep the old one
@Field(name = "Email", type = "Text")
public String email;             // original field, keep stable

@Field(name = "Secondary Email", type = "Text")
public String secondaryEmail;   // new field added in v2

// Bad: renaming "Email" to "Primary Email" breaks existing references
```

### Entity Transformation Pipeline

Understand the transformation flow:

```
Platform Entity (Entity) → ExtensionEntityParser → Extension Format
                                    ↓
                        EntityValue | EntityReference | Domain Object
```

### Using EntityReference (Lazy Loading)

```java
// For lazy loading - entity data loaded on demand
@Field(name = "Contact", type = "Entity(Contact)")
public EntityReference<Contact> contactRef;

// Load when needed
Contact contact = contactRef.load(Contact.class);
```

### Using EntityValue (Concrete Data)

```java
// For immediate data access
@Field(name = "Contact", type = "Entity(Contact)")
public EntityValue<Contact> contactValue;

// Access fields directly
String email = contactValue.getField("Email");
```

### Returning Entities from Catalog Requests

```java
@CatalogRequest(
    id = "unique-id",
    name = "Get Contact",
    area = "Contacts",
    type = CatalogRequest.Type.QUERY_SYSTEM)
@Field.Desc(name = "Contact", type = "Entity(Contact)", required = false)
public ExtensionResponse getContact(
        @Field.Text(name = "Email", required = true) String email) {
    
    Contact contact = contactService.findByEmail(email);
    return ExtensionResponseFactory.create(Map.of("Contact", contact));
}
```

### Returning Entity Lists

```java
@Field.Desc(name = "Contacts", type = "[ Entity(Contact) ]", required = false)
public ExtensionResponse listContacts() {
    List<Contact> contacts = contactService.findAll();
    return ExtensionResponseFactory.create(Map.of("Contacts", contacts));
}
```

Please implement the entity following these patterns and ensure proper integration with the extension's catalog requests.
```

---

## Key Concepts

### Entity Hierarchy

```
Entity Ecosystem
├── Entity (Data Container)
├── EntityMeta (Metadata)
├── EntityType (Type Definition)
├── EntityDefinition (Schema)
├── EntityReference (Reference/Proxy)
└── EntityValue (Value Object)
```

### Field Annotations

| Annotation | Purpose | Example |
|------------|---------|---------|
| `@Field` | Generic field definition | `@Field(name = "Email", type = "Text")` |
| `@Field.Text` | Text field shorthand | `@Field.Text(name = "Name", required = true)` |
| `@Field.Number` | Numeric field | `@Field.Number(name = "Age", required = false)` |
| `@Field.Boolean` | Boolean field | `@Field.Boolean(name = "Active")` |
| `@Searchable` | Makes field/entity searchable | `@Searchable` |
| `@ToString` | Includes in string representation | `@ToString` |

### Entity vs FreeForm Decision

| Use Case | Entity | FreeForm |
|----------|--------|----------|
| Structured business objects | ✅ | ❌ |
| Unknown data structure | ❌ | ✅ |
| Needs persistence | ✅ | ❌ |
| API response passthrough | ❌ | ✅ |

