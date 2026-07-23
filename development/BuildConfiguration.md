<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Build configuration

# Build configuration

## Overview

Every Krista extension ships as a fat JAR built with Gradle. This page covers the build plugins, dependency layout, test setup, code-quality tooling, and packaging conventions.

## Plugins

A typical extension applies:

- `java` / `java-library` — standard compilation
- `maven-publish` — publish to the Krista artifact repository
- `jacoco` — code-coverage reports
- `org.sonarqube` — static analysis

If your extension bundles a web UI (for example an OAuth page), add the Node/Yarn plugin as well.

## Java toolchain

- Set `sourceCompatibility` and `targetCompatibility` to **Java 21**.
- Declare the same version in the extension class with `@Java(version = Java.Version.JAVA_21)`.
- Enable UTF-8 encoding and compiler warnings across all compile tasks.

## Repositories and dependencies

### Repositories

Resolve dependencies from the Krista artifact repository first, then Maven Central.

### Core dependencies

Every extension needs:

- **Annotation processor** — `app.krista:extension-impl-anno-processors` (generates catalog-request metadata at compile time)
- **Runtime APIs** — `app.krista:krista-apis`
- **Dependency injection** — `org.glassfish.hk2:hk2-api`
- **Logging** — `org.apache.logging.log4j:log4j-slf4j-impl`

Pin the annotation processor and runtime APIs to the same platform release. Never mix versions from different releases.

### Test dependencies

- JUnit 5 (`junit-jupiter-api`, `junit-jupiter-engine`)
- Mockito (`mockito-core`, `mockito-junit-jupiter`)
- Krista common test utilities (`com.kristasoft.common:common-test`)

### Mockito with Java 21

Java 21 requires extra configuration for Mockito:

1. Set `-Dnet.bytebuddy.experimental=true` in test JVM args.
2. Set system property `mockito.mock.maker` to `subclass`.
3. Attach the Byte Buddy agent via `-javaagent`.

## Code quality

### JaCoCo

- Use JaCoCo toolchain version `0.8.11` or later.
- Generate XML reports (required by SonarQube) and HTML reports (useful for local review).
- Chain `jacocoTestReport` to run after `test`.

### SonarQube

Configure the SonarQube plugin with these properties:

- `sonar.projectKey` — unique key for your extension
- `sonar.sources` / `sonar.tests` — point to `src/main/java` and `src/test/java`
- `sonar.java.binaries` / `sonar.java.test.binaries` — compiled class directories
- `sonar.coverage.jacoco.xmlReportPaths` — path to JaCoCo XML report
- `sonar.junit.reportPaths` — path to JUnit test results

Ensure the `sonar` task depends on `jacocoTestReport` so coverage data is available.

## Version management

### release.properties

Maintain a `release.properties` file at the project root:

- `extension.name` — display name
- `extension.version` — semantic version (X.Y.Z)
- `domain.name` — domain the extension belongs to
- `ecosystem.name` — ecosystem the extension belongs to

The JAR task reads this file to set the archive name and version.

### Keeping versions in sync

These three locations must always agree:

- `@Extension(version = "X.Y.Z")` in the extension class
- `extension.version` in `release.properties`
- `patch` in `version.properties` (if present)

### generateReleaseProperties task

Most extensions include a `generateReleaseProperties` Gradle task that eliminates manual drift:

1. Parses the `@Extension` annotation for `version` and `name`
2. Parses the `@Domain` annotation for `domain.name` and `ecosystem.name`
3. Writes the extracted values to `release.properties`

The JAR task should depend on this task so properties are always current at build time. The task uses regex matching against the source files — no compilation required.

## Packaging (fat JAR)

Extensions ship as a single fat JAR:

- Bundle all runtime dependencies by collecting `runtimeClasspath` into the JAR.
- Exclude signature files (`META-INF/*.RSA`, `*.SF`, `*.DSA`) from third-party JARs.
- Set `duplicatesStrategy` to `exclude` to resolve conflicts.
- Optionally embed source under `META-INF/project/src` for platform-side debugging.

## Common Gradle tasks

- `./gradlew clean build` — full clean build
- `./gradlew compileJava` — compile only (fast pre-commit check)
- `./gradlew test` — run all tests
- `./gradlew jacocoTestReport` — generate coverage report
- `./gradlew sonar` — run SonarQube analysis
- `./gradlew dependencies` — show dependency tree

## Troubleshooting

- **Java version mismatch** — verify `sourceCompatibility`, `targetCompatibility`, and `@Java` annotation all target 21.
- **Missing annotation metadata** — confirm the annotation processor dependency is declared and run a clean compile.
- **Mockito failures on Java 21** — confirm Byte Buddy experimental mode and subclass mock maker are enabled.
- **SonarQube reports zero coverage** — confirm the JaCoCo XML report exists before the `sonar` task runs.
- **Wrong JAR name** — confirm `release.properties` is up to date and the `jar` task reads from it.

## See also

- [Project structure](ProjectStructure.md)
- [Java 21 patterns](Java21Patterns.md)
- [Testing strategy](TestingStrategy.md)
- [Extension annotations](../reference/ExtensionAnnotations.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
