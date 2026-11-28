import { isIPv6 } from 'node:net';

/**
 * The network a request comes from, for a per-address limit. An IPv4
 * address counts alone; an IPv6 address counts by its /56, the smallest
 * prefix providers hand a customer — otherwise every address of one home
 * would be a fresh budget (chantier 9, case 63).
 */
export function addressKey(ip: string | undefined): string {
  if (!ip) return 'unknown';
  const mapped = /^::ffff:(\d{1,3}(?:\.\d{1,3}){3})$/i.exec(ip);
  if (mapped) return mapped[1];
  const bare = ip.split('%')[0];
  if (!isIPv6(bare)) return ip;
  const [head, tail] = bare.toLowerCase().split('::');
  const groupsOf = (part: string | undefined): string[] => {
    if (!part) return [];
    const groups = part.split(':');
    const last = groups[groups.length - 1];
    if (last.includes('.')) {
      // An IPv4 tail (64:ff9b::192.0.2.33) is the last two groups.
      const [a, b, c, d] = last.split('.').map(Number);
      groups.splice(groups.length - 1, 1, ((a << 8) | b).toString(16), ((c << 8) | d).toString(16));
    }
    return groups;
  };
  const before = groupsOf(head);
  const after = tail === undefined ? [] : groupsOf(tail);
  const groups = tail === undefined ? before : [...before, ...Array(8 - before.length - after.length).fill('0'), ...after];
  const g = groups.map((x) => parseInt(x, 16));
  return `${g[0].toString(16)}:${g[1].toString(16)}:${g[2].toString(16)}:${(g[3] & 0xff00).toString(16)}::/56`;
}
