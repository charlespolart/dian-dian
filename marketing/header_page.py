"""App Store product page HEADER: one 3840x1646 PNG (Apple's header size),
distinct from the universal 16:9 asset of header.py, which stays on the
search results placement.

Why a dedicated one: on an iPhone the product page shows only the centre of
the asset, zoomed (measured on the universal one: about half its width and
60 % of its height), so a brand block laid out off-centre gets cut. Here the
lockup — cat icon, 点点, DIAN DIAN — is one horizontal group centred in a
zone of 1480x980 px (38 % × 60 %), and everything outside that zone is
texture that crops gracefully: the app's dotted background and two faint
year grids, one per side.

Run (needs Pillow):
    python3 marketing/header_page.py "/path/to/output/dir"
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import BG, FONT_CJK, FONT_PIXEL, PALETTES, DAYS, TITLE, dotted_background, paste_icon, seeded  # noqa: E402

W, H = 3840, 1646
SAFE_W, SAFE_H = 1480, 980


def faint_grid(img, cx, cy, palette, rng, step=44, radius=15, alpha=70):
    """A 12 × 31 year grid of coloured dots, washed out, centred on (cx, cy)."""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0 = cx - 11 * step / 2
    y0 = cy - 30 * step / 2
    for m in range(12):
        for day in range(31):
            if day >= DAYS[m]:
                continue
            filled = m < 9 or (m == 9 and day < 14)
            if not filled or rng.random() < 0.08:
                continue
            c = Image.new('RGB', (1, 1), rng.choice(palette)).getpixel((0, 0))
            x = x0 + m * step
            y = y0 + day * step
            d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=c + (alpha,))
    img.alpha_composite(layer)


def render(out):
    img = Image.new('RGBA', (W, H), BG)
    dotted_background(img, step=118, radius=7, scale=0.9)

    # Texture: two faint year grids, far from the centre, cut by any crop
    # without harm.
    rng = seeded(7)
    faint_grid(img, W * 0.17, H / 2, PALETTES['MOOD'], rng)
    faint_grid(img, W * 0.83, H / 2, PALETTES['READING'], rng)

    # The lockup: icon on the left, 点点 over DIAN DIAN on the right, the
    # group centred in the safe zone.
    d = ImageDraw.Draw(img)
    icon = 410
    f_cjk = ImageFont.truetype(FONT_CJK, 240)
    f_lat = ImageFont.truetype(FONT_PIXEL, 92)
    cjk = f_cjk.getbbox('点点')
    lat = f_lat.getbbox('DIAN DIAN')
    cjk_w, cjk_h = cjk[2] - cjk[0], cjk[3] - cjk[1]
    lat_w, lat_h = lat[2] - lat[0], lat[3] - lat[1]
    gap_icon, gap_lines = 80, 40
    text_w = max(cjk_w, lat_w)
    group_w = icon + gap_icon + text_w
    text_h = cjk_h + gap_lines + lat_h
    assert group_w <= SAFE_W and icon <= SAFE_H, (group_w, icon)
    gx = (W - group_w) // 2
    paste_icon(img, gx, (H - icon) // 2, icon, s=1.0)
    tx = gx + icon + gap_icon
    ty = (H - text_h) // 2
    d.text((tx - cjk[0], ty - cjk[1]), '点点', font=f_cjk, fill=TITLE)
    d.text((tx - lat[0], ty + cjk_h + gap_lines - lat[1]), 'DIAN DIAN', font=f_lat, fill=TITLE)

    img.convert('RGB').save(out, 'PNG', optimize=True)
    print(out, img.size)
    return img


if __name__ == '__main__':
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    img = render(f'{out_dir}/header-3840x1646.png')
    # Previews of what an iPhone may show: the full-height 1.5:1 crop, and
    # the zoomed crop measured on the universal asset (38 % × 60 %).
    for name, (cw, ch) in {'crop-height-fit': (int(H * 1.5), H), 'crop-zoomed': (SAFE_W, SAFE_H)}.items():
        box = ((W - cw) // 2, (H - ch) // 2, (W + cw) // 2, (H + ch) // 2)
        img.crop(box).convert('RGB').resize((cw // 2, ch // 2), Image.LANCZOS).save(f'{out_dir}/{name}.png')
