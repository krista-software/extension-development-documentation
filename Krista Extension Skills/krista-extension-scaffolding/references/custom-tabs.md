# Custom Setup-tab tabs

Tabs are returned from a `@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)` method on the extension
class as a `Map<String,String>` of `title → url`.

```java
@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
public Map<String, String> customTabs() {
    return Map.of(
        "Documentation", "static/docs",                    // bundled Docsify site
        "Authentication", "rest/<jaxrsId>/authentication/", // JAX-RS resource
        "<Name> Audit", "rest/<jaxrsId>/audit/",            // JAX-RS resource (AbstractAuditResource)
        "AI Assistant", "rest/<jaxrsId>/mcp-setup");        // JAX-RS resource (AbstractMcpSetupResource)
}
```

## URL forms

- `"static/<path>"` — served from the `@StaticResource(path="<path>", file="<resourcesFolder>")` bundle.
  The Documentation tab is always `"static/docs"` with `@StaticResource(path="docs", file="docs")`.
- `"rest/<jaxrsId>/<resourcePath>"` — routed to the extension's JAX-RS `Application`. The full route is
  `rest/` + `@Extension(jaxrsId=...)` (default `"rest"`) + the resource's `@Path`. jira uses
  `"jiraextn/sdk/auth/"` because it set `@Extension(jaxrsId="jiraextn")` and does not re-prefix `rest/`.

## Routing rule (the #1 trap)

The `rest/<jaxrsId>/` prefix in the tab string **must** match `@ApplicationPath("<jaxrsId>")` + the
resource `@Path`. If you set `@Extension(jaxrsId = "x")` the platform does NOT auto-prepend `rest/` —
either inherit the default (`jaxrsId` = `"rest"`, mirror Outlook's `rest/<name>/...`) or emit
`<jaxrsId>/<path>` everywhere (tabs, callback endpoint, docs redirect URIs). Verify the registered
bindings in the generated `build/classes/java/main/META-INF/krista/extension.json` after building.

## Minimum

A REST extension with only bundled docs needs just:
```java
@InvokerRequest(InvokerRequest.Type.CUSTOM_TABS)
public Map<String, String> customTabs() { return Map.of("Documentation", "static/docs"); }
```
paired with `@StaticResource(path = "docs", file = "docs")` and a Docsify site under
`src/main/resources/docs/`.
