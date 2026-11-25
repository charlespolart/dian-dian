/**
 * Does the address back the name? A robot is whatever its User-Agent says,
 * and the best-known names are the most imitated (ChatGPT-User first). The
 * operators that want to be recognised publish the IP ranges their robots
 * use, all in one JSON shape (`{ prefixes: [{ ipv4Prefix } | { ipv6Prefix }] }`);
 * they are loaded here into one `net.BlockList` each and reloaded every day.
 *
 * The address is only compared, then dropped by the caller: nothing here
 * keeps it. Sources and their sizes on 2026-11-23:
 * docs/research/notes/Mesure de trafic auto hébergée/robots_et_ia.md.
 */
import { BlockList, isIP } from 'node:net';
import { download, plainAddress } from './download.js';

export type BotCheck =
  | 'verified' // the address is in the operator's ranges
  | 'unverified' // it is not, or the ranges could not be loaded, or the address could not be read
  | 'unverifiable'; // the operator publishes no ranges

/** List name (what `Bot.ranges` holds, see bots.ts) → where its operator publishes it. */
export const RANGE_SOURCES: Record<string, string> = {
  'openai-chatgpt-user': 'https://openai.com/chatgpt-user.json',
  'openai-searchbot': 'https://openai.com/searchbot.json',
  'openai-gptbot': 'https://openai.com/gptbot.json',
  'openai-adsbot': 'https://openai.com/adsbot.json',
  anthropic: 'https://claude.com/crawling/bots.json',
  'perplexity-user': 'https://www.perplexity.ai/perplexity-user.json',
  perplexitybot: 'https://www.perplexity.ai/perplexitybot.json',
  'mistral-user': 'https://mistral.ai/mistralai-user-ips.json',
  'mistral-index': 'https://mistral.ai/mistralai-index-ips.json',
  duckduckgo: 'https://duckduckgo.com/duckassistbot.json',
  'google-user-triggered-agents': 'https://developers.google.com/static/crawling/ipranges/user-triggered-agents.json',
  'google-common-crawlers': 'https://developers.google.com/static/crawling/ipranges/common-crawlers.json',
  apple: 'https://search.developer.apple.com/applebot.json',
  commoncrawl: 'https://index.commoncrawl.org/ccbot.json',
};

/** The largest of these files is about 60 KB. */
const LIMITS = { maxBytes: 2_000_000, timeoutMs: 10_000 };

/** The ranges of a published file; null when it holds none that can be read. */
function rangesOf(body: Buffer): BlockList | null {
  let prefixes: unknown;
  try {
    prefixes = (JSON.parse(body.toString('utf8')) as { prefixes?: unknown } | null)?.prefixes;
  } catch {
    return null;
  }
  if (!Array.isArray(prefixes)) return null;
  const list = new BlockList();
  let added = 0;
  for (const entry of prefixes) {
    for (const [field, family] of [['ipv4Prefix', 'ipv4'], ['ipv6Prefix', 'ipv6']] as const) {
      const prefix = (entry as Record<string, unknown> | null)?.[field];
      if (typeof prefix !== 'string') continue;
      const [network, bits] = prefix.split('/');
      const length = Number(bits);
      // One unreadable line does not cost the file its other lines.
      if (isIP(network) !== (family === 'ipv4' ? 4 : 6) || !Number.isInteger(length) || length < 0 || length > (family === 'ipv4' ? 32 : 128)) continue;
      list.addSubnet(network, length, family);
      added++;
    }
  }
  return added === 0 ? null : list;
}

export function createIpRanges(deps: { fetch: typeof fetch; sources?: Record<string, string>; warn?: (message: string) => void }): {
  /** Reloads every list. One that fails keeps the version loaded before. Never throws. */
  refresh(): Promise<void>;
  check(ranges: string | null, ip: string | undefined): BotCheck;
} {
  const sources = deps.sources ?? RANGE_SOURCES;
  const warn = deps.warn ?? ((message: string) => console.error(message));
  const lists = new Map<string, BlockList>();

  return {
    async refresh() {
      await Promise.all(Object.entries(sources).map(async ([name, url]) => {
        const body = await download(deps.fetch, url, LIMITS);
        const list = body === null ? null : rangesOf(body);
        if (list === null) {
          warn(`Audience: IP ranges not loaded: ${name}`);
          return;
        }
        // Built aside, then swapped in: a check never sees half a list.
        lists.set(name, list);
      }));
    },

    check(ranges, ip) {
      if (ranges === null) return 'unverifiable';
      const list = lists.get(ranges);
      const address = plainAddress(ip);
      const family = isIP(address);
      if (list === undefined || family === 0) return 'unverified';
      return list.check(address, family === 4 ? 'ipv4' : 'ipv6') ? 'verified' : 'unverified';
    },
  };
}
