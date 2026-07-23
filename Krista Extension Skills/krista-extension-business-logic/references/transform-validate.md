# DTO → Entity transformers & input validation

Full code: `idioms/Transformer.java`, `idioms/Validation.java`.

## Transformers (JSON/DTO → Krista entity)
> **Always transform to an `@Entity` — never pass the raw vendor JSON straight through as a
> `FreeForm`/`Map` output.** If a catalog request returns a domain object, it declares an
> `Entity(<Name>)` / `[ Entity(<Name>) ]` output and this transformer produces it. Skipping the entity
> and returning the raw response is a defect (no fields in Krista, not composable). `FreeForm` output is
> only for genuinely unstructured data. See scaffolding `field-types.md` → "Entity vs FreeForm".

- **Stateless final class, private constructor, static methods**: `transform(JsonObject)` (null-in →
  null-out) and `transformList(JsonArray)` (never null; skip non-object elements).
- Every field read goes through **null-safe accessors** — never `json.get(k).getAsX()` directly.
  Provide `getStringOrNull`, `getLongOrNull`, `getBoolOrNull`, `getNestedString(json, obj, field)`,
  `getEpochMillisOrNull` (ISO-8601 → epoch-millis string for `@Field.Date`), `joinArray` (flatten to
  comma-joined string).
- **Type coercions the platform expects:** numeric IDs stored as `String` (entity Number fields are
  `String`), timestamps as epoch-millis strings, `1/0` → `Boolean`. Put business mapping here
  (e.g. `status == "enabled"` → boolean).
- Entities stay pure DTOs: `public` fields, no-arg constructor, `@Field.*` metadata, a `toFields()`
  that returns a `LinkedHashMap` keyed by the display names. No logic.

## Input validation (fail-fast, actionable)
Two tiers:
- **`ValidationUtil`** — static, non-instantiable toolkit. `requireNonEmpty`, `requireNonNull`,
  `requireAtLeastOne`, `parseLongOrNull`/`parseIntegerOrNull` (parse **is** validation),
  `validateEmailFormat`, `validateRange`, `validateMinLength/MaxLength`. Every failure throws
  `IllegalArgumentException` with **field name + why + an example** ("Invalid number '<v>' … Examples: 123, 456789").
- **`<Entity>ValidationService`** (`@Service`) — composes the primitives into domain rules
  (`validateCreateTicketData`, `validateSearchCriteria`) and parses ID strings once.

`IllegalArgumentException` is the deliberate signal the orchestration layer catches to produce an
INPUT-classified / validation response. Validate **before** any external call.

## Resolving inputs & building request bodies
- Fall back to configured defaults when an input is blank (`resolveOwner`/`resolveRepo`).
- Build request bodies by adding **only non-blank** properties (`if (x != null && !x.isBlank()) body.addProperty(...)`)
  so you never overwrite server fields with nulls.
