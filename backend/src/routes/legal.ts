import express, { Router, Request } from 'express';
import { OPT_OUT_COOKIE, objection } from '../audience/index.js';

const router = Router();

type Lang = 'en' | 'fr' | 'zh-CN' | 'zh-TW';
const SUPPORTED: Lang[] = ['en', 'fr', 'zh-CN', 'zh-TW'];

export function detectLang(req: Request): Lang {
  // Only a plain string: `?lang[toString]=x` gives an object that cannot be converted to text.
  const q = typeof req.query.lang === 'string' ? req.query.lang : '';
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
  footer: { en: 'Dian Dian (点点) — diandian.overridedev.com', fr: 'Dian Dian (点点) — diandian.overridedev.com', 'zh-CN': '点点 — diandian.overridedev.com', 'zh-TW': '點點 — diandian.overridedev.com' },
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

const notFound = {
  title: { en: 'Page not found', fr: 'Page introuvable', 'zh-CN': '找不到页面', 'zh-TW': '找不到頁面' },
  text: { en: 'There is nothing at this address.', fr: 'Il n’y a rien à cette adresse.', 'zh-CN': '此地址没有内容。', 'zh-TW': '此網址沒有內容。' },
  home: { en: 'Back to Dian Dian', fr: 'Retour à l’accueil', 'zh-CN': '返回首页', 'zh-TW': '返回首頁' },
};

/** The <title> of each page, in each language (zh-TW in Traditional characters). */
const titles: Record<'privacy' | 'terms' | 'about' | 'contact' | 'legal' | 'deleteAccount', Record<Lang, string>> = {
  privacy: { en: 'Privacy Policy', fr: 'Politique de confidentialité', 'zh-CN': '隐私政策', 'zh-TW': '隱私權政策' },
  terms: { en: 'Terms of Use', fr: "Conditions d'utilisation", 'zh-CN': '使用条款', 'zh-TW': '使用條款' },
  about: { en: 'About', fr: 'À propos', 'zh-CN': '关于', 'zh-TW': '關於' },
  contact: { en: 'Contact', fr: 'Contact', 'zh-CN': '联系我们', 'zh-TW': '聯絡我們' },
  legal: { en: 'Legal Notice', fr: 'Mentions légales', 'zh-CN': '法律声明', 'zh-TW': '法律聲明' },
  deleteAccount: { en: 'Delete Account', fr: 'Suppression du compte', 'zh-CN': '删除账户', 'zh-TW': '刪除帳戶' },
};

/** What an unknown path gets (see index.ts): a 404 in the site's layout, with a way back. */
export function notFoundPage(lang: Lang): string {
  return layout(notFound.title[lang], `<h1>${notFound.title[lang]}</h1>
    <p>${notFound.text[lang]}</p>
    <p><a href="/">${notFound.home[lang]}</a></p>`, lang);
}

function layout(title: string, content: string, lang: Lang): string {
  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title} — Dian Dian</title>
  <link href="/fonts/fonts.css" rel="stylesheet" />
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
    .container { max-width: 640px; margin: 0 auto; position: relative; }
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
      position: absolute; top: 0; right: 0; display: inline-block;
      font-family: 'Silkscreen', monospace; font-size: 11px;
    }
    .lang-menu-wrap { position: relative; }
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
    <div class="lang-select" id="langSelect">
      <div class="lang-menu-wrap">
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

// The day the policy's text last changed, written out in each language. One
// date for the four: change it with the text, nowhere else.
export const PRIVACY_UPDATED = '2026-11-27';
const updatedOn = (locale: string) => new Intl.DateTimeFormat(locale, { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(`${PRIVACY_UPDATED}T00:00:00Z`));

// What it says is what docs/REGISTRE.md records: a change to one is a change
// to the other, in the four languages.
const privacy: Record<Lang, string> = {
  en: `
    <h1>Privacy Policy</h1>
    <p class="subtitle">Last updated: ${updatedOn('en-US')}</p>
    <h2>1. Introduction</h2>
    <p>Dian Dian is published by OVERRIDE, SASU with a capital of 1 euro, registered under SIREN 953 122 868, which is the controller of your data. This Privacy Policy explains which data we process, why, who it is entrusted to and how long we keep it. Any question: <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>.</p>
    <h2>2. Data We Process</h2>
    <ul>
      <li><strong>Account:</strong> your email address and, if you chose a password, its hash (the password itself is never kept). If you sign in with Apple or Google, we keep only your email address and an identifier that service gives us for you: nothing else from your profile.</li>
      <li><strong>Account without an address:</strong> if you start without an account, an account is created without an email address or a password. It is reopened by a key made by your phone and kept in its secure storage; we keep only its fingerprint, never the key itself. For every account, we also keep the date the app last contacted it.</li>
      <li><strong>Tracker content:</strong> the trackers, colored days, legend entries and comments you create. You choose what you write in them.</li>
      <li><strong>Settings:</strong> the theme, language and cursor you chose.</li>
      <li><strong>Purchases:</strong> the plan you bought, the store, the dates, the price and the store's country, whether it was a trial or a test purchase, why a subscription ended, and the store's transaction identifier. We never have access to your payment information.</li>
      <li><strong>Product events:</strong> see section 7.</li>
      <li><strong>Technical data:</strong> your IP address is used to limit abuse (counted in memory for 15 minutes) and is written to the server's log when a sign-in or a session token is refused.</li>
      <li><strong>Messages:</strong> what you write to us through the contact form or by email.</li>
    </ul>
    <h2>3. Why, and on What Basis</h2>
    <ul>
      <li><strong>To provide the service</strong> (performance of the contract): create your account, sign you in, keep your trackers and sync them across your devices, give you Premium when you buy it, and send you the service's emails (reset code, deletion confirmation).</li>
      <li><strong>To protect the service</strong> (legitimate interest): limit abuse and be able to notice an attack.</li>
      <li><strong>To improve the app</strong> (legitimate interest): the product events and usage statistics of section 7, the website audience measurement of section 6, and the measurement of sales.</li>
      <li><strong>To answer you</strong> (legitimate interest) when you write to us.</li>
    </ul>
    <p>We do <strong>not</strong> sell your data or use it for profiling. We send no marketing email.</p>
    <h2>4. Who Your Data Is Entrusted To</h2>
    <p>Nobody but us reads your data. These companies host or carry it on our behalf:</p>
    <ul>
      <li><strong>Vultr:</strong> the server, in France.</li>
      <li><strong>Cloudflare:</strong> the backups of the database, encrypted before they leave our server and stored in the European Union; and the forwarding of the emails you write to us.</li>
      <li><strong>Resend:</strong> the sending of our emails. Resend receives your address and the content of the email, and keeps them 30 days.</li>
      <li><strong>RevenueCat:</strong> keeping track of purchases. RevenueCat receives your account's identifier, your purchase receipts and technical information about your device, never your email address.</li>
      <li><strong>Microsoft:</strong> the mailbox where the messages you write to us arrive.</li>
    </ul>
    <p>Resend and RevenueCat are in the United States: these transfers are covered by the European Commission's standard contractual clauses.</p>
    <p><strong>Apple and Google</strong> process on their own account what you entrust to them: signing in through them, if you choose to, and your purchases (App Store or Google Play, depending on your device). See <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple's Privacy Policy</a> and <a href="https://policies.google.com/privacy" target="_blank">Google's Privacy Policy</a>.</p>
    <p>We use <strong>no third-party analytics tool</strong> or tracking script. Apart from these companies and the advertising described in section 8, your data is disclosed to no one.</p>
    <h2>5. Cookies</h2>
    <p>We use cookies for two things only: <strong>authentication</strong> (session tokens) and, if you refuse the website's audience measurement, remembering that choice (<code>dd_noaudience</code>, kept 13 months). No tracking or advertising cookies are used on the website.</p>
    <h2>6. Website Audience Measurement</h2>
    <p>We count the visits to this website ourselves, to know how many people come, from which site, and how many tap a store button. This measurement uses <strong>no cookie and no third-party tool</strong>. The site loads nothing from a third party: its fonts and images come from our own server.</p>
    <ul>
      <li><strong>What is counted:</strong> page views and taps on the store buttons, per day, with the site you came from (its domain name only, as your browser gives it or as the link you followed names it), whether that link carried a campaign tag (not the tag itself), the type of device and browser, the page language and the country.</li>
      <li><strong>What is not kept:</strong> your IP address and your browser's full identification are never written anywhere. They are used to find the country and, mixed with a random value that changes every day, to tell the visitors of one day apart; that mix stays in the server's memory until the end of the day at the latest. Nothing is linked to an account, and no visitor can be followed from one day to the next.</li>
      <li><strong>How long:</strong> daily counts are kept 25 months at most; after that only monthly totals remain.</li>
      <li><strong>Where:</strong> on our server, in France, and in the encrypted backups of its database. These figures are for Dian Dian only and are never shared.</li>
    </ul>
    <p>You can <a href="/privacy/audience?lang=en">refuse to be counted</a>. If your browser sends the "Global Privacy Control" or "Do Not Track" signal, you are not counted at all. The country is found with the database <a href="https://db-ip.com" target="_blank" rel="noopener">IP Geolocation by DB-IP</a>.</p>
    <h2 id="events">7. Product Events and Usage Statistics</h2>
    <p>To know where the app stops its users, it reports a few events to us, linked to your account.</p>
    <ul>
      <li><strong>What is reported:</strong> the name of a screen or an action (today: a limit of the free version being shown), the platform (iOS, Android), the app's version and the date. Never the content of your trackers.</li>
      <li><strong>Why:</strong> to adjust the limits of the free version and fix what gets in the way.</li>
      <li><strong>How long:</strong> 13 months at most, then they are deleted. They are deleted with your account if you delete it.</li>
      <li><strong>For whom:</strong> Dian Dian only. They are never shared.</li>
      <li><strong>Objecting:</strong> write to us at <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>. We then stop recording them for your account and delete those already received.</li>
    </ul>
    <p>We also compute statistics over all accounts together (number of accounts, of trackers, of days filled in, most common tracker titles) to decide how the app evolves. They describe no one in particular.</p>
    <h2>8. Advertising</h2>
    <p>The free version of the app displays banner ads via <strong>Google AdMob</strong>. AdMob may collect device identifiers and usage data, which Google processes on its own account according to <a href="https://policies.google.com/privacy" target="_blank">Google's Privacy Policy</a>. Premium users are not shown ads.</p>
    <h2>9. Data Storage &amp; Security</h2>
    <p>Your data is stored on our server, hosted by Vultr in France. Passwords are hashed using Argon2. All connections are encrypted via HTTPS. The database is backed up every day; the backups are encrypted, stored in the European Union and kept 30 days. The app also keeps on your phone a full copy of your account (every tracker, colored day, legend and comment, of every year), and the changes you made offline until they reach our server. It is deleted when you sign out; if our server closes your session, it stays on the phone, hidden, until you sign in again to that account (signing in to another one deletes it). Like the rest of the app's data, it can be included in your phone's backups (iCloud, Google).</p>
    <h2>10. Data Retention &amp; Deletion</h2>
    <ul>
      <li><strong>Account and content:</strong> as long as your account exists. You can <strong>delete your account and all data</strong> at any time from the app ("Delete my data" for an account created without an address, "Delete my account and my data" otherwise); the deletion is immediate. After it, the identifier of a deleted account (nothing else) is kept 24 months, so that a key or a copy restored on a phone does not bring it back.</li>
      <li><strong>Backups:</strong> 30 days. A deleted account is therefore gone from the backups 30 days later.</li>
      <li><strong>Offline sync:</strong> the changes a phone sends, with our answer, 90 days (so that a change sent twice is never applied twice); the trace of a deleted tracker, legend or day (its identifier, none of its content), 24 months; both go with your account. When an account is deleted, when its password is changed or its other devices are logged out, a fingerprint of the closed sessions' tokens, with the reason and linked to no account, is kept 548 days so that those phones learn why.</li>
      <li><strong>Product events:</strong> 13 months at most.</li>
      <li><strong>Website audience measurement:</strong> daily counts for 25 months at most, then monthly totals only.</li>
      <li><strong>Server log:</strong> the IP address of a refused sign-in or session token stays there 6 months at most.</li>
      <li><strong>Messages you write to us:</strong> 3 years at most after the last exchange.</li>
      <li><strong>Purchases:</strong> as long as your account exists. A store subscription keeps renewing until you cancel it with Apple or Google, even after your account is deleted: the purchase events that then reach us are kept 13 months at most, linked to no account. Apple, Google and RevenueCat keep their own record of your purchases, under their own rules.</li>
    </ul>
    <h2>11. Your Rights</h2>
    <p>You can access your data, have it corrected or deleted, receive a copy of it, have its processing restricted, and object to the processing based on our legitimate interest (sections 6 and 7). Write to us at <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>: we answer within one month. If our answer does not satisfy you, you can lodge a complaint with the French data protection authority, the <a href="https://www.cnil.fr/fr/plaintes" target="_blank" rel="noopener">CNIL</a>, or with the authority of your country.</p>
    <h2>12. Changes</h2>
    <p>We may update this policy. Material changes will be communicated via email.</p>
    <h2>13. Contact</h2>
    <p>Questions? <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  fr: `
    <h1>Politique de confidentialité</h1>
    <p class="subtitle">Dernière mise à jour : ${updatedOn('fr-FR')}</p>
    <h2>1. Introduction</h2>
    <p>Dian Dian est édité par OVERRIDE, SASU au capital de 1 euro, immatriculée sous le SIREN 953 122 868, qui est responsable du traitement de vos données. Cette politique explique quelles données nous traitons, pourquoi, à qui elles sont confiées et combien de temps nous les gardons. Pour toute question : <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>.</p>
    <h2>2. Données que nous traitons</h2>
    <ul>
      <li><strong>Compte :</strong> votre adresse e-mail et, si vous avez choisi un mot de passe, son empreinte (le mot de passe lui-même n'est jamais gardé). Si vous vous connectez avec Apple ou Google, nous ne gardons que votre adresse e-mail et un identifiant que ce service nous donne pour vous : rien d'autre de votre profil.</li>
      <li><strong>Compte sans adresse :</strong> si vous commencez sans compte, un compte est créé sans adresse e-mail ni mot de passe. Il est rouvert par une clé faite par votre téléphone et rangée dans son stockage sécurisé ; nous ne gardons que son empreinte, jamais la clé elle-même. Pour tous les comptes, nous gardons aussi la date du dernier contact de l'app.</li>
      <li><strong>Contenu de vos trackers :</strong> les trackers, les jours coloriés, les légendes et les commentaires que vous créez. Vous choisissez ce que vous y notez.</li>
      <li><strong>Réglages :</strong> le thème, la langue et le curseur choisis.</li>
      <li><strong>Achats :</strong> la formule achetée, le store, les dates, le prix et le pays du store, s'il s'agissait d'un essai ou d'un achat de test, pourquoi un abonnement a pris fin, et l'identifiant de la transaction chez le store. Nous n'avons jamais accès à votre moyen de paiement.</li>
      <li><strong>Événements produit :</strong> voir la section 7.</li>
      <li><strong>Données techniques :</strong> votre adresse IP sert à limiter les abus (elle est comptée en mémoire pendant 15 minutes) et est écrite dans le journal du serveur quand une connexion ou un jeton de session est refusé.</li>
      <li><strong>Messages :</strong> ce que vous nous écrivez par le formulaire de contact ou par e-mail.</li>
    </ul>
    <h2>3. Pourquoi, et sur quelle base</h2>
    <ul>
      <li><strong>Pour fournir le service</strong> (exécution du contrat) : créer votre compte, vous y connecter, garder vos trackers et les synchroniser entre vos appareils, vous donner Premium quand vous l'achetez, et vous envoyer les e-mails du service (code de réinitialisation, confirmation de suppression).</li>
      <li><strong>Pour protéger le service</strong> (intérêt légitime) : limiter les abus et pouvoir constater une attaque.</li>
      <li><strong>Pour améliorer l'app</strong> (intérêt légitime) : les événements produit et les statistiques d'usage de la section 7, la mesure d'audience du site de la section 6, et la mesure des ventes.</li>
      <li><strong>Pour vous répondre</strong> (intérêt légitime) quand vous nous écrivez.</li>
    </ul>
    <p>Nous ne <strong>vendons pas</strong> vos données et ne les utilisons pas à des fins de profilage. Nous n'envoyons aucun e-mail publicitaire.</p>
    <h2>4. À qui vos données sont confiées</h2>
    <p>Personne d'autre que nous ne lit vos données. Ces sociétés les hébergent ou les transportent pour notre compte :</p>
    <ul>
      <li><strong>Vultr :</strong> le serveur, en France.</li>
      <li><strong>Cloudflare :</strong> les sauvegardes de la base, chiffrées avant de quitter notre serveur et stockées dans l'Union européenne ; et l'acheminement des e-mails que vous nous écrivez.</li>
      <li><strong>Resend :</strong> l'envoi de nos e-mails. Resend reçoit votre adresse et le contenu de l'e-mail, et les garde 30 jours.</li>
      <li><strong>RevenueCat :</strong> le suivi des achats. RevenueCat reçoit l'identifiant de votre compte, vos reçus d'achat et des informations techniques sur votre appareil, jamais votre adresse e-mail.</li>
      <li><strong>Microsoft :</strong> la boîte où arrivent les messages que vous nous écrivez.</li>
    </ul>
    <p>Resend et RevenueCat sont aux États-Unis : ces transferts sont encadrés par les clauses contractuelles types de la Commission européenne.</p>
    <p><strong>Apple et Google</strong> traitent pour leur propre compte ce que vous leur confiez : la connexion par leur service, si vous la choisissez, et vos achats (App Store ou Google Play, selon votre appareil). Voir la <a href="https://www.apple.com/legal/privacy/" target="_blank">Politique de confidentialité d'Apple</a> et la <a href="https://policies.google.com/privacy" target="_blank">Politique de confidentialité de Google</a>.</p>
    <p>Nous n'utilisons <strong>aucun outil d'analyse tiers</strong> ni script de suivi. En dehors de ces sociétés et de la publicité décrite en section 8, vos données ne sont communiquées à personne.</p>
    <h2>5. Cookies</h2>
    <p>Nous utilisons des cookies pour deux choses seulement : <strong>l'authentification</strong> (jetons de session) et, si vous refusez la mesure d'audience du site, retenir ce choix (<code>dd_noaudience</code>, gardé 13 mois). Aucun cookie de suivi ou publicitaire n'est utilisé sur le site web.</p>
    <h2>6. Mesure d'audience du site</h2>
    <p>Nous comptons nous-mêmes les visites de ce site, pour savoir combien de personnes viennent, depuis quel site, et combien touchent un bouton vers un store. Cette mesure n'utilise <strong>aucun cookie ni outil tiers</strong>. Le site ne charge rien chez un tiers : ses polices et ses images viennent de notre serveur.</p>
    <ul>
      <li><strong>Ce qui est compté :</strong> les affichages de la page et les clics vers les stores, par jour, avec le site d'où vous venez (son nom de domaine seulement, tel que votre navigateur le donne ou que le lien suivi le désigne), le fait que ce lien portait ou non un marquage de campagne (pas le marquage lui-même), le type d'appareil et de navigateur, la langue de la page et le pays.</li>
      <li><strong>Ce qui n'est pas gardé :</strong> votre adresse IP et l'identification complète de votre navigateur ne sont jamais écrites nulle part. Elles servent à trouver le pays et, mêlées à une valeur tirée au hasard qui change chaque jour, à distinguer les visiteurs d'une même journée ; ce mélange reste dans la mémoire du serveur jusqu'à la fin de la journée au plus tard. Rien n'est relié à un compte, et aucun visiteur ne peut être suivi d'un jour à l'autre.</li>
      <li><strong>Combien de temps :</strong> les comptes par jour sont gardés 25 mois au plus ; ensuite il ne reste que des totaux par mois.</li>
      <li><strong>Où :</strong> sur notre serveur, en France, et dans les sauvegardes chiffrées de sa base de données. Ces chiffres ne servent qu'à Dian Dian et ne sont jamais partagés.</li>
    </ul>
    <p>Vous pouvez <a href="/privacy/audience?lang=fr">refuser d'être compté</a>. Si votre navigateur envoie le signal « Global Privacy Control » ou « Do Not Track », vous n'êtes pas compté du tout. Le pays est trouvé avec la base <a href="https://db-ip.com" target="_blank" rel="noopener">IP Geolocation by DB-IP</a>.</p>
    <h2 id="events">7. Événements produit et statistiques d'usage</h2>
    <p>Pour savoir où l'app arrête ses utilisateurs, elle nous signale quelques événements, liés à votre compte.</p>
    <ul>
      <li><strong>Ce qui est signalé :</strong> le nom d'un écran ou d'une action (aujourd'hui : l'affichage d'une limite de la version gratuite), la plateforme (iOS, Android), la version de l'app et la date. Jamais le contenu de vos trackers.</li>
      <li><strong>Pourquoi :</strong> régler les limites de la version gratuite et corriger ce qui gêne.</li>
      <li><strong>Combien de temps :</strong> 13 mois au plus, puis ils sont effacés. Ils sont effacés avec votre compte si vous le supprimez.</li>
      <li><strong>Pour qui :</strong> Dian Dian seulement. Ils ne sont jamais partagés.</li>
      <li><strong>Vous y opposer :</strong> écrivez-nous à <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>. Nous arrêtons alors de les enregistrer pour votre compte et effaçons ceux déjà reçus.</li>
    </ul>
    <p>Nous calculons aussi des statistiques sur l'ensemble des comptes (nombre de comptes, de trackers, de jours remplis, titres de trackers les plus fréquents) pour décider de l'évolution de l'app. Elles ne décrivent personne en particulier.</p>
    <h2>8. Publicité</h2>
    <p>La version gratuite de l'application affiche des bannières publicitaires via <strong>Google AdMob</strong>. AdMob peut collecter des identifiants d'appareil et des données d'utilisation, que Google traite pour son propre compte conformément à la <a href="https://policies.google.com/privacy" target="_blank">Politique de confidentialité de Google</a>. Les utilisateurs Premium ne voient pas de publicités.</p>
    <h2>9. Stockage et sécurité</h2>
    <p>Vos données sont stockées sur notre serveur, hébergé par Vultr en France. Les mots de passe sont hachés avec Argon2. Toutes les connexions sont chiffrées via HTTPS. La base est sauvegardée chaque jour ; les sauvegardes sont chiffrées, stockées dans l'Union européenne et gardées 30 jours. L'app garde aussi sur votre téléphone une copie complète de votre compte (tous vos trackers, jours coloriés, légendes et commentaires, de toutes les années), et les modifications faites hors ligne jusqu'à ce qu'elles atteignent notre serveur. Elle est effacée quand vous vous déconnectez ; si notre serveur ferme votre session, elle reste sur le téléphone, cachée, jusqu'à ce que vous vous reconnectiez à ce compte (se connecter à un autre l'efface). Comme le reste des données de l'app, elle peut être incluse dans les sauvegardes de votre téléphone (iCloud, Google).</p>
    <h2>10. Conservation et suppression</h2>
    <ul>
      <li><strong>Compte et contenu :</strong> tant que votre compte existe. Vous pouvez <strong>supprimer votre compte et toutes vos données</strong> à tout moment depuis l'application (« Supprimer mes données » pour un compte créé sans adresse, « Supprimer mon compte et mes données » sinon) ; la suppression est immédiate. Ensuite, l'identifiant d'un compte supprimé (rien d'autre) est gardé 24 mois, pour qu'une clé ou une copie restaurée sur un téléphone ne le fasse pas revivre.</li>
      <li><strong>Sauvegardes :</strong> 30 jours. Un compte supprimé a donc disparu des sauvegardes 30 jours plus tard.</li>
      <li><strong>Synchronisation hors ligne :</strong> les modifications qu'un téléphone envoie, avec notre réponse, 90 jours (pour qu'une modification envoyée deux fois ne soit jamais appliquée deux fois) ; la trace d'un tracker, d'une légende ou d'un jour supprimés (son identifiant, rien de son contenu), 24 mois ; les deux partent avec votre compte. À la suppression d'un compte, quand son mot de passe change ou que ses autres appareils sont déconnectés, une empreinte des jetons des sessions fermées, avec la raison et sans lien avec un compte, est gardée 548 jours pour que ces téléphones sachent pourquoi.</li>
      <li><strong>Événements produit :</strong> 13 mois au plus.</li>
      <li><strong>Mesure d'audience du site :</strong> les comptes par jour pendant 25 mois au plus, puis seulement des totaux par mois.</li>
      <li><strong>Journal du serveur :</strong> l'adresse IP d'une connexion ou d'un jeton de session refusés y reste 6 mois au plus.</li>
      <li><strong>Messages que vous nous écrivez :</strong> 3 ans au plus après le dernier échange.</li>
      <li><strong>Achats :</strong> tant que votre compte existe. Un abonnement continue de se renouveler tant que vous ne l'annulez pas chez Apple ou Google, même après la suppression de votre compte : les événements d'achat qui nous parviennent alors sont gardés 13 mois au plus, sans lien avec un compte. Apple, Google et RevenueCat gardent leur propre historique de vos achats, selon leurs règles.</li>
    </ul>
    <h2>11. Vos droits</h2>
    <p>Vous pouvez accéder à vos données, les faire corriger ou effacer, en recevoir une copie, en faire limiter le traitement, et vous opposer aux traitements fondés sur notre intérêt légitime (sections 6 et 7). Écrivez-nous à <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a> : nous répondons sous un mois. Si notre réponse ne vous convient pas, vous pouvez saisir la <a href="https://www.cnil.fr/fr/plaintes" target="_blank" rel="noopener">CNIL</a> ou l'autorité de protection des données de votre pays.</p>
    <h2>12. Modifications</h2>
    <p>Nous pouvons mettre à jour cette politique. Les changements importants seront communiqués par e-mail.</p>
    <h2>13. Contact</h2>
    <p>Questions ? <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  'zh-CN': `
    <h1>隐私政策</h1>
    <p class="subtitle">最后更新：${updatedOn('zh-CN')}</p>
    <h2>1. 简介</h2>
    <p>点点由 OVERRIDE 公司（SASU，注册资本1欧元，SIREN 953 122 868）发布，该公司是您数据的控制者。本隐私政策说明我们处理哪些数据、为什么处理、交给谁保管以及保留多久。如有疑问，请联系 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>。</p>
    <h2>2. 我们处理的数据</h2>
    <ul>
      <li><strong>账户：</strong>您的电子邮箱；如果您设置了密码，我们只保存其哈希值（密码本身从不保存）。如果您使用 Apple 或 Google 登录，我们只保存您的电子邮箱以及该服务为您提供的一个标识符，不保存您个人资料中的其他内容。</li>
      <li><strong>无邮箱的账户：</strong>如果您不使用账户直接开始，我们会创建一个无需电子邮箱、也没有密码的账户。它由您的手机生成并保存在其安全存储中的密钥重新打开；我们只保存它的指纹，从不保存密钥本身。对于所有账户，我们还会保存应用最后一次联系该账户的日期。</li>
      <li><strong>追踪器内容：</strong>您创建的追踪器、上色的日期、图例和备注。记录什么由您决定。</li>
      <li><strong>设置：</strong>您选择的主题、语言和光标。</li>
      <li><strong>购买：</strong>所购方案、应用商店、日期、价格和商店所在的国家/地区，是否为试用或测试购买，订阅结束的原因，以及商店的交易标识符。我们无法获取您的支付信息。</li>
      <li><strong>产品事件：</strong>见第 7 节。</li>
      <li><strong>技术数据：</strong>您的 IP 地址用于限制滥用（在内存中统计 15 分钟），并在登录或会话令牌被拒绝时写入服务器日志。</li>
      <li><strong>消息：</strong>您通过联系表单或电子邮件写给我们的内容。</li>
    </ul>
    <h2>3. 处理目的与依据</h2>
    <ul>
      <li><strong>提供服务</strong>（履行合同）：创建账户、登录、保存您的追踪器并在您的设备间同步、在您购买后提供高级版，以及发送服务邮件（重置验证码、删除确认）。</li>
      <li><strong>保护服务</strong>（正当利益）：限制滥用并能够发现攻击。</li>
      <li><strong>改进应用</strong>（正当利益）：第 7 节所述的产品事件和使用统计、第 6 节所述的网站访问统计，以及销售统计。</li>
      <li><strong>回复您</strong>（正当利益）：当您写信给我们时。</li>
    </ul>
    <p>我们<strong>不会</strong>出售您的数据或将其用于用户画像，也不发送任何广告邮件。</p>
    <h2>4. 数据交给谁保管</h2>
    <p>除我们之外，没有人会查看您的数据。以下公司代我们托管或传输数据：</p>
    <ul>
      <li><strong>Vultr：</strong>服务器，位于法国。</li>
      <li><strong>Cloudflare：</strong>数据库备份（离开我们的服务器前已加密，存储在欧盟境内）；以及转发您写给我们的电子邮件。</li>
      <li><strong>Resend：</strong>发送我们的电子邮件。Resend 会收到您的邮箱地址和邮件内容，并保留 30 天。</li>
      <li><strong>RevenueCat：</strong>跟踪购买状态。RevenueCat 会收到您的账户标识符、购买凭证以及您设备的技术信息，绝不会收到您的电子邮箱。</li>
      <li><strong>Microsoft：</strong>接收您写给我们的消息的邮箱。</li>
    </ul>
    <p>Resend 和 RevenueCat 位于美国：这些数据传输受欧盟委员会标准合同条款的约束。</p>
    <p><strong>Apple 和 Google</strong> 自行负责处理您交给它们的数据：通过它们登录（如果您选择这样做），以及您的购买（App Store 或 Google Play，取决于您的设备）。请参阅 <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple 隐私政策</a>和 <a href="https://policies.google.com/privacy" target="_blank">Google 隐私政策</a>。</p>
    <p>我们<strong>不使用任何第三方分析工具</strong>或追踪脚本。除上述公司和第 8 节所述的广告外，您的数据不会提供给任何人。</p>
    <h2>5. Cookie</h2>
    <p>我们仅将 Cookie 用于两个用途：<strong>身份验证</strong>（会话令牌），以及在您拒绝网站访问统计时记住该选择（<code>dd_noaudience</code>，保留 13 个月）。网站上不使用追踪或广告 Cookie。</p>
    <h2>6. 网站访问统计</h2>
    <p>我们自行统计本网站的访问量，以了解有多少人访问、来自哪个网站，以及有多少人点击了应用商店按钮。此统计<strong>不使用任何 Cookie 或第三方工具</strong>。本网站不从任何第三方加载内容：字体和图片均来自我们自己的服务器。</p>
    <ul>
      <li><strong>统计内容：</strong>每天的页面浏览次数和应用商店按钮点击次数，以及来源网站（仅域名，由您的浏览器提供或由您点击的链接指明）、该链接是否带有推广标记（不记录标记本身）、设备和浏览器类型、页面语言和国家/地区。</li>
      <li><strong>不保留的内容：</strong>您的 IP 地址和浏览器的完整标识不会被写入任何地方。它们用于确定国家/地区，并与一个每天更换的随机值混合后，用于区分同一天的访客；该混合值最迟在当天结束时从服务器内存中清除。任何数据都不会与账户关联，也无法跨天追踪任何访客。</li>
      <li><strong>保留期限：</strong>每日统计最多保留 25 个月，之后仅保留每月总数。</li>
      <li><strong>存储位置：</strong>我们位于法国的服务器，以及其数据库的加密备份。这些数据仅供点点使用，绝不与他人分享。</li>
    </ul>
    <p>您可以<a href="/privacy/audience?lang=zh-CN">拒绝被统计</a>。如果您的浏览器发送“Global Privacy Control”或“Do Not Track”信号，您将完全不被统计。国家/地区查询使用 <a href="https://db-ip.com" target="_blank" rel="noopener">IP Geolocation by DB-IP</a> 数据库。</p>
    <h2 id="events">7. 产品事件与使用统计</h2>
    <p>为了解应用在哪些地方让用户受阻，应用会向我们报告少量与您账户关联的事件。</p>
    <ul>
      <li><strong>报告的内容：</strong>某个界面或操作的名称（目前为：显示免费版的某项限制）、平台（iOS、Android）、应用版本和日期。绝不包含您追踪器的内容。</li>
      <li><strong>目的：</strong>调整免费版的限制，并修复造成阻碍的问题。</li>
      <li><strong>保留期限：</strong>最多 13 个月，之后删除。如果您删除账户，它们会随账户一并删除。</li>
      <li><strong>接收方：</strong>仅限点点，绝不与他人分享。</li>
      <li><strong>提出反对：</strong>请写信至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>。我们将停止为您的账户记录这些事件，并删除已收到的事件。</li>
    </ul>
    <p>我们还会对全体账户进行统计（账户数、追踪器数、已填写的天数、最常见的追踪器标题），以决定应用的发展方向。这些统计不描述任何特定个人。</p>
    <h2>8. 广告</h2>
    <p>免费版应用通过 <strong>Google AdMob</strong> 显示横幅广告。AdMob 可能收集设备标识符和使用数据，由 Google 根据 <a href="https://policies.google.com/privacy" target="_blank">Google 隐私政策</a>自行处理。高级用户不会看到广告。</p>
    <h2>9. 数据存储与安全</h2>
    <p>您的数据存储在我们位于法国、由 Vultr 托管的服务器上。密码使用 Argon2 进行哈希处理。所有连接通过 HTTPS 加密。数据库每天备份；备份经过加密，存储在欧盟境内，保留 30 天。应用还会在您的手机上保存您账户的完整副本（所有年份的全部追踪器、上色的日期、图例和备注），以及离线时所做、尚未送达我们服务器的更改。您退出登录时它会被删除；如果我们的服务器关闭了您的会话，它会隐藏保留在手机上，直到您重新登录该账户（登录其他账户则会删除它）。与应用的其他数据一样，它可能包含在您手机的备份中（iCloud、Google）。</p>
    <h2>10. 数据保留与删除</h2>
    <ul>
      <li><strong>账户和内容：</strong>账户存在期间一直保留。您可以随时从应用中<strong>删除账户和所有数据</strong>（未使用邮箱创建的账户为“删除我的数据”，其他为“删除我的账号和数据”），删除立即生效。删除后，已删除账户的标识符（仅此而已）保留 24 个月，以免手机上的密钥或恢复的副本让它重新出现。</li>
      <li><strong>备份：</strong>30 天。因此，已删除的账户会在 30 天后从备份中消失。</li>
      <li><strong>离线同步：</strong>手机发送的更改及我们的答复保留 90 天（以免同一更改被应用两次）；已删除的追踪器、图例或日期的痕迹（仅其标识符，不含任何内容）保留 24 个月；两者都会随账户一起删除。账户删除、密码更改或其他设备被退出时，被关闭会话的令牌指纹连同原因（不与任何账户关联）保留 548 天，以便这些手机得知原因。</li>
      <li><strong>产品事件：</strong>最多 13 个月。</li>
      <li><strong>网站访问统计：</strong>每日统计最多保留 25 个月，之后仅保留每月总数。</li>
      <li><strong>服务器日志：</strong>登录或会话令牌被拒绝时记录的 IP 地址最多保留 6 个月。</li>
      <li><strong>您写给我们的消息：</strong>最后一次往来后最多 3 年。</li>
      <li><strong>购买：</strong>账户存在期间一直保留。即使您删除了账户，应用商店的订阅仍会续订，直到您在 Apple 或 Google 处取消：届时我们收到的购买事件最多保留 13 个月，不与任何账户关联。Apple、Google 和 RevenueCat 会按各自的规则保留它们自己的购买记录。</li>
    </ul>
    <h2>11. 您的权利</h2>
    <p>您可以查阅、更正或删除您的数据，获取其副本，要求限制处理，并反对基于我们正当利益的处理（第 6 节和第 7 节）。请写信至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>：我们会在一个月内答复。如果您对我们的答复不满意，可以向法国数据保护机构 <a href="https://www.cnil.fr/fr/plaintes" target="_blank" rel="noopener">CNIL</a> 或您所在国家/地区的数据保护机构投诉。</p>
    <h2>12. 变更</h2>
    <p>我们可能会更新本政策。重大变更将通过电子邮件通知。</p>
    <h2>13. 联系</h2>
    <p>有问题？<a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  'zh-TW': `
    <h1>隱私權政策</h1>
    <p class="subtitle">最後更新：${updatedOn('zh-TW')}</p>
    <h2>1. 簡介</h2>
    <p>點點由 OVERRIDE 公司（SASU，註冊資本1歐元，SIREN 953 122 868）發布，該公司是您資料的控管者。本隱私權政策說明我們處理哪些資料、為什麼處理、交給誰保管以及保留多久。如有疑問，請聯繫 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>。</p>
    <h2>2. 我們處理的資料</h2>
    <ul>
      <li><strong>帳戶：</strong>您的電子郵件；如果您設定了密碼，我們只儲存其雜湊值（密碼本身從不儲存）。如果您使用 Apple 或 Google 登入，我們只儲存您的電子郵件以及該服務為您提供的一個識別碼，不儲存您個人檔案中的其他內容。</li>
      <li><strong>無電子郵件的帳戶：</strong>如果您不使用帳戶直接開始，我們會建立一個無需電子郵件、也沒有密碼的帳戶。它由您的手機產生並存放在其安全儲存空間中的金鑰重新開啟；我們只儲存它的指紋，從不儲存金鑰本身。對於所有帳戶，我們也會儲存 App 最後一次聯繫該帳戶的日期。</li>
      <li><strong>追蹤器內容：</strong>您建立的追蹤器、上色的日期、圖例和備註。記錄什麼由您決定。</li>
      <li><strong>設定：</strong>您選擇的主題、語言和游標。</li>
      <li><strong>購買：</strong>所購方案、應用程式商店、日期、價格和商店所在的國家/地區，是否為試用或測試購買，訂閱結束的原因，以及商店的交易識別碼。我們無法取得您的付款資訊。</li>
      <li><strong>產品事件：</strong>見第 7 節。</li>
      <li><strong>技術資料：</strong>您的 IP 位址用於限制濫用（在記憶體中統計 15 分鐘），並在登入或工作階段權杖被拒絕時寫入伺服器日誌。</li>
      <li><strong>訊息：</strong>您透過聯絡表單或電子郵件寫給我們的內容。</li>
    </ul>
    <h2>3. 處理目的與依據</h2>
    <ul>
      <li><strong>提供服務</strong>（履行契約）：建立帳戶、登入、儲存您的追蹤器並在您的裝置間同步、在您購買後提供進階版，以及寄送服務郵件（重設驗證碼、刪除確認）。</li>
      <li><strong>保護服務</strong>（正當利益）：限制濫用並能夠發現攻擊。</li>
      <li><strong>改進應用程式</strong>（正當利益）：第 7 節所述的產品事件和使用統計、第 6 節所述的網站流量統計，以及銷售統計。</li>
      <li><strong>回覆您</strong>（正當利益）：當您寫信給我們時。</li>
    </ul>
    <p>我們<strong>不會</strong>出售您的資料，也不會用它建立您的個人側寫；我們不寄送任何廣告郵件。</p>
    <h2>4. 資料交給誰保管</h2>
    <p>除我們之外，沒有人會查看您的資料。以下公司代我們託管或傳輸資料：</p>
    <ul>
      <li><strong>Vultr：</strong>伺服器，位於法國。</li>
      <li><strong>Cloudflare：</strong>資料庫備份（離開我們的伺服器前已加密，儲存在歐盟境內）；以及轉寄您寫給我們的電子郵件。</li>
      <li><strong>Resend：</strong>寄送我們的電子郵件。Resend 會收到您的郵件地址和郵件內容，並保留 30 天。</li>
      <li><strong>RevenueCat：</strong>追蹤購買狀態。RevenueCat 會收到您的帳戶識別碼、購買憑證以及您裝置的技術資訊，絕不會收到您的電子郵件。</li>
      <li><strong>Microsoft：</strong>接收您寫給我們的訊息的信箱。</li>
    </ul>
    <p>Resend 和 RevenueCat 位於美國：這些資料傳輸受歐盟執委會標準契約條款的約束。</p>
    <p><strong>Apple 和 Google</strong> 自行負責處理您交給它們的資料：透過它們登入（如果您選擇這樣做），以及您的購買（App Store 或 Google Play，取決於您的裝置）。請參閱 <a href="https://www.apple.com/legal/privacy/" target="_blank">Apple 隱私權政策</a>和 <a href="https://policies.google.com/privacy" target="_blank">Google 隱私權政策</a>。</p>
    <p>我們<strong>不使用任何第三方分析工具</strong>或追蹤指令碼。除上述公司和第 8 節所述的廣告外，您的資料不會提供給任何人。</p>
    <h2>5. Cookie</h2>
    <p>我們僅將 Cookie 用於兩個用途：<strong>身分驗證</strong>（工作階段權杖），以及在您拒絕網站流量統計時記住該選擇（<code>dd_noaudience</code>，保留 13 個月）。網站上不使用追蹤或廣告 Cookie。</p>
    <h2>6. 網站流量統計</h2>
    <p>我們自行統計本網站的造訪次數，以了解有多少人造訪、來自哪個網站，以及有多少人點擊了應用程式商店按鈕。此統計<strong>不使用任何 Cookie 或第三方工具</strong>。本網站不從任何第三方載入內容：字型和圖片均來自我們自己的伺服器。</p>
    <ul>
      <li><strong>統計內容：</strong>每天的頁面瀏覽次數和應用程式商店按鈕點擊次數，以及來源網站（僅網域名稱，由您的瀏覽器提供或由您點擊的連結指明）、該連結是否帶有推廣標記（不記錄標記本身）、裝置和瀏覽器類型、頁面語言和國家/地區。</li>
      <li><strong>不保留的內容：</strong>您的 IP 位址和瀏覽器的完整識別資訊不會被寫入任何地方。它們用於判斷國家/地區，並與一個每天更換的隨機值混合後，用於區分同一天的訪客；該混合值最遲在當天結束時從伺服器記憶體中清除。任何資料都不會與帳號關聯，也無法跨天追蹤任何訪客。</li>
      <li><strong>保留期限：</strong>每日統計最多保留 25 個月，之後僅保留每月總數。</li>
      <li><strong>儲存位置：</strong>我們位於法國的伺服器，以及其資料庫的加密備份。這些資料僅供點點使用，絕不與他人分享。</li>
    </ul>
    <p>您可以<a href="/privacy/audience?lang=zh-TW">拒絕被統計</a>。如果您的瀏覽器傳送「Global Privacy Control」或「Do Not Track」訊號，您將完全不被統計。國家/地區查詢使用 <a href="https://db-ip.com" target="_blank" rel="noopener">IP Geolocation by DB-IP</a> 資料庫。</p>
    <h2 id="events">7. 產品事件與使用統計</h2>
    <p>為了解應用程式在哪些地方讓使用者受阻，應用程式會向我們回報少量與您帳戶關聯的事件。</p>
    <ul>
      <li><strong>回報的內容：</strong>某個畫面或操作的名稱（目前為：顯示免費版的某項限制）、平台（iOS、Android）、應用程式版本和日期。絕不包含您追蹤器的內容。</li>
      <li><strong>目的：</strong>調整免費版的限制，並修正造成阻礙的問題。</li>
      <li><strong>保留期限：</strong>最多 13 個月，之後刪除。如果您刪除帳戶，它們會隨帳戶一併刪除。</li>
      <li><strong>接收方：</strong>僅限點點，絕不與他人分享。</li>
      <li><strong>提出反對：</strong>請寫信至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>。我們將停止為您的帳戶記錄這些事件，並刪除已收到的事件。</li>
    </ul>
    <p>我們還會對全體帳戶進行統計（帳戶數、追蹤器數、已填寫的天數、最常見的追蹤器標題），以決定應用程式的發展方向。這些統計不描述任何特定個人。</p>
    <h2>8. 廣告</h2>
    <p>免費版應用程式透過 <strong>Google AdMob</strong> 顯示橫幅廣告。AdMob 可能收集裝置識別碼和使用資料，由 Google 根據 <a href="https://policies.google.com/privacy" target="_blank">Google 隱私權政策</a>自行處理。進階使用者不會看到廣告。</p>
    <h2>9. 資料儲存與安全</h2>
    <p>您的資料儲存在我們位於法國、由 Vultr 託管的伺服器上。密碼使用 Argon2 進行雜湊處理。所有連線透過 HTTPS 加密。資料庫每天備份；備份經過加密，儲存在歐盟境內，保留 30 天。應用程式還會在您的手機上儲存您帳戶的完整副本（所有年份的全部追蹤器、上色的日期、圖例和備註），以及離線時所做、尚未送達我們伺服器的變更。您登出時它會被刪除；如果我們的伺服器關閉了您的工作階段，它會隱藏保留在手機上，直到您重新登入該帳戶（登入其他帳戶則會刪除它）。與應用程式的其他資料一樣，它可能包含在您手機的備份中（iCloud、Google）。</p>
    <h2>10. 資料保留與刪除</h2>
    <ul>
      <li><strong>帳戶和內容：</strong>帳戶存在期間一直保留。您可以隨時從應用程式中<strong>刪除帳戶和所有資料</strong>（未使用電子郵件建立的帳戶為「刪除我的資料」，其他為「刪除我的帳號和資料」），刪除立即生效。刪除後，已刪除帳戶的識別碼（僅此而已）保留 24 個月，以免手機上的金鑰或還原的副本讓它重新出現。</li>
      <li><strong>備份：</strong>30 天。因此，已刪除的帳戶會在 30 天後從備份中消失。</li>
      <li><strong>離線同步：</strong>手機傳送的變更及我們的答覆保留 90 天（以免同一變更被套用兩次）；已刪除的追蹤器、圖例或日期的痕跡（僅其識別碼，不含任何內容）保留 24 個月；兩者都會隨帳戶一起刪除。帳戶刪除、密碼變更或其他裝置被登出時，被關閉工作階段的權杖指紋連同原因（不與任何帳戶關聯）保留 548 天，以便這些手機得知原因。</li>
      <li><strong>產品事件：</strong>最多 13 個月。</li>
      <li><strong>網站流量統計：</strong>每日統計最多保留 25 個月，之後僅保留每月總數。</li>
      <li><strong>伺服器日誌：</strong>登入或工作階段權杖被拒絕時記錄的 IP 位址最多保留 6 個月。</li>
      <li><strong>您寫給我們的訊息：</strong>最後一次往來後最多 3 年。</li>
      <li><strong>購買：</strong>帳戶存在期間一直保留。即使您刪除了帳戶，應用程式商店的訂閱仍會續訂，直到您在 Apple 或 Google 處取消：屆時我們收到的購買事件最多保留 13 個月，不與任何帳戶關聯。Apple、Google 和 RevenueCat 會按各自的規則保留它們自己的購買紀錄。</li>
    </ul>
    <h2>11. 您的權利</h2>
    <p>您可以查閱、更正或刪除您的資料，取得其副本，要求限制處理，並反對基於我們正當利益的處理（第 6 節和第 7 節）。請寫信至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>：我們會在一個月內答覆。如果您對我們的答覆不滿意，可以向法國資料保護機關 <a href="https://www.cnil.fr/fr/plaintes" target="_blank" rel="noopener">CNIL</a> 或您所在國家/地區的資料保護機關申訴。</p>
    <h2>12. 變更</h2>
    <p>我們可能會更新本政策。重大變更將透過電子郵件通知。</p>
    <h2>13. 聯繫</h2>
    <p>有問題？<a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
};

// --- Audience measurement: the right to object -----------------------------
// The site counts its visits without a cookie (src/audience). Whoever does not
// want to be counted says so here: a cookie then records the choice, and the
// counter leaves its bearer out. A browser that sends Global Privacy Control
// or Do Not Track is left out already, with nothing to do.
const optOut = {
  title: { en: 'Audience measurement', fr: "Mesure d'audience", 'zh-CN': '访问统计', 'zh-TW': '流量統計' },
  intro: {
    en: 'This website counts its visits without cookies and without keeping your IP address (see the <a href="/privacy?lang=en">privacy policy</a>). You can ask not to be counted at all.',
    fr: 'Ce site compte ses visites sans cookie et sans garder votre adresse IP (voir la <a href="/privacy?lang=fr">politique de confidentialité</a>). Vous pouvez demander à ne pas être compté du tout.',
    'zh-CN': '本网站统计访问量时不使用 Cookie，也不保留您的 IP 地址（参见<a href="/privacy?lang=zh-CN">隐私政策</a>）。您可以要求完全不被统计。',
    'zh-TW': '本網站統計造訪次數時不使用 Cookie，也不保留您的 IP 位址（參見<a href="/privacy?lang=zh-TW">隱私權政策</a>）。您可以要求完全不被統計。',
  },
  counted: { en: 'Your visits are counted.', fr: 'Vos visites sont comptées.', 'zh-CN': '目前您的访问会被统计。', 'zh-TW': '目前您的造訪會被統計。' },
  notCounted: {
    en: 'Your visits are not counted. A cookie on this device remembers your choice for 13 months.',
    fr: 'Vos visites ne sont pas comptées. Un cookie sur cet appareil retient votre choix pendant 13 mois.',
    'zh-CN': '您的访问不会被统计。本设备上的一个 Cookie 会将您的选择保留 13 个月。',
    'zh-TW': '您的造訪不會被統計。本裝置上的一個 Cookie 會將您的選擇保留 13 個月。',
  },
  signal: {
    en: 'Your browser asks not to be tracked (Global Privacy Control or Do Not Track): your visits are not counted, and there is nothing to do.',
    fr: "Votre navigateur demande à ne pas être suivi (Global Privacy Control ou Do Not Track) : vos visites ne sont pas comptées, et il n'y a rien à faire.",
    'zh-CN': '您的浏览器已要求不被追踪（Global Privacy Control 或 Do Not Track）：您的访问不会被统计，无需任何操作。',
    'zh-TW': '您的瀏覽器已要求不被追蹤（Global Privacy Control 或 Do Not Track）：您的造訪不會被統計，無需任何操作。',
  },
  stop: { en: 'Do not count my visits', fr: 'Ne plus compter mes visites', 'zh-CN': '不再统计我的访问', 'zh-TW': '不再統計我的造訪' },
  resume: { en: 'Count my visits again', fr: 'Compter à nouveau mes visites', 'zh-CN': '重新统计我的访问', 'zh-TW': '重新統計我的造訪' },
};

// 13 months: the lifetime the CNIL's guidelines give an audience tracker. The
// refusal is remembered as long.
const OPT_OUT_MAX_AGE_MS = 395 * 24 * 60 * 60 * 1000;
const optOutCookie = (req: Request) => ({ httpOnly: true, sameSite: 'lax' as const, secure: req.secure, path: '/' });

function fromThisSite(req: Request): boolean {
  const fetchSite = req.get('sec-fetch-site');
  if (fetchSite !== undefined) return fetchSite === 'same-origin';
  const origin = req.get('origin');
  if (origin === undefined) return true; // neither header: not a browser a page could have steered
  try {
    return new URL(origin).host === req.get('host');
  } catch {
    return false; // `null`, or anything that is not an origin
  }
}

router.get('/privacy/audience', (req, res) => {
  const lang = detectLang(req);
  const why = objection(req);
  const button = (choice: 'out' | 'in', label: string) => `
    <form method="post" action="/privacy/audience?lang=${lang}" style="margin-top:20px;text-align:center;">
      <input type="hidden" name="choice" value="${choice}" />
      <button type="submit" style="padding:12px 28px;background:#d8e8c8;border:2px solid #b0c8a0;border-radius:10px;color:#708060;font:inherit;font-weight:600;cursor:pointer;">${label}</button>
    </form>`;
  const state = why === 'signal'
    ? `<p><strong>${optOut.signal[lang]}</strong></p>`
    : why === 'cookie'
      ? `<p><strong>${optOut.notCounted[lang]}</strong></p>${button('in', optOut.resume[lang])}`
      : `<p><strong>${optOut.counted[lang]}</strong></p>${button('out', optOut.stop[lang])}`;
  // The page depends on the visitor's cookie and browser: never cached.
  res.set('Cache-Control', 'no-store');
  // Under the site's `no-referrer`, a browser sends `Origin: null` with the
  // form below, and the handler could not know the request is this page's.
  res.set('Referrer-Policy', 'same-origin');
  res.type('html').send(layout(optOut.title[lang], `<h1>${optOut.title[lang]}</h1>
    <p>${optOut.intro[lang]}</p>
    ${state}`, lang));
});

router.post('/privacy/audience', express.urlencoded({ extended: false, limit: '1kb' }), (req, res) => {
  // Only this site's own page may make the choice: a form on another site
  // must not be able to opt a visitor back in, or out. Browsers say where a
  // request comes from in Sec-Fetch-Site, which a page cannot forge: when it
  // is there it is what is believed (Origin may be `null` even for our own
  // form). A browser too old to send it has its Origin compared instead.
  if (!fromThisSite(req)) {
    res.status(403).type('text').send('Forbidden');
    return;
  }
  const choice = (req.body as { choice?: unknown } | undefined)?.choice;
  if (choice === 'out') res.cookie(OPT_OUT_COOKIE, '1', { ...optOutCookie(req), maxAge: OPT_OUT_MAX_AGE_MS });
  else if (choice === 'in') res.clearCookie(OPT_OUT_COOKIE, optOutCookie(req));
  else {
    res.status(400).type('text').send('Bad request');
    return;
  }
  res.redirect(303, `/privacy/audience?lang=${detectLang(req)}`);
});

router.get('/privacy', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(titles.privacy[lang], privacy[lang], lang));
});

// ── Terms of Use ──

const terms: Record<Lang, string> = {
  en: `
    <h1>Terms of Use</h1>
    <p class="subtitle">Last updated: March 26, 2026</p>
    <h2>1. Acceptance</h2>
    <p>By using Dian Dian ("the Service"), you agree to these Terms. If you do not agree, please do not use the Service.</p>
    <h2>2. Your Account</h2>
    <ul>
      <li>You are responsible for keeping your credentials secure.</li>
      <li>You are responsible for all activity under your account.</li>
      <li>Notify us immediately if you suspect unauthorized access.</li>
    </ul>
    <h2>3. Your Content</h2>
    <p>All tracker data and content you create <strong>belongs to you</strong>. We do not claim ownership.</p>
    <h2>4. Acceptable Use</h2>
    <p>You agree <strong>not</strong> to: use the Service unlawfully, attempt unauthorized access, disrupt the Service, automate access without permission, or harass others.</p>
    <h2>5. Service Availability</h2>
    <p>The Service is provided <strong>"as is"</strong> without warranties. We do not guarantee uninterrupted or error-free access.</p>
    <h2>6. Limitation of Liability</h2>
    <p>To the fullest extent permitted by law, we shall not be liable for any indirect, incidental, or consequential damages.</p>
    <h2>7. Account Termination</h2>
    <p>You may delete your account at any time. We may suspend accounts that violate these Terms.</p>
    <h2>8. Changes</h2>
    <p>We may update these Terms. Material changes will be communicated via email.</p>
    <h2>9. Contact</h2>
    <p>Questions? <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  fr: `
    <h1>Conditions d'utilisation</h1>
    <p class="subtitle">Dernière mise à jour : 26 mars 2026</p>
    <h2>1. Acceptation</h2>
    <p>En utilisant Dian Dian (« le Service »), vous acceptez ces Conditions. Si vous n'êtes pas d'accord, veuillez ne pas utiliser le Service.</p>
    <h2>2. Votre compte</h2>
    <ul>
      <li>Vous êtes responsable de la sécurité de vos identifiants.</li>
      <li>Vous êtes responsable de toute activité sur votre compte.</li>
      <li>Prévenez-nous immédiatement en cas d'accès non autorisé.</li>
    </ul>
    <h2>3. Votre contenu</h2>
    <p>Toutes les données et le contenu que vous créez <strong>vous appartiennent</strong>. Nous ne revendiquons aucun droit de propriété.</p>
    <h2>4. Utilisation acceptable</h2>
    <p>Vous vous engagez à <strong>ne pas</strong> : utiliser le Service illégalement, tenter un accès non autorisé, perturber le Service, automatiser l'accès sans permission, ou harceler d'autres utilisateurs.</p>
    <h2>5. Disponibilité du service</h2>
    <p>Le Service est fourni <strong>« tel quel »</strong> sans garantie. Nous ne garantissons pas un accès ininterrompu ou sans erreur.</p>
    <h2>6. Limitation de responsabilité</h2>
    <p>Dans les limites permises par la loi, nous ne serons pas responsables des dommages indirects, accessoires ou consécutifs.</p>
    <h2>7. Résiliation de compte</h2>
    <p>Vous pouvez supprimer votre compte à tout moment. Nous pouvons suspendre les comptes qui violent ces Conditions.</p>
    <h2>8. Modifications</h2>
    <p>Nous pouvons mettre à jour ces Conditions. Les changements importants seront communiqués par email.</p>
    <h2>9. Contact</h2>
    <p>Questions ? <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  'zh-CN': `
    <h1>使用条款</h1>
    <p class="subtitle">最后更新：2026年3月26日</p>
    <h2>1. 接受条款</h2>
    <p>使用点点（"本服务"）即表示您同意这些条款。如不同意，请勿使用本服务。</p>
    <h2>2. 您的账户</h2>
    <ul>
      <li>您有责任保管好登录凭证的安全。</li>
      <li>您对账户下的所有活动负责。</li>
      <li>如怀疑未经授权的访问，请立即通知我们。</li>
    </ul>
    <h2>3. 您的内容</h2>
    <p>您创建的所有追踪数据和内容<strong>归您所有</strong>。我们不主张所有权。</p>
    <h2>4. 合理使用</h2>
    <p>您同意<strong>不会</strong>：非法使用服务、尝试未经授权的访问、干扰服务、未经许可自动化访问或骚扰他人。</p>
    <h2>5. 服务可用性</h2>
    <p>服务按<strong>"现状"</strong>提供，不附带任何保证。我们不保证服务不间断或无错误。</p>
    <h2>6. 责任限制</h2>
    <p>在法律允许的最大范围内，我们不对任何间接、附带或后果性损害承担责任。</p>
    <h2>7. 账户终止</h2>
    <p>您可以随时删除账户。我们可能会暂停违反这些条款的账户。</p>
    <h2>8. 变更</h2>
    <p>我们可能会更新这些条款。重大变更将通过电子邮件通知。</p>
    <h2>9. 联系</h2>
    <p>有问题？<a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
  'zh-TW': `
    <h1>使用條款</h1>
    <p class="subtitle">最後更新：2026年3月26日</p>
    <h2>1. 接受條款</h2>
    <p>使用點點（「本服務」）即表示您同意這些條款。如不同意，請勿使用本服務。</p>
    <h2>2. 您的帳戶</h2>
    <ul>
      <li>您有責任保管好登入憑證的安全。</li>
      <li>您對帳戶下的所有活動負責。</li>
      <li>如懷疑未經授權的存取，請立即通知我們。</li>
    </ul>
    <h2>3. 您的內容</h2>
    <p>您建立的所有追蹤資料和內容<strong>歸您所有</strong>。我們不主張所有權。</p>
    <h2>4. 合理使用</h2>
    <p>您同意<strong>不會</strong>：非法使用服務、嘗試未經授權的存取、干擾服務、未經許可自動化存取或騷擾他人。</p>
    <h2>5. 服務可用性</h2>
    <p>服務按<strong>「現狀」</strong>提供，不附帶任何保證。我們不保證服務不間斷或無錯誤。</p>
    <h2>6. 責任限制</h2>
    <p>在法律允許的最大範圍內，我們不對任何間接、附帶或後果性損害承擔責任。</p>
    <h2>7. 帳戶終止</h2>
    <p>您可以隨時刪除帳戶。我們可能會暫停違反這些條款的帳戶。</p>
    <h2>8. 變更</h2>
    <p>我們可能會更新這些條款。重大變更將透過電子郵件通知。</p>
    <h2>9. 聯繫</h2>
    <p>有問題？<a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></p>`,
};

router.get('/terms', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(titles.terms[lang], terms[lang], lang));
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
  res.type('html').send(layout(titles.about[lang], about[lang], lang));
});

// ── Contact ──

function contactContent(lang: Lang): string {
  const t = {
    en: { title: 'Contact', sub: "An idea, a bug, a question? We'd love to hear from you.", name: 'Name', email: 'Email', message: 'Message', send: 'Send', sending: 'Sending…', sent: 'Thanks, your message is sent. We reply by email.', error: 'Could not send. Please try again, or write to', delay: 'As a solo indie project, please allow up to <strong>48 hours</strong> for a response.' },
    fr: { title: 'Contact', sub: 'Une idée, un bug, une question ? Nous serions ravis de vous lire.', name: 'Nom', email: 'Email', message: 'Message', send: 'Envoyer', sending: 'Envoi…', sent: 'Merci, votre message est envoyé. Nous répondons par email.', error: "Envoi impossible. Réessayez, ou écrivez à", delay: 'En tant que projet indépendant, veuillez prévoir jusqu\'à <strong>48 heures</strong> pour une réponse.' },
    'zh-CN': { title: '联系我们', sub: '有想法、问题或遇到 bug？我们很想听到您的意见。', name: '姓名', email: '邮箱', message: '留言', send: '发送', sending: '发送中…', sent: '已发送，谢谢。我们会通过邮件回复。', error: '发送失败。请重试，或写信至', delay: '作为独立开发项目，请允许最多 <strong>48 小时</strong> 的回复时间。' },
    'zh-TW': { title: '聯繫我們', sub: '有想法、問題或遇到 bug？我們很想聽到您的意見。', name: '姓名', email: '信箱', message: '留言', send: '傳送', sending: '傳送中…', sent: '已傳送，謝謝。我們會透過電子郵件回覆。', error: '傳送失敗。請重試，或寫信至', delay: '作為獨立開發專案，請允許最多 <strong>48 小時</strong> 的回覆時間。' },
  }[lang];
  const field = 'width:100%;box-sizing:border-box;padding:10px 12px;border:1px solid #d0c8b0;border-radius:8px;background:#fffdf8;font:inherit;color:#4e4c60;';
  return `
    <h1>${t.title}</h1>
    <p class="subtitle">${t.sub}</p>

    <form id="contact-form" style="max-width:520px;margin:24px auto 0;display:grid;gap:12px;" data-sent="${t.sent}" data-error="${t.error}" data-sending="${t.sending}" data-send="${t.send}">
      <label style="display:grid;gap:4px;font-size:14px;">${t.name}<input name="name" required maxlength="80" autocomplete="name" style="${field}"></label>
      <label style="display:grid;gap:4px;font-size:14px;">${t.email}<input name="email" type="email" required maxlength="120" autocomplete="email" autocapitalize="off" spellcheck="false" style="${field}"></label>
      <label style="display:grid;gap:4px;font-size:14px;">${t.message}<textarea name="message" required maxlength="2000" rows="6" style="${field}resize:vertical;"></textarea></label>
      <button type="submit" style="justify-self:center;padding:12px 28px;background:#d8e8c8;border:2px solid #b0c8a0;border-radius:10px;color:#708060;font:inherit;font-weight:600;cursor:pointer;">${t.send}</button>
      <p id="contact-status" role="status" aria-live="polite" style="text-align:center;min-height:1.4em;margin:0;font-size:14px;"></p>
    </form>

    <p style="text-align:center;margin-top:16px;font-size:14px;">
      <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>
    </p>
    <p style="font-size:13px;color:#a0855b;margin-top:12px;text-align:center;">${t.delay}</p>

    <script>
      (function () {
        var form = document.getElementById('contact-form');
        var status = document.getElementById('contact-status');
        var button = form.querySelector('button');
        form.addEventListener('submit', function (e) {
          e.preventDefault();
          status.textContent = form.dataset.sending;
          button.disabled = true;
          fetch('/api/contact', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: form.name.value, email: form.email.value, message: form.message.value }),
          }).then(function (r) {
            if (!r.ok) throw new Error(String(r.status));
            status.textContent = form.dataset.sent;
            form.reset();
          }).catch(function () {
            status.textContent = form.dataset.error + ' contact@diandian.overridedev.com';
          }).then(function () { button.disabled = false; });
        });
      })();
    </script>`;
}

router.get('/contact', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(titles.contact[lang], contactContent(lang), lang));
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
      <li><strong>Contact:</strong> <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></li>
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
      <li><strong>Contact :</strong> <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></li>
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
      <li><strong>联系方式：</strong><a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></li>
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
      <li><strong>聯繫方式：</strong><a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a></li>
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
  res.type('html').send(layout(titles.legal[lang], legal[lang], lang));
});

// ── Account & data deletion (required by Google Play) ──

const deleteAccount: Record<Lang, string> = {
  en: `
    <h1>Delete your account &amp; data</h1>
    <p class="subtitle">Dian Dian (点点) — published by OVERRIDE</p>
    <h2>1. Delete your entire account</h2>
    <p>You can permanently delete your account and all associated data directly in the app:</p>
    <ul>
      <li>Open <strong>Settings</strong> (the gear icon at the top-right of the home screen).</li>
      <li>Tap <strong>Delete account</strong>.</li>
      <li>Confirm by typing your email address.</li>
    </ul>
    <p>Deletion is immediate and permanent.</p>
    <p><strong>Deleting your account does not cancel a subscription.</strong> Cancel it first in your App Store or Google Play subscription settings, or it will keep renewing.</p>
    <h2>2. Delete only part of your data</h2>
    <p>You do not have to delete your whole account to remove data:</p>
    <ul>
      <li>Delete any single tracker, day cell or legend at any time from within the app.</li>
      <li>Or email us at <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a> and we will handle your request.</li>
    </ul>
    <h2>3. What is deleted</h2>
    <p>Deleting your account <strong>immediately and permanently</strong> removes:</p>
    <ul>
      <li>Your account and email address</li>
      <li>All of your trackers, day cells, colors, legends and comments</li>
      <li>Your subscription records stored on our servers</li>
    </ul>
    <p>The deletion reaches our entire database at once.</p>
    <h2>4. What may be retained</h2>
    <ul>
      <li><strong>Backups:</strong> the encrypted backups of our database are kept 30 days. Your data is gone from them 30 days after the deletion.</li>
      <li><strong>Server log:</strong> it may hold the IP address of a refused sign-in or session token for 6 months at most. That line does not name your account.</li>
      <li><strong>Purchases:</strong> the record of your purchases stays with Apple or Google, and with RevenueCat, the service that keeps track of purchases for us (under your account's identifier, never your email address), under their own rules.</li>
      <li><strong>Purchase events:</strong> if a subscription keeps renewing after the deletion, the events the store sends us are kept 13 months at most, linked to no account.</li>
      <li><strong>Emails:</strong> the emails we sent you (reset codes, the deletion confirmation) stay 30 days with Resend, our email service.</li>
    </ul>
    <h2>5. Need help?</h2>
    <p>If you cannot access the app, contact <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a> and we will delete your account for you.</p>`,
  fr: `
    <h1>Supprimer votre compte et vos données</h1>
    <p class="subtitle">Dian Dian (点点) — édité par OVERRIDE</p>
    <h2>1. Supprimer entièrement votre compte</h2>
    <p>Vous pouvez supprimer définitivement votre compte et toutes les données associées directement dans l'application :</p>
    <ul>
      <li>Ouvrez les <strong>Réglages</strong> (icône engrenage, en haut à droite de l'écran d'accueil).</li>
      <li>Touchez <strong>Supprimer le compte</strong>.</li>
      <li>Confirmez en saisissant votre adresse e-mail.</li>
    </ul>
    <p>La suppression est immédiate et définitive.</p>
    <p><strong>Supprimer votre compte n'annule pas un abonnement.</strong> Annulez-le d'abord dans les réglages d'abonnement de l'App Store ou de Google Play, sinon il continuera de se renouveler.</p>
    <h2>2. Supprimer seulement une partie de vos données</h2>
    <p>Vous n'êtes pas obligé de supprimer tout votre compte pour effacer des données :</p>
    <ul>
      <li>Supprimez à tout moment un tracker, une journée ou une légende depuis l'application.</li>
      <li>Ou écrivez-nous à <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a> et nous traiterons votre demande.</li>
    </ul>
    <h2>3. Ce qui est supprimé</h2>
    <p>La suppression de votre compte efface <strong>immédiatement et définitivement</strong> :</p>
    <ul>
      <li>Votre compte et votre adresse e-mail</li>
      <li>Tous vos trackers, cellules, couleurs, légendes et commentaires</li>
      <li>Vos enregistrements d'abonnement stockés sur nos serveurs</li>
    </ul>
    <p>La suppression se propage aussitôt à toute notre base de données.</p>
    <h2>4. Ce qui peut être conservé</h2>
    <ul>
      <li><strong>Sauvegardes :</strong> les sauvegardes chiffrées de notre base sont gardées 30 jours. Vos données en ont disparu 30 jours après la suppression.</li>
      <li><strong>Journal du serveur :</strong> il peut garder l'adresse IP d'une connexion ou d'un jeton de session refusés 6 mois au plus. Cette ligne ne nomme pas votre compte.</li>
      <li><strong>Achats :</strong> l'historique de vos achats reste chez Apple ou Google, et chez RevenueCat, le service qui suit les achats pour nous (sous l'identifiant de votre compte, jamais votre adresse e-mail), selon leurs propres règles.</li>
      <li><strong>Événements d'achat :</strong> si un abonnement continue de se renouveler après la suppression, les événements que le store nous envoie sont gardés 13 mois au plus, sans lien avec un compte.</li>
      <li><strong>E-mails :</strong> les e-mails que nous vous avons envoyés (codes de réinitialisation, confirmation de suppression) restent 30 jours chez Resend, notre service d'envoi.</li>
    </ul>
    <h2>5. Besoin d'aide ?</h2>
    <p>Si vous ne pouvez pas accéder à l'application, contactez <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a> et nous supprimerons votre compte pour vous.</p>`,
  'zh-CN': `
    <h1>删除您的账户和数据</h1>
    <p class="subtitle">点点 (Dian Dian) — 由 OVERRIDE 发布</p>
    <h2>1. 删除整个账户</h2>
    <p>您可以直接在应用中永久删除您的账户及所有相关数据：</p>
    <ul>
      <li>打开<strong>设置</strong>（主屏幕右上角的齿轮图标）。</li>
      <li>点击<strong>删除账户</strong>。</li>
      <li>输入您的电子邮箱以确认。</li>
    </ul>
    <p>删除是即时且永久的。</p>
    <p><strong>删除账户不会取消订阅。</strong>请先在 App Store 或 Google Play 的订阅设置中取消，否则订阅会继续续订。</p>
    <h2>2. 仅删除部分数据</h2>
    <p>您无需删除整个账户即可移除数据：</p>
    <ul>
      <li>随时在应用中删除任意单个追踪器、某一天或图例。</li>
      <li>或发送邮件至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>，我们将处理您的请求。</li>
    </ul>
    <h2>3. 删除的内容</h2>
    <p>删除账户会<strong>即时且永久</strong>移除：</p>
    <ul>
      <li>您的账户和电子邮箱</li>
      <li>您所有的追踪器、格子、颜色、图例和备注</li>
      <li>存储在我们服务器上的订阅记录</li>
    </ul>
    <p>删除操作会立即级联至整个数据库。</p>
    <h2>4. 可能保留的内容</h2>
    <ul>
      <li><strong>备份：</strong>数据库的加密备份保留 30 天。删除 30 天后，您的数据将从备份中消失。</li>
      <li><strong>服务器日志：</strong>可能会保留登录或会话令牌被拒绝时的 IP 地址，最多 6 个月。该记录不会指明您的账户。</li>
      <li><strong>购买：</strong>您的购买记录由 Apple 或 Google，以及代我们跟踪购买状态的服务 RevenueCat（仅使用您的账户标识符，绝不使用您的电子邮箱）按各自的规则保留。</li>
      <li><strong>购买事件：</strong>如果删除后订阅仍在续订，应用商店发给我们的事件最多保留 13 个月，不与任何账户关联。</li>
      <li><strong>电子邮件：</strong>我们发给您的电子邮件（重置验证码、删除确认）会在我们的邮件服务 Resend 处保留 30 天。</li>
    </ul>
    <h2>5. 需要帮助？</h2>
    <p>如果您无法访问应用，请联系 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>，我们将为您删除账户。</p>`,
  'zh-TW': `
    <h1>刪除您的帳戶和資料</h1>
    <p class="subtitle">點點 (Dian Dian) — 由 OVERRIDE 發布</p>
    <h2>1. 刪除整個帳戶</h2>
    <p>您可以直接在應用程式中永久刪除您的帳戶及所有相關資料：</p>
    <ul>
      <li>開啟<strong>設定</strong>（主畫面右上角的齒輪圖示）。</li>
      <li>點擊<strong>刪除帳戶</strong>。</li>
      <li>輸入您的電子郵件以確認。</li>
    </ul>
    <p>刪除是即時且永久的。</p>
    <p><strong>刪除帳戶不會取消訂閱。</strong>請先在 App Store 或 Google Play 的訂閱設定中取消，否則訂閱會繼續續訂。</p>
    <h2>2. 僅刪除部分資料</h2>
    <p>您無需刪除整個帳戶即可移除資料：</p>
    <ul>
      <li>隨時在應用程式中刪除任意單個追蹤器、某一天或圖例。</li>
      <li>或發送郵件至 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>，我們將處理您的請求。</li>
    </ul>
    <h2>3. 刪除的內容</h2>
    <p>刪除帳戶會<strong>即時且永久</strong>移除：</p>
    <ul>
      <li>您的帳戶和電子郵件</li>
      <li>您所有的追蹤器、格子、顏色、圖例和備註</li>
      <li>儲存在我們伺服器上的訂閱紀錄</li>
    </ul>
    <p>刪除操作會立即級聯至整個資料庫。</p>
    <h2>4. 可能保留的內容</h2>
    <ul>
      <li><strong>備份：</strong>資料庫的加密備份保留 30 天。刪除 30 天後，您的資料將從備份中消失。</li>
      <li><strong>伺服器日誌：</strong>可能會保留登入或工作階段權杖被拒絕時的 IP 位址，最多 6 個月。該紀錄不會指明您的帳戶。</li>
      <li><strong>購買：</strong>您的購買紀錄由 Apple 或 Google，以及代我們追蹤購買狀態的服務 RevenueCat（僅使用您的帳戶識別碼，絕不使用您的電子郵件）按各自的規則保留。</li>
      <li><strong>購買事件：</strong>如果刪除後訂閱仍在續訂，應用程式商店寄給我們的事件最多保留 13 個月，不與任何帳戶關聯。</li>
      <li><strong>電子郵件：</strong>我們寄給您的電子郵件（重設驗證碼、刪除確認）會在我們的郵件服務 Resend 處保留 30 天。</li>
    </ul>
    <h2>5. 需要協助？</h2>
    <p>如果您無法存取應用程式，請聯繫 <a href="mailto:contact@diandian.overridedev.com">contact@diandian.overridedev.com</a>，我們將為您刪除帳戶。</p>`,
};

router.get('/delete-account', (req, res) => {
  const lang = detectLang(req);
  res.type('html').send(layout(titles.deleteAccount[lang], deleteAccount[lang], lang));
});

export default router;
