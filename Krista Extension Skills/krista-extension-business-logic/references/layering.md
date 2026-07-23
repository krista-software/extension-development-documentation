# Layering & responsibilities

The business logic sits behind the `@CatalogRequest` method. Keep each layer single-purpose so the
code is testable and the failure handling is uniform.

| Layer | Package (typical) | Responsibility | Throws? |
|---|---|---|---|
| Area (controller) | `catalog/` | The `@CatalogRequest` method — telemetry + the audited try/catch only; delegates immediately | returns `ExtensionResponse` |
| Service / Operations | `service/`, `impl/` | Orchestrate: validate → connector → transform → build response | **never throws** (compact: the `audited` wrapper catches) |
| Validation | `service/validation/` | Fail-fast input checks + String→typed parsing | `IllegalArgumentException` |
| Filter | `service/filter/` | In-memory narrowing after a coarse server query | no |
| Response | `service/response/` | Build `ExtensionResponse` with stable keys | no |
| Error | `service/error/` | Raw exception text → user-facing, operation-specific guidance | no |
| Mapper / Transformer | `impl/transformers/`, `service/util/` | DTO(JSON)→Entity, type coercions | no (null-safe) |
| Connector | `impl/connectors/`, `system/client/` | The ONLY code that talks HTTP | **typed exceptions** |
| DTO | `model/`, `*/dto/` | Wire model (Gson) | — |
| Entity | `catalog/entities/` | Krista `@Entity` (annotation metadata + `toFields`) | — |

## Two boundary shapes

**Compact (github)** — best for small/medium extensions. The connector throws typed Java exceptions;
the Area wraps each method in an `audited(name, CheckedSupplier<ExtensionResponse>)` helper that owns
the try/catch → classify → `ExtensionResponse` + telemetry + timing. Individual methods hold only
business logic. See `idioms/AuditedArea.java`.

**Decomposed (autotask)** — best for large domains / heavy validation / client-side filtering. Two
tiers: `system/*ServiceImpl` (thin: HTTP + typed exceptions) and `service/*OperationsService`
(orchestration, returns `ExtensionResponse`, never throws), plus one `@Service` each for
validation/filter/response/error/mapper. The OperationsService owns the try/catch:
`IllegalArgumentException` → validation response; everything else → error-message-service → failure
response.

## DI & conventions

- Every service is an HK2 `@Service` with an `@Inject` constructor. Depend on an **interface**
  (`IHttpClient`, `I<Entity>Service`) so units are mockable.
- One SLF4J logger per class. A fresh connector per request, attributes loaded by `invokerId`.
- Transformers, mappers, and the validation toolkit are **stateless final classes with static methods**
  (private constructor) — trivially unit-testable.
