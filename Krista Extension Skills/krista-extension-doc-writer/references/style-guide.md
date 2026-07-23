# Technical-writing style guide (Krista extension docs)

## Audience & purpose

Write for the **business/automation user configuring and calling the extension inside Krista** — not
the Java developer. Each page answers a decision or a task: *Is this the request I need? What do I
put in? What comes back? What can go wrong? When would I use it?*

## Voice

- **Second person, present tense, active voice.** "Lists all releases for a repository." not "This
  request will be used to list releases."
- **Lead with the capability**, then the mechanics. First sentence of an Overview says what it does
  and the one thing that makes it distinct.
- **Concrete over abstract.** Real field names, real example values (`v1.2.0`, `acme/backend`), real
  error strings the code actually returns.
- **Concise.** Short sentences. No marketing ("powerful", "seamless"). No filler headings you can't
  fill with code-derived content — an empty "Business Rules" heading is worse than none.

## Accuracy rules (non-negotiable)

- Every input parameter, output field, type, required-ness, and error message comes from the **code**
  (`@CatalogRequest` method signature, `@Field` annotations, validation/error strings), never from a
  sibling page you copied the shape of.
- Copy page *structure* from a sibling in the same module; never copy its *content*.
- When code and an existing doc disagree, the code wins — fix the doc.
- Version numbers and the extension name/description come from the `@Extension` annotation.

## Formatting conventions

- **Parameter/field/output = Markdown tables.** Standard columns:
  - Inputs: `| Parameter | Type | Required | Description |` (add `| Example |` when helpful).
  - Outputs: `| Parameter | Type | Description |`; for an entity/list output, follow with a nested
    `| Field | Type | Description |` table for the entity's key fields (or link to `entities.md`).
- **Types** use the field-type names the platform shows: `Text`, `Number`, `Boolean`, `Date`,
  `Paragraph`, `RichText`, `FreeForm`, `PickOne`, `Entity(<Name>)`, `[ Entity(<Name>) ]`,
  `[ { Key: Text, ... } ]`. Match the `@Field`/`@Field.Desc` `type` exactly.
- **Backtick** literal values, endpoints, headers, field names in prose (`owner`, `v1.2.0`,
  `GET /repos/{owner}/{repo}/releases`).
- Booleans described as "`true` if …".
- Keep one H1 (`#`) per page — its text should match the catalog request's `name` for request pages
  (the audit script checks this).

## Per-request page — the lean house shape (github)

Overview → Request Details (Area, Type, external API endpoint) → Input Parameters → Output Parameters
(+ nested entity fields) → Example (Input/Output) → Error Handling. Add sections only when the code
justifies them. For heavy requests (multi-rule validation, retry, client-side filtering) escalate to
the exhaustive 15-section template in the **krista-extension-docs** skill.

## Mention agent-callability

If a `@CatalogRequest` has `tool = true`, state on its page that it is callable by Krista's AI agent
(MCP). Omit that claim when `tool` is absent/false.

## Do / Don't

| Do | Don't |
|---|---|
| Derive every fact from code | Invent parameters, defaults, or errors |
| Match the module's existing file names & table columns | Rename files or restyle untouched pages |
| Explain what the user puts in and gets back | Explain the Java call chain in the main flow |
| Use real example values | Use `foo`/`bar` placeholders |
| Say "Not Available" for an empty release-notes section | Delete the section heading |
