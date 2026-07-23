# Release-notes block template

`ReleaseNotes.md` is a reverse-chronological changelog: newest version block at the **top**.
It is also the `@ChangeLog` target, so it is surfaced inside the Krista platform — keep it
readable for a non-developer evaluating whether to upgrade.

When the `@Extension(version = ...)` annotation changes, add a new block at the top. Keep the
prior blocks untouched.

## Block format

```markdown
## Version <X.Y.Z>

- **Krista Service APIs Java** : <version of app.krista:krista-apis / service APIs used>
- **Global Catalog Version** : <GC-YYYY.M.R tag, if the module tracks one>

### New Features

* <User-visible capability added this release. Lead with the capability, then briefly how it
  works. If none, write "Not Available".>

### Resolved Bugs

* <Bug fixed this release, phrased as what the user will no longer experience. If none,
  "Not Available".>

### Dependency Updates

* <Notable dependency version bumps, especially ones that change behavior or are required for a
  new feature. If none, "Not Available".>

### Known Issues

* <Known defects shipping in this release. If none, "Not Available".>

### Limitations and Caveats

* <Standing constraints (API scope, required permissions, config prerequisites). These often
  carry forward from the previous block; keep them unless they changed.>
```

## Conventions observed in existing files

- Some blocks include a `**Developer Name**` line — include it if the module's prior blocks do.
- Use `* Not Available` (not an empty section) when a category has nothing this release; the
  section headings stay present for consistency.
- The metadata lines (Krista Service APIs, Global Catalog Version) reflect what this specific
  release was built against — pull the real values from `build.gradle` / `release.properties`
  rather than copying the previous block's numbers.
- **Krista Service APIs Java** is the single most drift-prone metadata line. Its source of truth
  is the `annotationProcessor` dependency in the module's `build.gradle`:
  `annotationProcessor 'app.krista:extension-impl-anno-processors:<VERSION>'`. Read `<VERSION>`
  from that line and use it verbatim; do **not** carry forward the previous block's number.
- After adding the block, reconcile the version line in `README.md` so the home page matches.
