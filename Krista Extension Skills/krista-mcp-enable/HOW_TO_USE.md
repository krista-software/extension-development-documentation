# krista-mcp-enable — How to Use

Bulk-enable MCP on Krista extension release branches. For each `release/*` branch it creates a
feature branch off the release tip, aligns dependency versions, exposes eligible catalog requests
as MCP tools (`tool = true`), bumps the extension version, adds a release note, compiles, and
commits — **never pushes, never opens a PR, never commits build artifacts.**

---

## 1. Install the skill

Unzip and place the `krista-mcp-enable/` folder into **one** of:

- `<your-project>/.claude/skills/krista-mcp-enable/` — available inside that project, or
- `~/.claude/skills/krista-mcp-enable/` — available in every project

Then **restart Claude Code**. It loads as the slash command `/krista-mcp-enable`.

Folder layout:
```
krista-mcp-enable/
├── SKILL.md                 # the contract Claude follows
├── HOW_TO_USE.md            # this file
└── scripts/
    ├── enable_mcp.sh        # the bulk driver
    ├── add_tool_true.py     # block-scoped tool=true editor
    └── add_release_note.py  # release-notes inserter
```

## 2. Prerequisites (per machine)

- **JDK 21** on `PATH` (verify: `java -version`).
- A local clone of **`krista-global-catalog`** — run from inside it.
- **On-network** access to the internal Artifactory `packages.cicd.in.antbrains.com`
  (dependency resolution) and `services.gradle.org` (first run only — it auto-downloads
  Gradle 8.14 to `~/.krista-mcp-gradle/`, because the repo ships no Gradle wrapper JAR).
- Optional: set `GRADLE_BIN=/path/to/gradle` to use your own Gradle instead of the auto-download.

## 3. Run it

Run from **inside the `krista-global-catalog` clone**, using the **absolute path** to the script
(the skill lives in the project root's `.claude/skills/`, while the repo is a subfolder — a
relative `.claude/...` path will not resolve from inside the repo):

```bash
cd /path/to/krista-global-catalog

# one or more specific branches
bash /ABS/PATH/.claude/skills/krista-mcp-enable/scripts/enable_mcp.sh release/slack release/servicenow

# every release/* branch (empty stub branches auto-skipped)
bash /ABS/PATH/.claude/skills/krista-mcp-enable/scripts/enable_mcp.sh --all

# override the target dependency version (default 1.0.126)
TARGET_VER=1.0.126 bash /ABS/PATH/.claude/skills/krista-mcp-enable/scripts/enable_mcp.sh release/gmail
```

Branch naming is deterministic: `release/<name>` → `feature/<name>-mcp`.

## 4. What it does per branch (automatic)

1. Create `feature/<name>-mcp` off **`origin/release/<name>`** (never `develop-1.0`).
2. Bump `krista-apis` **and** `extension-impl-anno-processors` to the target version.
3. Set `tool = true` on every `@CatalogRequest` except `WAIT_FOR_EVENT` (block-scoped edit — only
   touches annotation bodies, never `CatalogRequest.Type.` used in code).
4. Bump the extension version (patch +1) in `@Extension(version=…)` + `release.properties`
   (when present) and prepend a new release-notes section.
5. `gradle compileJava` — **commit only if it compiles**; otherwise revert and report.
6. Print a per-branch row: `branch | apis | ext-ver | total | wait | added | build | commit`.

## 5. After the run

Commits are **local only.** Review the diffs, then push when ready:

```bash
git push -u origin feature/<name>-mcp
```

## Safety guarantees

- Never `git push`, never opens a PR.
- Stages tracked source only (`git add -u`) — build output is never committed.
- Never claims success without a green compile (auto-reverts on failure).
- Skips empty stub branches (no `build.gradle`/no `.java`).
- Excludes `WAIT_FOR_EVENT` requests; does not add an "Ask Agent"/MCP area (tool=true only).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `No such file or directory` on the script | Use the **absolute path** to `enable_mcp.sh` (see §3). |
| `SKIP (stub …)` for a branch | That branch has no extension code (e.g. an empty `-3.0`/directory stub). Expected. |
| `FAIL … reverted` | Compilation failed — see `/tmp/mcp_build.log`; nothing was committed. |
| Push rejected: file ≥ 100 MB | Should not happen (we commit source only). If it does, a build dir was staged — re-run; the skill uses `git add -u`. |
| Dependency resolution errors | Not on the network / VPN for the internal Artifactory. |
