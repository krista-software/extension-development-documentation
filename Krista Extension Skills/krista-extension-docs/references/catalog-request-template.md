# Catalog-request page template

Each catalog request gets one detailed page under `docs/pages/`. Existing pages follow the
section order below. Treat it as the house structure: **mirror an existing sibling page in the
same module** rather than copying this file verbatim, because a module may use a leaner or
richer subset. The goal is that all request pages in a module look like they were written by
the same person.

Not every request needs every section. Simple requests (single input, no retry) often stop
after Usage Examples. Rich requests (validation, retry, client-side filtering) use the full
set. Never include a section you cannot fill with real, code-derived content — an empty
"Business Rules" heading is worse than no heading.

## Section order

```markdown
# <Request Name>

## 1. Overview
One or two sentences: what the request fetches/does and the key capability that makes it
distinct (e.g. enrollment-type filtering). Written for someone deciding whether this is the
request they need.

## 2. Request Details
- **Area**: <the @Domain area name, e.g. Course Management>
- **Type**: <QUERY_SYSTEM | ...>  (from the @CatalogRequest)
- **Retry Support**: ✅ YES / ❌ NO  (does the service build a guided-retry confirmation?)
- **Ask Agent (MCP)**: ✅ Enabled — **include this line whenever the `@CatalogRequest` has
  `tool = true`** (the request is callable by Krista's AI agent). Omit it when `tool` is absent/false.

## 3. Input Parameters
| Parameter Name | Type | Required | Description | Example |
Then, when a parameter needs it, a "Detailed Parameter Descriptions" subsection expanding on
allowed values, formats, and matching semantics. Parameter names, types, and required-ness must
match the actual @CatalogRequest method signature / input fields.

## 4. Output Parameters
| Parameter Name | Type | Description | Example |
If the output is an entity or list of entities, follow with a short note on the entity's key
fields and link to entities.md rather than duplicating the full field table.

## 5. Validation Rules      (only if the request validates inputs)
| Validation | Error Message | Resolution |
Use the actual message strings the code produces.

## 6. Error Handling        (only if meaningfully more than a generic failure)
Group by error class as the code does (INPUT_ERROR / LOGIC_ERROR / SYSTEM_ERROR /
Authorization), each with Cause, Error Message, Common Scenarios, Resolution Steps.

## 7. Usage Examples
2–4 concrete Input/Expected-Output/Result examples with realistic values. Include a retry
example if the request supports retry.

## 8. Business Rules        (only if non-obvious rules govern the result)
Numbered list of the rules the code enforces (filtering semantics, case sensitivity, how
multiple matches are handled, when empty results are valid).

## 9. Limitations
Real constraints: API rate limits, API version scope, data dependencies, performance notes.

## 10. Best Practices
Actionable guidance for callers.

## 11. Common Use Cases
Named scenarios (Scenario / Implementation / Expected Result) showing who uses this and how.

## 12. Related Catalog Requests
Links to sibling request pages a reader would naturally reach for next.

## 13. Technical Implementation
The one section allowed to speak to developers: helper class/method, validation flow, service
delegation chain, and telemetry metric names. Keep it factual and short.

## 14. Troubleshooting
Issue / Symptoms / Possible Causes / Resolution for the failure modes users actually hit.

## 15. See Also
Links to configuration, authentication, and entities pages.
```

## Filling it accurately

- Read the request end to end: the `@CatalogRequest` method in the Area class, the service it
  delegates to, and the impl that talks to the external API. The **input/output parameters,
  validation, and error messages come from that code**, not from a sibling page you are copying
  the shape of.
- Copy the *structure* from a sibling, but never copy its *content* — wrong parameter names
  carried over from another request are the most common documentation bug.
- Reuse the exact table column headers the module's other request pages use so the pages align.
