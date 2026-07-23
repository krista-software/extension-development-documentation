#!/usr/bin/env python3
"""Add `, tool = true` ONLY inside @CatalogRequest(...) annotation blocks.

Skips blocks whose type is WAIT_FOR_EVENT and blocks that already have a `tool`
attribute. Balances parentheses while respecting string/char literals, so it
NEVER touches `CatalogRequest.Type.*` references that appear in ordinary code
(switch/if/comparisons) — the mistake to avoid.

Usage: add_tool_true.py <dir>
Prints: TOOL_TRUE_ADDED <n> across <files> files
"""
import re, sys, os

MARK = "@CatalogRequest"

def process(s):
    out, i, n, added = [], 0, len(s), 0
    while i < n:
        j = s.find(MARK, i)
        if j == -1:
            out.append(s[i:]); break
        k = j + len(MARK)
        while k < n and s[k] in " \t\r\n":
            k += 1
        if k >= n or s[k] != "(":                 # not an annotation invocation
            out.append(s[i:k]); i = k; continue
        depth, p, in_str, in_ch, esc = 0, k, False, False, False
        while p < n:                               # find matching ')'
            c = s[p]
            if in_str:
                if esc: esc = False
                elif c == "\\": esc = True
                elif c == '"': in_str = False
            elif in_ch:
                if esc: esc = False
                elif c == "\\": esc = True
                elif c == "'": in_ch = False
            else:
                if c == '"': in_str = True
                elif c == "'": in_ch = True
                elif c == "(": depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0: break
            p += 1
        block = s[j:p+1]
        if "WAIT_FOR_EVENT" in block or re.search(r"\btool\s*=", block):
            out.append(s[i:p+1]); i = p+1; continue
        out.append(s[i:p]); out.append(", tool = true)")
        i = p + 1; added += 1
    return "".join(out), added

def main(root):
    total, files = 0, 0
    for dp, _, fns in os.walk(root):
        for fn in fns:
            if not fn.endswith(".java"):
                continue
            path = os.path.join(dp, fn)
            with open(path) as fh:
                s = fh.read()
            new, added = process(s)
            if added:
                with open(path, "w") as fh:
                    fh.write(new)
                total += added; files += 1
    print(f"TOOL_TRUE_ADDED {total} across {files} files")

if __name__ == "__main__":
    main(sys.argv[1])
