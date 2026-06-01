<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Project structure

# Project structure

## Overview

This page describes a recommended Java extension project layout that supports Krista’s layered architecture and keeps code testable.

## Recommended layout

A typical Gradle-based extension looks like:

```text
my-extension/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/yourcompany/krista/extension/{system}/
│   │   │       ├── {System}Extension.java
│   │   │       ├── controller/        # Area classes + request orchestration
│   │   │       ├── integration/       # External API clients/auth/errors
│   │   │       ├── transformation/    # External models ↔ Krista entities
│   │   │       ├── entity/            # Krista-facing entities/DTOs
│   │   │       └── config/            # Attribute keys, config parsing
│   │   └── resources/
│   │       └── META-INF/
│   │           └── logo.png
│   └── test/
│       └── java/
│           └── com/yourcompany/krista/extension/{system}/
└── build.gradle
```

> **📝 Note**: Package names in this guide are illustrative. Use your organization’s conventions.

## How this maps to the layered architecture

- **Controller (Areas)**: Krista-facing entry points (`@CatalogRequest`, `@InvokerRequest`), orchestration, response formatting
- **Integration**: HTTP clients, auth/token handling, retries/backoff, external error mapping
- **Transformation**: map external payloads into stable Krista entities and vice versa
- **Entities**: request/response models returned by catalog requests
- **Config**: centralize attribute keys and parsing (avoid scattering string keys)

See: [Layered architecture](../architecture/LayeredArchitecture.md)

## Resources and packaging expectations

Most extensions include:

- `META-INF/logo.png` referenced by the `@Extension(logo=...)` annotation
- any static configuration files required by your integration client

Keep secrets out of resources; secrets should come from **secured attributes**.

## Testing layout

Recommended test organization mirrors `src/main/java`:

- `controller/` tests: request orchestration + input validation
- `integration/` tests: API client behavior (mock HTTP)
- `transformation/` tests: mapping logic + edge cases

## Best practices

1. Keep Krista annotations in controller/area code only.
2. Make integration and transformation code usable without the Krista runtime.
3. Prefer immutable entities (for example Java records).
4. Centralize attribute names and parsing in `config/`.

## See also

- [Module/package structure](../architecture/ModuleAndPackageStructure.md)
- [Build configuration](BuildConfiguration.md)
- [Catalog requests](catalog-requests/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
