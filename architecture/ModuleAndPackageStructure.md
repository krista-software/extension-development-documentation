<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Architecture](README.md) > Module and package structure

# Module and package structure

## Overview

A modular extension structure helps keep boundaries clear, improves testability, and makes long-term maintenance safer.

The monolithic guide describes five core sub-modules; use them as a baseline for most extensions.

## Recommended sub-modules

| Module | Purpose | Typical package prefix |
|--------|---------|------------------------|
| External integration | Third-party communication (HTTP, auth, retries, pagination) | `com.yourcompany.integration.{system}` |
| Transformation | Mapping between external models and Krista entities | `com.yourcompany.krista.extension.{system}.transformation` |
| Controller (Areas) | Krista request handlers & orchestration | `com.yourcompany.krista.extension.{system}.controller` |
| Entities | Krista entity definitions + annotations | `com.yourcompany.krista.extension.{system}.entity` |
| Configuration | Extension settings, invoker attributes, validation | `com.yourcompany.krista.extension.{system}.config` |

## Responsibilities by module

### External integration

- HTTP client setup (timeouts, pooling)
- Authentication flows and token refresh
- Request/response serialization
- Rate limit handling
- Translate external errors into integration exceptions

### Transformation

- Bidirectional mapping (external → Krista, Krista → external)
- Validation of mapped data
- Enrichment/derived fields

### Controller

- Validate inputs and apply business rules
- Orchestrate integration/transformation
- Convert exceptions into user-friendly error responses

### Entities

- Stable contract between extension and Krista UI/platform
- Annotations for UI rendering/search/storage as required

### Configuration

- Connection settings and credentials metadata
- Environment/feature flags
- Validation for required settings

## Dependency and data flow

- Controller → Transformation → Integration → External system
- Errors bubble up with context; Controller maps them to user-facing errors

## Example package layout (simplified)

- `.../{System}Extension.java`
- `.../integration/*`
- `.../transformation/*`
- `.../controller/*`
- `.../entity/*`
- `.../config/*`

## See also

- [Layered architecture](LayeredArchitecture.md)
- [Connector framework architecture](ConnectorFrameworkArchitecture.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
