<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Local development workflow

# Local development workflow

## Overview

This page describes a practical, repeatable workflow for developing a Java-based Krista extension locally.

## Prerequisites

- Java **21** installed (or Gradle toolchains enabled)
- Gradle available (`./gradlew` preferred)
- Access to the target Krista platform environment (for smoke testing)

## Typical workflow

### 1) Build and run unit tests

1. Clean + build:
   - `./gradlew clean build`
2. Run tests only:
   - `./gradlew test`

> **📝 Note**: Prefer failing fast locally (unit tests + static checks) before uploading a JAR to a platform environment.

### 2) Iterate on a single area/request

When you change a catalog request:

1. Update validation first (inputs + cross-field checks)
2. Update the integration/service call
3. Update transformation into stable entities
4. Update tests

See: [Implement a catalog request](catalog-requests/ImplementCatalogRequest.md)

### 3) Inspect the built artifact

After a successful build:

- Inspect contents: `jar tf build/libs/<your-jar>.jar`
- Confirm key resources exist (for example `META-INF/logo.png`)

See: [Build configuration](BuildConfiguration.md)

### 4) Do a small smoke test

Use a minimal “happy path” request as your smoke test:

- a `QUERY_SYSTEM` request that reads a small payload
- returns a stable entity shape
- exercises auth + basic HTTP

## Debugging tips

1. Log request correlation identifiers and safe context (never secrets).
2. Prefer structured errors and consistent mapping.
3. Add focused tests for boundary cases (null/empty/invalid formats).

## See also

- [Build configuration](BuildConfiguration.md)
- [Testing strategy](TestingStrategy.md)
- [Error handling](../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
