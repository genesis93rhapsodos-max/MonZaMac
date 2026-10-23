# Bisect which game code objects break when built -O1 (characters invisible in the optimised build): link a mixed
# lasgame.dll (objects in the "slow" set from build/obj (-O0), the rest from build/o1/obj (-O1)), run the street scene
# and look for Taunie (pink hair pixels at the right of the frame).
# usage (from LASRecomp/): python tools/za/bisect_o1.py
import glob, os, subprocess, sys
from PIL import Image

os.environ['PATH'] = r'C:\msys64\ucrt64\bin;C:\msys64\usr\bin;' + os.environ['PATH']
objs = sorted(os.path.relpath(p, 'build/o1/obj').replace('\\', '/') for p in glob.glob('build/o1/obj/main/*.o') + glob.glob('build/o1/obj/sdk/*.o'))
os.makedirs('build/mix', exist_ok=True)

def link(slow):
    rsp = 'build/mix/lasgame.rsp'
    with open(rsp, 'w') as f:
        for o in objs:
            f.write(('build/obj/' if o in slow else 'build/o1/obj/') + o + '\n')
        f.write('build/o1/obj/tools/gamelib_entry.o\n')
    subprocess.run(['clang', '-shared', '-fuse-ld=lld', 'build/o1/lasrecomp.dll.a', '-o', 'build/mix/lasgame.dll', '@' + rsp], check=True)
    open('build/mix/lasgame.dll.id', 'w').write(open('build/o1/lasgame.dll.id').read())

def taunie_visible():
    for f in glob.glob('build/frame_*.png'): os.remove(f)
    env = dict(os.environ, EXE='build/o1/lasrecomp.exe', IN='300:A:6', SHOT='150', T='75',
               LARECOMP_GAME_LIB=os.path.abspath('build/mix/lasgame.dll'))
    subprocess.run([r'C:\Program Files\Git\usr\bin\bash.exe', '../za-tools/auto-win.sh'], env=env, capture_output=True)
    frames = sorted(glob.glob('build/frame_*.png'), key=lambda f: int(f[12:-4]))
    if not frames: return None
    im = Image.open(frames[-2] if len(frames) > 1 else frames[-1]).convert('RGB').resize((1280, 720))
    global run_no
    run_no = globals().get('run_no', 0) + 1
    im.save(f'build/mix/run_{run_no}.png')
    pink = 0
    for y in range(300, 600, 3):
        for x in range(860, 1040, 3):
            r, g, b = im.getpixel((x, y))
            pink += r > 200 and 110 < g < 190 and 120 < b < 200 and r - g > 50
    return pink

lo, hi = 0, len(objs)  # suspects: objs[lo:hi] built -O0 makes it work
cand = objs[:]
print(len(cand), 'objects')
while len(cand) > 1:
    half = cand[:len(cand) // 2]
    link(set(half))
    p = taunie_visible()
    print(f'{len(cand)} suspects: -O0 for the first {len(half)} ({half[0]}..{half[-1]}): pink {p}', flush=True)
    cand = half if p and p > 200 else cand[len(cand) // 2:]
print('culprit:', cand)
