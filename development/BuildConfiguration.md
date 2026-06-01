<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Build configuration

# Build configuration

## Overview

Every Krista extension ships as a fat JAR built with Gradle. This page documents the complete `build.gradle` structure, required plugins, dependency management, test configuration, code-quality tooling, and packaging tasks. All examples are drawn from production extensions.

---

## Plugins

A typical extension applies the following plugins:

```gradle
plugins {
    id 'java'
    id 'java-library'
    id 'maven-publish'
    id "jacoco"                                     // Code coverage
    id("org.sonarqube") version "6.3.1.5724"        // Static analysis
}
```

| Plugin | Purpose |
|--------|---------|
| `java` / `java-library` | Standard Java compilation and library conventions |
| `maven-publish` | Publish the JAR to the Krista artifact repository |
| `jacoco` | Generate code-coverage reports consumed by SonarQube |
| `org.sonarqube` | Run SonarQube analysis from Gradle |

> If your extension includes a web UI (for example an OAuth redirect page), add the Node/Yarn plugin as well:
> ```gradle
> id "com.github.node-gradle.node" version "3.1.0"
> ```

---

## Java toolchain

Set the Java toolchain to **21** so builds are reproducible across developer machines and CI:

```gradle
java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}
```

Declare the same version in the extension class:

```java
@Java(version = Java.Version.JAVA_21)
```

### Compiler options

Enable all warnings and enforce UTF-8 encoding:

```gradle
tasks.withType(JavaCompile).configureEach {
    options.encoding = 'UTF-8'
    options.compilerArgs << '-Xlint:all,-serial'
}
```

---

## Repositories and dependencies

### Repositories

Extensions resolve dependencies from the Krista artifact repository and Maven Central:

```gradle
repositories {
    maven {
        url = "https://packages.cicd.in.antbrains.com/artifactory/libs-release"
    }
    mavenCentral()
    mavenLocal()
}
```

### Core dependencies

Every extension requires the Krista APIs and annotation processor. Pin both to the same platform release:

```gradle
dependencies {
    // Annotation processor — generates catalog-request metadata at compile time
    annotationProcessor 'app.krista:extension-impl-anno-processors:1.0.125-sp1'

    // Runtime APIs
    implementation 'app.krista:krista-apis:1.0.125-sp1'

    // HK2 dependency injection
    implementation 'org.glassfish.hk2:hk2-api:3.0.3'

    // Logging
    implementation 'org.apache.logging.log4j:log4j-slf4j-impl:2.20.0'
}
```

> Use the artifact coordinates and versions published for your Krista platform/KSDK release. Never copy version numbers from an incompatible platform release.

### Test dependencies

```gradle
dependencies {
    testImplementation 'com.kristasoft.common:common-test:1.0.39'
    testImplementation 'app.krista:krista-apis:1.0.125-sp1'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.9.2'
    testImplementation 'org.junit.jupiter:junit-jupiter-engine:5.9.2'
    testImplementation 'org.mockito:mockito-core:5.10.0'
    testImplementation 'org.mockito:mockito-junit-jupiter:5.10.0'
    testRuntimeOnly  'org.junit.platform:junit-platform-launcher:1.10.0'
}
```

### Extension-specific dependencies

Add libraries for the external system your extension integrates with. For example, an Outlook extension adds Microsoft Graph and Azure Identity:

```gradle
dependencies {
    implementation 'com.microsoft.graph:microsoft-graph:5.76.0'
    implementation 'com.azure:azure-identity:1.11.0'
}
```

---

## Test configuration

### JUnit 5

Configure Gradle to use the JUnit Platform and produce detailed output:

```gradle
test {
    useJUnitPlatform()
    finalizedBy jacocoTestReport   // Generate coverage after tests

    testLogging {
        events "passed", "skipped", "failed"
        exceptionFormat = "full"
    }

    maxHeapSize = "1G"
}
```

### Mockito with Java 21

Java 21's stronger encapsulation requires Byte Buddy experimental mode and the subclass mock maker:

```gradle
test {
    // Enable experimental support for Java 21+ in Byte Buddy
    jvmArgs '-Dnet.bytebuddy.experimental=true'

    // Use subclass mock maker (compatible with Java 21 module restrictions)
    systemProperty 'mockito.mock.maker', 'subclass'
}
```

Additionally, register the Byte Buddy agent for inline mocking:

```gradle
tasks.withType(Test).configureEach {
    doFirst {
        def byteBuddyAgent = configurations.testRuntimeClasspath.find {
            it.name.contains('byte-buddy-agent')
        }
        if (byteBuddyAgent) {
            jvmArgs "-javaagent:${byteBuddyAgent}"
        }
    }
}
```

---

## Code quality: SonarQube and JaCoCo

### JaCoCo configuration

JaCoCo generates coverage reports that SonarQube consumes:

```gradle
jacoco {
    toolVersion = "0.8.11"
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required  = true    // Required by SonarQube
        html.required = true    // Useful for local review
        csv.required  = false
    }
}
```

### SonarQube configuration

Configure the SonarQube plugin with project-specific properties:

```gradle
sonar {
    properties {
        property('sonar.projectName',
                 'SonarScanner for Krista Global Catalog (<extension-name> with Jacoco code coverage)')
        property('sonar.projectKey',   'sonar-scanner-<extension-name>')
        property('sonar.sources',      'src/main/java')
        property('sonar.tests',        'src/test/java')
        property('sonar.java.binaries',      'build/classes/java/main')
        property('sonar.java.test.binaries', 'build/classes/java/test')
        property('sonar.coverage.jacoco.xmlReportPaths',
                 'build/reports/jacoco/test/jacocoTestReport.xml')
        property('sonar.junit.reportPaths', 'build/test-results/test')
    }
}
```

### Task dependency chain

Ensure the `sonar` task runs coverage first:

```gradle
tasks.named('sonar') {
    dependsOn jacocoTestReport
}
```

### Running the analysis

```bash
# Run tests, generate coverage, then analyse
./gradlew test jacocoTestReport sonar \
    -Dsonar.host.url=<YOUR_SONAR_URL> \
    -Dsonar.token=<YOUR_SONAR_TOKEN>
```

After the run completes:
- **JaCoCo HTML report** is at `build/reports/jacoco/test/html/index.html`
- **JaCoCo XML report** is at `build/reports/jacoco/test/jacocoTestReport.xml`
- **SonarQube dashboard** shows quality gate results at your Sonar server URL

---

## Version management

### release.properties

Every extension maintains a `release.properties` file at the project root:

```properties
extension.name=Outlook
extension.version=4.0.5
domain.name=Collaboration
ecosystem.name=Essentials
```

The JAR task reads this file to set the archive name and version:

```
build/libs/Outlook-4.0.5.jar
```

### Automatic generation

Use a Gradle task to extract version, domain, and ecosystem from annotations, eliminating manual drift:

```gradle
tasks.register('generateReleaseProperties') {
    group = 'build'
    description = 'Generates release.properties from extension annotations'

    doLast {
        def extensionFile = file('src/main/java/.../YourExtension.java')
        def areaFile      = file('src/main/java/.../YourArea.java')

        def properties = new Properties()

        // Parse @Extension annotation for version and name
        // Parse @Domain annotation for domain and ecosystem
        // Write to release.properties
    }
}

tasks.named("jar") {
    dependsOn tasks.named("generateReleaseProperties")
}
```

### Version consistency checklist

Keep these three locations in sync:

| Location | Field | Example |
|----------|-------|---------|
| Extension class | `@Extension(version = "X.Y.Z")` | `@Extension(version = "4.0.5")` |
| `release.properties` | `extension.version=X.Y.Z` | `extension.version=4.0.5` |
| `version.properties` (if present) | `patch=Z` | `patch=5` |

---

## Packaging (fat JAR)

Extensions ship as a single fat JAR containing all runtime dependencies:

```gradle
jar {
    archiveBaseName.set("Outlook")

    manifest {}

    from {
        configurations.runtimeClasspath.collect {
            it.isDirectory() ? it : zipTree(it)
        }
    }

    exclude 'META-INF/*.RSA', 'META-INF/*.SF', 'META-INF/*.DSA'
    duplicatesStrategy = "exclude"
}
```

| Setting | Purpose |
|---------|---------|
| `runtimeClasspath.collect { zipTree(it) }` | Bundles all dependencies into one JAR |
| `exclude 'META-INF/*.RSA', ...` | Strips signing files from third-party JARs to avoid verification errors |
| `duplicatesStrategy = "exclude"` | Keeps the first copy when multiple JARs provide the same file |

### Including source for debugging

Optionally embed source code in the JAR for platform-side debugging:

```gradle
tasks.register('includeSources', Exec) {
    dependsOn copyGradleFile
    commandLine "cp", "-r",
        "$projectDir/src",
        "$projectDir/build/classes/java/main/META-INF/project/src"
}
```

---

## Common Gradle tasks

| Command | Purpose |
|---------|---------|
| `./gradlew clean build` | Full clean build |
| `./gradlew compileJava` | Compile only (fast check before committing) |
| `./gradlew test` | Run all tests |
| `./gradlew jacocoTestReport` | Generate coverage report |
| `./gradlew sonar` | Run SonarQube analysis (includes tests + coverage) |
| `./gradlew dependencies` | Show dependency tree |
| `./gradlew generateReleaseProperties` | Regenerate `release.properties` from annotations |

---

## Troubleshooting

### Build fails due to Java version

- Verify `java.sourceCompatibility` and `java.targetCompatibility` are both `VERSION_21`.
- Verify your local JDK is 21 or later: `java -version`.
- Verify the extension class includes `@Java(version = Java.Version.JAVA_21)`.

### Missing annotation-generated metadata

- Confirm the `annotationProcessor` dependency is declared in `build.gradle`.
- Run `./gradlew clean compileJava` to regenerate metadata.

### Mockito / Byte Buddy failures on Java 21

- Confirm `-Dnet.bytebuddy.experimental=true` is set in test JVM args.
- Confirm `mockito.mock.maker` is set to `subclass`.
- Confirm the Byte Buddy agent is attached (see [Mockito with Java 21](#mockito-with-java-21)).

### SonarQube reports zero coverage

- Confirm `jacocoTestReport` ran before `sonar`: check that the XML report exists at `build/reports/jacoco/test/jacocoTestReport.xml`.
- Confirm `sonar.coverage.jacoco.xmlReportPaths` points to the correct path.
- Confirm `tasks.named('sonar') { dependsOn jacocoTestReport }` is present.

### JAR name or version is wrong

- Confirm `release.properties` contains the correct `extension.name` and `extension.version`.
- Run `./gradlew generateReleaseProperties` to regenerate from annotations.
- Confirm `archiveBaseName` in the `jar` task reads from `release.properties`.

---

## See also

- [Project structure](ProjectStructure.md)
- [Java 21 patterns](Java21Patterns.md)
- [Framework 4 features](Framework4Features.md)
- [Testing strategy](TestingStrategy.md)
- [Extension annotations](../reference/ExtensionAnnotations.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
