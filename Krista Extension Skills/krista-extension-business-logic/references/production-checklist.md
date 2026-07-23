# Production checklist (business logic)

Distilled from github + autotask. Treat as go/no-go before a PR.

## HTTP client
- [ ] One shared `OkHttpClient` (connection pool + connect/read/write timeouts from validated config; read-timeout = vendor ceiling).
- [ ] Auth / retry / rate-limit are **interceptors**, not per-call code.
- [ ] One `execute()` path; body read once; `try (Response)`; empty success body null-defaulted.
- [ ] 204/no-content verb variants return the status code.
- [ ] One centralized `Gson` (+ vendor date adapter).

## Resilience
- [ ] Retry only transient (429/502/503/504 + `IOException`); never 400/401/403/404.
- [ ] Exponential backoff **with jitter**; close prior `Response`; restore interrupt flag; re-throw last.
- [ ] Rate-limit handler: snapshot `X-RateLimit-*`, fail fast on 429/exhausted-403 with reset time.
- [ ] resilience4j decorators used if declared (or deps removed). No unused resilience deps.

## Errors & responses
- [ ] Single status→exception mapping point; full context logged, friendly message to the user.
- [ ] User-facing messages are actionable constants; raw URLs stay in logs only.
- [ ] Uniform try/catch → `ExtensionResponse` classification (AUTH/INPUT/SYSTEM) via `audited`/OperationsService.
- [ ] `MustAuthorize/MustAuthenticateException` re-thrown, never swallowed.
- [ ] Responses use stable keys; CHANGE_SYSTEM uses the `Success` envelope.

## Transform / validate
- [ ] Every domain-object response is an `@Entity` with a typed `Entity(X)` / `[ Entity(X) ]` output — NOT a raw FreeForm/Map passthrough.
- [ ] Transformers stateless/static; null-in→null-out; `transformList` never null.
- [ ] All JSON reads via null-safe accessors; IDs→String; timestamps→epoch-millis.
- [ ] Fail-fast validation with field+reason+example; validate before external calls.
- [ ] Request bodies add only non-blank properties; inputs fall back to configured defaults.

## Telemetry / logging / security
- [ ] Telemetry lifecycle (start→success/failure/exception); low-cardinality attributes; never crashes logic.
- [ ] INFO/WARN/ERROR discipline with `invokerId`; no bodies logged by default.
- [ ] Secrets never logged (masked to last-4); config validated at construction; https enforced.
- [ ] Attributes loaded per `invokerId`; fresh connector per request; allowlist on agent-driven endpoints.

## Testing
- [ ] Connector tested with mockwebserver incl. error-status mapping + 204.
- [ ] Transformers, validation, response building, and the orchestration try/catch unit-tested.
