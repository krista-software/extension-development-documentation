---
name: krista-mcp-enable
description: >-
  Bulk-enable MCP on Krista extension release branches. For each release/* branch: create a
  feature branch off the RELEASE tip (never develop-1.0), bump the krista-apis and
  extension-impl-anno-processors dependencies to a target version (default 1.0.126, kept aligned),
  set tool = true on every eligible @CatalogRequest — excluding WAIT_FOR_EVENT — using a
  block-scoped edit that only touches annotation bodies, then bump the extension version
  (patch +1) across @Extension/release.properties and add a release-notes entry.
  Compile-gate with Gradle and commit only on a clean build (never push, never PR). Skips empty
  stub branches. Does NOT create an "Ask Agent"/MCP area — tool=true only. Bundled scripts do the
  work so it runs identically at scale.
---

# Bulk MCP-enable Krista release branches

> Part of the Krista extension skill set (see the folder `README.md`). This is the **fleet-wide MCP**
> option referenced by the `krista-extension-builder` runbook. For a single new extension, set
> `tool = true` on requests during builder Phase 4; use this skill to bulk-enable MCP across many
> existing `release/*` branches.

Turn each extension's eligible catalog requests into MCP tools (`tool = true`) and standardize the
`krista-apis` version, verified by compilation. Two bundled scripts under `scripts/` do the work;
this file is the contract and the run recipe.

## What this does (per release branch)
1. Create `feature/<name>-mcp` from **`origin/release/<name>`** (the release tip, NOT `develop-1.0` — that branch has no code).
2. Bump every `krista-apis:<x.y.z>` **and** `extension-impl-anno-processors:<x.y.z>` in `build.gradle` to the target version (default `1.0.126`) — the two are kept aligned.
3. Set `tool = true` on every `@CatalogRequest` whose type is **not** `WAIT_FOR_EVENT` and that doesn't already have a `tool` attribute.
4. **Bump the extension version** (patch +1) in the `@Extension(version=…)` class and in `release.properties` (when present), and prepend a new section to the release-notes `.md` (auto-located under the extension's `docs`/`documentation` tree) describing the MCP enablement + dependency upgrade.
5. `gradle compileJava` — **commit only if it compiles**; on failure, revert the working tree and report (nothing broken is committed).
6. Report: apis version, extension version bump, total catalog requests, waitForEvent skipped, tool=true added, build result, commit hash.

## Hard rules (learned the hard way — do not deviate)
- **Base new branches on `origin/release/<name>`.** Branching from `develop-1.0` gives an empty tree.
- **Edit ONLY inside `@CatalogRequest(...)` blocks.** Never text-replace on `CatalogRequest.Type.` — that token also appears in ordinary code (switch/if/comparisons); replacing it there corrupts the file. The bundled `add_tool_true.py` balances parentheses (respecting string literals) to stay inside the annotation.
- **Exclude `WAIT_FOR_EVENT`** catalog requests — they are not agent tools.
- **Do NOT add an MCP/"Ask Agent" area, query service, or custom tab.** This skill is `tool = true` only.
- **Compile-gate every branch.** A branch is committed only if `gradle compileJava` passes; otherwise revert and report. Never claim success without a green build.
- **Stage tracked source only — use `git add -u`, NEVER `git add -A`.** Compiling produces untracked build output (`build/`, `.gradle/`, `*.class`); `git add -A` would commit it (and, worse, artifacts left over from a previously-processed branch), and Bitbucket rejects the push for files ≥100 MB. `git add -u` stages only modified tracked files (`build.gradle` + `.java`). Run `git clean -fdx` between branches so leftover build output can't leak into the next commit.
- **Skip stubs.** Branches with no `build.gradle` containing `krista-apis` or no `.java` files (e.g. `release/gmail-3.0`, `release/google-directory`) are empty — skip them.
- **Local only.** Never `git push`, never open a PR. Leave branches for human review.

## Prerequisites
- Run inside the local `krista-global-catalog` clone.
- **JDK 21** on PATH (extensions target `@Java(JAVA_21)`).
- Network to the internal Artifactory (`packages.cicd.in.antbrains.com`) for dependency resolution, and to `services.gradle.org` on first run.
- **Gradle:** the repo does **not** commit the wrapper JAR, so `./gradlew` cannot bootstrap. The bundled driver auto-resolves a real Gradle 8.14 (cached in `~/.krista-mcp-gradle/`) — or set `GRADLE_BIN` to your own gradle.

## Run it

Selected branches:
```
bash .claude/skills/krista-mcp-enable/scripts/enable_mcp.sh \
  release/salesforce_sales release/servicenow release/slack
```

Every release branch (stubs auto-skipped):
```
bash .claude/skills/krista-mcp-enable/scripts/enable_mcp.sh --all
```

Override the target API version:
```
TARGET_VER=1.0.126 bash .claude/skills/krista-mcp-enable/scripts/enable_mcp.sh --all
```

Branch naming is derived deterministically: `release/<name>` → `feature/<name>-mcp`.

## Verify after a run
```
# committed tool=true count per branch
git grep -hoE 'tool *= *true' feature/<name>-mcp -- '*.java' | wc -l
# should equal:  (@CatalogRequest count) − (WAIT_FOR_EVENT count) − (any pre-existing tool=true)
```
`added` in the report should equal `total − wait` for a branch that had no prior `tool = true`.

## Then (human decides)
- Review the branches/diffs.
- Push: `git push -u origin feature/<name>-mcp` (per branch) — only when you're ready.
