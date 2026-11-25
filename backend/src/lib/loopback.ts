/**
 * Whether a URL — of a server or of a database — points at this machine:
 * `localhost`, `127.0.0.1` or `::1`. The smoke suite (scripts/smoke.ts)
 * posts made-up purchases and writes to the database it reads: it does so
 * only when both are here, whatever its environment variables say.
 *
 * A URL that cannot be read, or that names no host (a socket path), is not
 * loopback: when in doubt the suite skips those checks.
 */
const LOOPBACK = new Set(['localhost', '127.0.0.1', '[::1]']);

export function isLoopbackUrl(url: string | undefined): boolean {
  if (!url) return false;
  try {
    return LOOPBACK.has(new URL(url).hostname.toLowerCase());
  } catch {
    return false;
  }
}
