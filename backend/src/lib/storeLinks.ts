/**
 * The links to the stores, with the campaign a visitor arrived with.
 *
 * A visitor arriving with ?utm_source=pinterest&utm_campaign=mood-en (our
 * pins, posts…) leaves for the store with it:
 *   - Google Play: `referrer=utm_source%3D…%26utm_campaign%3D…` → Play
 *     Console → Acquisition, down to the pin;
 *   - App Store: `pt=<provider token>&ct=<source>&mt=8` → App Store Connect →
 *     Analytics → Sources. One `ct` per SOURCE, not per pin: Apple only shows
 *     a campaign name from 5 first downloads within 24 hours of the tap, and
 *     a name per pin kept every one of them under that. The provider token
 *     is per developer account (App Store Connect → Analytics → Campaigns →
 *     "Generate campaign link"); without it the App Store link stays plain.
 *
 * Nothing of this is stored: the values are relayed, cleaned, to the store.
 */
export const APP_STORE_URL = 'https://apps.apple.com/app/id6761432329';
export const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=app.mydiandian';

export type StoreLinks = { apple: string; play: string };
/** A request's query: only `utm_source` and `utm_campaign` are read. */
type Query = Record<string, unknown>;

/** Lower case, letters, digits, `_` and `-` only: safe in a URL and in HTML. */
export function campaignParam(value: unknown, max: number): string {
  return String(value ?? '').slice(0, max).replace(/[^a-zA-Z0-9_-]/g, '').toLowerCase();
}

export function storeLinks(query: Query, applePt: string): StoreLinks {
  const source = campaignParam(query.utm_source, 40);
  if (!source) return { apple: APP_STORE_URL, play: PLAY_STORE_URL };
  const campaign = campaignParam(query.utm_campaign, 60);
  const referrer = encodeURIComponent(`utm_source=${source}${campaign ? `&utm_campaign=${campaign}` : ''}`);
  return {
    apple: applePt ? `${APP_STORE_URL}?pt=${encodeURIComponent(applePt)}&ct=${source}&mt=8` : APP_STORE_URL,
    play: `${PLAY_STORE_URL}&referrer=${referrer}`,
  };
}

/** What the site's own store buttons (`/go/apple`, `/go/play`) carry: '' or `?utm_source=…[&utm_campaign=…]`. */
export function campaignQuery(query: Query): string {
  const source = campaignParam(query.utm_source, 40);
  if (!source) return '';
  const campaign = campaignParam(query.utm_campaign, 60);
  return `?utm_source=${source}${campaign ? `&utm_campaign=${campaign}` : ''}`;
}
