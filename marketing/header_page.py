"""App Store product page HEADER: one 3840x1646 PNG (21:9), the same for
every store locale.

A title, like the app's own (login and loading screens): 点点 in the pixel
font and the title colour, "Dian Dian" under it in the smaller subtitle
style, same proportions (36 : 14), on the app's dotted background. Sober;
the decoration around it is a choice (DECO):
  none     — the title alone;
  confetti — a few pastel dots scattered around, like those around the cat
             on the app icon;
  week     — one row of mood dots under the title, the last one still
             empty: one dot a day.

The title sits inside Apple's art safe area (the central 1646x661 px), so
no device crops it; the decoration may fall outside it, where losing a dot
does no harm. On an iPhone the product page shows the full height and about
the central 82 % of the width.

Run (needs Pillow):
    python3 marketing/header_page.py "/path/to/output/dir" [none|confetti|week]
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import BG, TITLE, SUBTITLE, EMPTY, DOT_BORDER, PALETTES, FONT_CJK, FONT_PIXEL_R, dotted_background, seeded  # noqa: E402

W, H = 3840, 1646
SAFE_W, SAFE_H = 1646, 661        # Apple's art safe area, centred
DECO = 'week'


def title_block(size=470):
    """Fonts and geometry of the two-line title for a 点点 of `size` px."""
    f_cjk = ImageFont.truetype(FONT_CJK, size)
    f_lat = ImageFont.truetype(FONT_PIXEL_R, int(size * 14 / 36))
    cjk, lat = f_cjk.getbbox('点点'), f_lat.getbbox('Dian Dian')
    gap = int(size * 0.16)
    cw, ch = cjk[2] - cjk[0], cjk[3] - cjk[1]
    lw, lh = lat[2] - lat[0], lat[3] - lat[1]
    return f_cjk, f_lat, cjk, lat, gap, cw, ch, lw, lh


def render(out, deco=DECO):
    img = Image.new('RGBA', (W, H), BG)
    dotted_background(img, step=118, radius=7, scale=0.9)
    d = ImageDraw.Draw(img)

    f_cjk, f_lat, cjk, lat, gap, cw, ch, lw, lh = title_block()
    block_h = ch + gap + lh
    assert max(cw, lw) <= SAFE_W and block_h <= SAFE_H, (cw, block_h)
    top = (H - block_h) / 2
    if deco == 'week':
        top -= 70                 # leave room for the row of dots under it
    d.text((W / 2 - cw / 2 - cjk[0], top - cjk[1]), '点点', font=f_cjk, fill=TITLE)
    d.text((W / 2 - lw / 2 - lat[0], top + ch + gap - lat[1]), 'Dian Dian', font=f_lat, fill=SUBTITLE)
    half = max(cw, lw) / 2
    x0, x1, y0, y1 = W / 2 - half, W / 2 + half, top, top + block_h

    if deco == 'confetti':
        # pastel dots on a loose ring around the title, a little jitter
        import math
        rng = seeded(4)
        pal = PALETTES['YEAR']
        cx, cy = W / 2, (y0 + y1) / 2
        rx, ry = (x1 - x0) / 2 + 300, (y1 - y0) / 2 + 230
        n = 14
        for i in range(n):
            a = 2 * math.pi * (i + 0.5) / n + rng.uniform(-0.12, 0.12)
            k = rng.uniform(1.0, 1.12)
            px, py = cx + rx * k * math.cos(a), cy + ry * k * math.sin(a)
            r = rng.choice([16, 20, 24, 28])
            d.ellipse([px - r, py - r, px + r, py + r], fill=pal[i % len(pal)])
    elif deco == 'week':
        # seven days of mood under the title, today still to fill
        pal = PALETTES['MOOD']
        colors = [pal[3], pal[2], pal[1], pal[1], pal[4], pal[2], None]
        r, step = 30, 96
        y = y1 + 120
        sx = W / 2 - step * 3
        for i, c in enumerate(colors):
            x = sx + i * step
            if c:
                d.ellipse([x - r, y - r, x + r, y + r], fill=c)
            else:
                d.ellipse([x - r, y - r, x + r, y + r], fill=EMPTY, outline=DOT_BORDER, width=4)

    img = img.convert('RGB')
    img.save(out, 'PNG', optimize=True)
    print(out, img.size, deco)
    return img


if __name__ == '__main__':
    out_dir = sys.argv[1]
    deco = sys.argv[2] if len(sys.argv) > 2 else DECO
    os.makedirs(out_dir, exist_ok=True)
    render(f'{out_dir}/header-3840x1646.png', deco)
