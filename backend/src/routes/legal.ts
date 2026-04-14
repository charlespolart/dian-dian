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

const ui = {
  backToApp: { en: 'Back to app', fr: "Retour à l'app", 'zh-CN': '返回应用', 'zh-TW': '返回應用' },
  footer: { en: 'Dian Dian (点点) — mydiandian.app', fr: 'Dian Dian (点点) — mydiandian.app', 'zh-CN': '点点 — mydiandian.app', 'zh-TW': '點點 — mydiandian.app' },
  sendMessage: { en: 'Send message', fr: 'Envoyer', 'zh-CN': '发送消息', 'zh-TW': '發送訊息' },
  sending: { en: 'Sending...', fr: 'Envoi...', 'zh-CN': '发送中...', 'zh-TW': '發送中...' },
  sent: { en: 'Message sent! We will get back to you soon.', fr: 'Message envoyé ! Nous reviendrons vers vous rapidement.', 'zh-CN': '消息已发送！我们会尽快回复。', 'zh-TW': '訊息已發送！我們會盡快回覆。' },
  sendFailed: { en: 'Failed to send. Please try again or email us directly.', fr: 'Envoi échoué. Réessayez ou écrivez-nous directement.', 'zh-CN': '发送失败，请重试或直接发邮件。', 'zh-TW': '發送失敗，請重試或直接發郵件。' },
  networkError: { en: 'Network error. Please try again.', fr: 'Erreur réseau. Réessayez.', 'zh-CN': '网络错误，请重试。', 'zh-TW': '網路錯誤，請重試。' },
  orEmail: { en: 'Or email us directly at', fr: 'Ou écrivez-nous directement à', 'zh-CN': '或直接发邮件至', 'zh-TW': '或直接發郵件至' },
  name: { en: 'Name', fr: 'Nom', 'zh-CN': '姓名', 'zh-TW': '姓名' },
  email: { en: 'Email', fr: 'Email', 'zh-CN': '邮箱', 'zh-TW': '電子郵件' },
  message: { en: 'Message', fr: 'Message', 'zh-CN': '消息', 'zh-TW': '訊息' },
};

function jsEscape(s: string): string {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function layout(title: string, content: string, lang: Lang): string {
  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title} — Dian Dian</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DotGothic16&family=Silkscreen:wght@400;700&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { height: auto; overflow: auto; }
    body {
      background: #f5f0d0;
      color: #5c4a2a;
      font-family: 'DotGothic16', 'Silkscreen', monospace;
      font-size: 15px;
      line-height: 1.7;
      min-height: 100vh;
      padding: 24px 16px 64px;
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
    }
    .container { max-width: 640px; margin: 0 auto; }
    .back-link {
      display: inline-block; margin-bottom: 24px; color: #a0855b;
      text-decoration: none; font-family: 'Silkscreen', monospace; font-size: 13px;
      border: 2px solid #a0855b; padding: 4px 12px; transition: background 0.15s, color 0.15s;
    }
    .back-link:hover { background: #a0855b; color: #f5f0d0; }
    h1 { font-family: 'Silkscreen', monospace; font-size: 26px; color: #3b2e14; margin-bottom: 8px; }
    .subtitle { font-size: 13px; color: #a0855b; margin-bottom: 32px; }
    h2 { font-family: 'Silkscreen', monospace; font-size: 17px; color: #3b2e14; margin-top: 28px; margin-bottom: 8px; }
    p, li { margin-bottom: 10px; }
    ul { padding-left: 24px; margin-bottom: 12px; }
    a { color: #7a6240; text-decoration: underline; }
    a:hover { color: #3b2e14; }
    hr { border: none; border-top: 2px dashed #d4c99a; margin: 32px 0; }
    .footer { margin-top: 48px; font-size: 12px; color: #a0855b; text-align: center; }
    .lang-select {
      position: relative; display: inline-block; font-family: 'Silkscreen', monospace; font-size: 11px;
    }
    .lang-btn {
      display: flex; align-items: center; gap: 4px; padding: 5px 10px;
      background: #ebe5c5; border: 1.5px solid #d4c99a; border-radius: 8px;
      color: #a0855b; cursor: pointer; font-family: inherit; font-size: inherit;
      transition: border-color 0.15s;
    }
    .lang-btn:hover { border-color: #a0855b; }
    .lang-btn svg { width: 14px; height: 14px; fill: none; stroke: #a0855b; stroke-width: 1.5; }
    .lang-menu {
      display: none; position: absolute; right: 0; top: calc(100% + 4px);
      background: #faf6e8; border: 1.5px solid #d4c99a; border-radius: 8px;
      overflow: hidden; z-index: 10; min-width: 100%;
    }
    .lang-select.open .lang-menu { display: block; }
    .lang-menu a {
      display: block; padding: 6px 12px; color: #5c4a2a; text-decoration: none;
      font-family: 'Silkscreen', monospace; font-size: 11px;
    }
    .lang-menu a:hover { background: #ebe5c5; }
    .lang-menu a.active { color: #3b2e14; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <a class="back-link" style="margin-bottom:0" href="/">&larr; ${ui.backToApp[lang]}</a>
      <div class="lang-select" id="langSelect">
        <button class="lang-btn" onclick="document.getElementById('langSelect').classList.toggle('open')">
          <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10A15.3 15.3 0 0 1 12 2z"/></svg>
          ${{ en: 'EN', fr: 'FR', 'zh-CN': '简', 'zh-TW': '繁' }[lang]}
        </button>
        <div class="lang-menu">
          <a href="?lang=en" class="${lang === 'en' ? 'active' : ''}">EN</a>
          <a href="?lang=fr" class="${lang === 'fr' ? 'active' : ''}">FR</a>
          <a href="?lang=zh-CN" class="${lang === 'zh-CN' ? 'active' : ''}">简</a>
          <a href="?lang=zh-TW" class="${lang === 'zh-TW' ? 'active' : ''}">繁</a>
        </div>
      </div>
    </div>
    ${content}
    <div class="footer">${ui.footer[lang]}</div>
  </div>
</body>
</html>`;
}

// ── Privacy Policy ──

const privacy: Record<Lang, string> = {
  en: `
    <h1>Privacy Policy</h1>
    <p class="subtitle">Last updated: April 14, 2026</p>
    <h2>1. Introduction</h2>
    <p>Dian Dian is published by OVERRIDE, SASU with a capital of 1 euro, registered under SIREN 953 122 868. This Privacy Policy explains how we collect, use, and protect your personal information.</p>
    <h2>2. Data We Collect</h2>
    <ul>
      <li><strong>Account information:</strong> email address and password (stored securely hashed).</li>
      <li><strong>Tracker data:</strong> the pages, day cells, colors, and legend entries you create.</li>
      <li><strong>Technical data:</strong> basic server logs (IP address, timestamps) for security.</li>
    </ul>
    <h2>3. How We Use Your Data</h2>
    <ul>
      <li>To provide and maintain the service.</li>
      <li>To authenticate you and keep your account secure.</li>
      <li>To sync your tracker data across devices.</li>
    </ul>
    <p>We do <strong>not</strong> sell your data or use it for profiling.</p>
    <h2>4. Third-Party Services</h2>
    <ul>
      <li><strong>Google AdMob:</strong> the free version of the app displays banner ads via Google AdMob. AdMob may collect device identifiers and usage data according to <a href="https://policies.google.com/privacy" target="_blank">Google's Privacy Policy</a>. Premium users are not shown ads.</li>
      <li><strong>Apple In-App Purchases:</strong> subscriptions and purchases are processed by Apple. We do not have access to your payment information. See <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple's Privacy Policy</a>.</li>
    </ul>
    <p>We do <strong>not</strong> use any other third-party analytics or tracking scripts. No personal data is shared with or sold to third parties.</p>
    <h2>5. Cookies</h2>
    <p>We use cookies <strong>solely for authentication</strong> (session tokens). No tracking or advertising cookies are used on the website.</p>
    <h2>6. Data Storage &amp; Security</h2>
    <p>Your data is stored on servers hosted by Vultr. Passwords are hashed using Argon2. All connections are encrypted via HTTPS.</p>
    <h2>7. Data Retention &amp; Deletion</h2>
    <p>We retain your data while your account is active. You can <strong>delete your account and all data</strong> at any time from the app.</p>
    <h2>8. Your Rights (GDPR)</h2>
    <p>If you are in the EEA, you have the right to access, correct, delete, export, or restrict processing of your data. Contact us at <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>.</p>
    <h2>9. Children</h2>
    <p>Dian Dian is not intended for children under 13. We do not knowingly collect data from children under 13.</p>
    <h2>10. Changes</h2>
    <p>We may update this policy. Material changes will be communicated via email.</p>
    <h2>11. Contact</h2>
    <p>Questions? <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  fr: `
    <h1>Politique de confidentialité</h1>
    <p class="subtitle">Dernière mise à jour : 14 avril 2026</p>
    <h2>1. Introduction</h2>
    <p>Dian Dian est édité par OVERRIDE, SASU au capital de 1 euro, immatriculée sous le SIREN 953 122 868. Cette politique explique comment nous collectons, utilisons et protégeons vos données personnelles.</p>
    <h2>2. Données collectées</h2>
    <ul>
      <li><strong>Informations de compte :</strong> adresse email et mot de passe (stocké de manière sécurisée, hashé).</li>
      <li><strong>Données de suivi :</strong> les pages, cellules, couleurs et légendes que vous créez.</li>
      <li><strong>Données techniques :</strong> journaux serveur basiques (adresse IP, horodatages) pour la sécurité.</li>
    </ul>
    <h2>3. Utilisation des données</h2>
    <ul>
      <li>Fournir et maintenir le service.</li>
      <li>Vous authentifier et sécuriser votre compte.</li>
      <li>Synchroniser vos données entre appareils.</li>
    </ul>
    <p>Nous ne <strong>vendons pas</strong> vos données et ne les utilisons pas à des fins de profilage.</p>
    <h2>4. Services tiers</h2>
    <ul>
      <li><strong>Google AdMob :</strong> la version gratuite de l'application affiche des bannières publicitaires via Google AdMob. AdMob peut collecter des identifiants d'appareil et des données d'utilisation conformément à la <a href="https://policies.google.com/privacy" target="_blank">Politique de confidentialité de Google</a>. Les utilisateurs Premium ne voient pas de publicités.</li>
      <li><strong>Achats intégrés Apple :</strong> les abonnements et achats sont traités par Apple. Nous n'avons pas accès à vos informations de paiement. Voir la <a href="https://www.apple.com/legal/privacy/" target="_blank">Politique de confidentialité d'Apple</a>.</li>
    </ul>
    <p>Nous n'utilisons <strong>aucun</strong> autre outil d'analyse ou script de suivi. Aucune donnée personnelle n'est partagée ou vendue à des tiers.</p>
    <h2>5. Cookies</h2>
    <p>Nous utilisons des cookies <strong>uniquement pour l'authentification</strong> (jetons de session). Aucun cookie de suivi ou publicitaire n'est utilisé sur le site web.</p>
    <h2>6. Stockage et sécurité</h2>
    <p>Vos données sont stockées sur des serveurs hébergés par Vultr. Les mots de passe sont hashés avec Argon2. Toutes les connexions sont chiffrées via HTTPS.</p>
    <h2>7. Conservation et suppression</h2>
    <p>Nous conservons vos données tant que votre compte est actif. Vous pouvez <strong>supprimer votre compte et toutes vos données</strong> à tout moment depuis l'application.</p>
    <h2>8. Vos droits (RGPD)</h2>
    <p>Si vous êtes dans l'EEE, vous avez le droit d'accéder, corriger, supprimer, exporter ou restreindre le traitement de vos données. Contactez-nous à <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>.</p>
    <h2>9. Enfants</h2>
    <p>Dian Dian n'est pas destiné aux enfants de moins de 13 ans.</p>
    <h2>10. Modifications</h2>
    <p>Nous pouvons mettre à jour cette politique. Les changements importants seront communiqués par email.</p>
    <h2>11. Contact</h2>
    <p>Questions ? <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  'zh-CN': `
    <h1>隐私政策</h1>
    <p class="subtitle">最后更新：2026年4月14日</p>
    <h2>1. 简介</h2>
    <p>点点由 OVERRIDE 公司（SASU，注册资本1欧元，SIREN 953 122 868）发布。本隐私政策说明我们如何收集、使用和保护您的个人信息。</p>
    <h2>2. 收集的数据</h2>
    <ul>
      <li><strong>账户信息：</strong>电子邮箱和密码（安全加密存储）。</li>
      <li><strong>追踪数据：</strong>您创建的页面、格子、颜色和图例。</li>
      <li><strong>技术数据：</strong>基本服务器日志（IP地址、时间戳），用于安全目的。</li>
    </ul>
    <h2>3. 数据使用方式</h2>
    <ul>
      <li>提供和维护服务。</li>
      <li>验证身份并保护账户安全。</li>
      <li>跨设备同步追踪数据。</li>
    </ul>
    <p>我们<strong>不会</strong>出售您的数据或将其用于用户画像。</p>
    <h2>4. 第三方服务</h2>
    <ul>
      <li><strong>Google AdMob：</strong>免费版应用通过 Google AdMob 显示横幅广告。AdMob 可能根据 <a href="https://policies.google.com/privacy" target="_blank">Google 隐私政策</a>收集设备标识符和使用数据。高级用户不会看到广告。</li>
      <li><strong>Apple 应用内购买：</strong>订阅和购买由 Apple 处理。我们无法访问您的支付信息。请参阅 <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple 隐私政策</a>。</li>
    </ul>
    <p>我们<strong>不使用</strong>任何其他第三方分析工具或追踪脚本。不会与第三方共享或出售个人数据。</p>
    <h2>5. Cookie</h2>
    <p>我们<strong>仅将 Cookie 用于身份验证</strong>（会话令牌）。网站上不使用追踪或广告 Cookie。</p>
    <h2>6. 数据存储与安全</h2>
    <p>您的数据存储在 Vultr 托管的服务器上。密码使用 Argon2 加密。所有连接通过 HTTPS 加密。</p>
    <h2>7. 数据保留与删除</h2>
    <p>账户活跃期间保留数据。您可以随时从应用中<strong>删除账户和所有数据</strong>。</p>
    <h2>8. 您的权利（GDPR）</h2>
    <p>如果您在欧洲经济区，您有权访问、更正、删除、导出或限制处理您的数据。请联系 <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>。</p>
    <h2>9. 儿童</h2>
    <p>点点不面向13岁以下的儿童。</p>
    <h2>10. 变更</h2>
    <p>我们可能会更新本政策。重大变更将通过电子邮件通知。</p>
    <h2>11. 联系</h2>
    <p>有问题？<a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  'zh-TW': `
    <h1>隱私權政策</h1>
    <p class="subtitle">最後更新：2026年4月14日</p>
    <h2>1. 簡介</h2>
    <p>點點由 OVERRIDE 公司（SASU，註冊資本1歐元，SIREN 953 122 868）發布。本隱私權政策說明我們如何收集、使用和保護您的個人資訊。</p>
    <h2>2. 收集的資料</h2>
    <ul>
      <li><strong>帳戶資訊：</strong>電子郵件和密碼（安全加密儲存）。</li>
      <li><strong>追蹤資料：</strong>您建立的頁面、格子、顏色和圖例。</li>
      <li><strong>技術資料：</strong>基本伺服器日誌（IP位址、時間戳），用於安全目的。</li>
    </ul>
    <h2>3. 資料使用方式</h2>
    <ul>
      <li>提供和維護服務。</li>
      <li>驗證身分並保護帳戶安全。</li>
      <li>跨裝置同步追蹤資料。</li>
    </ul>
    <p>我們<strong>不會</strong>出售您的資料或將其用於使用者分析。</p>
    <h2>4. 第三方服務</h2>
    <ul>
      <li><strong>Google AdMob：</strong>免費版應用程式透過 Google AdMob 顯示橫幅廣告。AdMob 可能根據 <a href="https://policies.google.com/privacy" target="_blank">Google 隱私權政策</a>收集裝置識別碼和使用資料。進階使用者不會看到廣告。</li>
      <li><strong>Apple 應用程式內購買：</strong>訂閱和購買由 Apple 處理。我們無法存取您的付款資訊。請參閱 <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple 隱私權政策</a>。</li>
    </ul>
    <p>我們<strong>不使用</strong>任何其他第三方分析工具或追蹤指令碼。不會與第三方分享或出售個人資料。</p>
    <h2>5. Cookie</h2>
    <p>我們<strong>僅將 Cookie 用於身分驗證</strong>（工作階段權杖）。網站上不使用追蹤或廣告 Cookie。</p>
    <h2>6. 資料儲存與安全</h2>
    <p>您的資料儲存在 Vultr 託管的伺服器上。密碼使用 Argon2 加密。所有連線透過 HTTPS 加密。</p>
    <h2>7. 資料保留與刪除</h2>
    <p>帳戶活躍期間保留資料。您可以隨時從應用程式中<strong>刪除帳戶和所有資料</strong>。</p>
    <h2>8. 您的權利（GDPR）</h2>
    <p>如果您在歐洲經濟區，您有權存取、更正、刪除、匯出或限制處理您的資料。請聯繫 <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>。</p>
    <h2>9. 兒童</h2>
    <p>點點不面向13歲以下的兒童。</p>
    <h2>10. 變更</h2>
    <p>我們可能會更新本政策。重大變更將透過電子郵件通知。</p>
    <h2>11. 聯繫</h2>
    <p>有問題？<a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
};

router.get('/privacy', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(lang === 'fr' ? 'Politique de confidentialité' : lang.startsWith('zh') ? '隐私政策' : 'Privacy Policy', privacy[lang], lang));
});

// ── Terms of Use ──

const terms: Record<Lang, string> = {
  en: `
    <h1>Terms of Use</h1>
    <p class="subtitle">Last updated: March 26, 2026</p>
    <h2>1. Acceptance</h2>
    <p>By using Dian Dian ("the Service"), you agree to these Terms. If you do not agree, please do not use the Service.</p>
    <h2>2. Eligibility</h2>
    <p>You must be at least <strong>13 years old</strong> to use Dian Dian.</p>
    <h2>3. Your Account</h2>
    <ul>
      <li>You are responsible for keeping your credentials secure.</li>
      <li>You are responsible for all activity under your account.</li>
      <li>Notify us immediately if you suspect unauthorized access.</li>
    </ul>
    <h2>4. Your Content</h2>
    <p>All tracker data and content you create <strong>belongs to you</strong>. We do not claim ownership.</p>
    <h2>5. Acceptable Use</h2>
    <p>You agree <strong>not</strong> to: use the Service unlawfully, attempt unauthorized access, disrupt the Service, automate access without permission, or harass others.</p>
    <h2>6. Service Availability</h2>
    <p>The Service is provided <strong>"as is"</strong> without warranties. We do not guarantee uninterrupted or error-free access.</p>
    <h2>7. Limitation of Liability</h2>
    <p>To the fullest extent permitted by law, we shall not be liable for any indirect, incidental, or consequential damages.</p>
    <h2>8. Account Termination</h2>
    <p>You may delete your account at any time. We may suspend accounts that violate these Terms.</p>
    <h2>9. Changes</h2>
    <p>We may update these Terms. Material changes will be communicated via email.</p>
    <h2>10. Contact</h2>
    <p>Questions? <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  fr: `
    <h1>Conditions d'utilisation</h1>
    <p class="subtitle">Dernière mise à jour : 26 mars 2026</p>
    <h2>1. Acceptation</h2>
    <p>En utilisant Dian Dian (« le Service »), vous acceptez ces Conditions. Si vous n'êtes pas d'accord, veuillez ne pas utiliser le Service.</p>
    <h2>2. Éligibilité</h2>
    <p>Vous devez avoir au moins <strong>13 ans</strong> pour utiliser Dian Dian.</p>
    <h2>3. Votre compte</h2>
    <ul>
      <li>Vous êtes responsable de la sécurité de vos identifiants.</li>
      <li>Vous êtes responsable de toute activité sur votre compte.</li>
      <li>Prévenez-nous immédiatement en cas d'accès non autorisé.</li>
    </ul>
    <h2>4. Votre contenu</h2>
    <p>Toutes les données et le contenu que vous créez <strong>vous appartiennent</strong>. Nous ne revendiquons aucun droit de propriété.</p>
    <h2>5. Utilisation acceptable</h2>
    <p>Vous vous engagez à <strong>ne pas</strong> : utiliser le Service illégalement, tenter un accès non autorisé, perturber le Service, automatiser l'accès sans permission, ou harceler d'autres utilisateurs.</p>
    <h2>6. Disponibilité du service</h2>
    <p>Le Service est fourni <strong>« tel quel »</strong> sans garantie. Nous ne garantissons pas un accès ininterrompu ou sans erreur.</p>
    <h2>7. Limitation de responsabilité</h2>
    <p>Dans les limites permises par la loi, nous ne serons pas responsables des dommages indirects, accessoires ou consécutifs.</p>
    <h2>8. Résiliation de compte</h2>
    <p>Vous pouvez supprimer votre compte à tout moment. Nous pouvons suspendre les comptes qui violent ces Conditions.</p>
    <h2>9. Modifications</h2>
    <p>Nous pouvons mettre à jour ces Conditions. Les changements importants seront communiqués par email.</p>
    <h2>10. Contact</h2>
    <p>Questions ? <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  'zh-CN': `
    <h1>使用条款</h1>
    <p class="subtitle">最后更新：2026年3月26日</p>
    <h2>1. 接受条款</h2>
    <p>使用点点（"本服务"）即表示您同意这些条款。如不同意，请勿使用本服务。</p>
    <h2>2. 资格</h2>
    <p>您必须年满 <strong>13 周岁</strong>才能使用点点。</p>
    <h2>3. 您的账户</h2>
    <ul>
      <li>您有责任保管好登录凭证的安全。</li>
      <li>您对账户下的所有活动负责。</li>
      <li>如怀疑未经授权的访问，请立即通知我们。</li>
    </ul>
    <h2>4. 您的内容</h2>
    <p>您创建的所有追踪数据和内容<strong>归您所有</strong>。我们不主张所有权。</p>
    <h2>5. 合理使用</h2>
    <p>您同意<strong>不会</strong>：非法使用服务、尝试未经授权的访问、干扰服务、未经许可自动化访问或骚扰他人。</p>
    <h2>6. 服务可用性</h2>
    <p>服务按<strong>"现状"</strong>提供，不附带任何保证。我们不保证服务不间断或无错误。</p>
    <h2>7. 责任限制</h2>
    <p>在法律允许的最大范围内，我们不对任何间接、附带或后果性损害承担责任。</p>
    <h2>8. 账户终止</h2>
    <p>您可以随时删除账户。我们可能会暂停违反这些条款的账户。</p>
    <h2>9. 变更</h2>
    <p>我们可能会更新这些条款。重大变更将通过电子邮件通知。</p>
    <h2>10. 联系</h2>
    <p>有问题？<a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
  'zh-TW': `
    <h1>使用條款</h1>
    <p class="subtitle">最後更新：2026年3月26日</p>
    <h2>1. 接受條款</h2>
    <p>使用點點（「本服務」）即表示您同意這些條款。如不同意，請勿使用本服務。</p>
    <h2>2. 資格</h2>
    <p>您必須年滿 <strong>13 歲</strong>才能使用點點。</p>
    <h2>3. 您的帳戶</h2>
    <ul>
      <li>您有責任保管好登入憑證的安全。</li>
      <li>您對帳戶下的所有活動負責。</li>
      <li>如懷疑未經授權的存取，請立即通知我們。</li>
    </ul>
    <h2>4. 您的內容</h2>
    <p>您建立的所有追蹤資料和內容<strong>歸您所有</strong>。我們不主張所有權。</p>
    <h2>5. 合理使用</h2>
    <p>您同意<strong>不會</strong>：非法使用服務、嘗試未經授權的存取、干擾服務、未經許可自動化存取或騷擾他人。</p>
    <h2>6. 服務可用性</h2>
    <p>服務按<strong>「現狀」</strong>提供，不附帶任何保證。我們不保證服務不間斷或無錯誤。</p>
    <h2>7. 責任限制</h2>
    <p>在法律允許的最大範圍內，我們不對任何間接、附帶或後果性損害承擔責任。</p>
    <h2>8. 帳戶終止</h2>
    <p>您可以隨時刪除帳戶。我們可能會暫停違反這些條款的帳戶。</p>
    <h2>9. 變更</h2>
    <p>我們可能會更新這些條款。重大變更將透過電子郵件通知。</p>
    <h2>10. 聯繫</h2>
    <p>有問題？<a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></p>`,
};

router.get('/terms', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(lang === 'fr' ? "Conditions d'utilisation" : lang.startsWith('zh') ? '使用条款' : 'Terms of Use', terms[lang], lang));
});

// ── About ──

const about: Record<Lang, string> = {
  en: `
    <h1>About Dian Dian</h1>
    <p class="subtitle">点点 — dot by dot, day by day</p>
    <h2>What is Dian Dian?</h2>
    <p>Dian Dian is a visual year tracker that lets you <strong>color-code each day</strong> of the year. Create custom pages with your own color legends, then fill in each day to build a beautiful overview of your year.</p>
    <p>Track habits, moods, workouts, reading days, side-project progress — anything you want to see at a glance across 365 days.</p>
    <h2>How It Works</h2>
    <ul>
      <li>Create a page and define your color legend (e.g., green = gym, blue = reading).</li>
      <li>Tap a day to color it.</li>
      <li>Watch your year fill up, one dot at a time.</li>
      <li>Your data syncs across devices in real time.</li>
    </ul>
    <h2>Built by an Indie Developer</h2>
    <p>Dian Dian is designed, built, and maintained by a solo indie developer. No big team, no venture capital — just a love for pixel aesthetics and useful tools.</p>
    <p>Have feedback or ideas? <a href="/contact">Get in touch</a>.</p>
    <hr />
    <p style="text-align:center;font-family:'Silkscreen',monospace;font-size:13px;color:#a0855b;">Made with care — one pixel at a time.</p>`,
  fr: `
    <h1>À propos de Dian Dian</h1>
    <p class="subtitle">点点 — point par point, jour après jour</p>
    <h2>Qu'est-ce que Dian Dian ?</h2>
    <p>Dian Dian est un tracker annuel visuel qui vous permet de <strong>colorier chaque jour</strong> de l'année. Créez des pages avec vos propres légendes de couleurs, puis remplissez chaque jour pour obtenir une vue d'ensemble de votre année.</p>
    <p>Suivez vos habitudes, humeurs, séances de sport, jours de lecture, projets perso — tout ce que vous voulez voir d'un coup d'œil sur 365 jours.</p>
    <h2>Comment ça marche</h2>
    <ul>
      <li>Créez une page et définissez votre légende (ex : vert = sport, bleu = lecture).</li>
      <li>Tapez sur un jour pour le colorier.</li>
      <li>Regardez votre année se remplir, un point à la fois.</li>
      <li>Vos données se synchronisent en temps réel entre vos appareils.</li>
    </ul>
    <h2>Créé par un développeur indépendant</h2>
    <p>Dian Dian est conçu, développé et maintenu par un développeur solo. Pas de grosse équipe, pas de capital-risque — juste une passion pour l'esthétique pixel et les outils utiles.</p>
    <p>Des retours ou des idées ? <a href="/contact">Contactez-nous</a>.</p>
    <hr />
    <p style="text-align:center;font-family:'Silkscreen',monospace;font-size:13px;color:#a0855b;">Fait avec soin — un pixel à la fois.</p>`,
  'zh-CN': `
    <h1>关于点点</h1>
    <p class="subtitle">点点 — 一点一点，一天一天</p>
    <h2>什么是点点？</h2>
    <p>点点是一个可视化年度追踪器，让您<strong>为每一天涂上颜色</strong>。创建自定义页面和颜色图例，逐日填充，构建一年的美丽总览。</p>
    <p>追踪习惯、心情、锻炼、阅读、个人项目——一切您想在 365 天中一目了然的事情。</p>
    <h2>如何使用</h2>
    <ul>
      <li>创建页面并定义颜色图例（例如：绿色 = 健身，蓝色 = 阅读）。</li>
      <li>点击某一天为其涂色。</li>
      <li>看着您的年度一个点一个点地填满。</li>
      <li>数据在设备间实时同步。</li>
    </ul>
    <h2>独立开发者作品</h2>
    <p>点点由一位独立开发者设计、开发和维护。没有大团队，没有风险投资——只有对像素美学和实用工具的热爱。</p>
    <p>有反馈或想法？<a href="/contact">联系我们</a>。</p>
    <hr />
    <p style="text-align:center;font-family:'Silkscreen',monospace;font-size:13px;color:#a0855b;">用心制作——一次一个像素。</p>`,
  'zh-TW': `
    <h1>關於點點</h1>
    <p class="subtitle">點點 — 一點一點，一天一天</p>
    <h2>什麼是點點？</h2>
    <p>點點是一個視覺化年度追蹤器，讓您<strong>為每一天塗上顏色</strong>。建立自訂頁面和顏色圖例，逐日填充，構建一年的美麗總覽。</p>
    <p>追蹤習慣、心情、鍛鍊、閱讀、個人專案——一切您想在 365 天中一目了然的事情。</p>
    <h2>如何使用</h2>
    <ul>
      <li>建立頁面並定義顏色圖例（例如：綠色 = 健身，藍色 = 閱讀）。</li>
      <li>點選某一天為其上色。</li>
      <li>看著您的年度一個點一個點地填滿。</li>
      <li>資料在裝置間即時同步。</li>
    </ul>
    <h2>獨立開發者作品</h2>
    <p>點點由一位獨立開發者設計、開發和維護。沒有大團隊，沒有風險投資——只有對像素美學和實用工具的熱愛。</p>
    <p>有回饋或想法？<a href="/contact">聯繫我們</a>。</p>
    <hr />
    <p style="text-align:center;font-family:'Silkscreen',monospace;font-size:13px;color:#a0855b;">用心製作——一次一個像素。</p>`,
};

router.get('/about', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(lang === 'fr' ? 'À propos' : lang.startsWith('zh') ? '关于' : 'About', about[lang], lang));
});

// ── Contact ──

function contactContent(lang: Lang): string {
  return `
    <h1>${{ en: 'Contact', fr: 'Contact', 'zh-CN': '联系我们', 'zh-TW': '聯繫我們' }[lang]}</h1>
    <p class="subtitle">${{ en: "We'd love to hear from you", fr: 'Nous serions ravis de vous entendre', 'zh-CN': '我们很想听到您的意见', 'zh-TW': '我們很想聽到您的意見' }[lang]}</p>

    <form id="contactForm" style="margin-top:20px;">
      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">${ui.name[lang]}</label>
      <input type="text" name="name" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;" />

      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">${ui.email[lang]}</label>
      <input type="email" name="email" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;" />

      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">${ui.message[lang]}</label>
      <textarea name="message" rows="5" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;resize:vertical;"></textarea>

      <button type="submit" id="submitBtn"
        style="font-family:'Silkscreen',monospace;font-size:13px;padding:10px 24px;background:#d8e8c8;border:2px solid #b0c8a0;border-radius:10px;color:#708060;cursor:pointer;width:100%;transition:transform 0.15s;">
        ${ui.sendMessage[lang]}
      </button>
    </form>

    <div id="formMsg" style="text-align:center;margin-top:16px;font-size:14px;display:none;"></div>

    <hr />

    <p style="text-align:center;font-size:13px;color:#a0855b;">
      ${ui.orEmail[lang]} <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>
    </p>

    <p style="font-size:13px;color:#a0855b;margin-top:16px;">
      ${{ en: 'As a solo indie project, please allow up to <strong>48 hours</strong> for a response. We read every message.', fr: 'En tant que projet indépendant, veuillez prévoir jusqu\'à <strong>48 heures</strong> pour une réponse. Nous lisons chaque message.', 'zh-CN': '作为个人独立项目，请允许最多 <strong>48 小时</strong>的回复时间。我们会阅读每条消息。', 'zh-TW': '作為個人獨立專案，請允許最多 <strong>48 小時</strong>的回覆時間。我們會閱讀每則訊息。' }[lang]}
    </p>

    <script>
      document.getElementById('contactForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('submitBtn');
        const msg = document.getElementById('formMsg');
        const form = e.target;
        btn.disabled = true;
        btn.textContent = '${jsEscape(ui.sending[lang])}';
        msg.style.display = 'none';
        try {
          const res = await fetch('/api/contact', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: form.name.value, email: form.email.value, message: form.message.value }),
          });
          if (res.ok) {
            msg.style.color = '#708060';
            msg.textContent = '${jsEscape(ui.sent[lang])}';
            form.reset();
          } else {
            msg.style.color = '#c0392b';
            msg.textContent = '${jsEscape(ui.sendFailed[lang])}';
          }
        } catch {
          msg.style.color = '#c0392b';
          msg.textContent = '${jsEscape(ui.networkError[lang])}';
        }
        msg.style.display = 'block';
        btn.disabled = false;
        btn.textContent = '${jsEscape(ui.sendMessage[lang])}';
      });
    </script>`;
}

router.get('/contact', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(lang === 'fr' ? 'Contact' : lang.startsWith('zh') ? '联系我们' : 'Contact', contactContent(lang), lang));
});

// ── Legal Notice (Mentions légales) ──

const legal: Record<Lang, string> = {
  en: `
    <h1>Legal Notice</h1>
    <h2>Publisher</h2>
    <ul>
      <li><strong>Company:</strong> OVERRIDE</li>
      <li><strong>Legal form:</strong> SASU (Société par Actions Simplifiée Unipersonnelle)</li>
      <li><strong>Share capital:</strong> 1 euro</li>
      <li><strong>SIREN:</strong> 953 122 868</li>
      <li><strong>Registered office:</strong> 12 Rue de Porspol, 29660 Carantec, France</li>
      <li><strong>Publication director:</strong> Charles Polart</li>
      <li><strong>Contact:</strong> <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></li>
    </ul>
    <h2>Hosting</h2>
    <ul>
      <li><strong>Provider:</strong> Vultr Holdings LLC</li>
      <li><strong>Address:</strong> 14 Cliffwood Ave, Suite 300, Matawan, NJ 07747, USA</li>
      <li><strong>Website:</strong> <a href="https://www.vultr.com" target="_blank">vultr.com</a></li>
    </ul>`,
  fr: `
    <h1>Mentions légales</h1>
    <h2>Éditeur</h2>
    <ul>
      <li><strong>Société :</strong> OVERRIDE</li>
      <li><strong>Forme juridique :</strong> SASU (Société par Actions Simplifiée Unipersonnelle)</li>
      <li><strong>Capital social :</strong> 1 euro</li>
      <li><strong>SIREN :</strong> 953 122 868</li>
      <li><strong>Siège social :</strong> 12 Rue de Porspol, 29660 Carantec, France</li>
      <li><strong>Directeur de la publication :</strong> Charles Polart</li>
      <li><strong>Contact :</strong> <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></li>
    </ul>
    <h2>Hébergement</h2>
    <ul>
      <li><strong>Prestataire :</strong> Vultr Holdings LLC</li>
      <li><strong>Adresse :</strong> 14 Cliffwood Ave, Suite 300, Matawan, NJ 07747, USA</li>
      <li><strong>Site web :</strong> <a href="https://www.vultr.com" target="_blank">vultr.com</a></li>
    </ul>`,
  'zh-CN': `
    <h1>法律声明</h1>
    <h2>发布者</h2>
    <ul>
      <li><strong>公司：</strong>OVERRIDE</li>
      <li><strong>法律形式：</strong>SASU（简易股份有限公司）</li>
      <li><strong>注册资本：</strong>1 欧元</li>
      <li><strong>SIREN：</strong>953 122 868</li>
      <li><strong>注册地址：</strong>12 Rue de Porspol, 29660 Carantec, France</li>
      <li><strong>出版总监：</strong>Charles Polart</li>
      <li><strong>联系方式：</strong><a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></li>
    </ul>
    <h2>托管服务</h2>
    <ul>
      <li><strong>服务商：</strong>Vultr Holdings LLC</li>
      <li><strong>地址：</strong>14 Cliffwood Ave, Suite 300, Matawan, NJ 07747, USA</li>
      <li><strong>网站：</strong><a href="https://www.vultr.com" target="_blank">vultr.com</a></li>
    </ul>`,
  'zh-TW': `
    <h1>法律聲明</h1>
    <h2>發布者</h2>
    <ul>
      <li><strong>公司：</strong>OVERRIDE</li>
      <li><strong>法律形式：</strong>SASU（簡易股份有限公司）</li>
      <li><strong>註冊資本：</strong>1 歐元</li>
      <li><strong>SIREN：</strong>953 122 868</li>
      <li><strong>註冊地址：</strong>12 Rue de Porspol, 29660 Carantec, France</li>
      <li><strong>出版總監：</strong>Charles Polart</li>
      <li><strong>聯繫方式：</strong><a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a></li>
    </ul>
    <h2>託管服務</h2>
    <ul>
      <li><strong>服務商：</strong>Vultr Holdings LLC</li>
      <li><strong>地址：</strong>14 Cliffwood Ave, Suite 300, Matawan, NJ 07747, USA</li>
      <li><strong>網站：</strong><a href="https://www.vultr.com" target="_blank">vultr.com</a></li>
    </ul>`,
};

router.get('/legal', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(lang === 'fr' ? 'Mentions légales' : lang.startsWith('zh') ? '法律声明' : 'Legal Notice', legal[lang], lang));
});

export default router;
