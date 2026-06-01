<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](kristaLogo.png)

# Complete Extension Development Guide

This documentation set helps you design, build, and operate Krista extensions.

## Start here

1. Read **[Getting started](getting-started/README.md)** to understand prerequisites and the recommended workflow.
2. Use **[Setup tab](setup-tab/README.md)** to configure and validate your extension.
3. Implement behaviors using **[Catalog requests](development/catalog-requests/README.md)**.

## Documentation navigation

Use this page as a clickable table of contents (mirrors the docs sidebar).

### Getting started

- [Getting started](getting-started/README.md)
  - [Prerequisites](getting-started/Prerequisites.md)
  - [Local development workflow](getting-started/LocalDevelopmentWorkflow.md)
  - [Building and packaging](getting-started/BuildingAndPackaging.md)
- [Setup tab](setup-tab/README.md)
  - [Attributes](setup-tab/Attributes.md)
  - [Dependencies](setup-tab/Dependencies.md)
  - [Authentication](setup-tab/Authentication.md)
  - [Trust](setup-tab/Trust.md)
  - [Validation and troubleshooting](setup-tab/ValidationAndTroubleshooting.md)
  - [Save changes](setup-tab/SaveChanges.md)

### Concepts

- [Concepts](concepts/README.md)
- [Key terms](concepts/KeyTerms.md)
- [Extension lifecycle](concepts/ExtensionLifecycle.md)
- [Invokers and lifecycle](concepts/InvokersAndLifecycle.md)
- [Configuration vs runtime behavior](concepts/ConfigurationVsRuntimeBehavior.md)
- [Entities and catalog requests](concepts/EntitiesAndCatalogRequests.md)

### Architecture

- [Architecture](architecture/README.md)
- [Connector framework](architecture/ConnectorFrameworkArchitecture.md)
- [Layered architecture](architecture/LayeredArchitecture.md)
- [Module/package structure](architecture/ModuleAndPackageStructure.md)

### Development

- [Development](development/README.md)
- [Catalog requests](development/catalog-requests/README.md)
  - [Catalog request types](development/catalog-requests/CatalogRequestTypes.md)
  - [Implement a catalog request](development/catalog-requests/ImplementCatalogRequest.md)
  - [Designing inputs and outputs](development/catalog-requests/DesigningInputsAndOutputs.md)
  - [Validation and error mapping](development/catalog-requests/ValidationAndErrorMapping.md)
  - [Retry and idempotency](development/catalog-requests/RetryAndIdempotency.md)
- [Project structure](development/ProjectStructure.md)
- [Build configuration](development/BuildConfiguration.md)
- [Java 21 patterns](development/Java21Patterns.md)
- [Local development workflow](development/LocalDevelopmentWorkflow.md)
- [Testing strategy](development/TestingStrategy.md)
- [Sub-catalog requests](development/SubCatalogRequests.md)

### Advanced

- [Advanced](advanced/README.md)
  - [Authentication patterns](advanced/AuthPatterns.md)
  - [Pagination and rate limits](advanced/PaginationRateLimits.md)
  - [Eventing and webhooks](advanced/EventingWebhooks.md)

### Operations

- [Operations](operations/README.md)
- [Error handling](operations/ErrorHandling.md)
- [Observability](operations/Observability.md)
- [Deployment and configuration](operations/DeploymentAndConfiguration.md)
- [Troubleshooting](operations/Troubleshooting.md)

### Performance

- [Performance](performance/README.md)
  - [Minimizing external API calls](performance/MinimizingExternalAPICalls.md)
  - [Pagination and batching](performance/PaginationAndBatching.md)
  - [Timeouts and retries](performance/TimeoutsAndRetries.md)

### Reference

- [Reference](reference/README.md)
- [Extension annotations](reference/ExtensionAnnotations.md)
- [KSDK classes and interfaces](reference/KsdkReference.md)
- [Invoker requests (@InvokerRequest)](reference/InvokerRequests.md)
- [API requests (@ApiRequest)](reference/ApiRequests.md)
- [Entity requests (@EntityRequest)](reference/EntityRequests.md)

### Custom agents

- [Custom agents](custom-agents/README.md)
  - [Hosting URL endpoint](custom-agents/HostingUrlEndpoint.md)
  - [Domain registration](custom-agents/DomainRegistration.md)
  - [Packaging and deployment](custom-agents/PackagingAndDeployment.md)
  - [Best practices](custom-agents/BestPractices.md)

### Examples

- [Examples](examples/README.md)

### FAQ

- [FAQ](faq/README.md)

## Legacy guide (source)

If you need the original monolithic guide, see `Complete_Extension_Development_Guide_final.md` in the repository root.



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).
