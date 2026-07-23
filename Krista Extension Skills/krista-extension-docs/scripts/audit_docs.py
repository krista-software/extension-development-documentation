#!/usr/bin/env python3
"""
Audit a Krista Global Catalog extension's Docsify docs against its code.

Deterministic drift checks only — it cannot judge prose accuracy. It reports:
  * version according to @Extension vs README.md vs ReleaseNotes.md
  * _sidebar.md links that point to missing files (broken nav)
  * pages/*.md not referenced by _sidebar.md (orphans / unreachable pages)
  * inventory of @CatalogRequest methods and @Field attributes found in the code,
    so you can eyeball whether every request has a page.

Usage:
    python3 audit_docs.py <extension-module-dir>   # dir containing src/ and build.gradle
    python3 audit_docs.py .                          # run from inside the module
"""
import os
import re
import sys

SEMVER = re.compile(r"\d+\.\d+\.\d+(?:[-.\w]+)?")


def find_file(root, *, name=None, contains=None, under="src/main/java"):
    """Return the first file under `root/under` matching name or containing regex `contains`."""
    base = os.path.join(root, under)
    for dirpath, _dirs, files in os.walk(base):
        for f in files:
            if name and f != name:
                continue
            path = os.path.join(dirpath, f)
            if contains is None:
                return path
            try:
                with open(path, encoding="utf-8", errors="ignore") as fh:
                    if re.search(contains, fh.read()):
                        return path
            except OSError:
                pass
    return None


def read(path):
    with open(path, encoding="utf-8", errors="ignore") as fh:
        return fh.read()


def find_docs_dir(root):
    """Locate the Docsify docs dir: the one under src/main/resources containing _sidebar.md."""
    res = os.path.join(root, "src", "main", "resources")
    for dirpath, _dirs, files in os.walk(res):
        if "_sidebar.md" in files or "index.html" in files and "README.md" in files:
            return dirpath
    # fallback: a 'docs' dir anywhere under resources
    cand = os.path.join(res, "docs")
    return cand if os.path.isdir(cand) else None


def extension_info(root):
    """Return (version, name, attributes[], extension_file) from the @Extension class."""
    path = find_file(root, contains=r"@Extension\s*\(")
    if not path:
        return None, None, [], None
    src = read(path)
    m = re.search(r"@Extension\s*\((.*?)\)", src, re.DOTALL)
    block = m.group(1) if m else ""
    version = (re.search(r'version\s*=\s*"([^"]+)"', block) or [None, None])[1]
    name = (re.search(r'name\s*=\s*"([^"]+)"', block) or [None, None])[1]
    # connection attributes declared as @Field.* on the extension class
    attrs = re.findall(r"@Field\.\w+\s*\(([^)]*)\)", src)
    attr_names = []
    for a in attrs:
        val = re.search(r'value\s*=\s*([A-Za-z0-9_.]+|"[^"]+")', a)
        secured = "isSecured = true" in a.replace(" ", "") or "isSecured=true" in a.replace(" ", "")
        if val:
            attr_names.append(val.group(1).strip('"') + (" (secured)" if secured else ""))
    return version, name, attr_names, path


def wiring_flags(ext_file, docs, root):
    """Check the @Extension class for the three annotations that make docs reach users.

    Returns a dict with booleans and a suggested @ChangeLog path.
    """
    src = read(ext_file) if ext_file and os.path.isfile(ext_file) else ""
    resources = os.path.join(root, "src", "main", "resources")
    # docs folder name under resources -> the value for @StaticResource path/file and the tab
    static_path = os.path.relpath(docs, resources).replace(os.sep, "/") if docs else "docs"
    # locate ReleaseNotes.md to suggest the @ChangeLog file= value (relative to resources)
    changelog_path = None
    for dirpath, _dirs, files in os.walk(resources):
        if "ReleaseNotes.md" in files:
            changelog_path = os.path.relpath(
                os.path.join(dirpath, "ReleaseNotes.md"), resources).replace(os.sep, "/")
            break
    return {
        "has_static_resource": "@StaticResource" in src,
        "has_changelog": "@ChangeLog" in src,
        "has_custom_tabs": "CUSTOM_TABS" in src,
        "has_doc_tab": '"Documentation"' in src,
        "static_path": static_path,
        "changelog_path": changelog_path,
        "custom_tabs": custom_tab_names(src),
    }


def custom_tab_names(src):
    """Extract the tab labels from the CUSTOM_TABS method's returned map.

    Tab labels are the map keys; values are REST/static paths. We distinguish them by
    shape (values start with rest/, static/, http, or /), which is robust to key order and
    to Map.of vs Map.ofEntries. Returns [] if no CUSTOM_TABS method / map is found.
    """
    m = re.search(r"CUSTOM_TABS", src)
    if not m:
        return []
    mo = re.search(r"Map\.of(?:Entries)?\s*\(", src[m.start():])
    if mo:
        paren = src.index("(", m.start() + mo.start())
        content, _ = _balanced(src, paren)
    else:
        # Fallback: a bounded window after CUSTOM_TABS (e.g. a HashMap built with put()).
        content = src[m.start():m.start() + 600]
    literals = re.findall(r'"([^"]*)"', content)
    return [s for s in literals if s and not re.match(r"(rest/|static/|https?:|/)", s)]


def first_semver(text):
    m = SEMVER.search(text or "")
    return m.group(0) if m else None


def readme_version(docs):
    path = os.path.join(docs, "README.md")
    if not os.path.isfile(path):
        return None, None
    for line in read(path).splitlines():
        if re.search(r"[Vv]ersion", line) and SEMVER.search(line):
            return first_semver(line), line.strip()
    return None, None


def releasenotes_version(docs):
    path = os.path.join(docs, "pages", "ReleaseNotes.md")
    if not os.path.isfile(path):
        path = find_file(os.path.dirname(docs) or ".", name="ReleaseNotes.md", under="") or ""
    if not path or not os.path.isfile(path):
        return None, None
    m = re.search(r"^##\s*Version\s*(" + SEMVER.pattern + ")", read(path), re.MULTILINE)
    return (m.group(1) if m else None), path


def _balanced(src, open_idx):
    """Given index of '(', return (content, index-after-close) for the balanced parens."""
    depth = 0
    for i in range(open_idx, len(src)):
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
            if depth == 0:
                return src[open_idx + 1:i], i + 1
    return src[open_idx + 1:], len(src)


def catalog_requests(root):
    """List dicts {name, area, file} for every @CatalogRequest found in the code.

    Prefers the human-readable `name = "..."` attribute (which maps to a doc page/sidebar
    entry) over the method name.
    """
    out = []
    base = os.path.join(root, "src", "main", "java")
    for dirpath, _dirs, files in os.walk(base):
        for f in files:
            if not f.endswith(".java"):
                continue
            path = os.path.join(dirpath, f)
            src = read(path)
            for m in re.finditer(r"@CatalogRequest\s*\(", src):
                block, _end = _balanced(src, src.index("(", m.start()))
                name = (re.search(r'name\s*=\s*"([^"]+)"', block) or [None, None])[1]
                area = (re.search(r'area\s*=\s*"([^"]+)"', block) or [None, None])[1]
                tool = bool(re.search(r"tool\s*=\s*true", block))
                if name:
                    out.append({"name": name, "area": area, "tool": tool,
                                "file": os.path.relpath(path, root)})
    return out


def page_for_request(pages_dir, name):
    """Find the docs page whose H1 title matches the request name. Returns (path, content)."""
    if not name or not os.path.isdir(pages_dir):
        return None, None
    for f in sorted(os.listdir(pages_dir)):
        if not f.endswith(".md"):
            continue
        path = os.path.join(pages_dir, f)
        content = read(path)
        m = re.search(r"^#\s+(.+?)\s*$", content, re.MULTILINE)
        if m and m.group(1).strip().lower() == name.lower():
            return path, content
    return None, None


def anno_processor_version(root):
    """The Krista Service APIs version — source of truth is the annotationProcessor line in
    build.gradle: annotationProcessor 'app.krista:extension-impl-anno-processors:<VERSION>'."""
    bg = os.path.join(root, "build.gradle")
    if not os.path.isfile(bg):
        return None
    m = re.search(r"extension-impl-anno-processors:([0-9][^'\"\s]*)", read(bg))
    return m.group(1) if m else None


def sidebar_links(docs):
    path = os.path.join(docs, "_sidebar.md")
    if not os.path.isfile(path):
        return [], None
    links = re.findall(r"\[[^\]]*\]\(([^)]+)\)", read(path))
    return links, path


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    print(f"# Docs audit for {root}\n")
    issues = []

    docs = find_docs_dir(root)
    if not docs:
        print("!! Could not find a Docsify docs dir under src/main/resources.")
        sys.exit(2)
    print(f"Docs dir: {os.path.relpath(docs, root)}")

    ext_ver, ext_name, attrs, ext_file = extension_info(root)
    print(f"Extension: name={ext_name!r} version={ext_ver!r}"
          + (f"  ({os.path.relpath(ext_file, root)})" if ext_file else "  (@Extension class not found)"))

    # --- Extension wiring (does the extension actually serve the docs?) ---
    print("\n## Extension wiring (@Extension class)")
    if ext_file:
        w = wiring_flags(ext_file, docs, root)
        print(f"  @StaticResource     : {'present' if w['has_static_resource'] else 'MISSING'}")
        print(f"  @ChangeLog          : {'present' if w['has_changelog'] else 'MISSING'}")
        print(f"  Documentation tab   : {'present' if w['has_doc_tab'] else 'MISSING'}"
              + ("" if w["has_custom_tabs"] else "  (no CUSTOM_TABS method at all)"))
        if not w["has_static_resource"]:
            issues.append(f'@StaticResource missing — add @StaticResource(path = "{w["static_path"]}", '
                          f'file = "{w["static_path"]}") so the docs are bundled.')
        if not w["has_changelog"]:
            cl = w["changelog_path"] or f"{w['static_path']}/pages/ReleaseNotes.md"
            issues.append(f'@ChangeLog missing — add @ChangeLog(file = "{cl}") '
                          "(create ReleaseNotes.md first if it does not exist).")
        if not w["has_doc_tab"]:
            issues.append('Documentation tab missing — add a "Documentation" -> '
                          f'"static/{w["static_path"]}" entry to the CUSTOM_TABS map'
                          + ("." if w["has_custom_tabs"] else " (add the customTabs() method)."))
        tabs = w["custom_tabs"]
        if tabs:
            print(f"  Custom tabs         : {', '.join(tabs)}")
            other = [t for t in tabs if t != "Documentation"]
            if other:
                print("    (advisory) confirm each user-facing tab is covered in the docs: "
                      + ", ".join(other))
    else:
        print("  (@Extension class not found — cannot check wiring)")

    # --- Version consistency ---
    print("\n## Version consistency")
    rm_ver, rm_line = readme_version(docs)
    rn_ver, rn_path = releasenotes_version(docs)
    print(f"  @Extension : {ext_ver}")
    print(f"  README.md  : {rm_ver}   ({rm_line or 'no version line found'})")
    print(f"  ReleaseNotes top block : {rn_ver}")
    if ext_ver and rm_ver and ext_ver != rm_ver:
        issues.append(f"README.md version ({rm_ver}) != @Extension version ({ext_ver}).")
    if ext_ver and rn_ver and ext_ver != rn_ver:
        issues.append(f"ReleaseNotes top version ({rn_ver}) != @Extension version ({ext_ver}).")
    if ext_ver and not rn_ver:
        issues.append("Could not find a '## Version X.Y.Z' block in ReleaseNotes.md.")

    # --- Krista Service APIs version: build.gradle is the source of truth ---
    print("\n## Krista Service APIs version (build.gradle vs ReleaseNotes)")
    ap_ver = anno_processor_version(root)
    print(f"  build.gradle (extension-impl-anno-processors): {ap_ver or 'not found'}")
    if ap_ver and rn_path and os.path.isfile(rn_path):
        rn_text = read(rn_path)
        blocks = re.split(r"^##\s+Version", rn_text, flags=re.MULTILINE)
        top = blocks[1] if len(blocks) > 1 else rn_text  # newest release block
        if ap_ver in top:
            print(f"  ReleaseNotes top block references {ap_ver}: yes")
        else:
            print(f"  ReleaseNotes top block references {ap_ver}: NO")
            issues.append(f"ReleaseNotes top block does not mention Krista Service APIs version "
                          f"{ap_ver} (from the build.gradle annotationProcessor line).")

    # --- Sidebar link integrity ---
    print("\n## Navigation (_sidebar.md)")
    links, sb_path = sidebar_links(docs)
    if not sb_path:
        issues.append("_sidebar.md not found.")
    referenced = set()
    for link in links:
        target = link.split("#")[0].strip()
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        rel = "README.md" if target in ("/", "") else target.lstrip("/")
        resolved = os.path.join(docs, rel)
        referenced.add(os.path.normpath(resolved))
        if not os.path.isfile(resolved):
            issues.append(f"_sidebar.md links to missing file: {target}")
    print(f"  {len(links)} links, {len(referenced)} resolve to doc files")

    # --- Orphan pages ---
    print("\n## Orphan pages (in pages/ but not linked from _sidebar.md)")
    pages_dir = os.path.join(docs, "pages")
    orphans = []
    if os.path.isdir(pages_dir):
        for f in sorted(os.listdir(pages_dir)):
            if not f.endswith(".md"):
                continue
            full = os.path.normpath(os.path.join(pages_dir, f))
            if full not in referenced:
                orphans.append(f"pages/{f}")
    if orphans:
        for o in orphans:
            print(f"  - {o}")
        issues.append(f"{len(orphans)} page(s) not reachable from _sidebar.md: {', '.join(orphans)}")
    else:
        print("  none")

    # --- Catalog requests: cross-check each against the docs ---
    print("\n## Catalog requests in code vs docs")
    reqs = catalog_requests(root)
    sb_text = read(sb_path) if sb_path and os.path.isfile(sb_path) else ""
    # Discover the aggregate "supported requests" page by pattern — its filename is not
    # standardized across modules (supported-requests.md, SupportedRequests.md, ...).
    pages_dir = os.path.join(docs, "pages")
    agg_path = None
    if os.path.isdir(pages_dir):
        for f in os.listdir(pages_dir):
            if re.fullmatch(r"supported[-_ ]?requests\.md", f, re.IGNORECASE):
                agg_path = os.path.join(pages_dir, f)
                break
    agg_text = read(agg_path) if agg_path else ""
    if agg_path:
        print(f"  (aggregate page: pages/{os.path.basename(agg_path)})")
    seen = set()
    for r in reqs:
        if r["name"] in seen:
            continue
        seen.add(r["name"])
        in_sidebar = r["name"] in sb_text
        # Only treat "missing from aggregate" as drift when an aggregate page actually exists;
        # some modules legitimately don't keep one.
        in_agg = (r["name"] in agg_text) if agg_path else True
        # Every catalog request must have a dedicated page (H1 matching its name).
        pg, content = page_for_request(pages_dir, r["name"])
        flags = []
        if pg is None:
            flags.append("no dedicated page — create one")
        if not in_sidebar:
            flags.append("NOT linked from _sidebar.md")
        if not in_agg:
            flags.append(f"NOT in {os.path.basename(agg_path)}")
        # tool = true must be reflected on the request's own page (Ask Agent / MCP callable).
        if r.get("tool") and pg is not None:
            low = content.lower()
            mentions = ("ask agent", "mcp", "tool = true", "ai agent",
                        "agent-callable", "agent callable", "tool call")
            if not any(k in low for k in mentions):
                flags.append("tool=true NOT documented on its page")
        tag = "  [tool=true]" if r.get("tool") else ""
        status = "ok" if not flags else "; ".join(flags)
        print(f"  - {r['name']!r} (area={r['area']!r}){tag}  ->  {status}")
        if flags:
            issues.append(f"Catalog request {r['name']!r}: {'; '.join(flags)}.")
    if not reqs:
        print("  (no @CatalogRequest methods found)")

    print("\n## Connection attributes (@Field on @Extension class)")
    for a in attrs:
        print(f"  - {a}")
    if not attrs:
        print("  (none found)")

    # --- Summary ---
    print("\n## Summary")
    if issues:
        print(f"  {len(issues)} issue(s) to resolve:")
        for i in issues:
            print(f"   - {i}")
        sys.exit(1)
    print("  No drift detected by the deterministic checks. Prose accuracy still needs a human read.")


if __name__ == "__main__":
    main()
