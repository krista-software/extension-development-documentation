# Prompt 25: Extension Versioning

## Purpose

Implement automated semantic versioning in Krista extensions following the brave-api pattern, with automatic version management, build integration, and Extension annotation synchronization.

## Prerequisites

- Existing Krista extension project with Gradle build
- Understanding of semantic versioning (major.minor.patch)
- Access to modify build.gradle

## Input Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `{EXTENSION_PACKAGE}` | Full package path | `app.krista.extensions.essentials.cloudfiles.ftp` |
| `{EXTENSION_CLASS}` | Main extension class name | `FtpExtension` |
| `{INITIAL_VERSION}` | Starting version | `1.0.0` |

---

## Prompt

```
I need to implement automated semantic versioning for my Krista extension.

## Extension Details

- Package: {EXTENSION_PACKAGE}
- Main Class: {EXTENSION_CLASS}
- Initial Version: {INITIAL_VERSION}

## Implementation Steps

### Step 1: Create version.properties

Create `version.properties` in the extension root directory:

```properties
#Auto-generated version file following brave-api pattern
major=1
minor=0
patch=0
```

### Step 2: Update build.gradle - Version Loading

Add version loading at the top of build.gradle:

```gradle
// Load version from properties file following brave-api pattern
def versionProps = new Properties()
def versionPropsFile = file('version.properties')
if (versionPropsFile.canRead()) {
    versionPropsFile.withInputStream { versionProps.load(it) }
}

def major = versionProps.getProperty('major', '1')
def minor = versionProps.getProperty('minor', '0')
def patch = versionProps.getProperty('patch', '0')

// Set the version based on the properties
version = "${major}.${minor}.${patch}"

// Set the extension version system property
System.setProperty("extensionVersion", version)
```

### Step 3: Add updateVersion Task

```gradle
tasks.register("updateVersion") {
    doFirst {
        // Increment patch version
        def newPatch = Integer.parseInt(patch) + 1

        // Update version.properties file
        versionProps.setProperty('patch', newPatch.toString())
        versionPropsFile.withOutputStream { versionProps.store(it, null) }

        // Update the version variable
        version = "${major}.${minor}.${newPatch}"

        println "Building extension version: ${version}"

        // Set system property with the updated version
        System.clearProperty("extensionVersion")
        System.setProperty("extensionVersion", version)

        // Update the extension version in the Java file
        updateExtensionVersion(version)
    }
}

def updateExtensionVersion(String newVersion) {
    def extensionFile = file('src/main/java/{EXTENSION_PACKAGE_PATH}/{EXTENSION_CLASS}.java')
    if (extensionFile.exists()) {
        def content = extensionFile.text
        def updatedContent = content.replaceAll(/version = "[\d\.]+"/, "version = \"${newVersion}\"")
        extensionFile.text = updatedContent
    }
}
```

### Step 4: Integrate with Build Process

```gradle
tasks.compileJava {
    dependsOn 'clean', 'updateVersion'
}
```

### Step 5: Update Extension Class

Ensure the @Extension annotation has the version:

```java
@Extension(version = "{INITIAL_VERSION}", name="{extension-name}")
public class {EXTENSION_CLASS} {
    // Extension implementation
}
```

## Version Strategy

- **Patch (auto)**: Bug fixes, small changes - increments automatically
- **Minor (manual)**: New features (backward compatible) - edit version.properties
- **Major (manual)**: Breaking changes - edit version.properties

## Disabling Auto-Increment

When manual version control is needed, comment out the dependency:

```gradle
// NOTE: Auto-update disabled to maintain manual version control
// tasks.compileJava {
//     dependsOn 'updateVersion'
// }
```

Please implement this versioning system and verify it works with a test build.
```

---

## Validation Checklist

- [ ] `version.properties` file created with correct format
- [ ] build.gradle loads version from properties
- [ ] `updateVersion` task increments patch version
- [ ] Extension class annotation updated automatically
- [ ] Build output shows correct version number
- [ ] Version consistent across all files

## Best Practices

1. **Commit version changes** with code changes
2. **Tag releases** with version numbers
3. **Use CI/CD** for automatic version increments
4. **Manual control** for major/minor bumps

## Related Prompts

- [Prompt 22: Architecture & Design Patterns](22-architecture-design-patterns.md)
- [Prompt 28: PR Requirements](28-pr-requirements.md)

