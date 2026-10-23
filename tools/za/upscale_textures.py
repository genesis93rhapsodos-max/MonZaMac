# Builds an HD texture pack (textures/hd/<hash>.png, runtime/nvn/vulkan/textures.c) from a texture dump
# (textures/dump: LARECOMP_TEX_DUMP=1 or tex_dump = 1, then play through the places you want).
#
# Only colour textures are upscaled. Normal maps (two channels: blue empty) and masks (grey / one channel) keep the
# game's own - an upscaler's "detail" in those reads as lighting noise. With Real-ESRGAN (realesrgan-ncnn-vulkan,
# put its folder in tools/realesrgan or pass --esrgan <exe>) the colour textures are upscaled by its model; without it,
# Lanczos + an unsharp mask (a mild gain). Needs Pillow.
#
# usage (from LASRecomp/): python tools/za/upscale_textures.py [--scale 2] [--max 2048] [--esrgan <exe>] [--model <name>]
#                          [--force]   (redo textures already in textures/hd)
import argparse, glob, os, shutil, subprocess, sys, tempfile
from PIL import Image, ImageFilter, ImageStat

ap = argparse.ArgumentParser()
ap.add_argument('--src', default='textures/dump')
ap.add_argument('--dst', default='textures/hd')
ap.add_argument('--scale', type=int, default=2, choices=(2, 3, 4))
ap.add_argument('--max', type=int, default=2048, help='skip textures larger than this (either side)')
ap.add_argument('--min', type=int, default=32, help='skip textures smaller than this (either side)')
ap.add_argument('--esrgan', default=None, help='realesrgan-ncnn-vulkan executable')
ap.add_argument('--model', default='realesrgan-x4plus')
ap.add_argument('--force', action='store_true')
args = ap.parse_args()


def kind(im):
    """'colour', 'normal' or 'mask' (by content)."""
    small = im.convert('RGBA').resize((64, 64))
    r, g, b, a = (ImageStat.Stat(small.getchannel(c)) for c in 'RGBA')
    if b.mean[0] < 24 and 70 < r.mean[0] < 190 and 70 < g.mean[0] < 190:
        return 'normal'  # BC5 XY normals: blue empty, red / green around the middle
    if abs(r.mean[0] - 128) < 30 and abs(g.mean[0] - 128) < 30 and b.mean[0] > 200:
        return 'normal'  # XYZ normals
    hsv = small.convert('RGB').convert('HSV')
    sat = ImageStat.Stat(hsv.getchannel('S')).mean[0]
    if sat < 12 and r.stddev[0] < 6:
        return 'mask'  # flat grey
    if g.stddev[0] < 2 and b.stddev[0] < 2 and r.stddev[0] > 8:
        return 'mask'  # one channel
    return 'colour'


def find_esrgan():
    if args.esrgan:
        return args.esrgan
    for c in glob.glob('tools/realesrgan/**/realesrgan-ncnn-vulkan*', recursive=True):
        if c.lower().endswith(('.exe', 'vulkan')):
            return c
    return shutil.which('realesrgan-ncnn-vulkan')


os.makedirs(args.dst, exist_ok=True)
todo, stats = [], {'colour': 0, 'normal': 0, 'mask': 0, 'size': 0, 'done': 0}
for f in sorted(glob.glob(os.path.join(args.src, '*.png'))):
    out = os.path.join(args.dst, os.path.basename(f))
    if os.path.exists(out) and not args.force:
        stats['done'] += 1
        continue
    im = Image.open(f)
    if max(im.size) > args.max or min(im.size) < args.min:
        stats['size'] += 1
        continue
    k = kind(im)
    stats[k] += 1
    if k == 'colour':
        todo.append(f)
print(f'{len(todo)} colour textures to upscale x{args.scale} (skipped: {stats["normal"]} normal maps, {stats["mask"]} masks, '
      f'{stats["size"]} by size, {stats["done"]} already in {args.dst})')

esr = find_esrgan()
if esr:
    print('Real-ESRGAN:', esr, args.model)
    with tempfile.TemporaryDirectory() as tin, tempfile.TemporaryDirectory() as tout:
        for f in todo:
            shutil.copy(f, tin)
        cmd = [esr, '-i', tin, '-o', tout, '-n', args.model, '-s', '4' if 'x4' in args.model else str(args.scale), '-f', 'png']
        print(' '.join(cmd))
        subprocess.run(cmd, check=True)
        for f in todo:
            name = os.path.basename(f)
            src = Image.open(f)
            up = Image.open(os.path.join(tout, name)).convert('RGBA')
            want = (src.width * args.scale, src.height * args.scale)
            if up.size != want:
                up = up.resize(want, Image.LANCZOS)
            if src.mode in ('RGBA', 'LA'):  # the model's alpha can smear: the original's, scaled smoothly
                up.putalpha(src.convert('RGBA').getchannel('A').resize(want, Image.BICUBIC))
            up.save(os.path.join(args.dst, name))
else:
    print('no Real-ESRGAN found: Lanczos + unsharp mask')
    for i, f in enumerate(todo):
        im = Image.open(f).convert('RGBA')
        up = im.resize((im.width * args.scale, im.height * args.scale), Image.LANCZOS)
        up = up.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
        up.save(os.path.join(args.dst, os.path.basename(f)))
        if i % 100 == 0:
            print(f'  {i}/{len(todo)}', flush=True)
print('done:', len(todo), 'textures in', args.dst)
