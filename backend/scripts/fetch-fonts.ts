/**
 * Brings the site's two fonts home: DotGothic16 and Silkscreen (SIL Open
 * Font License), served from `public/fonts/` instead of Google Fonts. Loaded
 * from Google, they gave it the IP address of every visitor of the site
 * (docs/REGISTRE.md).
 *
 * What it writes is committed; run it again only to change or update a font:
 *
 *   cd backend && npx tsx scripts/fetch-fonts.ts
 *
 * It asks Google for the stylesheet it serves to a current Chrome (woff2
 * files cut by `unicode-range`, so a browser only fetches the slices a page
 * uses), downloads every file that stylesheet names under its own name, and
 * writes the same stylesheet pointing at `/fonts/<name>`. Same files, same
 * rules as before: the pages render as they did. Nothing is written unless
 * everything was downloaded.
 */
import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';

const STYLESHEET = 'https://fonts.googleapis.com/css2?family=DotGothic16&family=Silkscreen:wght@400;700&display=swap';
const CHROME = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36';
// The licence asks that its text and the copyright notice travel with the fonts.
const LICENCES: Record<string, string> = {
  'OFL-DotGothic16.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/dotgothic16/OFL.txt',
  'OFL-Silkscreen.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/silkscreen/OFL.txt',
};
const MAX_BYTES = 6 * 1024 * 1024;
const out = new URL('../public/fonts/', import.meta.url);

async function download(url: string): Promise<Buffer> {
  const res = await fetch(url, { headers: { 'user-agent': CHROME } });
  if (!res.ok) throw new Error(`${url}: ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
}

async function main() {
  const css = (await download(STYLESHEET)).toString('utf8');
  const rules = css.match(/@font-face\s*{[^}]*}/g) ?? [];
  if (rules.length === 0) throw new Error('the stylesheet has no @font-face rule');

  const files = new Map<string, string>(); // file name → where it comes from
  for (const rule of rules) {
    const sources = [...rule.matchAll(/url\(([^)]+)\)/g)].map((match) => match[1]);
    if (sources.length !== 1 || !/^https:\/\/fonts\.gstatic\.com\/[^?#]+\.woff2$/.test(sources[0])) {
      throw new Error(`a rule without exactly one woff2 file from Google: ${rule.slice(0, 200)}`);
    }
    const name = sources[0].slice(sources[0].lastIndexOf('/') + 1);
    if (files.has(name) && files.get(name) !== sources[0]) throw new Error(`two files named ${name}`);
    files.set(name, sources[0]);
  }

  const fonts = new Map<string, Buffer>();
  let bytes = 0;
  for (const [name, url] of files) {
    const font = await download(url);
    if (font.subarray(0, 4).toString('latin1') !== 'wOF2') throw new Error(`${url} is not a woff2 file`);
    bytes += font.length;
    if (bytes > MAX_BYTES) throw new Error(`more than ${MAX_BYTES} bytes of fonts: something changed at the source`);
    fonts.set(name, font);
  }
  const licences = new Map<string, Buffer>();
  for (const [name, url] of Object.entries(LICENCES)) {
    const text = await download(url);
    if (!text.toString('utf8').includes('SIL OPEN FONT LICENSE')) throw new Error(`${url} is not the Open Font License`);
    licences.set(name, text);
  }

  const local = css.replace(/url\(https:\/\/fonts\.gstatic\.com\/[^)]*\/([^/)]+)\)/g, 'url(/fonts/$1)');
  if (local.includes('https://')) throw new Error('the stylesheet still names another site');

  // Everything is here: replace what was there.
  mkdirSync(out, { recursive: true });
  for (const old of readdirSync(out)) rmSync(new URL(old, out));
  for (const [name, font] of fonts) writeFileSync(new URL(name, out), font);
  for (const [name, text] of licences) writeFileSync(new URL(name, out), text);
  writeFileSync(new URL('fonts.css', out), `/* DotGothic16 and Silkscreen, SIL Open Font License (OFL-*.txt). Written by scripts/fetch-fonts.ts: do not edit. */\n${local}`);
  console.log(`${rules.length} rules, ${fonts.size} font files, ${(bytes / 1024).toFixed(0)} KB, stylesheet ${(local.length / 1024).toFixed(0)} KB`);
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
