<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Architecture](README.md) > Connector framework architecture

# Connector framework architecture

## Overview

Krista extensions are designed as **connectors**: focused integration components that bridge the Krista platform and an external system.

Instead of building a monolithic application, you isolate external-system complexity (APIs, auth, data models, protocols) behind a consistent Krista-facing interface.

## Design principle

A connector should focus on:

1. **One external system** (or a tightly related suite such as Microsoft 365 / Google Workspace)
2. **Deep, reliable integration** (auth, pagination, rate limits, error formats)
3. **Clear boundaries** between layers (integration vs transformation vs controller)

## Core responsibilities

### 1) API integration

- Build requests, handle pagination and rate limits
- Implement authentication flows (for example OAuth 2.0) and token refresh
- Normalize external API response handling

### 2) Protocol abstraction

Hide protocol differences (REST, GraphQL, SOAP, webhooks, queues) so Krista interacts through consistent catalog requests.

### 3) State management

Manage connector runtime state safely:

- access/refresh tokens
- session identifiers
- connection pools
- caching (with invalidation rules)

### 4) Error translation

Translate external failures into actionable errors for Krista users:

- preserve context (what operation failed)
- map external codes to meaningful messages
- suggest remediation where possible

## Architectural benefits

- **Modularity**: connectors can be developed/deployed/scaled independently
- **Reusability**: a connector can support multiple use cases within the same external system
- **Maintainability**: external API changes are isolated to the connector
- **Testability**: each layer can be tested in isolation; integration calls can be mocked

## See also

- [Layered architecture](LayeredArchitecture.md)
- [Module and package structure](ModuleAndPackageStructure.md)
- [Catalog requests](../development/catalog-requests/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
