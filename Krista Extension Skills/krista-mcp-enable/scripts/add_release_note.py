#!/usr/bin/env python3
"""Insert a new release-notes section above the newest '## Version' heading.

Usage: add_release_note.py <md_path> <new_version> <dep_version>
"""
import sys

md, ver, dep = sys.argv[1], sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else "the target")
block = f"""## Version {ver}

- **Krista Service APIs Java**: {dep}

### What's New
- **MCP Enablement**: Set `tool = true` on all eligible catalog requests so they are exposed as tools to the Krista AI agent (WAIT_FOR_EVENT requests excluded).
- **Dependency Upgrade**: Bumped `krista-apis` and `extension-impl-anno-processors` to `{dep}`.

---
"""
with open(md) as f:
    lines = f.read().split("\n")
idx = next((i for i, l in enumerate(lines) if l.strip().startswith("## Version ")), None)
if idx is None:  # fallback: after the first heading line
    idx = next((i for i, l in enumerate(lines) if l.lstrip().startswith("#")), -1) + 1
new_lines = lines[:idx] + block.split("\n") + [""] + lines[idx:]
with open(md, "w") as f:
    f.write("\n".join(new_lines))
print(f"RELEASE_NOTE_ADDED {ver}")
