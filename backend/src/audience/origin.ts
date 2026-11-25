/**
 * Where a visitor comes from, within what the CNIL's audience-measurement
 * exemption allows: the site of origin as a bare domain name, and whether
 * the link carried a tag. Never the page of origin, never a `utm_*` value.
 *
 * When the browser sent no Referer (the ChatGPT apps almost never do), a
 * `utm_source` that is on a closed list of sites is read as that site's
 * domain — which says no more than a Referer would have. Any other value is
 * dropped; only "there was a tag" remains. `from` records which of the two
 * spoke, so the share of the fallback can be measured, and it can be turned
 * off (`tagFallback`).
 */
export type Origin = {
  /** A domain name, 'other' for a host that is not one, '' when unknown. */
  site: string;
  /** Read from the Referer header, or from a known `utm_source`. */
  from: 'referer' | 'tag' | '';
  /** A `utm_source` was present, whatever it said. */
  tagged: boolean;
};

/**
 * `utm_source` values, cleaned as the store links clean them (lower case,
 * letters, digits, `_` and `-` only — `chatgpt.com` arrives as `chatgptcom`),
 * and the site each one names.
 */
export const KNOWN_SITES: Record<string, string> = {
  pinterest: 'pinterest.com', pinterestcom: 'pinterest.com',
  chatgpt: 'chatgpt.com', chatgptcom: 'chatgpt.com', openai: 'chatgpt.com',
  perplexity: 'perplexity.ai', perplexityai: 'perplexity.ai',
  claude: 'claude.ai', claudeai: 'claude.ai',
  gemini: 'gemini.google.com', copilot: 'copilot.microsoft.com',
  google: 'google.com', googlecom: 'google.com',
  instagram: 'instagram.com', instagramcom: 'instagram.com',
  facebook: 'facebook.com', facebookcom: 'facebook.com', fb: 'facebook.com',
  tiktok: 'tiktok.com', tiktokcom: 'tiktok.com',
  youtube: 'youtube.com', youtubecom: 'youtube.com',
  reddit: 'reddit.com', redditcom: 'reddit.com',
  x: 'x.com', xcom: 'x.com', twitter: 'x.com', twittercom: 'x.com',
};

/** The same cleaning as `campaignParam` in routes/landing.ts. */
function cleanTag(value: unknown): string {
  return String(value ?? '').slice(0, 40).replace(/[^a-zA-Z0-9_-]/g, '').toLowerCase();
}

/** No browser sends a longer Referer; one that long is not read. */
const MAX_REFERER = 2048;
const DOMAIN = /^[a-z0-9-]+(\.[a-z0-9-]+)+$/;
const IPV4 = /^\d+(\.\d+){3}$/;

/** `www.`, and the hosts that only say "mobile" or "outgoing link" (Facebook's m., l., lm.). */
function bare(host: string): string {
  return host.toLowerCase().replace(/^(www|m|l|lm)\./, '');
}

/** The domain a Referer names; 'other' when its host is not a domain; null when it is not a web page. */
function refererSite(referer: string | undefined): string | null {
  if (!referer || referer.length > MAX_REFERER) return null;
  let url: URL;
  try {
    url = new URL(referer);
  } catch {
    return null;
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
  const host = bare(url.hostname);
  // Written by whoever sends the request: only what looks like a domain is kept as one.
  if (host.length > 60 || IPV4.test(host) || !DOMAIN.test(host)) return 'other';
  return host;
}

export function originOf(input: {
  referer: string | undefined;
  utmSource: unknown;
  ownHost: string;
  knownSites: Record<string, string>;
  tagFallback: boolean;
}): Origin {
  const tag = cleanTag(input.utmSource);
  const tagged = tag !== '';
  const site = refererSite(input.referer);
  // The site is never its own origin: its language links reload the page,
  // and the store redirections are reached from it.
  if (site !== null && site !== bare(input.ownHost)) return { site, from: 'referer', tagged };
  const known = input.tagFallback && typeof input.utmSource === 'string' && Object.hasOwn(input.knownSites, tag) ? input.knownSites[tag] : undefined;
  return known === undefined ? { site: '', from: '', tagged } : { site: known, from: 'tag', tagged };
}
