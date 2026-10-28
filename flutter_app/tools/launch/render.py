"""The native launch image: the title block of the Flutter loading screen
(_LoadingScreen in lib/main.dart — 点点 at 36 px in the title colour, "Dian
Dian" at 14 px in Silkscreen in the subtitle colour, a 24 px gap and the
20 px spinner's slot left empty), on a transparent background, so that
iOS and Android show it centred on the cream before Flutter draws and the
handover to the loading screen is invisible.

Also the dotted background (DottedBackground: a dot every 24 pt, radius 2,
AppColors.bgDot, the grid centred on the screen with a dot at its centre):
for iOS one square image per scale, far larger than any screen, centred and
cropped by the storyboard, so the grid lands exactly where Flutter draws it;
for Android a 24 dp tile repeated from the window's top-left corner (Android
11 and below only — 12+ shows the system splash), whose phase may differ from
Flutter's by up to half a step.

Writes ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png,
ios/Runner/Assets.xcassets/LaunchDots.imageset/LaunchDots{,@2x,@3x}.png and
android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/launch_{image,dots}.png.
Run from flutter_app: `python3 tools/launch/render.py` (Pillow; the CJK face
is the macOS system Hiragino Sans GB W3, the closest file on disk to the
PingFang iOS falls back to for 点点, since Silkscreen has no CJK glyphs)."""
import os
from PIL import Image, ImageDraw, ImageFont

CJK = '/System/Library/Fonts/Hiragino Sans GB.ttc'  # index 0: W3
PIXEL = 'assets/fonts/Silkscreen-Regular.ttf'
TITLE, SUB = (0x90, 0x90, 0xB0), (0xB0, 0xA8, 0x90)  # AppColors.title / subtitle, default theme
DOT, SPACING, RADIUS = (0xB8, 0xC0, 0xD8), 24, 2   # AppColors.bgDot, _DottedPainter
W, H = 200, 124                 # 36 × 1.43 + 8 + 14 × 1.43 + 24 + 20
Y_TITLE, Y_SUB = 25.75, 69.5    # line centres, as the Column lays them out


def render(scale):
    w, h = round(W * scale), round(H * scale)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    big = ImageFont.truetype(CJK, round(36 * scale), index=0)
    small = ImageFont.truetype(PIXEL, round(14 * scale))
    d.text((w / 2, Y_TITLE * scale), '点点', font=big, fill=TITLE + (255,), anchor='mm')
    d.text((w / 2, Y_SUB * scale), 'Dian Dian', font=small, fill=SUB + (255,), anchor='mm')
    return im


def _dot(scale):
    """One antialiased dot, drawn at 8× and shrunk, on a transparent square."""
    ss = 8
    size = int(2 * (RADIUS + 1) * scale)
    big = Image.new('RGBA', (size * ss, size * ss), (0, 0, 0, 0))
    r = RADIUS * scale * ss
    c = size * ss / 2
    ImageDraw.Draw(big).ellipse((c - r, c - r, c + r, c + r), fill=DOT + (255,))
    return big.resize((size, size), Image.LANCZOS)


def render_dots(side_pt, scale):
    """A side_pt × side_pt square of the grid, a dot at its centre."""
    px = round(side_pt * scale)
    im = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    dot = _dot(scale)
    half = dot.width // 2
    n = int((side_pt / 2) // SPACING)
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x = round(px / 2 + i * SPACING * scale) - half
            y = round(px / 2 + j * SPACING * scale) - half
            im.alpha_composite(dot, (x, y))
    return im


def render_tile(scale):
    """A 24 dp tile with a dot at its centre, for Android's repeat."""
    px = round(SPACING * scale)
    im = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    dot = _dot(scale)
    im.alpha_composite(dot, (round(px / 2) - dot.width // 2, round(px / 2) - dot.width // 2))
    return im


if __name__ == '__main__':
    ios = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for s, name in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
        render(s).save(f'{ios}/{name}')
    for s, folder in ((1, 'mdpi'), (1.5, 'hdpi'), (2, 'xhdpi'), (3, 'xxhdpi'), (4, 'xxxhdpi')):
        d = f'android/app/src/main/res/drawable-{folder}'
        os.makedirs(d, exist_ok=True)
        render(s).save(f'{d}/launch_image.png')
    dots = 'ios/Runner/Assets.xcassets/LaunchDots.imageset'
    os.makedirs(dots, exist_ok=True)
    # 2x covers every iPad (up to 1376 pt a side); 3x phones never exceed 956 pt.
    for s, side, name in ((1, 1392, 'LaunchDots.png'), (2, 1392, 'LaunchDots@2x.png'), (3, 1000, 'LaunchDots@3x.png')):
        render_dots(side, s).save(f'{dots}/{name}', optimize=True)
    for s, folder in ((1, 'mdpi'), (1.5, 'hdpi'), (2, 'xhdpi'), (3, 'xxhdpi'), (4, 'xxxhdpi')):
        render_tile(s).save(f'android/app/src/main/res/drawable-{folder}/launch_dots.png')
    print('launch images written')
