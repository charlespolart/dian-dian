/**
 * Whether a server or a database is on this machine: `localhost`,
 * `127.0.0.1` or `::1`. The smoke suite (scripts/smoke.ts) posts made-up
 * purchases and writes to the database it reads: it does so only when both
 * are here, whatever its environment variables say.
 *
 * When in doubt the answer is no, and the suite skips those checks: a URL
 * that cannot be read, that names no host, or a database address its client
 * reads differently from a URL parser.
 *
 * What no address can tell: `localhost:<port>` may be the near end of an SSH
 * tunnel or of a published port. A local server and a DATABASE_URL that both
 * go through one to another machine pass every check here. Do not run the
 * suite with a tunnel to production open.
 */
import postgres from 'postgres';

const LOOPBACK = new Set(['localhost', '127.0.0.1', '::1', '[::1]']);

export function isLoopbackHost(host: string): boolean {
  return LOOPBACK.has(host.toLowerCase());
}

/** For the address of an HTTP server. */
export function isLoopbackUrl(url: string | undefined): boolean {
  if (!url) return false;
  try {
    return isLoopbackHost(new URL(url).hostname);
  } catch {
    return false;
  }
}

/**
 * For a database address, judged by the hosts its client will connect to
 * rather than by a URL parser: with several hosts
 * (`postgres://a@elsewhere,b@localhost/db`) the two disagree, and the client
 * goes to the first. Every host must be here. No connection is opened.
 */
export function isLoopbackDatabase(url: string | undefined): boolean {
  if (!url) return false; // the client would fall back on PGHOST and its defaults
  try {
    const hosts = postgres(url, { max: 1 }).options.host;
    return hosts.length > 0 && hosts.every(isLoopbackHost);
  } catch {
    return false;
  }
}
