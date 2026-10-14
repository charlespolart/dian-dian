"""App Store "universal creative asset": one 16:9 PNG, 5244x2950, per store
locale, used for BOTH the product page header and the search results
placement (App Store Connect Help, "Creative assets specifications" and
"Manage your App Store assets": "If you upload a universal creative asset,
you can use it for both your product page header and search results
placement.").

Apple crops it per placement — 21:9 for the header (about 350 px off the top
and bottom) and 3:2 for search results (about 410 px off each side) — so the
composition stays inside the central 4425x2247 safe area, and a crop preview
of each placement is written next to every asset for checking.

Run (needs Pillow):
    python3 flutter_app/docs/store/header.py "/path/to/output/dir"
"""
import random, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = '/Users/charlespolart/Documents/Coding/dian-dian/flutter_app/assets'
OUT = sys.argv[1]
FONT_PIXEL = f'{ROOT}/fonts/Silkscreen-Bold.ttf'
FONT_PIXEL_R = f'{ROOT}/fonts/Silkscreen-Regular.ttf'
FONT_CJK = f'{ROOT}/fonts/DotGothic16-Regular.ttf'
ICON = f'{ROOT}/images/icon.png'

BG, DOT_BG = '#F4EFD0', '#D4D4E2'
CARD, CARD_BORDER, SCREEN, SCREEN_BORDER = '#FBF8EA', '#D8D1B5', '#FFFDF5', '#E3DCC3'
TITLE, MUTED, EMPTY = '#7E7EB8', '#9A957F', '#E6E2D2'
PALETTES = {
    'MOOD':     ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7'],
    'READING':  ['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'],
    'SLEEP':    ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'],
    'EXERCISE': ['#51CF66', '#339AF0', '#FF922B', '#CC5DE8', '#20C997'],
}
DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
TAGLINES = {
    'en': ('ONE DOT A DAY', FONT_PIXEL_R),
    'fr': ('UN POINT PAR JOUR', FONT_PIXEL_R),
    'zh-Hans': ('一天一个点', FONT_CJK),
    'zh-Hant': ('一天一點', FONT_CJK),
}

def draw_card(img, x, y, w, h, title, palette, rng, s):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x, y, x + w, y + h], radius=int(30 * s), fill=CARD, outline=CARD_BORDER, width=max(2, int(4 * s)))
    f = ImageFont.truetype(FONT_PIXEL, int(50 * s))
    tw = d.textlength(title, font=f)
    d.text((x + (w - tw) / 2, y + int(72 * s)), title, font=f, fill='#5C5C80')
    ld = int(28 * s); gap = int(16 * s)
    total = len(palette) * ld + (len(palette) - 1) * gap
    lx = x + (w - total) / 2; ly = y + int(160 * s)
    for c in palette:
        d.ellipse([lx, ly, lx + ld, ly + ld], fill=c); lx += ld + gap
    pad = int(42 * s)
    sx, sy = x + pad, y + int(230 * s)
    sw, sh = w - 2 * pad, h - int(230 * s) - pad
    d.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=int(20 * s), fill=SCREEN, outline=SCREEN_BORDER, width=max(2, int(3 * s)))
    cols, rows = 12, 31
    inner = int(24 * s)
    stepx = (sw - 2 * inner) / cols; stepy = (sh - 2 * inner) / rows
    rad = min(stepx, stepy) * 0.40
    for m in range(cols):
        for day in range(rows):
            if day >= DAYS[m]:
                continue
            cx = sx + inner + stepx * m + stepx / 2
            cy = sy + inner + stepy * day + stepy / 2
            filled = m < 9 or (m == 9 and day < 14)
            color = rng.choice(palette) if (filled and rng.random() > 0.08) else EMPTY
            d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=color)

def render(W, H, lang, out):
    s = W / 5244
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    step = int(118 * s); r = max(3, int(7 * s))
    for yy in range(step, H, step):
        for xx in range(step, W, step):
            d.ellipse([xx - r, yy - r, xx + r, yy + r], fill=DOT_BG)

    # Safe area: what survives both crops (21:9 header, 3:2 search results),
    # plus a little breathing room.
    safe_x0 = int((W - H * 3 / 2) / 2) + int(90 * s)
    safe_x1 = W - safe_x0
    safe_y0 = int((H - W * 9 / 21) / 2) + int(90 * s)
    safe_y1 = H - safe_y0

    # cards on the right, filling the safe height
    rng = random.Random(7)
    ch = safe_y1 - safe_y0
    cw = int(ch * 0.29)
    gap = int(70 * s)
    names = list(PALETTES)[:3]
    total = len(names) * cw + (len(names) - 1) * gap
    cx0 = safe_x1 - total
    for i, name in enumerate(names):
        draw_card(img, cx0 + i * (cw + gap), safe_y0, cw, ch, name, PALETTES[name], rng, s)

    # brand lockup on the left: a centred stack — cat icon on its own line,
    # 点点, DIAN DIAN, tagline — every element centred on the same vertical
    # axis, the stack centred in the free space left of the cards.
    k = 0.92
    f_cjk = ImageFont.truetype(FONT_CJK, int(640 * s * k))
    f_lat = ImageFont.truetype(FONT_PIXEL, int(170 * s * k))
    tag_text, tag_font = TAGLINES[lang]
    f_tag = ImageFont.truetype(tag_font, int((110 if tag_font == FONT_CJK else 90) * s * k))
    cjk_box = f_cjk.getbbox('点点')
    cjk_w, cjk_h = cjk_box[2] - cjk_box[0], cjk_box[3] - cjk_box[1]
    lat_box = f_lat.getbbox('DIAN DIAN')
    lat_w, lat_h = lat_box[2] - lat_box[0], lat_box[3] - lat_box[1]
    tag_box = f_tag.getbbox(tag_text)
    tag_w, tag_h = tag_box[2] - tag_box[0], tag_box[3] - tag_box[1]
    icon_size = int(400 * s * k)
    g1, g2, g3 = int(110 * s * k), int(110 * s * k), int(70 * s * k)
    block_h = icon_size + g1 + cjk_h + g2 + lat_h + g3 + tag_h
    area_left, area_right = safe_x0, cx0 - int(160 * s)
    axis = (area_left + area_right) // 2
    y = (H - block_h) // 2

    icon = Image.open(ICON).convert('RGBA').resize((icon_size, icon_size), Image.LANCZOS)
    mask = Image.new('L', (icon_size, icon_size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, icon_size, icon_size], radius=int(icon_size * 0.24), fill=255)
    ix = axis - icon_size // 2
    bw = max(2, int(10 * s))
    d.rounded_rectangle([ix - bw, y - bw, ix + icon_size + bw, y + icon_size + bw], radius=int(icon_size * 0.26), fill='#FFFFFF', outline=CARD_BORDER, width=max(2, int(4 * s)))
    img.paste(icon, (ix, y), mask)
    y += icon_size + g1
    d.text((axis - cjk_w // 2 - cjk_box[0], y - cjk_box[1]), '点点', font=f_cjk, fill=TITLE)
    y += cjk_h + g2
    d.text((axis - lat_w // 2 - lat_box[0], y - lat_box[1]), 'DIAN DIAN', font=f_lat, fill=TITLE)
    y += lat_h + g3
    d.text((axis - tag_w // 2 - tag_box[0], y - tag_box[1]), tag_text, font=f_tag, fill=MUTED)

    img.save(out, 'PNG', optimize=True)
    # Previews of what each placement shows (Apple crops the universal asset).
    base = out.replace('.png', '')
    img.resize((W // 4, H // 4), Image.LANCZOS).save(f'{base}-preview.png', 'PNG')
    hh = int(W * 9 / 21); y0 = (H - hh) // 2
    img.crop((0, y0, W, y0 + hh)).resize((W // 4, hh // 4), Image.LANCZOS).save(f'{base}-preview-header-21x9.png', 'PNG')
    ww = int(H * 3 / 2); x0 = (W - ww) // 2
    img.crop((x0, 0, x0 + ww, H)).resize((ww // 4, H // 4), Image.LANCZOS).save(f'{base}-preview-search-3x2.png', 'PNG')
    print(out, img.size)

for lang in TAGLINES:
    render(5244, 2950, lang, f'{OUT}/universal-{lang}-5244x2950.png')
