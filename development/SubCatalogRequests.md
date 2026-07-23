<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Sub-catalog requests

# Sub-catalog requests

## Overview

**Sub-catalog requests** are helper operations used to break complex workflows into reusable steps. They support catalog requests but are not meant to be primary user-facing operations.

## When to use them

Use sub-catalog requests when you need:

- a reusable validation step shared by multiple catalog requests
- a common lookup (for example “resolve user”, “fetch project settings”)
- a multi-step workflow where steps are easier to test in isolation

Avoid sub-catalog requests for trivial logic that can remain private methods.

## How they differ from catalog requests

- Catalog requests are the main operations exposed to users.
- Sub-catalog requests are supporting operations used by other requests.
- Sub-catalog requests should remain small, deterministic, and easy to compose.

## Design guidelines

1. Keep inputs explicit; avoid reading global/static state.
2. Prefer idempotent behavior where possible.
3. Propagate typed errors so the caller can map them to user-facing responses.
4. Document which catalog requests depend on the sub-request.

## Testing guidance

- Unit test each sub-catalog request for edge cases.
- In higher-level tests, verify orchestration (catalog request → sub-catalog request chain).

## Common pitfalls

- Making sub-catalog requests do “too much” orchestration.
- Returning raw external payloads instead of stable entities/DTOs.
- Using them as a workaround for missing validation in the main request.

## See also

- [Catalog requests](catalog-requests/README.md)
- [Entities and catalog requests (concepts)](../concepts/EntitiesAndCatalogRequests.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
