<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > Architecture

# Architecture

## Overview

How extensions are structured and how components interact at runtime.

This section is extracted from the monolithic guide’s architecture chapters and reorganized into focused pages.

## What you’ll learn

- The connector-framework design principle (extensions as focused connectors)
- The layered architecture (controller → transformation → integration)
- How to organize packages/modules so boundaries stay clear and testable

## Topics

- [Connector framework architecture](ConnectorFrameworkArchitecture.md)
- [Layered architecture](LayeredArchitecture.md)
- [Module and package structure](ModuleAndPackageStructure.md)

## Quick reference

- **Integration layer**: talks to the external API; **no Krista dependencies**
- **Transformation layer**: converts external models ↔ Krista entities
- **Controller (Area) layer**: Krista-facing request handlers + orchestration

## Next steps

- Implement operations using [Catalog requests](../development/catalog-requests/README.md).



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
