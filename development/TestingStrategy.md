<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Testing strategy

# Testing strategy

## Overview

A good testing strategy makes catalog requests predictable and safe to change. Aim for fast unit tests, a small number of integration tests, and clear ownership of what each test layer validates.

## Recommended layers

### 1) Unit tests (most of your tests)

Use unit tests for:

- input validation rules
- transformation/mapping to entities
- error mapping logic
- small helper/sub-catalog request logic

**Guideline:** unit tests should not call external systems.

### 2) Controller/Area tests (orchestrations)

Use controller/Area-level tests to verify:

- orchestration across validator → service → transformer
- that failures are mapped into consistent responses
- required telemetry/logging hooks are invoked (where applicable)

Mock the integration client/service layer.

### 3) Integration tests (few, high-signal)

Use integration tests only where they provide unique value:

- authentication/token refresh flows
- pagination/retry behavior against a sandbox
- webhook delivery handshake (for event-driven integrations)

Keep these tests isolated, and run them separately when possible.

## What to test for catalog requests

1. Required parameter handling
2. Cross-field validation (for example start < end)
3. External error mapping (401/403/429/5xx)
4. Stable output structure (keys and entity fields)
5. Retry/idempotency behavior for `CHANGE_SYSTEM`

## Testability design tips

1. Keep external calls behind a small interface (service/integration layer).
2. Prefer pure functions for transformation.
3. Avoid static/global state in request handlers.

## See also

- [Catalog requests](catalog-requests/README.md)
- [Sub-catalog requests](SubCatalogRequests.md)
- [Error handling](../operations/ErrorHandling.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
