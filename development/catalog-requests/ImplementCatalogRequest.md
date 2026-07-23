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

## Async catalog requests

Some operations take too long to complete synchronously. Use the async pattern:

1. Generate a unique task ID
2. Submit the work to an `ExecutorService` background thread
3. Return the task ID immediately to the caller
4. When the background work completes, deliver the result via `EventHandler.handleEvent(taskId, result)`
5. The caller retrieves results through a separate "Get Result" catalog request

Use this pattern for bulk operations, long-running exports, or operations that depend on external processing time. Pair the async request with a corresponding `QUERY_SYSTEM` request to retrieve results.

## Health check request

Most extensions include a standard health check catalog request in the Setup area:

- Type: `QUERY_SYSTEM` (or `CHANGE_SYSTEM`)
- Area: `"Setup"`
- Returns: boolean health status plus system resource details (memory, connectivity)
- Purpose: verify the extension appliance is running and can reach external dependencies

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
