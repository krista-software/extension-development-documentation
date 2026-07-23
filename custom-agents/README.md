<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > Custom agents

# Custom agents

## Overview

Custom agent extensions allow you to extend the Krista platform with specialized agents that integrate seamlessly into the platform's user interface. Once properly implemented, your custom agent will appear in the **Agent Setup → Agent List** section and its dashboard will be embedded in the user's **Home** page under the **Topic** section.

This section provides comprehensive guidance for building, testing, and deploying custom agent extensions.

## What you'll learn

- How to implement the required hosting URL endpoint
- Domain and ecosystem registration requirements
- Packaging and deployment workflows
- Best practices for custom agent development

## Topics

- [Hosting URL endpoint](HostingUrlEndpoint.md)
- [Domain registration](DomainRegistration.md)
- [Packaging and deployment](PackagingAndDeployment.md)
- [Best practices](BestPractices.md)

## Quick start

1. Implement the `/hostUrl` REST endpoint that returns your agent's hosting URL
2. Register your extension with the Krista ecosystem and Agent domain
3. Package your extension as a `.daz` file
4. Import into Private Catalog for testing
5. Deploy to Global Catalog for production use

## Key requirements

- **JAX-RS ID**: Must be set to `default REST`
- **Hosting URL**: Must be stable, publicly accessible, and support HTTPS
- **Domain ID**: `catEntryDomain_c54d9930-ea03-4c58-bee6-26f90939171d`
- **Ecosystem ID**: `catEntryEcosystem_d3b05047-07b0-4b06-95a3-9fb8f7f608d9`

## Related topics

- [Extension annotations](../reference/ExtensionAnnotations.md)
- [Catalog requests](../development/catalog-requests/README.md)
- [Deployment and configuration](../operations/DeploymentAndConfiguration.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).

