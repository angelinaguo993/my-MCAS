#!/usr/bin/env python3
"""
Restores .font(...) modifiers that a Replace All with an EMPTY replacement
deleted. Compares every Swift file against a known-good git commit and puts
back any line whose ONLY difference is a missing .font(...) modifier.

Lines you already retyped by hand (e.g. with the new .nHeadline names) are
left alone. Nothing is committed; review the result with `git diff`.

usage (from anywhere inside the repo):  python3 restore_fonts.py <good-commit>
"""
import difflib
import os
import re
import subprocess
import sys

if len(sys.argv) != 2:
    sys.exit("usage: python3 restore_fonts.py <good-commit>")
BASE = sys.argv[1]

# .font(.headline)   .font(.title2.bold())   .font(.nHeadline)
# (the optional (\(\))? is what lets the .bold() variants match)
FONT = re.compile(r"\.font\(\.[A-Za-z0-9.]+(?:\(\))?\)")


def git(*args):
    return subprocess.check_output(["git", *args], text=True)


os.chdir(git("rev-parse", "--show-toplevel").strip())

files = [p for p in git("diff", "--name-only", BASE, "--", "*.swift").split() if os.path.exists(p)]
total_restored = 0
unresolved = []

for path in files:
    try:
        old = git("show", f"{BASE}:{path}").split("\n")
    except subprocess.CalledProcessError:
        continue  # file didn't exist at BASE, so there's no original to restore from

    with open(path, encoding="utf-8") as f:
        new = f.read().split("\n")

    out, restored = [], 0
    matcher = difflib.SequenceMatcher(None, old, new, autojunk=False)
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "replace" and (i2 - i1) == (j2 - j1):
            for o, n in zip(old[i1:i2], new[j1:j2]):
                # the only difference is the missing .font(...) -> put it back
                if FONT.search(o) and FONT.sub("", o).strip() == n.strip():
                    out.append(o)
                    restored += 1
                else:
                    out.append(n)
        else:
            if tag in ("replace", "delete"):
                for o in old[i1:i2]:
                    if FONT.search(o):
                        unresolved.append((path, j1 + 1, o.strip()))
            out.extend(new[j1:j2])

    if restored:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(out))
        print(f"restored {restored:3d} in {path}")
        total_restored += restored

print(f"\nTotal restored: {total_restored}")
if unresolved:
    print("\nCould not auto-restore (the surrounding code changed too). Check by hand:")
    for path, line, text in unresolved:
        print(f"  {path} near line {line}: {text}")