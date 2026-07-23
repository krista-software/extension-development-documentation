#!/bin/bash
# Bulk MCP-enable Krista extension release branches.
# Per release branch: create feature branch off the RELEASE tip, bump krista-apis,
# set tool=true on eligible catalog requests, compile-gate, commit (no push).
#
# Usage:   enable_mcp.sh release/google-drive release/google-docs ...
#   or:    enable_mcp.sh --all              (every release/* branch; stubs auto-skipped)
# Env:     TARGET_VER (default 1.0.126)  GRADLE_BIN (optional path to a gradle 8.x)
#
# Requires: run inside the krista-global-catalog clone; JDK 21; network to the
# internal Artifactory (dependency resolution) and services.gradle.org (first run).

set -u
TARGET_VER="${TARGET_VER:-1.0.126}"
HERE="$(cd "$(dirname "$0")" && pwd)"
EDITOR="$HERE/add_tool_true.py"

# --- locate repo root ---
if [ ! -d .git ] || ! git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
  echo "ERROR: run this from inside the krista-global-catalog git clone."; exit 2
fi

# --- resolve a usable gradle (wrapper jar is NOT committed in this repo) ---
resolve_gradle() {
  if [ -n "${GRADLE_BIN:-}" ] && [ -x "$GRADLE_BIN" ]; then echo "$GRADLE_BIN"; return; fi
  if command -v gradle >/dev/null 2>&1; then command -v gradle; return; fi
  local ver=8.14 cache="$HOME/.krista-mcp-gradle"
  if [ ! -x "$cache/gradle-$ver/bin/gradle" ]; then
    mkdir -p "$cache"; ( cd "$cache" &&
      curl -sL -o "gradle-$ver-bin.zip" "https://services.gradle.org/distributions/gradle-$ver-bin.zip" &&
      unzip -qo "gradle-$ver-bin.zip" ) >&2
  fi
  echo "$cache/gradle-$ver/bin/gradle"
}
GRADLE="$(resolve_gradle)"
echo "using gradle: $GRADLE"

# --- build branch list ---
BRANCHES=()
if [ "${1:-}" = "--all" ]; then
  while read -r b; do BRANCHES+=("$b"); done < <(git branch -r | sed 's# *origin/##' | grep '^release/' | sort -u)
else
  BRANCHES=("$@")
fi
[ ${#BRANCHES[@]} -eq 0 ] && { echo "no branches given"; exit 2; }

printf "%-40s | %-9s | %-13s | %5s | %4s | %5s | %-6s | %s\n" branch apis ext-ver total wait added build commit
printf -- "-------------------------------------------------------------------------------------------------------------------\n"

for src in "${BRANCHES[@]}"; do
  git fetch -q origin "$src" 2>/dev/null
  new="feature/${src#release/}-mcp"
  git checkout -qB "$new" "origin/$src" 2>/dev/null || { echo "$src : cannot checkout"; continue; }
  git clean -qfdx 2>/dev/null   # remove any leftover build artifacts before editing

  bg="$(grep -rl 'krista-apis:' --include=build.gradle . 2>/dev/null | head -1)"
  if [ -z "$bg" ]; then echo "$src : SKIP (stub — no build.gradle with krista-apis)"; continue; fi
  d="$(dirname "$bg")"
  if [ -z "$(find "$d" -name '*.java' 2>/dev/null | head -1)" ]; then echo "$src : SKIP (stub — no java)"; continue; fi

  # 1) bump krista-apis AND extension-impl-anno-processors to TARGET_VER (keep them aligned)
  while IFS= read -r f; do
    for art in krista-apis extension-impl-anno-processors; do
      sed -i '' -E "s/(${art}:)[0-9]+\.[0-9]+\.[0-9]+/\1${TARGET_VER}/g" "$f" 2>/dev/null || \
      sed -i -E "s/(${art}:)[0-9]+\.[0-9]+\.[0-9]+/\1${TARGET_VER}/g" "$f"
    done
  done < <(grep -rlE 'krista-apis:|extension-impl-anno-processors:' --include=build.gradle .)

  # 2) counts + block-scoped tool=true
  total=$(git grep -h "@CatalogRequest" HEAD -- '*.java' | wc -l | tr -d ' ')
  wait=$(grep -rhoE 'CatalogRequest\.Type\.WAIT_FOR_EVENT' "$d" | wc -l | tr -d ' ')
  added=$(python3 "$EDITOR" "$d" | grep -oE 'ADDED [0-9]+' | awk '{print $2}')

  # 3) bump the extension version (patch +1) in @Extension + release.properties, and add a release note
  verbump="ver:skip"
  extclass="$(grep -rlE '@Extension\(' "$d" --include='*.java' | head -1)"
  cur="$(grep -oE 'version[[:space:]]*=[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$extclass" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  if [ -n "$cur" ]; then
    IFS='.' read -r MA MI PA <<< "$cur"; newver="${MA}.${MI}.$((PA+1))"
    sed -i '' -E "s/(version[[:space:]]*=[[:space:]]*)\"${cur}\"/\1\"${newver}\"/" "$extclass" 2>/dev/null || \
      sed -i -E "s/(version[[:space:]]*=[[:space:]]*)\"${cur}\"/\1\"${newver}\"/" "$extclass"
    rp="$(grep -rl '^extension.version' --include='*release.properties' "$d" 2>/dev/null | head -1)"
    [ -n "$rp" ] && { sed -i '' -E "s/(extension.version[[:space:]]*=[[:space:]]*)${cur}/\1${newver}/" "$rp" 2>/dev/null || \
      sed -i -E "s/(extension.version[[:space:]]*=[[:space:]]*)${cur}/\1${newver}/" "$rp"; }
    rn="$(find "$d" -type f \( -iname '*release*note*.md' -o -iname 'releasenotes.md' -o -iname 'changelog*.md' \) 2>/dev/null | head -1)"
    [ -n "$rn" ] && python3 "$HERE/add_release_note.py" "$rn" "$newver" "$TARGET_VER" >/dev/null
    verbump="${cur}->${newver}"
  fi

  # 4) compile-gate
  ( cd "$d" && "$GRADLE" compileJava --console=plain --no-daemon ) >/tmp/mcp_build.log 2>&1
  if [ $? -eq 0 ]; then
    git add -u    # ONLY tracked source (build.gradle + .java + release notes/props). NEVER -A: build output is untracked and must not be committed.
    git commit -q -m "feat(${src#release/}): krista-apis ${TARGET_VER} + MCP tool=true + version ${verbump}"
    printf "%-40s | %-9s | %-13s | %5s | %4s | %5s | %-6s | %s\n" "$new" "$TARGET_VER" "$verbump" "$total" "$wait" "${added:-0}" PASS "$(git rev-parse --short HEAD)"
  else
    git checkout -q -- .
    printf "%-40s | %-9s | %-13s | %5s | %4s | %5s | %-6s | %s\n" "$new" "$TARGET_VER" "$verbump" "$total" "$wait" "${added:-0}" FAIL "reverted; see /tmp/mcp_build.log"
  fi
  git clean -qfdx 2>/dev/null   # tidy build output so it can't leak into the next branch
done
echo "DONE (branches are local only — not pushed)"
