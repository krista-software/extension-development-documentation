# EntityStore CRUD — create / get / update / delete (step by step)

`EntityStore<E>` is not search-only. For a `@Entity(supportStore = true)` the same store implements the
full mutation set. This page gives create/get/update/delete the same step-by-step treatment the search
method gets in the main guide. Patterns are verbatim from `salesforce_sales` (`AccountStore` +
`AccountDaoImpl`).

## Layers (same as search)

```
EntityStore<E>  (@Service)   ← the contract Krista calls
   └─ Dao / Manager          ← owns the HTTP call to the backend (add/getById/update/delete/list/query)
   └─ Transformer / CatalogType   ← maps backend DTO/JSON ↔ the @Entity
```

The store method is thin: guard inputs → call the DAO → map → (for create/update) re-fetch. All backend
I/O and JSON live in the DAO; all mapping lives in the transformer/catalog-type.

## CREATE — `E create(Map<String,Object> fields)`
1. Guard: null/empty map → log a warning, return `new E()` (empty entity, not null — the executor shows an empty row rather than erroring).
2. `String id = dao.add(fields)` — the DAO POSTs the field map and returns the new primary key.
3. `return get(id)` — **re-fetch** so the caller receives the fully-populated created entity (with server-set fields).
4. Catch `IllegalArgumentException` → log → return `new E()`.

```java
public Account create(Map<String,Object> fields) {
    if (fields == null || fields.isEmpty()) { LOGGER.warn("create: empty fields"); return new Account(); }
    try { String id = accountDao.addAccount(fields); return get(id); }
    catch (IllegalArgumentException e) { LOGGER.error(e.getMessage(), e); return new Account(); }
}
```

## GET — `E get(String primaryKey)`
1. Guard: null/empty key → log, return `null`.
2. `return Transformer.transform(dao.getById(key))` — DAO fetches the DTO, transformer maps to the entity.
3. Catch → log → `null`. (Also the re-fetch used by create/update.)

## UPDATE — `E update(E entity)`
1. Guard: null entity → log, return `null`.
2. Map entity → backend DTO and `dao.update(...)` (PATCH/PUT). Send **only changed/non-null** fields so
   you don't overwrite server data (see business-logic "build bodies with only non-blank properties").
3. `return get(entity.id)` — re-fetch the updated record.
4. Catch → log → `null`.

```java
public Account update(Account a) {
    if (a == null) { LOGGER.warn("update: null"); return null; }
    try { accountDao.updateAccount(new AccountImpl(SFAccount.from(a))); return get(a.id); }
    catch (IllegalArgumentException e) { LOGGER.error(e.getMessage(), e); return null; }
}
```

## DELETE — `void delete(String primaryKey)`  ← **fails loud**
1. Guard: null/empty key → **throw** `IllegalArgumentException` with an actionable, entity-specific
   message ("Account ID is required for deletion. Provide the Salesforce ID …"). Destructive ops must
   never silently no-op.
2. `dao.delete(key)` — let backend errors (404/permission) propagate; they surface to the caller.

```java
public void delete(String key) {
    if (key == null || key.isEmpty())
        throw new IllegalArgumentException("Account ID is required for deletion. Provide the Salesforce ID of the account.");
    accountDao.deleteAccount(key);
}
```

## The DAO side (what create/update/delete call)
The `*Dao`/`*DaoImpl` owns the HTTP + wire mapping — one method per verb:
- `String add(Map<String,Object> fields)` → POST, return new id (parse `id`/`itemId` from the response).
- `DTO getById(String id)` → GET by id.
- `void update(entity/DTO)` → PATCH/PUT; 204-no-content is normal (see business-logic HTTP client).
- `void delete(String id)` → DELETE (204).
- `List<DTO> list(int size, long page)` / `query(...)` → for search.
Use `@SerializedName` DTOs with `from(Map)` / `from(entity)` converters; flatten dynamic/custom fields
on create/update.

## Error / return policy (summary)

| Op | On bad input | On backend error | Returns |
|---|---|---|---|
| create | empty map → `new E()` | catch+log | created entity (re-fetched) or empty |
| get | blank key → `null` | catch+log | entity or `null` |
| update | null → `null` | catch+log | updated entity (re-fetched) or `null` |
| delete | blank key → **throw** | propagate | void |
| contains / count / lookup | — | — | `false` / `0` / `List.of()` unless implemented |
| search | — | catch → `List.of()` (never throws) | list |

## Testing (pure Java — per krista-extension-testing)
Unit-test the store with a **mocked DAO** (`@Mock <Dao>` + `@InjectMocks <Entity>Store`): stub
`dao.add/getById/update/delete`, assert the store maps correctly, re-fetches on create/update, and that
`delete("")` throws. Do not need the Krista runtime.

## Exposing CRUD
- **As entity operations**: implementing these on a `supportStore=true` store makes Krista manage the
  entity (search + CRUD) natively — nothing else to wire; HK2 binds the store to the entity.
- **As catalog requests too** (optional): thin `@CatalogRequest` Create/Get/Update/Delete methods can
  delegate to the same DAO/store and return the entity as their typed output.
