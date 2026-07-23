---
name: krista-extension-testing
description: >-
  Unit-testing policy for a Krista extension — test the PURE JAVA classes ONLY, and deliberately
  neglect the Krista-framework code. Unit tests cover transformers/DTOs, validation, query & dialect
  builders, field-mapping registries, the HTTP client (via mockwebserver), and helpers (pagination,
  rate-limit, date, filename). They do NOT cover the @Extension class, @CatalogRequest Area methods,
  RequestAuthenticator, EntityStore @Service, or JAX-RS/@ApiRequest resources — those need the Krista
  runtime and are kept as thin delegators, validated by a green build + manual/integration testing.
  Use when adding or reviewing an extension's unit tests, when coverage should target the extractable
  logic, or when deciding what to test vs skip. Stack: JUnit 5 + Mockito + okhttp mockwebserver.
---

# Krista Extension — Testing (pure Java only)

> Part of the Krista extension skill set (see the folder `README.md`). Complements
> `krista-extension-business-logic` (whose `testing.md` has the pure-unit idioms). Part of builder
> **Phase 7** — `gradle test` must be green before the jar is produced.

## Policy

**Unit tests cover pure Java classes only. Do NOT unit-test the Krista-framework classes.** The
framework classes require the Krista runtime / DI container; mocking the whole platform is brittle,
slow, and low-value. Instead, keep those classes thin and push all real logic into framework-free
classes — and test those.

Framework classes are validated a different way: a **green `./gradlew build`** (the annotation
processor generates the descriptor, proving the annotations are correct) plus **manual / integration
testing on a Krista appliance**. Not by unit tests.

## The principle that makes "neglect" safe: keep framework classes THIN

- A `@CatalogRequest` method should be a delegator: resolve inputs → call the client/service →
  transform → build the `ExtensionResponse`. Nothing branchy worth a unit test.
- All testable logic lives in pure classes (transformers, validators, builders, helpers, the client).
- **If a framework class accumulates real logic, EXTRACT it into a plain class and unit-test that.**
  A fat `@CatalogRequest`/`@Extension` method with untested branches is the smell to fix — not by
  mocking the platform, but by moving the logic out.

## What to unit-test (pure Java) — the coverage target

| Class | Test |
|---|---|
| Transformers (JSON→entity) | nulls, missing keys, type coercions (id→String, epoch-millis), `transformList` skips non-objects / never null |
| Validation toolkit + domain validators | each rule throws `IllegalArgumentException` with an actionable message; parse-and-validate returns the typed value |
| Query / dialect builder, field-mapping registry (entity search) | operator×type matrix, IN grouping, **injection rejection**, unknown field → null, case-insensitivity |
| HTTP client (`@Service` but framework-free) | via okhttp **MockWebServer**: status→exception mapping, 204/no-content, headers/auth, retry/backoff |
| Helpers | pagination clamps, rate-limit header parsing, date/epoch conversion, filename sanitize, JSON accessors, `KristaMediaClient` zip/name logic |
| Error-message services, response-shaping helpers | plain `Map` building / message text |

## What to NEGLECT (no unit tests) — validated other ways

- `<X>Extension` (`@Extension` + `@InvokerRequest` lifecycle)
- `<X>Area` (`@CatalogRequest` methods)
- `<X>RequestAuthenticator`
- `<Entity>Store` (`EntityStore` `@Service`) — unit-test the DAO / query-builder it delegates to instead
- JAX-RS resources / `@ApiRequest` webhooks

Validate these via: a green build (annotation processor) + a manual/integration pass on a real Krista
appliance (Test Connection, run each catalog request once, fire a webhook).

## Stack

JUnit 5 (`org.junit.jupiter:junit-jupiter`), Mockito (`mockito-core` + `mockito-junit-jupiter` —
`@Mock`/`@InjectMocks` or plain `mock()`), okhttp `mockwebserver` — all already in the scaffolding
`build.gradle`. (Optional `com.kristasoft.common:common-test`; not required.)

## Workflow

1. Enumerate the **pure-Java** classes (transformers, validators, builders, registries, helpers, the
   client). Each gets a `*Test`.
2. Write the tests — see `krista-extension-business-logic/testing.md` and its idioms
   (`Transformer`, `Validation`, `HttpClient` via mockwebserver).
3. For any **framework** class that holds branchy logic, refactor: extract the logic to a plain class
   and test that. Leave the framework class a thin, untested delegator.
4. `gradle test` green (builder Phase 7) before the jar.

## Coverage checklist

- [ ] Every transformer, validator, query builder / field registry, and helper has a unit test.
- [ ] HTTP client tested with MockWebServer (status mapping, 204, headers, retry).
- [ ] Framework classes intentionally NOT unit-tested — **and** thin enough to contain no untested
      logic (if one isn't, extract the logic to a pure class and test it).
- [ ] No real network (MockWebServer only); no secrets in tests (use dummy tokens).

## Files

- `references/what-to-test.md` — the pure-vs-neglect classification + the extract-for-testability rule.
- Idioms live in `krista-extension-business-logic/` (`testing.md` + `idioms/Transformer.java`,
  `Validation.java`, `HttpClient.java`) — reused here rather than duplicated.
