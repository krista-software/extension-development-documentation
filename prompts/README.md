# Krista Extension Development Prompts

A collection of 29 detailed prompts for extension developers to use with AI assistants when building Krista Extensions.

## Overview

These prompts are designed to be executed by AI coding assistants (like GitHub Copilot, Claude, or similar tools) to help developers quickly scaffold, implement, and test Krista Extensions following best practices.

## How to Use

1. Open the prompt file for your use case
2. Copy the entire prompt content
3. Replace the placeholder values (marked with `{{PLACEHOLDER}}` or `{PLACEHOLDER}`) with your specific values
4. Paste into your AI assistant
5. Follow the generated implementation

## Prompt Categories

### Category 1: Extension Creation

| # | Prompt | Description |
|---|--------|-------------|
| 01 | [Create Extension with OAuth 2.0](01-create-extension-oauth2.md) | Full extension with OAuth 2.0 authentication |
| 02 | [Create Extension with API Key](02-create-extension-apikey.md) | Full extension with API key authentication |
| 03 | [Create Extension with Username/Password](03-create-extension-basic-auth.md) | Full extension with basic authentication |
| 04 | [Create Minimal Extension](04-create-extension-minimal.md) | Minimal extension skeleton |

### Category 2: Catalog Requests

| # | Prompt | Description |
|---|--------|-------------|
| 05 | [Add QUERY_SYSTEM Request](05-add-query-system-request.md) | Read-only catalog request with pagination |
| 06 | [Add CHANGE_SYSTEM Request](06-add-change-system-request.md) | Create/update/delete catalog request |
| 07 | [Add WAIT_FOR_EVENT (Polling)](07-add-wait-for-event-polling.md) | Event-driven request using polling |
| 08 | [Add WAIT_FOR_EVENT (Webhook)](08-add-wait-for-event-webhook.md) | Event-driven request using webhooks |
| 09 | [Add Request with Complex Validation](09-add-request-complex-validation.md) | Multi-field validation rules |

### Category 3: Sub-Catalog Requests & Helpers

| # | Prompt | Description |
|---|--------|-------------|
| 10 | [Add Sub-Catalog Request](10-add-subcatalog-request.md) | Helper operation for parent request |
| 11 | [Add Helper Class](11-add-helper-class.md) | Helper with validation and telemetry |

### Category 4: Setup Tab & Configuration

| # | Prompt | Description |
|---|--------|-------------|
| 12 | [Configure Setup Tab](12-configure-setup-tab.md) | Custom fields configuration |
| 13 | [Implement VALIDATE_ATTRIBUTES](13-implement-validate-attributes.md) | Attribute validation |
| 14 | [Implement TEST_CONNECTION](14-implement-test-connection.md) | Connection test handler |

### Category 5: Lifecycle & Error Handling

| # | Prompt | Description |
|---|--------|-------------|
| 15 | [Implement Lifecycle Hooks](15-implement-lifecycle-hooks.md) | Load/update/unload handlers |
| 16 | [Implement Error Handling](16-implement-error-handling.md) | Error categorization and mapping |
| 17 | [Add Retry Support](17-add-retry-idempotency.md) | Retry and idempotency |

### Category 6: Testing & Integration

| # | Prompt | Description |
|---|--------|-------------|
| 18 | [Write Unit Tests](18-write-unit-tests.md) | Unit tests for catalog requests |
| 19 | [Write Integration Tests](19-write-integration-tests.md) | Integration tests for auth flows |
| 20 | [Add Webhook Handler](20-add-webhook-handler.md) | Webhook handler with signature validation |

### Category 7: Reference Guides & Best Practices

| # | Prompt | Description |
|---|--------|-------------|
| 21 | [Field Types Reference](21-field-types-reference.md) | Complete guide to field annotations and response patterns |
| 22 | [Architecture & Design Patterns](22-architecture-design-patterns.md) | Package structure, connection management, error handling |
| 23 | [Configure Log Levels](23-configure-log-levels.md) | Dynamic log level configuration with LogLevelManager |
| 24 | [Entity Development](24-entity-development.md) | Entity definition, transformation pipeline, EntityReference/EntityValue |
| 25 | [Extension Versioning](25-extension-versioning.md) | Automated semantic versioning with Gradle |
| 26 | [WAIT_FOR_EVENT Implementation](26-wait-for-event.md) | Event-driven architecture patterns |
| 27 | [MultiField Guide](27-multifield-guide.md) | Composite field types for grouped data |
| 28 | [PR Requirements](28-pr-requirements.md) | Quality standards and pre-submission checklist |
| 29 | [Getting Started](29-getting-started-catalog-requests.md) | First catalog request tutorial |

## Prerequisites

Before using these prompts, ensure you have:

- Java 21+ development environment
- Gradle build system
- Understanding of Krista Extension architecture
- Access to the target external API documentation

## Reference Documentation

- [Extension Development Documentation](https://github.com/krista-software/extension-development-documentation)
- [Example Extensions](https://github.com/krista-software)

## License

These prompts are provided under the GNU General Public License v3.0.

