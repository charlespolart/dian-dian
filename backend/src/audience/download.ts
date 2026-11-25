/**
 * Fetches a file into memory, within a size and a time. The counter depends
 * on files other people publish (lists of IP ranges, the country database):
 * whatever goes wrong with one of them — no network, an error page, a body
 * that never ends — the answer is null, never an exception, and the caller
 * keeps what it had.
 */
export async function download(fetcher: typeof fetch, url: string, limits: { maxBytes: number; timeoutMs: number }): Promise<Buffer | null> {
  try {
    const res = await fetcher(url, { signal: AbortSignal.timeout(limits.timeoutMs) });
    if (!res.ok || res.body === null) return null;
    const reader = res.body.getReader();
    const chunks: Uint8Array[] = [];
    let size = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > limits.maxBytes) {
        await reader.cancel();
        return null;
      }
      chunks.push(value);
    }
    return Buffer.concat(chunks);
  } catch {
    return null;
  }
}

/** `::ffff:203.0.113.7`, an IPv4 address written as IPv6, is that IPv4 address. */
export function plainAddress(ip: string | undefined): string {
  return (ip ?? '').replace(/^::ffff:(?=\d+\.\d+\.\d+\.\d+$)/i, '');
}
