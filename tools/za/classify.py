import re, sys, glob, struct, collections
sys.path.insert(0, sys.argv[1])
from nso import Nso
import capstone
n = Nso(sys.argv[2]); base = 0x7000000000
addrs = set()
for f in glob.glob(sys.argv[3] + '/*.c'):
    addrs.update(int(x, 16) for x in re.findall(r'rt_udf\(c, (0x[0-9a-f]+)ull\)', open(f).read()))
md = capstone.Cs(capstone.CS_ARCH_ARM64, capstone.CS_MODE_ARM)
c = collections.Counter(); ex = {}
for a in addrs:
    w = n.image[a - base:a - base + 4]
    ins = list(md.disasm(bytes(w), a))
    k = ins[0].mnemonic if ins else ('zero' if w == b'\0\0\0\0' else 'invalido')
    c[k] += 1; ex.setdefault(k, f'{a:x}: {ins[0].mnemonic} {ins[0].op_str}' if ins else f'{a:x}: {w.hex()}')
print('enderecos unicos:', len(addrs))
for k, v in c.most_common(30): print(f'{v:7d}  {k:12s} ex. {ex[k]}')
