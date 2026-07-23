<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Getting started](README.md) > Building and packaging

# Building and packaging

## Overview

Extensions are typically packaged as a Java JAR. This page summarizes the build/package steps and what to verify before uploading.

## Build steps

1. Clean build:
   - `./gradlew clean build`
2. Run tests:
   - `./gradlew test`

## Packaging checklist

Before you upload:

1. Inspect the artifact contents:
   - `jar tf build/libs/<your-jar>.jar`
2. Confirm required resources are present (if your extension uses them):
   - `META-INF/logo.png`
3. Confirm the extension is compiled for Java 21.

## See also

- [Development: Build configuration](../development/BuildConfiguration.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
