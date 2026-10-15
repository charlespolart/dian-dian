"""Pinterest pins for Dian Dian: 1000 × 1500 (2:3, the Pinterest standard),
one per theme and language, plus `pins.csv` with the title, description,
alt text and link of each pin (copy once, paste when publishing or
scheduling).

Run (needs Pillow):
    python3 marketing/pinterest/pins.py "/path/to/output/dir"

Languages: en, fr, zh-Hant (Pinterest is not available in mainland China,
so no simplified Chinese). Pins link to the landing page with a campaign
parameter the landing forwards to the store links (see backend/src/routes/landing.ts).
"""
import csv
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from PIL import Image, ImageDraw  # noqa: E402

import common as c  # noqa: E402

W, H = 1000, 1500
LANDING = 'https://diandian.overridedev.com/'
LANGS = ['en', 'fr', 'zh-Hant']

# One card per theme: the title printed on the card and the pin copy per language.
THEMES = [
    {
        'key': 'mood', 'labels': {"en": ["Amazing", "Great", "Good", "Okay", "Meh"], "fr": ["Génial", "Super", "Bien", "Bof", "Mou"], "zh-Hant": ["超棒", "很好", "不錯", "普通", "低落"]}, 'mode': 'runs', 'palette': c.PALETTES['MOOD'], 'card': 'MOOD', 'seed': 11,
        'title': {'en': 'MOOD TRACKER', 'fr': "SUIVI D'HUMEUR", 'zh-Hant': '心情追蹤'},
        'pin_title': {
            'en': 'Mood tracker: a year in pixels, one dot a day',
            'fr': "Suivi d'humeur : une année en pixels, un point par jour",
            'zh-Hant': '心情追蹤：一年的像素，一天一點',
        },
        'desc': {
            'en': 'Color one dot a day and watch your mood over the whole year. Dian Dian is a free, cozy pixel-art year-in-pixels app: mood tracker, habit tracker, sleep log, with custom colors and legends. iOS & Android.',
            'fr': "Coloriez un point par jour et voyez votre humeur sur toute l'année. Dian Dian est une app gratuite de suivi en pixels (year in pixels), au style pixel-art cozy : humeur, habitudes, sommeil, avec vos couleurs et légendes. iOS et Android.",
            'zh-Hant': '每天塗一個點，看見整年的心情變化。Dian Dian 是免費的像素風年曆記錄 app：心情、習慣、睡眠，自訂顏色與圖例。iOS 與 Android。',
        },
        'keywords': 'year in pixels, mood tracker, mood tracker app, pixel diary, bullet journal, mood journal',
    },
    {
        'key': 'sleep', 'labels': {"en": ["8h+", "7-8h", "6-7h", "5-6h", "<5h"], "fr": ["8 h+", "7-8 h", "6-7 h", "5-6 h", "<5 h"], "zh-Hant": ["8h+", "7-8h", "6-7h", "5-6h", "<5h"]}, 'mode': 'runs', 'palette': c.PALETTES['SLEEP'], 'card': 'SLEEP', 'seed': 12,
        'title': {'en': 'SLEEP TRACKER', 'fr': 'SUIVI DU SOMMEIL', 'zh-Hant': '睡眠追蹤'},
        'pin_title': {
            'en': 'Sleep tracker in pixels: see your whole year at a glance',
            'fr': "Suivi du sommeil en pixels : toute l'année d'un coup d'œil",
            'zh-Hant': '睡眠像素記錄：一眼看完整年',
        },
        'desc': {
            'en': 'One dot per night, from deep blue (8h+) to light blue (short night). A simple sleep log that shows patterns over months. Dian Dian, free year-in-pixels tracker on iOS & Android.',
            'fr': "Un point par nuit, du bleu foncé (8 h et plus) au bleu clair (nuit courte). Un journal de sommeil simple qui révèle vos rythmes sur des mois. Dian Dian, tracker year-in-pixels gratuit, iOS et Android.",
            'zh-Hant': '每晚一個點，從深藍（8 小時以上）到淺藍（短眠）。簡單的睡眠日誌，看見幾個月的節奏。Dian Dian，免費像素年曆 app，iOS 與 Android。',
        },
        'keywords': 'sleep tracker, sleep log, year in pixels, habit tracker, bullet journal sleep tracker',
    },
    {
        'key': 'exercise', 'labels': {"en": ["Running", "Swimming", "Gym", "Yoga", "Cycling"], "fr": ["Course", "Natation", "Muscu", "Yoga", "Vélo"], "zh-Hant": ["跑步", "游泳", "健身", "瑜伽", "騎車"]}, 'mode': 'weekly', 'palette': c.PALETTES['EXERCISE'], 'card': 'EXERCISE', 'seed': 13,
        'title': {'en': 'WORKOUT LOG', 'fr': 'SUIVI SPORTIF', 'zh-Hant': '運動追蹤'},
        'pin_title': {
            'en': 'Workout log in pixels: running, gym, yoga, one color each',
            'fr': "Journal sportif en pixels : course, muscu, yoga, une couleur chacun",
            'zh-Hant': '運動像素日誌：跑步、健身、瑜伽，各一種顏色',
        },
        'desc': {
            'en': 'Give each sport a color and fill one dot per workout. The year grid shows streaks and gaps instantly. Dian Dian, free habit & workout tracker in pixel art, iOS & Android.',
            'fr': "Une couleur par sport, un point par séance. La grille de l'année montre vos séries et vos pauses en un coup d'œil. Dian Dian, tracker d'habitudes et de sport gratuit, style pixel-art, iOS et Android.",
            'zh-Hant': '每種運動一個顏色，每次鍛鍊一個點。年曆格子立刻顯示連續與空檔。Dian Dian，免費像素風習慣與運動追蹤，iOS 與 Android。',
        },
        'keywords': 'workout tracker, fitness tracker, habit tracker, year in pixels, exercise log',
    },
    {
        'key': 'reading', 'labels': {"en": ["1-10 p.", "11-30 p.", "31-60 p.", "60+ p."], "fr": ["1-10 p.", "11-30 p.", "31-60 p.", "60+ p."], "zh-Hant": ["1-10 頁", "11-30 頁", "31-60 頁", "60+ 頁"]}, 'mode': 'runs', 'palette': c.PALETTES['READING'], 'card': 'READING', 'seed': 14,
        'title': {'en': 'READING LOG', 'fr': 'JOURNAL DE LECTURE', 'zh-Hant': '讀書追蹤'},
        'pin_title': {
            'en': 'Reading log in pixels: how many pages did you read today?',
            'fr': "Journal de lecture en pixels : combien de pages aujourd'hui ?",
            'zh-Hant': '讀書像素日誌：今天讀了幾頁？',
        },
        'desc': {
            'en': 'From a few pages to a whole evening: four shades of red, one dot a day. A reading tracker that becomes a poster of your year. Dian Dian, free on iOS & Android.',
            'fr': "De quelques pages à une soirée entière : quatre nuances de rouge, un point par jour. Un suivi de lecture qui devient le poster de votre année. Dian Dian, gratuit, iOS et Android.",
            'zh-Hant': '從幾頁到一整晚：四種紅色深淺，一天一點。把閱讀習慣變成一整年的海報。Dian Dian，iOS 與 Android 免費下載。',
        },
        'keywords': 'reading log, reading tracker, book tracker, year in pixels, bullet journal reading',
    },
    {
        'key': 'habits', 'labels': {"en": ["Done", "Almost", "A bit", "Rest", "Sick"], "fr": ["Fait", "Presque", "Un peu", "Repos", "Malade"], "zh-Hant": ["完成", "幾乎", "一點", "休息", "生病"]}, 'mode': 'dominant', 'palette': c.PALETTES['HABITS'], 'card': 'HABITS', 'seed': 15,
        'title': {'en': 'HABIT TRACKER', 'fr': "SUIVI D'HABITUDES", 'zh-Hant': '習慣追蹤'},
        'pin_title': {
            'en': 'Habit tracker in pixels: build streaks you can see',
            'fr': "Suivi d'habitudes en pixels : des séries que l'on voit",
            'zh-Hant': '習慣像素追蹤：看得見的連續紀錄',
        },
        'desc': {
            'en': 'Water, meditation, no-sugar days, anything daily: one tracker each, one dot a day, and streaks you can actually see. Dian Dian, the cozy year-in-pixels app, free on iOS & Android.',
            'fr': "Eau, méditation, jours sans sucre, tout ce qui se fait chaque jour : un tracker par habitude, un point par jour, et des séries bien visibles. Dian Dian, l'app year-in-pixels cozy, gratuite, iOS et Android.",
            'zh-Hant': '喝水、冥想、無糖日，任何每日習慣：一個習慣一個追蹤器，一天一點，連續紀錄一目了然。Dian Dian，溫馨的像素年曆 app，iOS 與 Android 免費。',
        },
        'keywords': 'habit tracker, habit tracker app, daily habits, streaks, year in pixels, bullet journal habit tracker',
    },
    {
        'key': 'year', 'labels': {"en": ["Work", "Rest", "Friends", "Sport", "Travel", "Study", "Family"], "fr": ["Travail", "Repos", "Amis", "Sport", "Voyage", "Études", "Famille"], "zh-Hant": ["工作", "休息", "朋友", "運動", "旅行", "學習", "家人"]}, 'mode': 'runs', 'palette': c.PALETTES['YEAR'], 'card': None, 'seed': 16,
        'title': {'en': 'YEAR IN PIXELS', 'fr': 'UNE ANNÉE EN PIXELS', 'zh-Hant': '像素年曆'},
        'pin_title': {
            'en': 'Year in pixels app: your whole year on one screen',
            'fr': "App year in pixels : toute votre année sur un écran",
            'zh-Hant': '像素年曆 app：整年濃縮在一個畫面',
        },
        'desc': {
            'en': '365 dots, 12 columns, your colors. Dian Dian is a year-in-pixels app with a pixel-art look: as many trackers as you need, legends, comments on any day, stats and a shareable image of your year. Free on iOS & Android.',
            'fr': "365 points, 12 colonnes, vos couleurs. Dian Dian est une app year-in-pixels au style pixel-art : autant de trackers que nécessaire, légendes, commentaires sur chaque jour, statistiques et image de votre année à partager. Gratuite, iOS et Android.",
            'zh-Hant': '365 個點、12 欄、你的顏色。Dian Dian 是像素風年曆 app：多個追蹤器、圖例、每日備註、統計，還能分享整年的圖片。iOS 與 Android 免費。',
        },
        'keywords': 'year in pixels, year in pixels app, pixel year, mood tracker, bullet journal, 2027 planner',
    },
]

TAGLINE = {'en': 'ONE DOT A DAY', 'fr': 'UN POINT PAR JOUR', 'zh-Hant': '一天一點'}
WORDS = {
    'en': {'legend': 'LEGEND', 'stats': 'STATS', 'days': 'days', 'streak': 'streak', 'year': 'year', 'edit': 'EDIT'},
    'fr': {'legend': 'LÉGENDE', 'stats': 'STATS', 'days': 'jours', 'streak': 'série', 'year': 'année', 'edit': 'ÉDITER'},
    'zh-Hant': {'legend': '圖例', 'stats': '統計', 'days': '天', 'streak': '連續', 'year': '年度', 'edit': '編輯'},
}
FREE = {'en': 'FREE ON IOS & ANDROID', 'fr': 'GRATUIT SUR IOS ET ANDROID', 'zh-Hant': 'iOS / Android 免費下載'}
ALT = {
    'en': 'Dian Dian app: a {what} shown as a year-in-pixels grid, 12 columns for the months, one colored dot per day, pixel-art style.',
    'fr': "App Dian Dian : un {what} affiché en grille year-in-pixels, 12 colonnes pour les mois, un point coloré par jour, style pixel-art.",
    'zh-Hant': 'Dian Dian app：以像素年曆格子呈現的{what}，12 欄代表月份，每天一個彩色點，像素風格。',
}


MAX_TITLE_W = 840  # keep the title clear of the pin's edges and rounded corners


def fitted_font(text, size, max_w, **kw):
    """Largest font ≤ size whose rendering of `text` fits in max_w."""
    while size > 20:
        f = c.font_for(text, size, **kw)
        box = f.getbbox(text)
        if box[2] - box[0] <= max_w:
            return f
        size -= 4
    return c.font_for(text, size, **kw)


def render(theme, lang, out):
    img = Image.new('RGB', (W, H), c.BG)
    c.dotted_background(img, step=92, radius=5)
    d = ImageDraw.Draw(img)
    cx = W / 2
    cjk = lang == 'zh-Hant'

    # Title block: a fixed height whatever the language, so every card has
    # the same size (a taller CJK title must not squash the grid).
    title = theme['title'][lang]
    y = 76
    y += c.text_centered(d, cx, y, title, fitted_font(title, 80 if cjk else 58, MAX_TITLE_W), c.TITLE) + 18
    tag = TAGLINE[lang]
    c.text_centered(d, cx, y, tag, c.font_for(tag, 36 if cjk else 26, pixel_bold=False), c.MUTED)
    card_top = 226

    # Footer: cat icon with the two lines stacked beside it, one row.
    icon = 84
    name_f = c.font_for('点点', 34)
    free = FREE[lang]
    free_f = c.font_for(free, 30 if cjk else 22, pixel_bold=False)
    nb, fb = name_f.getbbox('点点 DIAN DIAN'), free_f.getbbox(free)
    text_w = max(nb[2] - nb[0], fb[2] - fb[0])
    gap = 26
    row_w = icon + gap + text_w
    row_x = cx - row_w / 2
    row_y = H - 58 - icon
    c.paste_icon(img, int(row_x), int(row_y), icon)
    tx = row_x + icon + gap
    lines_h = (nb[3] - nb[1]) + 12 + (fb[3] - fb[1])
    ty = row_y + (icon - lines_h) / 2
    d.text((tx - nb[0], ty - nb[1]), '点点 DIAN DIAN', font=name_f, fill=c.TITLE)
    ty += (nb[3] - nb[1]) + 12
    d.text((tx - fb[0], ty - fb[1]), free, font=free_f, fill=c.MUTED)

    # The app's tracker screen (sidebar + grid) takes all the height left
    # between the title block and the footer.
    card_h = int(row_y - 34 - card_top)
    w = c.tracker_screen_metrics(card_h, 1.0)['w']
    c.draw_tracker_screen(img, int(cx - w / 2), card_top, card_h, theme['palette'], theme['labels'][lang],
                          c.seeded(theme['seed']), s=1.0, fill_until=(9, 14), mode=theme['mode'],
                          year=2026, words=WORDS[lang])

    img.save(out, 'PNG', optimize=True)


def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    rows = []
    for theme in THEMES:
        for lang in LANGS:
            name = f"pin-{theme['key']}-{lang}.png"
            render(theme, lang, os.path.join(out_dir, name))
            what = theme['title'][lang].lower() if lang != 'zh-Hant' else theme['title'][lang]
            rows.append({
                'file': name,
                'lang': lang,
                'title': theme['pin_title'][lang],
                'description': theme['desc'][lang],
                'alt_text': ALT[lang].format(what=what),
                'keywords': theme['keywords'],
                'link': f"{LANDING}?utm_source=pinterest&utm_medium=pin&utm_campaign={theme['key']}-{lang}",
            })
            print(name)
    with open(os.path.join(out_dir, 'pins.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    print(f"{len(rows)} pins, copy in pins.csv")


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), 'out'))
