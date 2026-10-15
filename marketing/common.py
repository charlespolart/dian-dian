"""Shared drawing bits for the marketing generators (App Store header,
Pinterest pins): the app's palette, fonts and the tracker card.

Needs Pillow. Fonts are the app's own (Silkscreen for Latin, DotGothic16 for
CJK); when DotGothic16 lacks a glyph the text falls back to a system CJK
font so nothing renders as a box.
"""
import glob
import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
ASSETS = os.path.join(ROOT, 'flutter_app', 'assets')
FONT_PIXEL = os.path.join(ASSETS, 'fonts', 'Silkscreen-Bold.ttf')
FONT_PIXEL_R = os.path.join(ASSETS, 'fonts', 'Silkscreen-Regular.ttf')
FONT_CJK = os.path.join(ASSETS, 'fonts', 'DotGothic16-Regular.ttf')
ICON = os.path.join(ASSETS, 'images', 'icon.png')

BG, DOT_BG = '#F4EFD0', '#D4D4E2'
CARD, CARD_BORDER, SCREEN, SCREEN_BORDER = '#FBF8EA', '#D8D1B5', '#FFFDF5', '#E3DCC3'
TITLE, SUBTITLE, MUTED, EMPTY, TEXT = '#7E7EB8', '#9C9CC6', '#9A957F', '#E6E2D2', '#5C5C80'

PALETTES = {
    'MOOD':     ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7'],
    'READING':  ['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'],
    'SLEEP':    ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'],
    'EXERCISE': ['#51CF66', '#339AF0', '#FF922B', '#CC5DE8', '#20C997'],
    'HABITS':   ['#20C997', '#63E6BE', '#C3FAE8', '#FFD8A8', '#FFA94D'],
    'PERIOD':   ['#FF6B6B', '#FFA8A8', '#FFD8D8', '#D0BFFF', '#E599F7'],
    'YEAR':     ['#FFEC99', '#8CE99A', '#74C0FC', '#E599F7', '#FFA8A8', '#20C997', '#FFD43B'],
}
DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


# --- fonts ---------------------------------------------------------------

def _renders(font, ch):
    im = Image.new('L', (80, 80), 0)
    ImageDraw.Draw(im).text((8, 8), ch, font=font, fill=255)
    return im.tobytes()


def has_glyphs(path, text):
    f = ImageFont.truetype(path, 40)
    notdef = _renders(f, '￿')
    return all(_renders(f, ch) != notdef for ch in text if not ch.isspace())


def _system_cjk():
    cands = []
    for pattern in ('/System/Library/Fonts/**/*', '/Library/Fonts/*'):
        cands += glob.glob(pattern, recursive=True)
    # Priority: a Traditional-Chinese face first (Heiti TC ships with macOS),
    # then PingFang, then anything else with CJK ideographs.
    for key in ('stheiti medium', 'pingfang', 'hiragino sans gb', 'notosanscjk', 'songti', 'applesdgothic'):
        for p in sorted(cands):
            if key in p.lower():
                try:
                    ImageFont.truetype(p, 20)
                    return p
                except Exception:
                    continue
    return None


def font_for(text, size, pixel_bold=True):
    """A font that can draw every glyph of `text` at `size`.

    Latin → Silkscreen; CJK → DotGothic16 when it has the glyphs, otherwise
    the first system CJK font found (keeps pixel look wherever possible).
    """
    if all(ord(ch) < 0x2E80 for ch in text):
        return ImageFont.truetype(FONT_PIXEL if pixel_bold else FONT_PIXEL_R, size)
    if has_glyphs(FONT_CJK, text):
        return ImageFont.truetype(FONT_CJK, size)
    fallback = _system_cjk()
    if fallback is None:
        raise RuntimeError(f'no font can draw: {text!r}')
    return ImageFont.truetype(fallback, size)


# --- drawing -------------------------------------------------------------

def dotted_background(img, step=118, radius=7, scale=1.0):
    d = ImageDraw.Draw(img)
    W, H = img.size
    st = max(8, int(step * scale)); r = max(2, int(radius * scale))
    for yy in range(st, H, st):
        for xx in range(st, W, st):
            d.ellipse([xx - r, yy - r, xx + r, yy + r], fill=DOT_BG)


def text_centered(d, cx, y, text, font, fill):
    """Draws `text` centred on x=cx with its top at y; returns its height."""
    box = font.getbbox(text)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text((cx - w / 2 - box[0], y - box[1]), text, font=font, fill=fill)
    return h


def draw_card(img, x, y, w, h, title, palette, rng, s=1.0, fill_until=(9, 14), legend=True):
    """A tracker card like the app's: title, legend dots, 12 × 31 dot grid."""
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x, y, x + w, y + h], radius=int(30 * s), fill=CARD, outline=CARD_BORDER, width=max(2, int(4 * s)))
    top = y + int(60 * s)
    if title:
        f = font_for(title, int(50 * s))
        top += text_centered(d, x + w / 2, top, title, f, TEXT) + int(28 * s)
    if legend:
        ld = int(28 * s); gap = int(16 * s)
        total = len(palette) * ld + (len(palette) - 1) * gap
        lx = x + (w - total) / 2
        for c in palette:
            d.ellipse([lx, top, lx + ld, top + ld], fill=c); lx += ld + gap
        top += ld + int(40 * s)
    pad = int(42 * s)
    sx, sy = x + pad, top
    sw, sh = w - 2 * pad, y + h - pad - top
    d.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=int(20 * s), fill=SCREEN, outline=SCREEN_BORDER, width=max(2, int(3 * s)))
    cols, rows = 12, 31
    inner = int(24 * s)
    stepx = (sw - 2 * inner) / cols; stepy = (sh - 2 * inner) / rows
    rad = min(stepx, stepy) * 0.40
    fm, fd = fill_until
    for m in range(cols):
        for day in range(rows):
            if day >= DAYS[m]:
                continue
            cx = sx + inner + stepx * m + stepx / 2
            cy = sy + inner + stepy * day + stepy / 2
            filled = m < fm or (m == fm and day < fd)
            color = rng.choice(palette) if (filled and rng.random() > 0.08) else EMPTY
            d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=color)


def paste_icon(img, x, y, size, s=1.0):
    """The cat icon as a rounded square with a soft white border."""
    d = ImageDraw.Draw(img)
    icon = Image.open(ICON).convert('RGBA').resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=int(size * 0.24), fill=255)
    bw = max(2, int(10 * s))
    d.rounded_rectangle([x - bw, y - bw, x + size + bw, y + size + bw], radius=int(size * 0.26), fill='#FFFFFF', outline=CARD_BORDER, width=max(2, int(4 * s)))
    img.paste(icon, (x, y), mask)


def seeded(seed):
    return random.Random(seed)
