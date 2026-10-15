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
DOT_BORDER, ACCENT, INPUT_BORDER = '#D9D3BF', '#8A8AC0', '#C9C3AE'

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


MONTHS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']


class Filler:
    """Picks a colour per day so a demo grid reads like real usage instead
    of confetti. Modes:
      runs     — a colour holds for a few days, then moves to a neighbour in
                 the palette (mood, sleep, reading: gradual changes);
      weekly   — only some weekdays are filled, each with its own colour
                 (exercise: a routine with rest days);
      dominant — one main colour most days, a second one sometimes, a few
                 misses (habits).
    """

    def __init__(self, mode, palette, rng, year=2026):
        import datetime
        self.mode, self.palette, self.rng, self.year = mode, palette, rng, year
        self._date = datetime.date
        self._idx = rng.randrange(len(palette))
        self._left = 0
        n = len(palette)
        # weekly: pick 3–4 training weekdays, each with a sport colour
        days = sorted(rng.sample(range(7), 4))
        self._weekly = {d: palette[(i * 2) % n] for i, d in enumerate(days)}
        self._main, self._second = palette[0], palette[min(1, n - 1)]

    def color(self, month, day):
        rng, pal = self.rng, self.palette
        if self.mode == 'weekly':
            wd = self._date(self.year, month + 1, day + 1).weekday()
            if wd not in self._weekly or rng.random() < 0.12:
                return None
            return self._weekly[wd] if rng.random() > 0.15 else rng.choice(pal)
        if self.mode == 'dominant':
            # Every legend colour shows up: main most days, second sometimes,
            # the rest now and then, and a few misses.
            r = rng.random()
            if r < 0.10:
                return None
            if r < 0.66:
                return self._main
            if r < 0.84:
                return self._second
            return rng.choice(pal[2:]) if len(pal) > 2 else self._main
        # runs
        if self._left <= 0:
            step = rng.choice([-1, -1, 0, 1, 1, 2, -2])
            self._idx = max(0, min(len(pal) - 1, self._idx + step))
            self._left = rng.randint(2, 6)
        self._left -= 1
        return None if rng.random() < 0.05 else pal[self._idx]


def card_metrics(h, s=1.0, title=True, legend=True):
    """Geometry of a tracker card of height `h`: everything derives from the
    square cell size so the dot spacing is identical in x and y, like the
    app's grid (13 columns: day labels + 12 months; 32 rows: month labels +
    31 days). Returns a dict with the card width and inner positions."""
    pad = int(36 * s)          # card padding around the screen
    inner = int(16 * s)        # screen padding around the grid
    header = int(44 * s) + (int(48 * s) + int(22 * s) if title else 0) + (int(26 * s) + int(30 * s) if legend else 0)
    screen_h = h - header - pad
    cell = (screen_h - 2 * inner) / 32
    label_font = ImageFont.truetype(FONT_PIXEL, max(8, int(cell * 0.58)))
    lab_w = max(cell, label_font.getbbox('30')[2] + int(8 * s))
    grid_w = lab_w + 12 * cell
    screen_w = grid_w + 2 * inner
    w = int(screen_w + 2 * pad)
    return dict(w=w, pad=pad, inner=inner, header=header, cell=cell, lab_w=lab_w, label_font=label_font)


def draw_card(img, x, y, h, title, palette, rng, s=1.0, fill_until=(9, 14), legend=True, mode='runs'):
    """A tracker card like the app's: title, legend dots, then the grid with
    month letters on top and day numbers on the left, square cells.
    Width follows from the height (see card_metrics); returns it."""
    m = card_metrics(h, s, title=bool(title), legend=legend)
    w, pad, inner, cell, lab_w = m['w'], m['pad'], m['inner'], m['cell'], m['lab_w']
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x, y, x + w, y + h], radius=int(30 * s), fill=CARD, outline=CARD_BORDER, width=max(2, int(4 * s)))
    top = y + int(44 * s)
    if title:
        f = font_for(title, int(48 * s))
        top += text_centered(d, x + w / 2, top, title, f, TEXT) + int(22 * s)
    if legend:
        ld = int(26 * s); gap = int(16 * s)
        total = len(palette) * ld + (len(palette) - 1) * gap
        lx = x + (w - total) / 2
        for col in palette:
            d.ellipse([lx, top, lx + ld, top + ld], fill=col); lx += ld + gap
        top += ld + int(30 * s)
    sx, sy = x + pad, top
    sw, sh = w - 2 * pad, y + h - pad - top
    draw_screen(img, sx, sy, sw, sh, inner, cell, lab_w, m['label_font'], palette, rng, fill_until, mode, s)
    return w


def draw_screen(img, sx, sy, sw, sh, inner, cell, lab_w, label_font, palette, rng, fill_until, mode, s=1.0):
    """The rounded "screen" holding the grid. Returns (filled_days, streak)."""
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=int(20 * s), fill=SCREEN, outline=SCREEN_BORDER, width=max(2, int(3 * s)))
    return draw_grid(img, sx + inner, sy + inner, cell, lab_w, label_font, palette, rng, fill_until, mode)


def draw_grid(img, gx, gy, cell, lab_w, lf, palette, rng, fill_until=(9, 14), mode='runs'):
    """Month letters on top, day numbers on the left, square cells.
    Returns (filled_days, current_streak) for the stats sidebar."""
    d = ImageDraw.Draw(img)
    for mi, letter in enumerate(MONTHS):
        cx = gx + lab_w + mi * cell + cell / 2
        text_centered(d, cx, gy + (cell - lf.getbbox('J')[3]) / 2, letter, lf, MUTED)
    for day in range(31):
        cy = gy + (day + 1) * cell + cell / 2
        box = lf.getbbox(str(day + 1))
        text_centered(d, gx + lab_w / 2, cy - (box[3] - box[1]) / 2, str(day + 1), lf, MUTED)
    rad = cell * 0.40
    fm, fd = fill_until
    filler = Filler(mode, palette, rng)
    filled_days, streak, run = 0, 0, 0
    for mi in range(12):
        for day in range(DAYS[mi]):
            cx = gx + lab_w + mi * cell + cell / 2
            cy = gy + (day + 1) * cell + cell / 2
            in_range = mi < fm or (mi == fm and day < fd)
            color = filler.color(mi, day) if in_range else None
            if color:
                filled_days += 1
                run += 1
            elif in_range:
                run = 0
            if color:
                d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=color)
            else:
                d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=EMPTY, outline=DOT_BORDER, width=1)
    streak = run
    return filled_days, streak


def tracker_screen_metrics(h, s=1.0, sidebar_w=150):
    """Geometry of the app's tracker screen: one dashed "book" frame holding
    the sidebar and the grid on the same background; grid cell derived from
    the height (square cells)."""
    shell = int(8 * s)          # outer shell padding (solid border → dashed frame)
    pad = int(18 * s)           # inside the dashed frame
    inner = int(14 * s)
    screen_h = h - 2 * shell - 2 * pad
    cell = (screen_h - 2 * inner) / 32
    label_font = ImageFont.truetype(FONT_PIXEL, max(8, int(cell * 0.58)))
    lab_w = max(cell, label_font.getbbox('30')[2] + int(8 * s))
    grid_w = lab_w + 12 * cell
    sb = int(sidebar_w * s)
    w = int(2 * shell + 2 * pad + sb + int(14 * s) + grid_w + 2 * inner)
    return dict(w=w, shell=shell, pad=pad, inner=inner, cell=cell, lab_w=lab_w, label_font=label_font, sidebar_w=sb, grid_w=grid_w)


def dashed_rounded_rect(d, box, radius, dash, gap, color, width=1):
    """Dashed rounded rectangle (PIL has no dash support): dashes along the
    four edges, and short arcs around the corners."""
    import math
    x0, y0, x1, y1 = box
    r = radius
    def hline(y, xa, xb):
        x = xa
        while x < xb:
            d.line([x, y, min(x + dash, xb), y], fill=color, width=width); x += dash + gap
    def vline(x, ya, yb):
        y = ya
        while y < yb:
            d.line([x, y, x, min(y + dash, yb)], fill=color, width=width); y += dash + gap
    hline(y0, x0 + r, x1 - r); hline(y1, x0 + r, x1 - r)
    vline(x0, y0 + r, y1 - r); vline(x1, y0 + r, y1 - r)
    step = math.degrees((dash + gap) / max(r, 1)); ds = math.degrees(dash / max(r, 1))
    for (cx, cy, a0) in [(x0 + r, y0 + r, 180), (x1 - r, y0 + r, 270), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90)]:
        a = a0
        while a < a0 + 90:
            d.arc([cx - r, cy - r, cx + r, cy + r], a, min(a + ds, a0 + 90), fill=color, width=width); a += step


def draw_tracker_screen(img, x, y, h, palette, labels, rng, s=1.0, fill_until=(9, 14), mode='runs',
                        year=2026, words=None, sidebar_w=150):
    """The app's tracker screen as one card, like the real thing: a solid
    shell, a dashed frame, one background for the sidebar and the grid, a
    dashed divider. Sidebar: "< year >", legend with labels,
    stats at the bottom. Returns the card width."""
    words = words or {'legend': 'LEGEND', 'stats': 'STATS', 'days': 'days', 'streak': 'streak', 'year': 'year'}
    m = tracker_screen_metrics(h, s, sidebar_w)
    w, shell, pad, inner, cell, lab_w, sb = m['w'], m['shell'], m['pad'], m['inner'], m['cell'], m['lab_w'], m['sidebar_w']
    d = ImageDraw.Draw(img)
    # shell + dashed frame, one background for everything inside
    d.rounded_rectangle([x, y, x + w, y + h], radius=int(14 * s), fill=CARD, outline=CARD_BORDER, width=max(1, int(2 * s)))
    fx0, fy0, fx1, fy1 = x + shell, y + shell, x + w - shell, y + h - shell
    d.rounded_rectangle([fx0, fy0, fx1, fy1], radius=int(10 * s), fill=SCREEN)
    dashed_rounded_rect(d, (fx0, fy0, fx1, fy1), int(10 * s), int(5 * s), int(3 * s), CARD_BORDER, max(1, int(1.5 * s)))
    # vertical dashed divider
    dx = fx0 + pad + sb + int(7 * s)
    yy = fy0
    while yy < fy1:
        d.line([dx, yy, dx, min(yy + int(4 * s), fy1)], fill=CARD_BORDER, width=max(1, int(1.5 * s))); yy += int(7 * s)
    # grid
    gx = dx + int(7 * s) + inner
    gy = fy0 + pad + inner
    filled, streak = draw_grid(img, gx, gy, cell, lab_w, m['label_font'], palette, rng, fill_until, mode)
    # sidebar
    cx = fx0 + pad + sb / 2
    ty = fy0 + pad + int(10 * s)
    yf = ImageFont.truetype(FONT_CJK, int(17 * s))
    ty += text_centered(d, cx, ty, f'<  {year}  >', yf, SUBTITLE) + int(14 * s)
    ty += section_header(d, cx, ty, words['legend'], sb, s)
    lf = font_for(''.join(labels), int(14 * s), pixel_bold=False)
    if all(ord(ch) < 0x2E80 for ch in ''.join(labels)):
        lf = ImageFont.truetype(FONT_CJK, int(14 * s))   # the app uses the dot font for labels
    dot = int(16 * s)
    lx = fx0 + pad + int(6 * s)
    for col, lab in zip(palette, labels):
        d.ellipse([lx, ty + int(2 * s), lx + dot, ty + int(2 * s) + dot], fill=col)
        box = lf.getbbox(lab)
        d.text((lx + dot + int(8 * s) - box[0], ty + (dot - (box[3] - box[1])) / 2 + int(2 * s) - box[1]), lab, font=lf, fill=TEXT)
        ty += dot + int(14 * s)
    # stats at the bottom
    pct = round(100 * filled / 365)
    stats = [(str(filled), words['days']), (str(streak), words['streak']), (f'{pct}%', words['year'])]
    vf = ImageFont.truetype(FONT_PIXEL, int(20 * s))
    sf = ImageFont.truetype(FONT_CJK, int(13 * s)) if all(ord(ch) < 0x2E80 for ch in ''.join(wd for _, wd in stats)) else font_for(''.join(wd for _, wd in stats), int(13 * s), pixel_bold=False)
    block = len(stats) * ((vf.getbbox('0')[3] - vf.getbbox('0')[1]) + int(4 * s) + (sf.getbbox('x')[3] - sf.getbbox('x')[1]) + int(12 * s))
    by = fy1 - pad - block - int(26 * s)
    by += section_header(d, cx, by, words['stats'], sb, s)
    for val, lab in stats:
        by += text_centered(d, cx, by, val, vf, TITLE) + int(4 * s)
        by += text_centered(d, cx, by, lab, sf, MUTED) + int(12 * s)
    return w


def section_header(d, cx, y, text, width, s=1.0):
    """Small muted caption with a short dashed line under it (app style)."""
    f = font_for(text, int(13 * s))
    h = text_centered(d, cx, y, text, f, MUTED)
    ly = y + h + int(6 * s)
    half = width * 0.22
    xx = cx - half
    while xx < cx + half:
        d.line([xx, ly, min(xx + int(3 * s), cx + half), ly], fill=SCREEN_BORDER, width=1)
        xx += int(5 * s)
    return h + int(16 * s)


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
