# HTTP client, interceptors, resilience, pagination

Full code: `idioms/HttpClient.java`, `idioms/Interceptors.java`.

## HTTP client
- Build **one** shared `OkHttpClient` in the constructor: a `ConnectionPool` + **three** timeouts
  (connect/read/write) sourced from validated config, never hard-coded. Set `readTimeout` to the
  vendor's execution ceiling (autotask uses 300s).
- Install cross-cutting concerns as **interceptors** (auth → retry → optional logging → rate-limit),
  so no verb method touches headers or retry logic.
- **One private `execute()`** runs every verb: read the body exactly once, `try (Response ...)`,
  route non-2xx into `handleErrorResponse()`, null-default an empty success body.
- Verbs are one-liners over `execute`. Provide **204/no-content variants** that return the status code
  instead of parsing a body (deletes, workflow dispatch, PUT-updates often return 204).
- Centralize JSON in one `Gson` instance; register a custom adapter for the vendor's date format if
  needed (e.g. strip trailing `Z` before `LocalDateTime.parse`).

## Auth interceptor
Stateless; holds the config; rewrites every request with the required auth headers (Bearer token, or
username/secret/integration-code, etc.) + Accept/version. Debug-log the URL only — never the secret.

## Retry / backoff
- Retry **only transient** failures: 429/502/503/504 and `IOException`. Never retry 400/401/403/404.
- Exponential backoff **with jitter** (`2^(n-2) * base` + 0–50%); first retry may be immediate.
- Close the prior `Response` before each retry; restore the interrupt flag after `InterruptedException`;
  re-throw the last exception when attempts are exhausted.
- **Prefer resilience4j `Retry`/`CircuitBreaker` decorators** over a hand-rolled loop when you can.
  (autotask ships the resilience4j deps but never uses them and has no circuit breaker — don't do
  that; either use them or drop the deps.)

## Rate limiting
A response interceptor snapshots `X-RateLimit-*` headers into `volatile` fields (thread-safe reads) and
fails fast on `429` — or on `403` when `remaining == 0` — computing wait time from
`X-RateLimit-Reset`. Header parsing is null-safe and swallows `NumberFormatException`. Surface reset
info to the user via the error mapper. This is fail-fast (informative `IOException`), not blocking.

## Pagination
- **Query-param (default):** clamp `per_page` to the max (e.g. 100) in a `withPagination(path,page,size)`
  helper, and clamp again at the call site (defense in depth).
- **Link-header:** parse `rel="next"` from the `Link` header and follow the opaque URL **verbatim**
  (never reconstruct it). Use when you must auto-page the whole result set.
