# Runs the optimised build N times with a debug frame, classifies each run (Taunie visible or not) and keeps the
# character draws' debug lines, to compare good and bad runs. usage (from LASRecomp/): python tools/za/goodbad.py N
import glob, os, re, shutil, subprocess, sys
from PIL import Image

N = int(sys.argv[1]) if len(sys.argv) > 1 else 4
CHAR_VS = ('77086f4900', '770868c900', '77085d4500', '7704e4b300', '77085fb700')
BASH = r'C:\Program Files\Git\usr\bin\bash.exe'
os.makedirs('build/gb', exist_ok=True)

def pink(path):
    im = Image.open(path).convert('RGB').resize((1280, 720))
    n = 0
    for y in range(300, 600, 3):
        for x in range(860, 1040, 3):
            r, g, b = im.getpixel((x, y))
            n += r > 200 and 110 < g < 190 and 120 < b < 200 and r - g > 50
    return n

for i in range(N):
    for f in glob.glob('build/frame_*.png'): os.remove(f)
    env = dict(os.environ, EXE='build/o1/lasrecomp.exe', IN='300:A:6', SHOT='150', T='75', LARECOMP_DEBUG_FRAME='2500',
               LARECOMP_DEBUG_DATA='1')
    subprocess.run([BASH, '../za-tools/auto-win.sh'], env=env, capture_output=True)
    frames = sorted(glob.glob('build/frame_*.png'), key=lambda f: int(f[12:-4]))
    p = pink(frames[-2]) if len(frames) > 1 else -1
    tag = 'good' if p > 200 else 'bad'
    log = open('../za-tools/auto.log', encoding='utf-8', errors='replace').read()
    shutil.copy('../za-tools/auto.log', f'build/gb/run{i}_{tag}.log')
    m = log.find('===== debug frame 2500')
    seg = log[m:] if m >= 0 else ''
    blocks = re.split(r'\n(?=\[draw\] [a-z])', seg)
    keep = [b for b in blocks if any(f'vs={v}' in b.split('\n')[0] for v in CHAR_VS)]
    with open(f'build/gb/run{i}_{tag}_chars.txt', 'w') as f:
        f.write('\n'.join(keep))
    print(i, tag, p, 'character draws', len(keep), flush=True)
