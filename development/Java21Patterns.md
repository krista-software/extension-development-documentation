<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Development](README.md) > Java 21 patterns

# Java 21 patterns

## Overview

Krista extensions can target **Java 21** for cleaner code and better scalability. This page highlights practical patterns that fit extension workloads (I/O-heavy, validation-heavy, mapping-heavy).

## Recommended language features

### 1. Records for immutable data

Use records for:

- entities returned by catalog requests
- transformation DTOs
- integration-layer models (when stable)

Benefits: concise, immutable-by-default, good for mapping and testing.

### 2. Switch expressions + pattern matching

Use switch expressions to simplify request-type or error-type branching (prefer data-driven mapping over deep `if/else`).

### 3. Text blocks for templates

Text blocks improve readability for:

- JSON payload templates
- multi-line error descriptions
- sample requests/responses used in tests

### 4. Sealed hierarchies for domain errors

A sealed interface/class hierarchy can represent integration failures precisely (rate limit vs auth vs not found) and map them into Krista error categories consistently.

## Concurrency: virtual threads (use with care)

Virtual threads can help if you make many outbound I/O calls (HTTP) concurrently.

Guidelines:

1. Prefer simple, synchronous clients; virtual threads reduce the need for complex async code.
2. Limit concurrency with a bounded executor/semaphore to avoid hammering external APIs.
3. Always implement timeouts and retry/backoff; virtual threads make it easy to overload a dependency.

> **⚠️ Warning**: Do not rely on Java preview features unless your platform runtime explicitly enables them.

## API-level best practices

- Prefer small, pure transformation functions.
- Keep `controller/` orchestration readable; push heavy logic into services.
- Use clear validation errors early, before external calls.

## See also

- [Error handling](../operations/ErrorHandling.md)
- [Layered architecture](../architecture/LayeredArchitecture.md)
- [Catalog requests](catalog-requests/README.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
