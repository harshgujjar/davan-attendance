#!/usr/bin/env python3
"""Check / refresh the line numbers in changelog "FILES (<file>): name 1234; ..." parts.

Every changelog entry (index.html HTML_CHANGELOG, student_portal.html VERSION header,
widget W*_CHANGES.md, any other app file) ends with a FILES part listing what changed:
    FILES (index.html): hcRatingsWho 82990; hcRatingsHtml (tap average) 83014.
The first word of each item is the function / const it points at. Line numbers move with
every edit, so run this before each commit:
    python3 tools/changelog_lines.py index.html student_portal.html          # report stale refs
    python3 tools/changelog_lines.py --fix index.html student_portal.html    # rewrite them
A stale ref moves to the nearest line (within 400) that mentions its name, else to its one definition;\nrefs that can't be found are listed to fix by hand.
"""
import re, sys, os

FILES_RE = re.compile(r'FILES \(([^)]+)\):\s*(.*?)(?=\.\'\s*\}|\.\s*$|\.\s+[A-Z]|$)', re.M)
ITEM_RE = re.compile(r'^\s*([A-Za-z_$][\w$.]*)(.*?)\s(\d{2,6})\s*$')
DEF_PATS = [r'(?:async\s+)?function\s+{n}\s*\(', r'^\s*(?:const|let|var)\s+{n}\b', r'\bfun\s+{n}\s*\(',
            r'\b(?:val|var|const val)\s+{n}\b', r'\bclass\s+{n}\b', r'\bid="{n}"']

def defs(lines, name):
    out = []
    for p in DEF_PATS:
        rx = re.compile(p.format(n=re.escape(name.split('.')[-1])))
        out += [i + 1 for i, l in enumerate(lines) if rx.search(l)]
    return sorted(set(out))

def run(path, fix):
    src = open(path, encoding='utf-8').read()
    base = os.path.dirname(path) or '.'
    cache, stale, changed = {}, 0, [src]
    def target(fname):
        if fname not in cache:
            p = os.path.join(base, fname)
            cache[fname] = open(p, encoding='utf-8').read().split('\n') if os.path.exists(p) else None
        return cache[fname]
    def fix_block(m):
        nonlocal stale
        fname, body = m.group(1).strip(), m.group(2)
        L = target(fname)
        if L is None: return m.group(0)
        items = body.split(';')
        for k, it in enumerate(items):
            mm = ITEM_RE.match(it)
            if not mm: continue
            name, n = mm.group(1), int(mm.group(3))
            short = name.split('.')[-1]
            if 0 < n <= len(L) and short in L[n - 1]: continue
            # plain words ("admin", "Data") are descriptions, not code names - nothing to check
            if not defs(L, name) and not re.search(r'[a-z][A-Z]|_|^[A-Z][A-Z0-9_]{2,}$', short): continue
            # the line moved: nearest line that mentions the name (edits shift code by a few lines),
            # else its one definition
            near = [i + 1 for i in range(max(0, n - 400), min(len(L), n + 400)) if re.search(r'\b%s\b' % re.escape(short), L[i])]
            d = defs(L, name)
            new_n = min(near, key=lambda x: abs(x - n)) if near else (d[0] if len(d) == 1 else None)
            stale += 1
            print('%s: FILES (%s) %s %d is stale -> %s' % (path, fname, name, n, new_n or 'NOT FOUND (fix by hand)'))
            if fix and new_n:
                items[k] = it[:mm.start(3)] + str(new_n) + it[mm.end(3):]
        return m.group(0).replace(body, ';'.join(items)) if fix else m.group(0)
    new = FILES_RE.sub(fix_block, src)
    if fix and new != src:
        open(path, 'w', encoding='utf-8').write(new)
        print('%s: refreshed' % path)
    return stale

if __name__ == '__main__':
    args = sys.argv[1:]; fix = '--fix' in args
    paths = [a for a in args if a != '--fix'] or ['index.html', 'student_portal.html']
    total = sum(run(p, fix) for p in paths)
    print('stale refs: %d' % total)
