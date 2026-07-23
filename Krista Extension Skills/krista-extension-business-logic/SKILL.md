---
name: krista-extension-business-logic
description: >-
  Write the PRODUCTION business-logic layer of a Krista extension — the code that
  krista-extension-scaffolding intentionally leaves as // TODO: the HTTP client + interceptors,
  service/operations orchestration, DTOs, DTO→entity transformers, input validation, error/exception
  mapping, retry/backoff, pagination, rate-limit handling, telemetry, and secret handling. Use when a
  developer says "implement the catalog request", "write the service / connector / HTTP client",
  "add validation / error handling / retry / pagination", "map the API response to the entity", or
  "make this production-ready". Produces code to the standard of the mature krista-global-catalog
  extensions (github, autotask). This is the implementation counterpart to krista-extension-scaffolding
  (structure) and Phase 4/5 of the krista-extension-builder runbook — scaffold the structure first,
  then fill it using the patterns and idioms here.
---

# Krista Extension — Business Logic (production standard)

> Part of the Krista extension skill set (see the folder `README.md`). This is the **implementation**
> layer for builder **Phases 4–5**: scaffold the framework with `krista-extension-scaffolding`, then
> fill the `// TODO` bodies using these patterns. The patterns are distilled verbatim from the mature
> `github` and `autotask` extensions.

## The layered model (write in this order)

```
@CatalogRequest method (Area)      ← thin: telemetry + the audited try/catch wrapper only
        │  delegates to
Service / Operations               ← orchestrates: validate → call connector → transform → build response; NEVER throws
        │  uses
Validation · Filter · Response · Error · Mapper   ← one @Service each, single responsibility
        │  calls
Connector (HTTP client, IHttpClient)  ← the ONLY thing that talks HTTP; throws typed exceptions
        │  returns
DTO (wire model)  →  Transformer  →  Entity (Krista @Entity)
```

Two proven shapes for the boundary between Area and connector:
- **Compact (github):** Area methods wrap logic in an `audited(name, () -> {...})` helper that owns
  the uniform try/catch→classify→`ExtensionResponse`+telemetry; the connector throws typed Java
  exceptions (`SecurityException`/`IllegalArgumentException`/`IllegalStateException`/`IOException`).
- **Decomposed (autotask):** a two-tier service layer — thin `system/*ServiceImpl` (HTTP + typed
  exceptions) and `service/*OperationsService` (orchestration, returns `ExtensionResponse`, never
  throws), with dedicated `validation`/`filter`/`response`/`error`/`mapper` `@Service` classes.

Pick **compact** for a small/medium extension, **decomposed** when a domain has many operations,
heavy validation, or client-side filtering. Both are documented in the references.

## Workflow — implementing one catalog request to production standard

1. **Connector first.** Ensure the HTTP client exists (`references/http-and-resilience.md`): one shared
   `OkHttpClient` (pooled, three timeouts from config), auth + retry + rate-limit as **interceptors**,
   one `execute()` path, centralized Gson (with any vendor date adapter), verbs incl. 204/no-content,
   and a single `handleErrorResponse()` that maps HTTP status → typed exception.
2. **DTO + transformer.** Define the wire DTO (or parse `JsonObject` directly) and a **stateless**
   transformer (`references/transform-validate.md`): null-in→null-out, null-safe field accessors,
   epoch-millis for `@Field.Date`, IDs as `String`. `transformList` never returns null.
3. **Validate inputs** (`references/transform-validate.md`): fail-fast, `IllegalArgumentException`
   with field name + reason + example. Parse-and-validate ID strings once.
4. **Orchestrate**: resolve inputs (fall back to configured defaults when blank), build the request
   body adding only non-blank properties, call the connector, transform, build the response.
5. **Build the response** (`references/errors-and-responses.md`): `new ExtensionResponseBuilder()
   .success(map)` / `.failure(msg)` (or an `ExtensionResponseFactory`); stable human-readable keys;
   for `CHANGE_SYSTEM`, a success envelope carrying a `Success` boolean is the convention.
6. **Wrap in the audited/telemetry boundary** (`references/telemetry-logging-security.md`): record
   start → success/failure/exception; classify caught exceptions into `ExtensionResponse` `ExceptionType`
   (AUTH / INPUT / SYSTEM); log start/success+duration/typed-failure at INFO/WARN/ERROR with the
   `invokerId` for correlation.
7. **Security pass** (`references/telemetry-logging-security.md`): never log secrets (mask to last-4),
   load attributes per `invokerId` (multi-tenant isolation), validate config at construction.
8. **Test** (`references/testing.md`): mock the `IHttpClient`; unit-test transformers, validation, and
   error mapping; use okhttp `mockwebserver` for the client.

## Choosing patterns by use case

| Use case | Reach for |
|---|---|
| Read/list with paging | pagination (query-param clamp to max, or Link-header follow) — `http-and-resilience.md` |
| Create/update/delete | conditional request-body building; 204 handling; idempotency key for retryable writes |
| Flaky/rate-limited API | retry interceptor (transient codes + backoff+jitter) + rate-limit handler (429/exhausted-403) |
| Rich object → Krista entity | transformer + null-safe accessors + type coercions |
| Many inputs / strict rules | a dedicated `*ValidationService` composed from a `ValidationUtil` toolkit |
| Large domain, many ops | the decomposed two-tier service layer |

## References & idioms

- `references/layering.md` — responsibilities of each layer + the two boundary shapes.
- `references/http-and-resilience.md` — HTTP client, interceptors, Gson, verbs/204, retry/backoff, rate limiting, pagination.
- `references/errors-and-responses.md` — exception hierarchy, status→exception mapping, the audited wrapper, `ExtensionResponse` building & classification, user-vs-log messages.
- `references/transform-validate.md` — DTO→entity transformers, null-safe accessors, coercions; the validation toolkit + domain validators.
- `references/telemetry-logging-security.md` — telemetry lifecycle, structured logging, secret handling, multi-tenant isolation.
- `references/testing.md` — mocking the client, unit-testing the pure units, mockwebserver.
- `references/production-checklist.md` — the combined go/no-go checklist.
- `idioms/` — real, adaptable code: `HttpClient`, `Interceptors`, `Exceptions`, `Transformer`, `Validation`, `ResponseFactory`, `Telemetry`, `AuditedArea`.
