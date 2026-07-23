---
name: entity-search-implementation
description: Use when implementing, extending, reviewing, or migrating KME Entity Search in any Krista catalog extension (Salesforce, Jira, Confluence, Slack, SharePoint, Outlook, Gmail, Dynamics, ServiceNow, HubSpot, Zendesk, …) — enforces the canonical EntityStore pattern, mandatory implementation order, field-mapping registry, injection-safe query building, and the test/review gates.
---

# Entity Search Implementation Skill

**Canonical reference:** `ENTITY_SEARCH_IMPLEMENTATION_SKILL.md` at the repo root (read the relevant section before each phase; it contains the full architecture, templates, and sequence diagrams). Reference implementation: `salesforce_sales`.

## Non-negotiable architecture rules

1. **The store IS the search implementation.** One HK2 `@Service` class per searchable entity implementing `app.krista.extension.util.EntityStore<E>`. NEVER create `EntityRequests`, `ServiceRegistry`, `EntityImplementationService`, or per-entity "search provider"/"condition translator" classes — HK2 `@Service` is the registration mechanism.
2. **One field-mapping registry per extension** (`SoqlFieldMapping`-shape or `FieldMappingRegistry`): `entity(lower) → field(lower) → (backendFieldName, FieldType)` plus a separate ORDER-BY map. Zero inline field-name `if/switch` chains in stores.
3. **One query builder + one dialect.** Only the dialect knows query syntax (SOQL/JQL/CQL/OData). Only the Manager knows HTTP. Only `model/` knows wire JSON. Entities are annotation-metadata only.
4. **FieldType is fixed:** `TEXT, EXACT, COMPARABLE, DATE, IDENTITY`. Operator×type matrix per guide §2.5. Equals/notequals on EXACT/IDENTITY group into `IN`/`NOT IN`.
5. **Search never throws to the executor:** catch `Exception` → `LOGGER.error(msg, e)` → `List.of()`. Deletes fail loud. Auth signals via `MustAuthorizeException` only.
6. Layer dependencies: `stores → service interfaces + search kit + catalogtypes`; `impl → Manager → TokenProvider`; entities import nothing from impl/model.

## Mandatory implementation order (do not reorder)

| # | Step | Gate to proceed |
|---|---|---|
| 0 | Build the mapping table: entity ↔ backend object, field ↔ backend field ↔ FieldType, sortable subset, default sort, relationship graph | Table reviewed; every relationship appears in two entity descriptions |
| 1 | Extension skeleton + auth (skip if exists) | TEST_CONNECTION acquires a real token |
| 2 | Entity annotations: `supportStore=true`, entity+field descriptions with "References X.Y" prose, `@Searchable`/`@ToString`, `LinkedHashMap` `toFields()` | toFields count/order/null tests green |
| 3 | Field-mapping registry (one file, from the step-0 table) | Registry test covers every table row + case-insensitivity + unknown→null |
| 4 | Dialect + query builder (operator matrix, IN grouping, numeric/date validation-and-drop, escaping, epoch→date with org timezone, orderby extraction, `max((page-1)*size,0)`) | ~60-case builder suite green incl. injection rejections |
| 5 | DAOs + Manager (`QUERY_FIELDS` constant in DaoImpl; HTTP ≥400 → friendly `IllegalArgumentException`) | DAO tests green with mocked Manager |
| 6 | Stores: 12-step template / `AbstractSearchableStore` (Id fast-path, empty-WHERE→default page, catch-all→`List.of()`) | Per-store query-fragment tests green |
| 7 | Owner/assignee name→id resolution (multi-match→IN; no-match→pass through) | Resolver tests green |
| 8 | Dynamic ORDER BY + verified per-entity default sort | Sort tests green |
| 9 | Full test pyramid + docs + version bump + changelog | Checklist below fully checked |

## The 12-step store search sequence (verbatim contract)

```
1 GUARD conditions null/empty → DAO default page      7 PAGINATION clause
2 EXTRACT conditions + clauses                        8 EMPTY-WHERE → DAO default page
3 TRY                                                 9 ASSEMBLE SELECT QUERY_FIELDS FROM obj WHERE …
4 ID FAST-PATH "Id" equals → get(id)                 10 dao.getXsByQuery(query)
4b RESOLVE name→id conditions                        11 map(XCatalogType::fromX) → catalog entities
5 WHERE via registry+dialect (skip orderby conds!)   12 CATCH Exception → log → List.of()
6 ORDER BY via registry, else per-entity default
```

## Coding standards

- Java 21; HK2 `@Service` + constructor `@Inject`; all deps `private final`; one static SLF4J `LOGGER` per class.
- SDK contract exactness: `SearchCondition(operator, operand, fieldName)` argument order; `Operator ∈ {gte,lte,gt,lt,equals,startswith,endswith,contains,notequals,orderby}`; legacy `search(List,…)`/`contains`/`count`/`lookup` return `List.of()`/`false`/`0`/`List.of()` — **never null**.
- Epoch operands parsed via `(long) Double.parseDouble(v)` (handles `1.71E12`). Quoted values escaped (`\→\\`, `'→\'`); unquoted values regex-validated and dropped if invalid.
- Never log tokens/secrets/auth headers; generated queries at `debug` only; dropped condition fields at `info`.
- Annotation values literal (build tooling parses them); do not copy legacy `*QueryBuilder` classes.

## Validation rules

- `VALIDATE_ATTRIBUTES` rejects invalid timezone (against `TimeZone.getAvailableIDs()`) and bad credentials before save.
- Store `delete`: blank key → throw `IllegalArgumentException` with entity-specific actionable message.
- Builder: null/empty operands skipped; unknown fields skipped **and reported**; `orderby` conditions excluded from WHERE.
- OAuth `state` = `userId[#authContextId]`, max one `#`, reject otherwise; refresh tokens keyed `userId&clientId&clientSecret` in `KeyValueStore`.

## Testing requirements (all mandatory)

1. Entity `toFields()` — count, order, null handling, per entity.
2. Registry — every mapping-table row, case-insensitivity, unknown→null.
3. Builder/dialect — every type×operator cell; injection (`0 OR 1=1`, quotes); IN grouping; timezone + scientific-notation dates; direction parsing; empty inputs.
4. Stores — `ArgumentCaptor` on the DAO, assert query fragments; Id fast-path bypasses query; DAO exception → empty list; invalid comparable → default-page fallback.
5. Resolver — single match, multi-match→IN, lookup failure→pass-through.
6. `gradlew test` green before claiming done — show output.

## Documentation requirements

Entity docs list searchable fields, supported operators, sortable fields, relationships; every catalog request page follows `.augment/rules/ExtensionDocumentationGuidelines.md`; `@Extension(version)` bumped + changelog entry; docs verified against source, not assumed.

## Code review checklist (reviewer blocks on any "no")

- [ ] No parallel search infrastructure (registries/providers) introduced
- [ ] All field mapping centralized; no inline name matching in stores
- [ ] Operator×type matrix complete; IN grouping present; orderby conditions skipped in WHERE
- [ ] Injection defense: escape (quoted) + validate-and-drop (unquoted), with tests
- [ ] Id fast-path, empty-WHERE fallback, catch-all→`List.of()` present in every store
- [ ] `supportStore` correct for every entity; descriptions carry relationship prose both directions
- [ ] `QUERY_FIELDS` covers every `toFields()` key; backend object names verified (Product2/WhoId-class traps)
- [ ] Per-entity default sort exists on the backend; pagination 1-indexed with negative-offset guard
- [ ] No nulls returned from any EntityStore method; no secrets in logs
- [ ] Timezone from Attributes used for DATE conditions

## Pull request checklist (author pastes into PR body)

- [ ] Mapping table included/linked in the PR description
- [ ] Implementation followed the mandatory order; one store per PR during migration
- [ ] Full §6 Extension Checklist from `ENTITY_SEARCH_IMPLEMENTATION_SKILL.md` pasted and checked
- [ ] Test run output attached; new tests enumerated per category above
- [ ] For migrations: query-parity diff (legacy vs new builder) attached; intentional semantic fixes called out
- [ ] Docs + version + changelog updated; `release.properties` regenerated
