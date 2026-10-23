# build/samples.txt (LARECOMP_SAMPLE, runtime/platform/windows.c) -> functions ranked by samples, total and per thread.
# usage: python samples.py <samples.txt> <log with the "[sample] ... lasgame.dll at X, exe at Y" line> <lasgame.dll> <lasrecomp.exe>
import bisect, collections, re, subprocess, sys

samples, log, dll, exe = sys.argv[1:5]
m = re.search(r'lasgame\.dll at (?:0x)?([0-9A-Fa-f]+), exe at (?:0x)?([0-9A-Fa-f]+)', open(log, encoding='utf-8', errors='replace').read())
loaded = {'dll': int(m.group(1), 16), 'exe': int(m.group(2), 16)}

def syms(path):
    out = subprocess.run(['nm', '-n', path], capture_output=True, text=True).stdout
    tab = []
    for line in out.splitlines():
        p = line.split()
        if len(p) == 3 and p[1] in 'tT':
            tab.append((int(p[0], 16), p[2]))
    tab.sort()
    return tab

mods = {}
for name, path in (('dll', dll), ('exe', exe)):
    tab = syms(path)
    # nm prints addresses at the preferred image base; the lowest text symbol's page approximates it
    pref = min(a for a, _ in tab) & ~0xFFFFF if tab else 0
    mods[name] = (tab, [a for a, _ in tab], pref)

def where(rip):
    best = None
    for name, (tab, addrs, pref) in mods.items():
        off = rip - loaded[name] + pref
        i = bisect.bisect_right(addrs, off) - 1
        if i >= 0 and off - addrs[i] < 0x100000:
            if best is None or off - addrs[i] < best[1]:
                best = (f'{name}:{tab[i][1]}', off - addrs[i])
    return best[0] if best else f'?{rip:x}'

tot = collections.Counter()
per = collections.defaultdict(collections.Counter)
n = 0
for line in open(samples):
    tid, rip, cnt = line.split()
    cnt = int(cnt)
    f = where(int(rip, 16))
    tot[f] += cnt
    per[tid][f] += cnt
    n += cnt
print(f'{n} samples')
for f, c in tot.most_common(40):
    print(f'{100 * c / n:6.2f}%  {f}')
print('\nper thread (top 6 threads):')
for tid, ctr in sorted(per.items(), key=lambda kv: -sum(kv[1].values()))[:6]:
    s = sum(ctr.values())
    print(f'thread {tid}: {s} samples; ' + ', '.join(f'{f} {100 * c / s:.0f}%' for f, c in ctr.most_common(6)))
