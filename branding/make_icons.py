"""Builds all platform app icons from branding/app_icon_source.png."""
import json, os, re, sys
from PIL import Image, ImageDraw, ImageOps

root = sys.argv[1]
PAPER = (252, 251, 246)
src = Image.open(os.path.join(root, 'branding/app_icon_source.png')).convert('RGBA')
W, H = src.size
print('source', src.size)

def clear_corners(img, fill):
    """Flood-fills the dark area outside the rounded border from each corner."""
    out = img.copy()
    for xy in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        ImageDraw.floodfill(out, xy, fill, thresh=90)
    return out

opaque = clear_corners(src, PAPER + (255,)).convert('RGB')   # iOS / Android legacy
transparent = clear_corners(src, (0, 0, 0, 0))               # macOS / web / Windows
inset = int(W * 0.045)
inner = opaque.crop((inset, inset, W - inset, H - inset))    # art inside the drawn border

def save(img, path, size):
    full = os.path.join(root, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(full)

def padded(art, canvas, art_size, bg):
    c = Image.new('RGBA', (canvas, canvas), bg)
    a = art.convert('RGBA').resize((art_size, art_size), Image.LANCZOS)
    c.paste(a, ((canvas - art_size) // 2, (canvas - art_size) // 2), a)
    return c

# Android: legacy square icons + adaptive foreground (108dp canvas, art fills
# ~76dp so the 72dp mask shows the drawing, not empty margins).
densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for d, k in densities.items():
    save(opaque, f'android/app/src/main/res/mipmap-{d}/ic_launcher.png', int(48 * k))
    fg = padded(inner, int(108 * k), int(76 * k), (0, 0, 0, 0))
    fg.save(os.path.join(root, f'android/app/src/main/res/mipmap-{d}/ic_launcher_foreground.png'))

# iOS: regenerate every file listed in Contents.json, opaque.
ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.load(open(os.path.join(root, ios_dir, 'Contents.json')))['images']:
    if 'filename' not in entry: continue
    size = float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x'))
    save(opaque, f"{ios_dir}/{entry['filename']}", round(size))

# macOS: transparent corners.
mac_dir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
for name in os.listdir(os.path.join(root, mac_dir)):
    m = re.match(r'app_icon_(\d+)\.png', name)
    if m: save(transparent, f'{mac_dir}/{name}', int(m.group(1)))

# Web.
save(transparent, 'web/favicon.png', 32)
for s in (192, 512):
    save(transparent, f'web/icons/Icon-{s}.png', s)
    padded(inner, s, int(s * 0.82), PAPER + (255,)).save(os.path.join(root, f'web/icons/Icon-maskable-{s}.png'))

# Windows.
transparent.save(os.path.join(root, 'windows/runner/resources/app_icon.ico'),
                 sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

# Preview of how a circular Android launcher mask will look.
prev = Image.new('RGBA', (432, 432), PAPER + (255,))
fg = Image.open(os.path.join(root, 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png'))
prev.alpha_composite(fg)
prev = prev.crop((72, 72, 360, 360))
mask = Image.new('L', prev.size, 0); ImageDraw.Draw(mask).ellipse((0, 0, 287, 287), fill=255)
out = Image.new('RGBA', prev.size, (40, 40, 40, 255)); out.paste(prev, (0, 0), mask)
out.save(sys.argv[2])
print('done')
