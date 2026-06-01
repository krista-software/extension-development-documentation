<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Build configuration

# Build configuration

## Overview

This page provides a Gradle-oriented baseline for building and packaging a Java extension.

## Java toolchain

Prefer a toolchain so builds are reproducible:

- Set the Java toolchain to **21**.
- Declare the runtime requirement via the extension’s `@Java(version = ...)` annotation.

## Repositories and dependencies

Most extensions depend on:

- Krista extension APIs + annotation processors
- an HTTP client stack (often JAX-RS/Jersey)
- JSON support (Jackson)
- test libraries (JUnit/Mockito)

> **📝 Note**: Use the artifact coordinates and versions published for your Krista platform/KSDK version. Avoid copying version numbers between incompatible platform releases.

## Annotation processing

Catalog request metadata is typically discovered via annotation processing. Ensure:

- the Krista annotation processor is configured (for example via Gradle `annotationProcessor`)
- generated sources (if any) are included by the build

## Packaging checklist (JAR)

Before you ship a JAR:

1. `gradle clean build`
2. Inspect the artifact:
   - `jar tf build/libs/<your-jar>.jar`
3. Confirm resources are present:
   - `META-INF/logo.png`
4. Confirm the extension class is included and compiled for Java 21.

## Common Gradle tasks

- Build: `gradle clean build`
- Test: `gradle test`
- Show dependencies: `gradle dependencies`

## Troubleshooting

### Build fails due to Java version

- Verify your local JDK can provision the toolchain.
- Verify the extension is annotated with `@Java(version = JAVA_21)`.

### Missing annotation-generated metadata

- Confirm the Krista annotation processor dependency is configured.
- Confirm annotation processing is enabled for your build.

## See also

- [Project structure](ProjectStructure.md)
- [Java 21 patterns](Java21Patterns.md)
- [Extension annotations (overview)](../reference/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
