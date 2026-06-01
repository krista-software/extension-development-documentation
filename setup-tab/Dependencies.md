<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Setup tab](README.md) > Dependencies

# Dependencies

## Overview

**Dependencies** let your extension declare that it relies on other extensions (for example: a shared authentication extension, a central logging extension, or a shared data access extension). In the Setup tab, users can connect/configure those dependent invokers.

Dependencies are useful when you want to reuse platform-integrated behaviors instead of re-implementing them repeatedly.

## Declaring dependencies

Dependencies are typically declared via a Krista annotation (for example `@Dependency`).

When you declare a dependency, consider:

- **What capability you need** (authentication, storage, etc.)
- **Which domain** the dependency must implement
- Whether the dependency is **required** or **optional**

See also:

- [Extension annotations](../reference/ExtensionAnnotations.md)
- [Project structure](../development/ProjectStructure.md)

## Using dependencies in code

At runtime, dependency invokers are generally obtained via dependency injection (for example HK2 injection with a `@Named(...)` qualifier).

Practical guidance:

1. Keep dependency usage at the **controller/service boundary**.
2. Hide dependency-specific access behind a small adapter/service interface.
3. Fail fast if a required dependency is missing or misconfigured.

## Design guidance

### Keep dependencies minimal

Every dependency adds operational and troubleshooting surface area.

Prefer:

- a small number of **standard** dependencies
- stable dependency names
- clear documentation explaining *why* the dependency exists

### Avoid circular dependencies

Circular dependencies are difficult to deploy and reason about.

If two extensions need each other, consider:

- extracting shared logic into a third dependency, or
- redesigning the interaction so one side calls the other via a catalog request instead of a dependency.

### Version and compatibility

If the dependency’s behavior changes, your extension may break.

Recommendations:

- depend on well-versioned, stable domain contracts
- validate expected behavior during setup-time validation

## Troubleshooting dependency issues

- **Injection returns null / fails**: verify the `@Named` value matches the declared dependency name.
- **Wrong invoker connected**: confirm the dependency invoker in Setup tab points to the correct environment (Prod vs Staging).
- **Runtime failures after updates**: handle **INVOKER_UPDATED** and rebuild any resources that rely on dependency configuration.

See: [Invokers and lifecycle](../concepts/InvokersAndLifecycle.md)

## Next steps

- Add save-time checks: [Validation and troubleshooting](ValidationAndTroubleshooting.md)
- For request-time behavior: [Catalog requests](../development/catalog-requests/README.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
