# build.gradle & release.properties

## What the build does

A Krista extension is packaged as a **fat jar**: the extension classes plus all `implementation`
dependencies (or `runtimeClasspath`) zipped in. The jar name and version come from
`release.properties`, which is itself **generated at build time** by scraping the `@Extension` and
`@Domain` annotations out of the source. So the annotation is the single source of truth for
name/version/domain — you never hand-edit `release.properties`.

## Version pins (choose one aligned pair)

`krista-apis` and `extension-impl-anno-processors` **must be the same version**. Versions seen in the
wild: `1.0.117` (autotask, connect-wise), `1.0.118` (servicenow, slack), `1.0.120-rc1` (restapi),
`1.0.124` (salesforce_sales), `1.0.125-sp1` (jira, outlook-4, sharepoint-4.0 — this is the first that
adds `CatalogRequest.tool` for MCP), `1.0.126`. **Use `1.0.126`** for a new extension unless you have
a reason to pin older; use ≥ `1.0.125-sp1` if you need `tool = true`.

Other common deps: `com.squareup.okhttp3:okhttp:4.12.0` (+ `logging-interceptor`),
`org.glassfish.hk2:hk2-api:3.0.3` (or 2.6.1), `com.google.code.gson:gson:2.11.0`,
`com.github.scribejava:scribejava-apis:8.3.3` (OAuth), `org.glassfish.jersey.media:jersey-media-multipart:2.35`.

## The template is the complete build

`templates/build.gradle.template` is now the **full** build — it folds in every block seen across the
branches, each marked CORE (always keep) or OPTIONAL (enable if needed):

- **CORE**: fat jar from `configurations.implementation`, `generateReleaseProperties`/`setReleaseProperties`,
  the `createSourceDir → copyGradleFile → includeSources` chain, Java 21, the Artifactory repo.
- **OPTIONAL** (enabled by default, safe to keep — they only *run* when invoked): `jacoco` +
  `jacocoTestReport`, `org.sonarqube` + `sonar {}`, the `publishing {}` block.
- **OPTIONAL** (commented out — enable deliberately, they need extra project files): the `sdkUi` +
  `extractSDKResources` task (UI-bearing SDKs), the node/yarn React-UI build, the `candidate`/`release`
  pipeline hooks.

To get the old lean build, just delete the OPTIONAL blocks. Nothing in the OPTIONAL set blocks a
plain `./gradlew build` from producing the jar.

## Dependency catalog (flexible SDK identification)

The template carries a **DEPENDENCY CATALOG** comment mapping each capability/SDK to the exact
coordinates used by shipping extensions (OAuth2→scribejava, Microsoft→microsoft-auth-sdk+graph+azure,
Atlassian→krista-atlassian-sdk, resilience→resilience4j, phone→libphonenumber, CSV→opencsv, etc.).
When adding a new SDK: prefer `implementation '<group>:<artifact>:<version>'`; and if the SDK bundles
Setup-tab HTML (auth/audit/mcp tabs) it is **UI-bearing** — also add an `sdkUi` config entry + an
`extractSDKResources` Copy task. Anything not in the catalog resolves from the Krista Artifactory or
mavenCentral the same way.

## The release.properties generator (verbatim shape)

The `generateReleaseProperties` task scrapes:
- `@Extension` → `extension.name`, `extension.version` (from the extension `.java`)
- `@Domain` → `domain.name`, `ecosystem.name` (from one nominated Area `.java`)

and writes the 4-line file:

```properties
ecosystem.name=<Ecosystem>
domain.name=<Domain>
extension.version=<x.y.z>
extension.name=<Display Name>
```

**You must point the task at the correct two files** — set `extensionFilePath` to your
`<Name>Extension.java` and `areaFilePath` to an Area class that carries `@Domain`. This is the single
edit most often forgotten when copying the template.

## Repositories

```groovy
repositories {
    mavenLocal()
    maven { url "https://packages.cicd.in.antbrains.com/artifactory/libs-release" }  // internal Krista Artifactory
    mavenCentral()
}
```
Building requires network to that Artifactory (VPN/on-network) and JDK 21.

## Jar wiring (the invariant idiom)

```groovy
jar {
    archiveBaseName = <extension.name with whitespace stripped>
    from { configurations.implementation.collect { it.isDirectory() ? it : zipTree(it) } }
    exclude 'META-INF/*.RSA', 'META-INF/*.SF', 'META-INF/*.DSA'
    duplicatesStrategy = "exclude"
}
```
