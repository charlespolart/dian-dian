"""App Store SEARCH RESULTS image: a 3840x2560 PNG (3:2) per store locale.

Three tracker cards side by side — mood, reading, sleep — the same cards as
the app, without the logo: in search results the app icon, name and
subtitle sit right above the image.

Where it shows: the iPhone search result is a 3:2 frame, so it shows the
whole asset (the previous 16:9 universal asset got zoomed and cut there).
Apple's art safe area for this placement is the central 2168x1030 px: the
cards are sized for the iPhone frame, so on a device that crops down to
that area the cards would lose their top and bottom. Check every device in
App Store Connect's preview before publishing.

Run (needs Pillow):
    python3 marketing/search_results.py "/path/to/output/dir"
"""
import os, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import BG, PALETTES, card_metrics, draw_card, dotted_background, seeded  # noqa: E402

W, H = 3840, 2560
TODAY = (10, 23)                  # fill_until: months before index 10, then 23 days of November
CARDS = [('MOOD', 'runs', 3), ('READING', 'runs', 5), ('SLEEP', 'runs', 9)]
TITLES = {
    'en':      {'MOOD': 'MOOD', 'READING': 'READING', 'SLEEP': 'SLEEP'},
    'fr':      {'MOOD': 'HUMEUR', 'READING': 'LECTURE', 'SLEEP': 'SOMMEIL'},
    'zh-Hans': {'MOOD': '心情', 'READING': '阅读', 'SLEEP': '睡眠'},
    'zh-Hant': {'MOOD': '心情', 'READING': '閱讀', 'SLEEP': '睡眠'},
}


def render(lang, out, card_h=2200, s=2.4, gap=110):
    img = Image.new('RGBA', (W, H), BG)
    dotted_background(img, step=118, radius=7, scale=0.9)
    cw = card_metrics(card_h, s)['w']
    total = len(CARDS) * cw + (len(CARDS) - 1) * gap
    x, y = (W - total) // 2, (H - card_h) // 2
    for key, mode, seed in CARDS:
        draw_card(img, x, y, card_h, TITLES[lang][key], PALETTES[key], seeded(seed), s, fill_until=TODAY, mode=mode)
        x += cw + gap
    img = img.convert('RGB')
    img.save(out, 'PNG', optimize=True)
    print(out, img.size, 'cards', cw, 'x', card_h, 'total width', total)
    return img


if __name__ == '__main__':
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for lang in TITLES:
        render(lang, f'{out_dir}/search-{lang}-3840x2560.png')
