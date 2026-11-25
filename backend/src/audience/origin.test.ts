import assert from 'node:assert/strict';
import { test } from 'node:test';
import { KNOWN_ORIGINS, KNOWN_SITES, originOf } from './origin.js';

const of = (referer: string | undefined, utmSource?: unknown, tagFallback = true) =>
  originOf({ referer, utmSource, ownHost: 'diandian.overridedev.com', knownSites: KNOWN_SITES, tagFallback });

test('the site of origin is the domain of the Referer, and nothing more of it', () => {
  assert.deepEqual(of('https://www.pinterest.com/pin/123/?x=1'), { site: 'pinterest.com', from: 'referer', tagged: false });
  assert.deepEqual(of('https://chatgpt.com/'), { site: 'chatgpt.com', from: 'referer', tagged: false });
  assert.deepEqual(of('http://news.ycombinator.com/item?id=1'), { site: 'news.ycombinator.com', from: 'referer', tagged: false });
});

test('prefixes that only say "mobile" or "link" are dropped, and the case', () => {
  assert.equal(of('https://M.Facebook.com/').site, 'facebook.com');
  assert.equal(of('https://l.facebook.com/l.php?u=x').site, 'facebook.com');
  assert.equal(of('https://lm.facebook.com/').site, 'facebook.com');
  assert.equal(of('https://WWW.Google.com/').site, 'google.com');
});

test('the Referer comes before the tag; the tag is only said to be there', () => {
  assert.deepEqual(of('https://chatgpt.com/', 'chatgpt.com'), { site: 'chatgpt.com', from: 'referer', tagged: true });
  assert.deepEqual(of('https://duckduckgo.com/', 'newsletter-42'), { site: 'duckduckgo.com', from: 'referer', tagged: true });
});

test('without a Referer, a utm_source of the closed list gives its site', () => {
  assert.deepEqual(of(undefined, 'chatgpt.com'), { site: 'chatgpt.com', from: 'tag', tagged: true });
  assert.deepEqual(of(undefined, 'pinterest'), { site: 'pinterest.com', from: 'tag', tagged: true });
  assert.deepEqual(of('', 'Pinterest'), { site: 'pinterest.com', from: 'tag', tagged: true });
  assert.deepEqual(of(undefined, 'twitter'), { site: 'x.com', from: 'tag', tagged: true });
});

test('a utm_source outside the list is never kept: only the flag stays', () => {
  assert.deepEqual(of(undefined, 'newsletter-42'), { site: '', from: '', tagged: true });
  assert.deepEqual(of(undefined, 'john.doe@example.com'), { site: '', from: '', tagged: true });
});

test('a tag named like something every object has is not a site', () => {
  for (const tag of ['constructor', 'toString', '__proto__', 'hasOwnProperty', 'valueOf']) {
    assert.deepEqual(of(undefined, tag), { site: '', from: '', tagged: true }, tag);
  }
});

test('the fallback can be turned off', () => {
  assert.deepEqual(of(undefined, 'pinterest', false), { site: '', from: '', tagged: true });
  assert.deepEqual(of('https://www.pinterest.com/', 'pinterest', false), { site: 'pinterest.com', from: 'referer', tagged: true });
});

test('the site is never its own origin', () => {
  assert.deepEqual(of('https://diandian.overridedev.com/?lang=fr&utm_source=x'), { site: '', from: '', tagged: false });
  assert.deepEqual(of('https://DianDian.overridedev.com/privacy'), { site: '', from: '', tagged: false });
  // The page of the site that carries the tag: the tag still tells where the visitor came from.
  assert.deepEqual(of('https://diandian.overridedev.com/?utm_source=pinterest', 'pinterest'), { site: 'pinterest.com', from: 'tag', tagged: true });
});

test('what is not a web site has no origin', () => {
  assert.equal(of('android-app://com.pinterest/').site, '');
  assert.equal(of('not a url').site, '');
  assert.equal(of('//example.com/').site, '');
  assert.equal(of(`https://example.com/${'a'.repeat(5_000)}`).site, '', 'a Referer no browser sends');
});

test('a host that could be anything is filed under "other"', () => {
  assert.equal(of('https://203.0.113.7/').site, 'other', 'an address');
  assert.equal(of('https://[2001:db8::1]/').site, 'other');
  assert.equal(of(`https://${'a'.repeat(61)}.com/`).site, 'other', 'longer than 60 characters');
  assert.equal(of('http://localhost:3000/').site, 'other', 'no dot');
  assert.equal(of('https://exa_mple.com/').site, 'other', 'a character no domain has');
});

test('only a plain string is a tag: any other shape is no tag, and never throws', () => {
  assert.deepEqual(of(undefined, ['pinterest', 'x']), { site: '', from: '', tagged: false });
  assert.deepEqual(of(undefined, { a: 1 }), { site: '', from: '', tagged: false });
  // What Express makes of ?utm_source[toString]=x: an object String() cannot convert.
  assert.deepEqual(of(undefined, { toString: 'x' }), { site: '', from: '', tagged: false });
  assert.deepEqual(of(undefined, ''), { site: '', from: '', tagged: false });
  assert.deepEqual(of(undefined, '   '), { site: '', from: '', tagged: false });
  assert.deepEqual(of(undefined, undefined), { site: '', from: '', tagged: false });
  assert.deepEqual(of(undefined, 42), { site: '', from: '', tagged: false });
});

test('a site that lives on several hosts is one site', () => {
  for (const host of ['www.pinterest.co.uk', 'fr.pinterest.com', 'www.pinterest.fr', 'pinterest.com.mx', 'pin.it']) assert.equal(of(`https://${host}/pin/1/`).site, 'pinterest.com', host);
  for (const host of ['www.google.com.hk', 'www.google.fr', 'google.co.uk', 'news.google.com']) assert.equal(of(`https://${host}/`).site, 'google.com', host);
  assert.equal(of('https://gemini.google.com/app').site, 'gemini.google.com', 'Gemini is its own source');
  assert.equal(of('https://l.instagram.com/?u=x').site, 'instagram.com');
  assert.equal(of('https://web.facebook.com/').site, 'facebook.com');
  assert.equal(of('https://t.co/abc').site, 'x.com');
  assert.equal(of('https://twitter.com/x/status/1').site, 'x.com');
  assert.equal(of('https://chat.openai.com/').site, 'chatgpt.com');
  assert.equal(of('https://m.youtube.com/watch').site, 'youtube.com');
  assert.equal(of('https://old.reddit.com/r/x').site, 'reddit.com');
  assert.equal(of('https://vm.tiktok.com/x').site, 'tiktok.com');
  assert.equal(of('https://www.perplexity.ai/search').site, 'perplexity.ai');
});

test('a host that only looks like a known site stays itself', () => {
  assert.equal(of('https://pinterest.evil.example/').site, 'pinterest.evil.example');
  assert.equal(of('https://notpinterest.com/').site, 'notpinterest.com');
  assert.equal(of('https://google.com.evil.example/').site, 'google.com.evil.example');
  assert.equal(of('https://mygoogle.fr/').site, 'mygoogle.fr');
});

test('every site a tag or a family can name is listed, so the counter can keep them out of its limits', () => {
  for (const site of ['pinterest.com', 'chatgpt.com', 'google.com', 'instagram.com', 'x.com', 'gemini.google.com']) assert.ok(KNOWN_ORIGINS.has(site), site);
  for (const site of Object.values(KNOWN_SITES)) assert.ok(KNOWN_ORIGINS.has(site), site);
});
