<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Concepts](README.md) > Key terms

# Key terms

## Overview

This page defines common Krista extension terms used throughout this guide.

## Glossary

### Extension

An **extension** is a deployable integration package that connects Krista to an external system (for example GitHub, ServiceNow, or a custom API).

See: [Architecture](../architecture/README.md)

### Connector framework

The **connector framework** is the architectural approach for building extensions as “connectors” that:

- expose user-facing operations as **catalog requests**
- keep Krista-specific code at the boundary (controller/area layer)
- isolate external API calls in an integration layer

See: [Connector framework](../architecture/ConnectorFrameworkArchitecture.md)

### Setup tab

The **Setup tab** is where a user configures an invoker (attributes, dependencies, authentication choices) before using the extension.

See: [Setup tab](../setup-tab/README.md)

### Configuration

**Configuration** is the saved values from the Setup tab (attributes, auth configuration, defaults). It is persisted by the platform and is typically different per invoker.

See: [Configuration vs runtime behavior](ConfigurationVsRuntimeBehavior.md)

### Runtime behavior

**Runtime behavior** is what your code does when serving requests using the saved configuration (token refresh, retries, API calls, transformation).

See: [Configuration vs runtime behavior](ConfigurationVsRuntimeBehavior.md)

### Invoker

An **invoker** is a runtime instance of an extension bound to a specific saved configuration. Multiple invokers can exist for the same extension.

See: [Invokers and lifecycle](InvokersAndLifecycle.md)

### Invoker lifecycle

**Invoker lifecycle events** (for example `INVOKER_LOADED`, `INVOKER_UPDATED`) are hooks used to safely initialize and refresh runtime resources when an invoker starts or its configuration changes.

See: [Invokers and lifecycle](InvokersAndLifecycle.md)

### Catalog request

A **catalog request** is a user-invokable operation exposed by an extension.

Common types:

- **QUERY_SYSTEM**: read-only operations
- **CHANGE_SYSTEM**: state-changing operations
- **WAIT_FOR_EVENT**: wait/poll/webhook-style operations

See: [Entities and catalog requests](EntitiesAndCatalogRequests.md)

### Area

An **area** is a logical grouping label for catalog requests (for example “Repository Management” or “User Management”). In codebases, you will often see **Area classes** as the controller layer where `@CatalogRequest` methods live.

See: [Layered architecture](../architecture/LayeredArchitecture.md)

### Entity

An **entity** is a structured data model returned by catalog requests (and used across requests) to represent external-system concepts in a consistent way.

See: [Entities and catalog requests](EntitiesAndCatalogRequests.md)

### Domain

A **domain** is a logical grouping of related functionality within an extension (often aligned with an integration target and its capabilities).

See: [Extension lifecycle](ExtensionLifecycle.md)

### KSDK

The **KSDK** (Krista Software Development Kit) provides the core annotations, interfaces, and utilities used to build extensions.

See: [Reference](../reference/README.md)

## See also

- [Concepts](README.md)
- [Architecture](../architecture/README.md)
- [Development](../development/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
