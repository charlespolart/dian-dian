"""The native launch image: the title block of the Flutter loading screen
(_LoadingScreen in lib/main.dart — 点点 at 36 px in the title colour, "Dian
Dian" at 14 px in Silkscreen in the subtitle colour, a 24 px gap and the
20 px spinner's slot left empty), on a transparent background, so that
iOS and Android show it centred on the cream before Flutter draws and the
handover to the loading screen is invisible.

Writes ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png
and android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/launch_image.png.
Run from flutter_app: `python3 tools/launch/render.py` (Pillow; the CJK face
is the macOS system Hiragino Sans GB W3, the closest file on disk to the
PingFang iOS falls back to for 点点, since Silkscreen has no CJK glyphs)."""
import os
from PIL import Image, ImageDraw, ImageFont

CJK = '/System/Library/Fonts/Hiragino Sans GB.ttc'  # index 0: W3
PIXEL = 'assets/fonts/Silkscreen-Regular.ttf'
TITLE, SUB = (0x90, 0x90, 0xB0), (0xB0, 0xA8, 0x90)  # AppColors.title / subtitle, default theme
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


if __name__ == '__main__':
    ios = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for s, name in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
        render(s).save(f'{ios}/{name}')
    for s, folder in ((1, 'mdpi'), (1.5, 'hdpi'), (2, 'xhdpi'), (3, 'xxhdpi'), (4, 'xxxhdpi')):
        d = f'android/app/src/main/res/drawable-{folder}'
        os.makedirs(d, exist_ok=True)
        render(s).save(f'{d}/launch_image.png')
    print('launch images written')
