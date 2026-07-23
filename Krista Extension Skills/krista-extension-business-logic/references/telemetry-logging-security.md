# Telemetry, logging & security

Full code: `idioms/Telemetry.java`.

## Telemetry
- Wrap Krista's `TelemetryMetrics` in a `@Service` with a **lifecycle**: `recordRequestStart(prefix,
  operation)` → returns a context (start time + prefix + attributes); then exactly one of
  `recordSuccess(ctx)` / `recordFailure(ctx, response)` / `recordException(ctx, e)`.
- Emit: `{prefix}.requests` (counter at start), `{prefix}.success` / `{prefix}.failure` (counter),
  `{prefix}.duration` (histogram, ms). Namespace prefixes like `github.ListReleases` /
  `autotask.servicemanagement`.
- **Telemetry must never crash business logic** — wrap every recording in `try/catch(Exception) ignored`.
- **Attributes must be low-cardinality** — `operation` name only, plus `error_class` +
  truncated (≤100 char) `error_message` on failure. Never put IDs/emails/URLs in metric tags.
- Wrap every catalog request at the Area boundary; on exception, record then re-throw (decomposed) or
  record-and-classify (compact `audited`).

## Logging
- One SLF4J logger per class. Levels: **INFO** request start + success-with-duration; **WARN** input
  errors; **ERROR** (with stack trace) auth/system errors.
- Include the **`invokerId`** in lifecycle logs for correlation. Log the vendor's error message and
  status, the HTTP method+URL — but never request/response bodies by default (gate body logging behind
  a config flag defaulted **off** in production).

## Security
- **Never log secrets.** Mask tokens to `****` + last-4 via a helper that returns empty if shorter than
  4; elsewhere log only the token's length. Log only non-sensitive config (base URL, username).
- Consider a redacting `toString()` on any config object that holds a secret behind a public getter.
- **Validate config at construction** (`config.validate()`), so misconfiguration fails before any call.
- **Multi-tenant isolation:** load attributes by `invokerId`; construct a fresh connector per request;
  never cache one tenant's client/token for another.
- Immutable, self-normalizing config: strip trailing slash on base URL, require `https://`, floor/cap
  numeric settings (page size ≤ max, timeout ≥ default).
- Enforce an **allowlist** on any endpoint driven by LLM/agent input (e.g. MCP query services): permit
  only the specific method+URL(s) intended, reject everything else before the HTTP call.
