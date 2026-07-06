import { Router, Request } from 'express';

const router = Router();

type Lang = 'en' | 'fr' | 'zh-CN' | 'zh-TW';
const SUPPORTED: Lang[] = ['en', 'fr', 'zh-CN', 'zh-TW'];

function detectLang(req: Request): Lang {
  const q = String(req.query.lang || '');
  if (SUPPORTED.includes(q as Lang)) return q as Lang;
  const accept = req.headers['accept-language'] || '';
  for (const part of accept.split(',')) {
    const tag = part.split(';')[0].trim();
    if (tag.startsWith('zh-Hans') || tag === 'zh-CN') return 'zh-CN';
    if (tag.startsWith('zh-Hant') || tag === 'zh-TW') return 'zh-TW';
    if (tag.startsWith('fr')) return 'fr';
    if (tag.startsWith('en')) return 'en';
  }
  return 'en';
}

const ORIGIN = 'https://diandian.overridedev.com';
const APP_STORE_URL = 'https://apps.apple.com/app/id6761432329';

// App Store screenshots shipped under /shots (see backend/public/shots).
// Each feature row pairs a screenshot with a line of copy.
type Copy = {
  title: string;
  desc: string;
  eyebrow: string;
  h1: string;
  sub: string;
  cta: string;
  note: string;
  rows: { kick: string; h: string; b: string; img: string; alt: string }[];
  themesKick: string;
  themesH: string;
  themesB: string;
  darkAlt: string;
  sakuraAlt: string;
  chips: string[];
  finalH: string;
  heroAlt: string;
  privacy: string;
  terms: string;
  legal: string;
  contact: string;
  made: string;
};

const t: Record<Lang, Copy> = {
  en: {
    title: 'Dian Dian — Year Tracker',
    desc: 'Dian Dian (点点) is a cozy pixel-art year tracker. Color every day of your year to follow habits, mood, sleep, reading — anything. Free on the App Store.',
    eyebrow: 'Year Tracker',
    h1: 'Color every day<br>of your year.',
    sub: 'A cozy pixel-art year tracker. Habits, mood, sleep, reading — whatever you want to follow, one dot at a time.',
    cta: 'Download on the App Store',
    note: 'iPhone & iPad · Android coming soon',
    rows: [
      { kick: 'The grid', h: 'One grid for the whole year', b: 'Twelve months across, thirty-one days down. Pick a color, tap a day, and watch the year quietly fill in.', img: '/shots/5.jpg', alt: 'A full year of sleep logged as a grid of blue dots, 365-day streak' },
      { kick: 'How it works', h: 'Log a day in one tap', b: 'Choose a legend color and jot a quick note. Quick-fill lets you color a whole streak in seconds.', img: '/shots/3.jpg', alt: 'The day editor open on a date, choosing a legend color and adding a comment' },
      { kick: 'Insights', h: 'See your patterns emerge', b: 'Streaks, yearly percentage, distribution, monthly and day-of-week breakdowns — your year at a glance.', img: '/shots/6.jpg', alt: 'Stats screen with distribution bars, monthly progress and day-of-week chart' },
    ],
    themesKick: 'Themes',
    themesH: 'Make it yours',
    themesB: 'Seven themes — Sakura, Ocean, Forest, Sunset and a Midnight dark mode. Custom colors and playful cursors, too.',
    darkAlt: 'Home screen in the Midnight dark theme with four colorful trackers',
    sakuraAlt: 'Home screen in the pink Sakura theme with four colorful trackers',
    chips: ['Real-time sync', 'Multi-year', 'Custom legends', 'Quick-fill', 'Day notes', 'PNG export', 'Stats & streaks', '4 languages'],
    finalH: 'Start coloring your year.',
    heroAlt: 'Dian Dian home screen with Mood, Reading, Exercise and Sleep trackers as colorful dot grids',
    privacy: 'Privacy',
    terms: 'Terms',
    legal: 'Legal Notice',
    contact: 'Contact',
    made: 'Made with care by OVERRIDE — one pixel at a time.',
  },
  fr: {
    title: 'Dian Dian — Tracker annuel',
    desc: 'Dian Dian (点点) est un tracker annuel en pixel art tout doux. Coloriez chaque jour de votre année pour suivre habitudes, humeur, sommeil, lecture — tout. Gratuit sur l’App Store.',
    eyebrow: 'Tracker annuel',
    h1: 'Coloriez chaque jour<br>de votre année.',
    sub: 'Un tracker annuel en pixel art tout doux. Habitudes, humeur, sommeil, lecture — tout ce que vous voulez suivre, un point à la fois.',
    cta: 'Télécharger sur l’App Store',
    note: 'iPhone & iPad · Android bientôt',
    rows: [
      { kick: 'La grille', h: 'Une grille pour toute l’année', b: 'Douze mois en largeur, trente et un jours en hauteur. Choisissez une couleur, touchez un jour, et regardez l’année se remplir.', img: '/shots/5.jpg', alt: 'Une année de sommeil en grille de points bleus, série de 365 jours' },
      { kick: 'Comment ça marche', h: 'Un jour en un tap', b: 'Choisissez une couleur de légende et ajoutez une note. Le remplissage rapide colore toute une série en quelques secondes.', img: '/shots/3.jpg', alt: 'L’éditeur d’une journée ouvert, choix d’une couleur de légende et ajout d’un commentaire' },
      { kick: 'Analyses', h: 'Voyez vos tendances apparaître', b: 'Séries, pourcentage annuel, répartition, progression mensuelle et par jour de la semaine — votre année d’un coup d’œil.', img: '/shots/6.jpg', alt: 'Écran de stats avec barres de répartition, progression mensuelle et jours de la semaine' },
    ],
    themesKick: 'Thèmes',
    themesH: 'Faites-en le vôtre',
    themesB: 'Sept thèmes — Sakura, Ocean, Forest, Sunset et un mode sombre Midnight. Couleurs personnalisées et curseurs rigolos aussi.',
    darkAlt: 'Écran d’accueil en thème sombre Midnight avec quatre trackers colorés',
    sakuraAlt: 'Écran d’accueil en thème rose Sakura avec quatre trackers colorés',
    chips: ['Sync temps réel', 'Multi-années', 'Légendes perso', 'Remplissage rapide', 'Notes du jour', 'Export PNG', 'Stats & séries', '4 langues'],
    finalH: 'Commencez à colorier votre année.',
    heroAlt: 'Écran d’accueil de Dian Dian avec les trackers Humeur, Lecture, Sport et Sommeil en grilles de points colorés',
    privacy: 'Confidentialité',
    terms: 'CGU',
    legal: 'Mentions légales',
    contact: 'Contact',
    made: 'Fait avec soin par OVERRIDE — un pixel à la fois.',
  },
  'zh-CN': {
    title: '点点 — 年度追踪器',
    desc: '点点 (Dian Dian) 是一款温馨的像素风年度追踪器。为一年中的每一天上色，追踪习惯、心情、睡眠、阅读——任何事。App Store 免费下载。',
    eyebrow: '年度追踪器',
    h1: '为一年中的<br>每一天上色。',
    sub: '一款温馨的像素风年度追踪器。习惯、心情、睡眠、阅读——任何你想追踪的，一次一个点。',
    cta: '在 App Store 下载',
    note: 'iPhone & iPad · Android 即将推出',
    rows: [
      { kick: '格子', h: '一整年的格子', b: '横向十二个月，纵向三十一天。选一个颜色，点一天，看着一年被静静填满。', img: '/shots/5.jpg', alt: '一整年的睡眠记录，蓝色点阵网格，365 天连续' },
      { kick: '如何使用', h: '一点即可记录一天', b: '选择图例颜色并写下简短备注。快速填充让你几秒内填满整段连续记录。', img: '/shots/3.jpg', alt: '日期编辑器打开，选择图例颜色并添加备注' },
      { kick: '洞察', h: '发现你的规律', b: '连续天数、年度百分比、分布、每月和每周分析——一眼看清你的一年。', img: '/shots/6.jpg', alt: '统计页面，含分布条、每月进度和每周图表' },
    ],
    themesKick: '主题',
    themesH: '打造专属风格',
    themesB: '七种主题——樱花、海洋、森林、日落，以及午夜深色模式。还有自定义颜色和俏皮的光标。',
    darkAlt: '午夜深色主题的主屏幕，四个多彩追踪器',
    sakuraAlt: '粉色樱花主题的主屏幕，四个多彩追踪器',
    chips: ['实时同步', '跨年度', '自定义图例', '快速填充', '每日备注', 'PNG 导出', '统计与连续', '四种语言'],
    finalH: '开始为你的一年上色。',
    heroAlt: '点点主屏幕，含心情、阅读、运动和睡眠追踪器的多彩点阵',
    privacy: '隐私',
    terms: '条款',
    legal: '法律声明',
    contact: '联系',
    made: '由 OVERRIDE 用心打造——一次一个像素。',
  },
  'zh-TW': {
    title: '點點 — 年度追蹤器',
    desc: '點點 (Dian Dian) 是一款溫馨的像素風年度追蹤器。為一年中的每一天上色，追蹤習慣、心情、睡眠、閱讀——任何事。App Store 免費下載。',
    eyebrow: '年度追蹤器',
    h1: '為一年中的<br>每一天上色。',
    sub: '一款溫馨的像素風年度追蹤器。習慣、心情、睡眠、閱讀——任何你想追蹤的，一次一個點。',
    cta: '在 App Store 下載',
    note: 'iPhone & iPad · Android 即將推出',
    rows: [
      { kick: '格子', h: '一整年的格子', b: '橫向十二個月，縱向三十一天。選一個顏色，點一天，看著一年被靜靜填滿。', img: '/shots/5.jpg', alt: '一整年的睡眠紀錄，藍色點陣網格，365 天連續' },
      { kick: '如何使用', h: '一點即可記錄一天', b: '選擇圖例顏色並寫下簡短備註。快速填充讓你幾秒內填滿整段連續紀錄。', img: '/shots/3.jpg', alt: '日期編輯器開啟，選擇圖例顏色並加入備註' },
      { kick: '洞察', h: '發現你的規律', b: '連續天數、年度百分比、分佈、每月和每週分析——一眼看清你的一年。', img: '/shots/6.jpg', alt: '統計頁面，含分佈條、每月進度和每週圖表' },
    ],
    themesKick: '主題',
    themesH: '打造專屬風格',
    themesB: '七種主題——櫻花、海洋、森林、日落，以及午夜深色模式。還有自訂顏色和俏皮的游標。',
    darkAlt: '午夜深色主題的主畫面，四個多彩追蹤器',
    sakuraAlt: '粉色櫻花主題的主畫面，四個多彩追蹤器',
    chips: ['即時同步', '跨年度', '自訂圖例', '快速填充', '每日備註', 'PNG 匯出', '統計與連續', '四種語言'],
    finalH: '開始為你的一年上色。',
    heroAlt: '點點主畫面，含心情、閱讀、運動和睡眠追蹤器的多彩點陣',
    privacy: '隱私',
    terms: '條款',
    legal: '法律聲明',
    contact: '聯繫',
    made: '由 OVERRIDE 用心打造——一次一個像素。',
  },
};

const CHIP_HUES = ['--p-pink', '--p-orange', '--p-yellow', '--p-green', '--p-blue', '--p-purple'];
const APPLE_GLYPH =
  '<svg viewBox="0 0 384 512" aria-hidden="true"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/></svg>';

function storeButton(c: Copy): string {
  return `<a class="btn-store" href="${APP_STORE_URL}" target="_blank" rel="noopener">${APPLE_GLYPH}<span>${c.cta}</span></a>`;
}

function langSwitch(lang: Lang): string {
  const items: [Lang, string][] = [['en', 'EN'], ['fr', 'FR'], ['zh-CN', '简'], ['zh-TW', '繁']];
  return items
    .map(([code, label]) => `<a class="${code === lang ? 'on' : ''}" href="?lang=${code}" hreflang="${code}">${label}</a>`)
    .join('');
}

function page(lang: Lang): string {
  const c = t[lang];

  const heroDots = CHIP_HUES.concat(['--p-pink', '--p-green'])
    .map((h, i) => `<i style="background:var(${h});animation-delay:${0.5 + i * 0.08}s"></i>`)
    .join('');

  const featureRows = c.rows
    .map(
      (r, i) => `
      <section class="feature ${i % 2 === 1 ? 'rev' : ''} reveal">
        <div class="fig"><div class="phone"><img src="${r.img}" alt="${r.alt}" loading="lazy" width="600" height="1300"></div></div>
        <div class="txt">
          <p class="kick">${r.kick}</p>
          <h2>${r.h}</h2>
          <p>${r.b}</p>
        </div>
      </section>`
    )
    .join('');

  const chips = c.chips
    .map((label, i) => `<span class="chip"><i style="background:var(${CHIP_HUES[i % CHIP_HUES.length]})"></i>${label}</span>`)
    .join('');

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${c.title}</title>
  <meta name="description" content="${c.desc}" />
  <link rel="canonical" href="${ORIGIN}/" />
  <link rel="alternate" hreflang="en" href="${ORIGIN}/?lang=en" />
  <link rel="alternate" hreflang="fr" href="${ORIGIN}/?lang=fr" />
  <link rel="alternate" hreflang="zh-Hans" href="${ORIGIN}/?lang=zh-CN" />
  <link rel="alternate" hreflang="zh-Hant" href="${ORIGIN}/?lang=zh-TW" />
  <link rel="icon" type="image/png" href="/favicon.png" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="${c.title}" />
  <meta property="og:description" content="${c.desc}" />
  <meta property="og:image" content="${ORIGIN}/shots/1.jpg" />
  <meta property="og:url" content="${ORIGIN}/" />
  <meta name="twitter:card" content="summary_large_image" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DotGothic16&family=Silkscreen:wght@400;700&display=swap" rel="stylesheet" />
  <script>document.documentElement.classList.add('js');</script>
  <style>
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    :root{
      --paper:#F5F0D0; --paper2:#FAF5EA; --dot:#C7CDE0;
      --ink:#55536b; --head:#6a6a98; --muted:#8f8aa0; --line:#E2D8C0;
      --title:#403f57;
      --green:#D8E8C8; --green-bd:#8AA378; --green-tx:#33402a;
      --accent:#8080A8; --pad:24px;
      --p-pink:#FF9EB8; --p-orange:#FFBA8A; --p-yellow:#FFD84D;
      --p-green:#7BC47F; --p-blue:#74C0FC; --p-purple:#B197FC;
    }
    html{scroll-behavior:smooth}
    body{
      font-family:'DotGothic16','Silkscreen',monospace; color:var(--ink);
      background-color:var(--paper);
      background-image:radial-gradient(var(--dot) 1.4px, transparent 1.5px);
      background-size:22px 22px; background-position:-11px -11px;
      line-height:1.7; -webkit-font-smoothing:antialiased; overflow-x:hidden;
    }
    img{max-width:100%;display:block;height:auto}
    .wrap{max-width:1080px;margin:0 auto;padding:0 var(--pad)}
    .pix{font-family:'Silkscreen',monospace}

    .topbar{display:flex;align-items:center;justify-content:space-between;padding:18px 0}
    .brand{font-family:'Silkscreen',monospace;font-size:22px;color:var(--head);letter-spacing:1px;text-decoration:none;display:flex;gap:9px;align-items:baseline}
    .brand small{font-size:9px;color:var(--muted);letter-spacing:3px}
    .langs{display:flex;gap:2px;align-items:center;font-family:'Silkscreen',monospace;font-size:11px}
    .langs a{color:var(--muted);text-decoration:none;padding:5px 8px;border-radius:7px;border:1px solid transparent}
    .langs a:hover{color:var(--head)}
    .langs a.on{color:var(--head);background:var(--paper2);border-color:var(--line)}

    .hero{display:grid;grid-template-columns:1.05fr .95fr;gap:44px;align-items:center;padding:32px 0 60px}
    .eyebrow{font-family:'Silkscreen',monospace;font-size:12px;letter-spacing:3px;color:var(--accent);text-transform:uppercase;margin-bottom:20px}
    .hero h1{font-family:'DotGothic16',sans-serif;font-weight:400;font-size:clamp(30px,5.4vw,52px);line-height:1.16;color:var(--title);letter-spacing:.5px}
    .hero .sub{font-size:clamp(15px,1.7vw,18px);color:var(--ink);margin-top:20px;max-width:30em}
    .cta-row{display:flex;flex-wrap:wrap;gap:16px;align-items:center;margin-top:30px}
    .note{font-family:'Silkscreen',monospace;font-size:10px;letter-spacing:1.5px;color:var(--muted);line-height:1.6}
    .dots{display:flex;gap:9px;margin-top:34px}
    .dots i{width:16px;height:16px;border-radius:50%;display:block;box-shadow:0 2px 0 rgba(90,80,110,.12)}

    .btn-store{display:inline-flex;align-items:center;gap:11px;background:var(--green);border:2px solid var(--green-bd);border-radius:13px;padding:13px 22px;font-family:'Silkscreen',monospace;font-size:13px;color:var(--green-tx);text-decoration:none;box-shadow:0 4px 0 rgba(112,128,96,.4);transition:transform .12s ease,box-shadow .12s ease}
    .btn-store:hover{transform:translateY(-2px);box-shadow:0 6px 0 rgba(112,128,96,.4)}
    .btn-store:active{transform:translateY(2px);box-shadow:0 2px 0 rgba(112,128,96,.4)}
    .btn-store svg{width:17px;height:17px;fill:var(--green-tx);margin-top:-2px}

    .phone{border-radius:34px;padding:6px;background:#242433;max-width:262px;width:100%;margin:0 auto;
      box-shadow:0 24px 46px -22px rgba(64,52,88,.55),0 7px 14px -8px rgba(64,52,88,.3)}
    .phone img{border-radius:28px;width:100%;height:auto}

    section{padding:56px 0}
    .feature{display:grid;grid-template-columns:1fr 1fr;gap:48px;align-items:center;max-width:1080px;margin:0 auto;padding-left:var(--pad);padding-right:var(--pad)}
    .feature .fig{display:flex;justify-content:center}
    .feature .phone{max-width:238px}
    .feature.rev .fig{order:2}
    .kick{font-family:'Silkscreen',monospace;font-size:11px;letter-spacing:3px;color:var(--accent);text-transform:uppercase;margin-bottom:15px}
    .feature h2{font-family:'DotGothic16',sans-serif;font-weight:400;font-size:clamp(22px,3vw,31px);color:var(--title);line-height:1.32}
    .feature p:not(.kick){margin-top:15px;font-size:16px;color:var(--ink);max-width:32em}

    .themes{text-align:center}
    .themes .kick{margin-bottom:14px}
    .themes h2{font-family:'DotGothic16',sans-serif;font-weight:400;font-size:clamp(24px,3.4vw,34px);color:var(--title)}
    .themes p.lead{font-size:16px;margin:16px auto 0;max-width:34em}
    .themes .phones{display:flex;justify-content:center;gap:30px;flex-wrap:wrap;margin-top:40px}
    .themes .phone{max-width:206px}

    .chips{display:flex;flex-wrap:wrap;gap:12px;justify-content:center;margin-top:8px}
    .chip{display:inline-flex;align-items:center;gap:9px;background:var(--paper2);border:1.5px solid var(--line);border-radius:999px;padding:9px 16px;font-family:'Silkscreen',monospace;font-size:11px;letter-spacing:.5px;color:#5f5d72}
    .chip i{width:10px;height:10px;border-radius:50%;flex:none}

    .final{text-align:center;padding:66px 0 44px}
    .final h2{font-family:'DotGothic16',sans-serif;font-weight:400;font-size:clamp(24px,3.6vw,36px);color:var(--title);margin-bottom:28px}

    footer{border-top:2px dashed var(--line);margin-top:24px;padding:36px 0 64px;text-align:center}
    .foot-links{display:flex;flex-wrap:wrap;gap:8px 20px;justify-content:center;font-family:'Silkscreen',monospace;font-size:11px;letter-spacing:1px}
    .foot-links a{color:var(--muted);text-decoration:none}
    .foot-links a:hover{color:var(--head)}
    .foot-brand{font-family:'Silkscreen',monospace;color:var(--head);font-size:15px;margin-top:26px;letter-spacing:1px}
    .foot-made{margin-top:12px;font-size:12.5px;color:var(--muted)}

    a:focus-visible,.btn-store:focus-visible{outline:3px solid var(--accent);outline-offset:3px;border-radius:9px}

    .js .reveal{opacity:0;transform:translateY(20px)}
    .reveal.in{opacity:1;transform:none;transition:opacity .7s ease,transform .7s ease}

    @media (prefers-reduced-motion:reduce){ .js .reveal{opacity:1;transform:none} }

    @media (max-width:820px){
      .hero{grid-template-columns:1fr;gap:34px;text-align:center;padding-top:16px}
      .hero .sub{margin-left:auto;margin-right:auto}
      .cta-row,.dots{justify-content:center}
      .eyebrow{margin-bottom:14px}
      .feature{grid-template-columns:1fr;gap:26px;text-align:center}
      .feature.rev .fig{order:0}
      .feature p:not(.kick){margin-left:auto;margin-right:auto}
      section{padding:44px 0}
    }
    @media (max-width:520px){ :root{--pad:26px} }
    @media (max-width:420px){
      .brand{font-size:19px}
      .langs a{padding:5px 6px}
    }
  </style>
</head>
<body>
  <header class="wrap topbar">
    <a class="brand" href="/">点点 <small>DIAN DIAN</small></a>
    <nav class="langs" aria-label="Language">${langSwitch(lang)}</nav>
  </header>

  <main>
    <div class="wrap hero">
      <div class="hero-copy">
        <p class="eyebrow">点点 · ${c.eyebrow}</p>
        <h1>${c.h1}</h1>
        <p class="sub">${c.sub}</p>
        <div class="cta-row">
          ${storeButton(c)}
          <span class="note">${c.note}</span>
        </div>
        <div class="dots" aria-hidden="true">${heroDots}</div>
      </div>
      <div class="fig">
        <div class="phone"><img src="/shots/1.jpg" alt="${c.heroAlt}" width="600" height="1300" fetchpriority="high"></div>
      </div>
    </div>

    ${featureRows}

    <section class="wrap themes reveal">
      <p class="kick">${c.themesKick}</p>
      <h2>${c.themesH}</h2>
      <p class="lead">${c.themesB}</p>
      <div class="phones">
        <div class="phone"><img src="/shots/8.jpg" alt="${c.sakuraAlt}" loading="lazy" width="600" height="1300"></div>
        <div class="phone"><img src="/shots/7.jpg" alt="${c.darkAlt}" loading="lazy" width="600" height="1300"></div>
      </div>
    </section>

    <section class="wrap reveal" style="padding-top:20px">
      <div class="chips">${chips}</div>
    </section>

    <section class="wrap final reveal">
      <h2>${c.finalH}</h2>
      <div class="cta-row" style="justify-content:center">
        ${storeButton(c)}
        <span class="note">${c.note}</span>
      </div>
    </section>
  </main>

  <footer>
    <div class="wrap">
      <nav class="foot-links" aria-label="Legal">
        <a href="/privacy">${c.privacy}</a>
        <a href="/terms">${c.terms}</a>
        <a href="/legal">${c.legal}</a>
        <a href="/contact">${c.contact}</a>
      </nav>
      <div class="foot-brand">点点 · Dian Dian</div>
      <p class="foot-made">${c.made}</p>
    </div>
  </footer>

  <script>
    (function () {
      if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
        });
      }, { threshold: 0.12 });
      document.querySelectorAll('.reveal').forEach(function (el) { io.observe(el); });
    })();
  </script>
</body>
</html>`;
}

router.get('/', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(page(lang));
});

export default router;
