/**
 * The audience counter of a site: visits, visitors of the day, taps on the
 * store buttons, where people come from and which robots pass — without a
 * measurement cookie, without a third-party script, and without keeping an
 * IP address, a User-Agent or a `utm_*` value. The database receives counts.
 *
 * Self-contained: it depends on the host application only through the
 * database handle given to `startAudience` and through its `AudienceConfig`.
 * Design: docs/superpowers/specs/2026-11-23-landing-visits-design.md.
 *
 * Whoever objects is not counted at all: the opt-out cookie, or a browser
 * that sends Global Privacy Control or Do Not Track. That is checked before
 * anything else of the request is read.
 */
import { randomBytes } from 'node:crypto';
import type { db as database } from '../db/index.js';
import { detectBot } from './bots.js';
import { classifyClient } from './classify.js';
import { createCounter, rollUpOldDays, writeBatch, type Hit } from './counter.js';
import { createCountries } from './country.js';
import { createIpRanges, type BotCheck } from './ipRanges.js';
import { originOf } from './origin.js';
import { createVisitors } from './visitors.js';

export type AudienceConfig = {
  /** The site's own host: part of the visitor fingerprint, and never an origin. */
  domain: string;
  /** Cleaned `utm_source` → the site it names (see origin.ts). */
  knownSites: Record<string, string>;
  /** Read a known `utm_source` as the site of origin when there is no Referer. */
  tagFallback: boolean;
};

/** What the counter reads of a request; an Express `Request` fits. */
export type AudienceRequest = {
  method: string;
  ip: string | undefined;
  headers: Record<string, string | string[] | undefined>;
  query: Record<string, unknown>;
  cookies?: Record<string, string>;
};

/** Set to '1' at the visitor's request (the opt-out page): they are no longer counted. */
export const OPT_OUT_COOKIE = 'dd_noaudience';

export type Audience = {
  /** A view of the page. Never throws. */
  visit(req: AudienceRequest, lang: string): void;
  /** A tap on a store button. Never throws. */
  storeTap(req: AudienceRequest, store: 'apple' | 'play', lang: string): void;
  /** Whether this visitor objects to being counted. */
  objects(req: AudienceRequest): boolean;
};

const first = (value: string | string[] | undefined): string | undefined => (Array.isArray(value) ? value[0] : value);

/** A browser fetching the page ahead of a visit that may never happen, or to draw a preview. */
function isPrefetch(headers: AudienceRequest['headers']): boolean {
  return /prefetch|prerender/i.test(first(headers['sec-purpose']) ?? '')
    || /prefetch|preview/i.test(first(headers.purpose) ?? '')
    || /prefetch/i.test(first(headers['x-moz']) ?? '')
    || /preview/i.test(first(headers['x-purpose']) ?? '');
}

const NOBODY = { origin: '', originFrom: '', tagged: false, device: '', browser: '', inApp: '', lang: '', country: '' } as const;

export function createAudience(config: AudienceConfig, deps: {
  counter: { add(hit: Hit, newVisitor: boolean): void };
  visitors: { isNew(domain: string, ip: string, userAgent: string): boolean };
  ipRanges: { check(ranges: string | null, ip: string | undefined): BotCheck };
  countries: { countryOf(ip: string | undefined): string };
}): Audience {
  function objects(req: AudienceRequest): boolean {
    return req?.cookies?.[OPT_OUT_COOKIE] === '1' || first(req?.headers?.['sec-gpc']) === '1' || first(req?.headers?.dnt) === '1';
  }

  function record(req: AudienceRequest, kind: Hit['kind'], store: Hit['store'], lang: string): void {
    try {
      if (req.method !== 'GET' || objects(req) || isPrefetch(req.headers)) return;
      const userAgent = first(req.headers['user-agent']);

      const bot = detectBot(userAgent, first(req.headers['signature-agent']));
      if (bot !== null) {
        // A robot: who it says it is and whether its address agrees. Nothing else.
        deps.counter.add({ ...NOBODY, kind, store, botFamily: bot.family, botName: bot.name, botCheck: deps.ipRanges.check(bot.ranges, req.ip) }, false);
        return;
      }

      const client = classifyClient(userAgent);
      const origin = originOf({
        // A store button is reached from the site's own page: its Referer says nothing. The tag is relayed to it.
        referer: kind === 'visit' ? first(req.headers.referer) : undefined,
        utmSource: req.query.utm_source,
        ownHost: config.domain,
        knownSites: config.knownSites,
        tagFallback: config.tagFallback,
      });
      const hit: Hit = {
        kind, store,
        origin: origin.site, originFrom: origin.from, tagged: origin.tagged,
        device: client.device, browser: client.browser, inApp: client.inApp,
        lang, country: deps.countries.countryOf(req.ip),
        botFamily: '', botName: '', botCheck: '',
      };
      deps.counter.add(hit, kind === 'visit' && deps.visitors.isNew(config.domain, req.ip ?? '', userAgent ?? ''));
    } catch {
      // Counting never costs the page: what cannot be counted is not.
    }
  }

  return {
    visit: (req, lang) => record(req, 'visit', '', lang),
    storeTap: (req, store, lang) => record(req, 'store_tap', store, lang),
    objects: (req) => {
      try {
        return objects(req);
      } catch {
        return false;
      }
    },
  };
}

const DAY = 24 * 60 * 60 * 1000;

/**
 * The counter, wired and running: counts written every 5 seconds, the
 * robots' IP ranges and the country database loaded now and looked at again
 * every day, days older than 25 months rolled up. Nothing here waits for the
 * network, and every timer lets the process exit.
 *
 * `downloads: false` (development, the release checks) loads nothing from
 * outside: countries are unknown and no robot is verified.
 */
export function startAudience(config: AudienceConfig & { downloads: boolean }, db: typeof database): Audience {
  const now = () => new Date();
  const counter = createCounter({ write: writeBatch(db), now });
  const ipRanges = createIpRanges({ fetch });
  const countries = createCountries({ fetch, now });

  const every = (ms: number, task: () => Promise<void>) => {
    const run = () => { task().catch((err) => console.error('Audience: background task failed:', err)); };
    setInterval(run, ms).unref();
    return run;
  };
  every(5_000, () => counter.flush());
  every(DAY, () => rollUpOldDays(db, now()))();
  if (config.downloads) {
    every(DAY, () => ipRanges.refresh())();
    every(DAY, () => countries.refresh())();
  }

  return createAudience(config, { counter, visitors: createVisitors({ now, randomBytes }), ipRanges, countries });
}
