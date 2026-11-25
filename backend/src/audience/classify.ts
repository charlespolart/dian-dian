/**
 * What kind of client a User-Agent describes: a class of device, a family
 * of browser, and the app whose built-in browser it is. Classes only: no
 * version, no model, nothing that tells one visitor from another. The
 * User-Agent itself is never kept.
 *
 * Robots are another question (bots.ts), asked first by the caller.
 */
export type Device = 'iphone' | 'ipad' | 'android' | 'desktop' | 'other';
export type Browser = 'safari' | 'chrome' | 'firefox' | 'edge' | 'samsung' | 'opera' | 'other';
export type InApp = 'pinterest' | 'instagram' | 'facebook' | 'tiktok' | '';
export type Client = { device: Device; browser: Browser; inApp: InApp };

/** A User-Agent is read up to here: real ones are shorter, and no expression ever sees a longer string. */
const MAX_LENGTH = 512;

function inAppOf(ua: string): InApp {
  // The app's built-in browser, not Pinterest's crawler (`Pinterest/0.2`, `Pinterestbot`).
  if (/\[Pinterest\/(iOS|Android)\]/i.test(ua)) return 'pinterest';
  if (/\bInstagram \d/.test(ua)) return 'instagram';
  if (/\bFBAN\/|\bFBAV\/|\bFB_IAB\//.test(ua)) return 'facebook';
  if (/BytedanceWebview|musical_ly|\btrill_\d|\bTikTok\b/i.test(ua)) return 'tiktok';
  return '';
}

function deviceOf(ua: string): Device {
  // Android first: no Android User-Agent names an Apple device (as in lib/storePlatform.ts).
  if (/\bAndroid\b/i.test(ua)) return 'android';
  if (/\b(iPhone|iPod)\b/.test(ua)) return 'iphone';
  if (/\biPad\b/.test(ua)) return 'ipad';
  // An iPad in its default desktop mode says it is a Mac: it counts as one.
  if (/\b(Windows NT|Macintosh|X11|CrOS)\b/.test(ua)) return 'desktop';
  return 'other';
}

function browserOf(ua: string): Browser {
  // Most browsers also say Chrome and Safari: the most specific name first.
  if (/\b(Edg|EdgA|EdgiOS)\//.test(ua)) return 'edge';
  if (/\b(OPR|OPiOS)\//.test(ua)) return 'opera';
  if (/\bSamsungBrowser\//.test(ua)) return 'samsung';
  if (/\b(Firefox|FxiOS)\//.test(ua)) return 'firefox';
  if (/\b(Chrome|CriOS)\//.test(ua)) return 'chrome';
  if (/\bVersion\/[\d.]+ .*Safari\//.test(ua)) return 'safari';
  return 'other';
}

export function classifyClient(userAgent: string | undefined): Client {
  const ua = (userAgent ?? '').slice(0, MAX_LENGTH);
  const inApp = inAppOf(ua);
  // Inside an app the web view says Safari or Chrome, which says nothing: the app is the answer.
  return { device: deviceOf(ua), browser: inApp === '' ? browserOf(ua) : 'other', inApp };
}
