# Verify — compile & generate the jar (the builder's final step)

This is the concluding action of the build: **Claude runs it and delivers the jar** — it is not a list
of commands for the user. The jar is the deliverable; binding/deploying is out of scope.

## Produce the jar

```bash
cd <module>
export JAVA_HOME=$(/usr/libexec/java_home -v 21)     # macOS; JDK 23 breaks Mockito/JaCoCo

# Pick a gradle: module wrapper → system gradle → cached distribution
GRADLE=./gradlew
command -v "$GRADLE" >/dev/null 2>&1 || GRADLE=$(command -v gradle) \
  || GRADLE=$(find ~/.gradle/wrapper/dists/gradle-8.14-bin -type f -path '*/bin/gradle' | head -1)

"$GRADLE" clean jar            # add --offline if Artifactory is unreachable but deps are in ~/.gradle
```
The `jar` task runs `generateReleaseProperties` (scraping `@Extension`/`@Domain`) and the annotation
processor, which emits `META-INF/krista/extension.json` (the platform descriptor). The fat jar lands
at **`build/libs/<extension.name>-<version>.jar`**. A green build with that jar + descriptor is the bar.

Requires JDK 21 and the `krista-apis` / `extension-impl-anno-processors` deps — from the internal
Artifactory (`packages.cicd.in.antbrains.com`) or already cached in `~/.gradle`.

## Fallback when the deps/processor can't be resolved (fully offline, no cache)

Compile the sources directly to prove they are green, and say plainly that the descriptor/jar step
needs the Artifactory. If the SDK jars are already in `~/.gradle/caches`:

```bash
M=~/.gradle/caches/modules-2/files-2.1
CP=$(find $M/app.krista -name "*-1.0.126.jar" | tr '\n' ':')
CP="$CP$(find $M -name 'okhttp-4.12.0.jar' -o -name 'gson-2.11.0.jar' -o -name 'hk2-api-*.jar' -o -name 'jakarta.inject-2.6.1.jar' | tr '\n' ':')"
javac -proc:none -d /tmp/out -cp "$CP" $(find src/main/java -name '*.java')
```
`-proc:none` skips the processor (it needs its own transitive classpath that Gradle resolves); this
still validates every annotation's members, enums, and types against the real SDK. For the processor
+ descriptor step, use Gradle.

## Checklist

- [ ] `@Java(version = Java.Version.JAVA_21)` present; sourceCompatibility/targetCompatibility 21.
- [ ] `krista-apis` and `extension-impl-anno-processors` pinned to the SAME version.
- [ ] `generateReleaseProperties` points at the real `<Name>Extension.java` and an Area with `@Domain`.
- [ ] Every `@CatalogRequest` has a unique `id`, typed `@Field` inputs, and a `@Field` output.
- [ ] `@Domain` ids are the real registered values (or flagged placeholders).
- [ ] For `implementationModel = Krista_4_O`: `@Containerize(baseImageVersion = "3.6.2-sp3")` present.
- [ ] Tab URLs match `rest/<jaxrsId>/<path>` (see custom-tabs.md).
- [ ] Green `./gradlew build`; `META-INF/krista/extension.json` generated.
