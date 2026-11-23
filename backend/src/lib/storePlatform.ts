/**
 * Which store buttons the landing shows, from the visitor's User-Agent: an
 * iPhone (or iPod, or an iPad that says so) gets the App Store only, an
 * Android device Google Play only. Anything we cannot tell — a computer, an
 * iPad in its default desktop mode (it reports a Mac), another system —
 * gets both buttons.
 *
 * In-app browsers (Pinterest, Instagram, TikTok…) keep the platform's token
 * in their User-Agent, so they are recognised like the system browser.
 */
export type StorePlatform = 'ios' | 'android' | 'unknown';

export function storePlatform(userAgent: string | undefined): StorePlatform {
  const ua = userAgent ?? '';
  // Android first: no Android User-Agent names an Apple device.
  if (/\bAndroid\b/i.test(ua)) return 'android';
  if (/\b(iPhone|iPad|iPod)\b/i.test(ua)) return 'ios';
  return 'unknown';
}
