<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Architecture](README.md) > Layered architecture

# Layered architecture

## Overview

Krista extensions follow a strict layered architecture so responsibilities stay separated and testing remains straightforward.

## Layers

### Controller layer (Area classes)

- Exposes extension operations to Krista via annotations (for example `@CatalogRequest`)
- Validates inputs, applies business rules, formats responses
- Orchestrates calls into lower layers

### Transformation layer

- Converts raw external data into Krista entities (and vice versa)
- Enriches/derives fields, applies mapping rules

### Integration layer

- Pure external-system communication
- **Zero Krista dependencies** (no Krista annotations / interfaces)
- Returns raw responses (or integration-specific models)

### External system API

The remote system (REST/GraphQL/SOAP/etc.) you’re integrating with.

## Data flow

1. Krista calls a catalog request in the **Controller layer**
2. Controller validates parameters and applies business rules
3. Controller calls **Transformation** with validated inputs
4. Transformation calls **Integration** to fetch/submit raw data
5. Integration calls the external API
6. Data returns upward; Transformation converts to Krista entities
7. Controller returns the final response to Krista

## Dependency rules

- Each layer depends only on the layer below it
- Integration must be usable as a standalone Java module (no Krista types)
- Controller is the only layer that knows about Krista request/response contracts

## Common mistakes to avoid

- Putting Krista annotations or business logic inside the integration module
- Returning Krista entities directly from the integration layer
- Skipping transformation and letting controllers do complex mapping

## See also

- [Connector framework architecture](ConnectorFrameworkArchitecture.md)
- [Module and package structure](ModuleAndPackageStructure.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
