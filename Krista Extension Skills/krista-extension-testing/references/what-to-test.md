# What to test vs neglect — the classification

Unit tests target **pure Java** — classes that run without the Krista runtime. The Krista-framework
classes are **neglected** by unit tests (kept thin, validated by build + manual/integration). Use this
table to classify every class in the module.

## TEST — pure Java (no Krista runtime needed)

| Class / package | Why it's testable | What the test asserts |
|---|---|---|
| `impl/transformers/*` | pure functions JSON→entity | field mapping, null-safety, coercions (id→String, epoch-millis), `transformList` skips non-objects & never null |
| `service/validation/*`, `ValidationUtil` | plain logic | each rule throws `IllegalArgumentException` w/ actionable message; parse-and-validate returns typed value |
| query/dialect builder, `FieldMappingRegistry` | string/logic only | operator×type matrix, IN grouping, **injection rejection**, unknown→null, case-insensitivity |
| `integration/*Client` (HTTP) | `@Service` marker only, otherwise plain | status→exception mapping, 204, headers/auth, retry — via **MockWebServer** |
| `impl/util/*` helpers | plain | pagination clamp, rate-limit header parse, date/epoch, filename sanitize, JSON accessors |
| `KristaMediaClient` (zip/sanitize parts) | plain logic | blacklist→zip decision, safe filename |
| error-message / response-shaping helpers | plain | message text, `Map` shape |

## NEGLECT — Krista-framework (needs the runtime; keep thin)

| Class | Why not unit-tested | How it's validated instead |
|---|---|---|
| `<X>Extension` (`@Extension`, `@InvokerRequest`) | lifecycle hooks invoked by the platform | green build + Setup-tab manual test (validate/test-connection) |
| `<X>Area` (`@CatalogRequest`) | thin delegator; the platform binds it | green build + run each request once on an appliance |
| `<X>RequestAuthenticator` | needs `ProtoRequest`/auth context | manual auth round-trip |
| `<Entity>Store` (`EntityStore`) | HK2-registered search entry point | unit-test the DAO / query builder it calls; manual entity search |
| JAX-RS `Application` / resources / `@ApiRequest` | served by the platform router | green build (check `META-INF/krista/extension.json`) + smoke-test the callback/webhook |

## The extract-for-testability rule

If a framework class contains real, branchy logic (not just delegation), that logic is currently
**untestable by policy** — so **move it out**:

- Bad: a 60-line `@CatalogRequest` method with filtering/branching/parsing inline → untested.
- Good: the `@CatalogRequest` method resolves inputs and calls a plain `*Service`/helper that holds
  the logic; the plain class gets a full unit test; the framework method stays a thin, untested wrapper.

This keeps the "neglect the framework" policy honest: what's neglected genuinely has nothing worth
testing, because every real decision lives in a pure class that IS tested.

## Boundaries

- **No real network** — MockWebServer only.
- **No secrets** in tests — dummy tokens (`"test-token"`).
- Assert on contracts (returned entity fields, thrown exception + message, the outbound request), not
  on private internals.
