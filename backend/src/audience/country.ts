/**
 * The country of a visitor, from the address — which is looked up and
 * dropped: only the two-letter code goes any further.
 *
 * The database is DB-IP's IP-to-Country Lite (CC BY 4.0, no account; the
 * licence asks for a link "IP Geolocation by DB-IP" on the pages that use
 * it — the site's footer carries it). One file a month, about 4 MB
 * compressed and 8 MB in memory. The server's image has no disk to keep it
 * on, so it is downloaded at start and held in memory, and asked for again
 * when the month changes. Until it is there, and whenever an address is not
 * in it, the country is unknown ('').
 */
import { isIP } from 'node:net';
import { promisify } from 'node:util';
import { gunzip } from 'node:zlib';
import { Reader } from 'maxmind';
import { download, plainAddress } from './download.js';

const unpack = promisify(gunzip);

const monthOf = (date: Date) => date.toISOString().slice(0, 7);

/** Where DB-IP publishes the file of the month `now` is in (UTC). */
export function countryDatabaseUrl(now: Date): string {
  return `https://download.db-ip.com/free/dbip-country-lite-${monthOf(now)}.mmdb.gz`;
}

type Database = { get(ip: string): unknown };

export function createCountries(deps: {
  fetch: typeof fetch;
  now: () => Date;
  /** Opens an unpacked database file; the default reads the MMDB format. Throws on a file it cannot read. */
  open?: (database: Buffer) => Database;
  warn?: (message: string) => void;
  /** The most a file may weigh, as sent and once unpacked. */
  maxBytes?: number;
}): {
  /** Loads the file of the month unless it is the one in service. A failure keeps what was loaded. Never throws. */
  refresh(): Promise<void>;
  /** 'FR', or '' when unknown. */
  countryOf(ip: string | undefined): string;
} {
  const open = deps.open ?? ((database: Buffer): Database => new Reader(database));
  const warn = deps.warn ?? ((message: string) => console.error(message));
  const maxBytes = deps.maxBytes ?? 64_000_000;
  let database: Database | null = null;
  let loaded = '';

  async function load(url: string): Promise<Database | null> {
    const packed = await download(deps.fetch, url, { maxBytes, timeoutMs: 60_000 });
    if (packed === null) return null;
    try {
      return open(await unpack(packed, { maxOutputLength: maxBytes }));
    } catch {
      return null; // cut short, not compressed, too large once unpacked, or not a database
    }
  }

  return {
    async refresh() {
      const now = deps.now();
      const wanted = countryDatabaseUrl(now);
      if (loaded === wanted) return;
      // On the first days of a month its file may not be out yet: last
      // month's will do, unless it is the one already in service.
      const before = countryDatabaseUrl(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1)));
      for (const url of loaded === before ? [wanted] : [wanted, before]) {
        const opened = await load(url);
        if (opened !== null) {
          database = opened;
          loaded = url;
          return;
        }
      }
      warn(`Audience: country database not loaded: ${wanted}`);
    },

    countryOf(ip) {
      const address = plainAddress(ip);
      if (database === null || isIP(address) === 0) return '';
      try {
        const code = (database.get(address) as { country?: { iso_code?: unknown } | null } | null)?.country?.iso_code;
        return typeof code === 'string' && /^[A-Za-z]{2}$/.test(code) ? code.toUpperCase() : '';
      } catch {
        return '';
      }
    },
  };
}
