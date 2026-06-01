<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../../kristaLogo.png)

**Breadcrumbs:** [Home](../../index.md) > [Development](../README.md) > [Catalog requests](README.md) > Implement a catalog request

# Implement a catalog request

## Overview

A catalog request is a public operation exposed by your extension. A good implementation is predictable, validated, observable, and easy to test.

## Step-by-step

### 1. Choose the request type

Pick `QUERY_SYSTEM`, `CHANGE_SYSTEM`, or `WAIT_FOR_EVENT` based on side effects and time semantics.

See: [Catalog request types](CatalogRequestTypes.md)

### 2. Implement in an Area (controller) class

Catalog request methods typically live in the controller layer (Area classes), which orchestrate calls into integration/transformation code.

See: [Layered architecture](../../architecture/LayeredArchitecture.md)

### 3. Define inputs with field annotations

- Use `@Field.*` annotations to declare parameters.
- Keep parameter names stable and user-friendly.
- Mark required fields as required.

### 4. Validate inputs before external calls

Validate:

- required fields present
- format constraints (IDs, URLs)
- cross-field rules (startDate < endDate)

Fail fast with user-actionable messages.

### 5. Call the integration layer

Keep the external API logic out of the controller layer. The integration layer should own:

- HTTP client construction
- authentication/token refresh
- retry/backoff and pagination

### 6. Transform into entities

Convert external payloads into stable entities/DTOs before returning. Avoid returning raw external models.

### 7. Return a clear response

Return:

- a success response with predictable keys
- structured outputs (entities) where possible
- useful metadata (counts, paging tokens) when relevant

### 8. Map errors consistently

Categorize failures so users know what to do next:

- input/validation failures
- authorization failures
- external system failures (timeouts, rate limits)

See: [Error handling](../../operations/ErrorHandling.md)

### 9. Test at the right level

- Unit test validation and transformation logic.
- Mock the integration layer for controller tests.
- Add a small number of end-to-end tests only when necessary.

## Checklist

- [ ] Correct request type
- [ ] Inputs validated before external calls
- [ ] External API calls isolated to integration layer
- [ ] Structured entities returned
- [ ] Errors mapped to actionable messages
- [ ] Metrics/logs include enough context (no secrets)

## Next steps

- Learn about [Sub-catalog requests](../SubCatalogRequests.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../../LICENSE).
