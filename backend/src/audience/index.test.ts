import assert from 'node:assert/strict';
import { test } from 'node:test';
import type { Hit } from './counter.js';
import { OPT_OUT_COOKIE, createAudience, type AudienceRequest } from './index.js';
import { KNOWN_SITES } from './origin.js';

const SAFARI = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';
const CHATGPT = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; ChatGPT-User/1.0; +https://openai.com/bot';

function setup(broken: Partial<Record<'counter' | 'visitors' | 'ipRanges' | 'countries', boolean>> = {}) {
  const hits: Array<{ hit: Hit; newVisitor: boolean }> = [];
  const asked = { visitors: [] as string[][], ranges: [] as Array<[string | null, string | undefined]>, countries: [] as Array<string | undefined> };
  const boom = () => { throw new Error('broken'); };
  const audience = createAudience({ domain: 'diandian.overridedev.com', knownSites: KNOWN_SITES, tagFallback: true }, {
    counter: { add: (hit, newVisitor) => { if (broken.counter) boom(); hits.push({ hit, newVisitor }); } },
    visitors: { isNew: (domain, ip, userAgent) => { if (broken.visitors) boom(); asked.visitors.push([domain, ip, userAgent]); return asked.visitors.length === 1; } },
    ipRanges: { check: (ranges, ip) => { if (broken.ipRanges) boom(); asked.ranges.push([ranges, ip]); return 'verified'; } },
    countries: { countryOf: (ip) => { if (broken.countries) boom(); asked.countries.push(ip); return 'FR'; } },
  });
  return { audience, hits, asked };
}

const request = (more: Partial<AudienceRequest> & { headers?: AudienceRequest['headers'] } = {}): AudienceRequest => ({
  method: 'GET', ip: '203.0.113.7', query: {}, cookies: {}, ...more, headers: { 'user-agent': SAFARI, ...more.headers },
});

test('a person\'s visit is counted with what is known of it', () => {
  const { audience, hits, asked } = setup();
  audience.visit(request({ headers: { referer: 'https://www.pinterest.com/pin/1/' } }), 'fr');
  assert.deepEqual(hits, [{
    hit: {
      kind: 'visit', store: '', origin: 'pinterest.com', originFrom: 'referer', tagged: false,
      device: 'iphone', browser: 'safari', inApp: '', lang: 'fr', country: 'FR', botFamily: '', botName: '', botCheck: '',
    },
    newVisitor: true,
  }]);
  assert.deepEqual(asked.visitors, [['diandian.overridedev.com', '203.0.113.7', SAFARI]]);
  assert.deepEqual(asked.countries, ['203.0.113.7']);
  audience.visit(request(), 'fr');
  assert.equal(hits[1].newVisitor, false, 'the second visit of the day is not a new visitor');
});

test('a tagged link without a Referer gets its origin from the closed list', () => {
  const { audience, hits } = setup();
  audience.visit(request({ query: { utm_source: 'chatgpt.com', utm_campaign: 'x' } }), 'en');
  assert.deepEqual([hits[0].hit.origin, hits[0].hit.originFrom, hits[0].hit.tagged], ['chatgpt.com', 'tag', true]);
});

for (const [what, more] of [
  ['the opt-out cookie', { cookies: { [OPT_OUT_COOKIE]: '1' } }],
  ['Global Privacy Control', { headers: { 'sec-gpc': '1' } }],
  ['Do Not Track', { headers: { dnt: '1' } }],
] as Array<[string, Partial<AudienceRequest>]>) {
  test(`${what}: the visit is not counted, and neither the address nor the User-Agent is looked at`, () => {
    const { audience, hits, asked } = setup();
    const req = request(more);
    assert.equal(audience.objects(req), true);
    // Reading the address or the User-Agent of someone who objects would be a failure of its own.
    const guarded: AudienceRequest = {
      ...req,
      get ip(): string { throw new Error('the address was read'); },
      headers: new Proxy(req.headers, { get: (target, name) => { if (name === 'user-agent' || name === 'referer') throw new Error(`${String(name)} was read`); return target[name as string]; } }),
    };
    audience.visit(guarded, 'fr');
    audience.storeTap(guarded, 'apple', 'fr');
    assert.deepEqual(hits, []);
    assert.deepEqual(asked, { visitors: [], ranges: [], countries: [] });
  });
}

test('who does not object is counted: the signals must say 1', () => {
  const { audience } = setup();
  assert.equal(audience.objects(request()), false);
  assert.equal(audience.objects(request({ headers: { dnt: '0', 'sec-gpc': '0' }, cookies: { [OPT_OUT_COOKIE]: '0' } })), false);
  assert.equal(audience.objects(request({ cookies: undefined })), false);
});

for (const [what, more] of [
  ['a HEAD request', { method: 'HEAD' }],
  ['a POST', { method: 'POST' }],
  ['a prefetch (Sec-Purpose)', { headers: { 'sec-purpose': 'prefetch;prerender' } }],
  ['a prefetch (Purpose)', { headers: { purpose: 'prefetch' } }],
  ['a prefetch (X-Moz)', { headers: { 'x-moz': 'prefetch' } }],
  ['a link preview (X-Purpose)', { headers: { 'x-purpose': 'preview' } }],
] as Array<[string, Partial<AudienceRequest>]>) {
  test(`${what} is not a visit, nor a tap`, () => {
    const { audience, hits } = setup();
    audience.visit(request(more), 'fr');
    audience.storeTap(request(more), 'play', 'fr');
    assert.deepEqual(hits, []);
  });
}

test('a robot is counted by family, name and verification, and nothing else', () => {
  const { audience, hits, asked } = setup();
  audience.visit(request({ headers: { 'user-agent': CHATGPT, referer: 'https://www.pinterest.com/' }, query: { utm_source: 'pinterest' } }), 'fr');
  assert.deepEqual(hits, [{
    hit: {
      kind: 'visit', store: '', origin: '', originFrom: '', tagged: false,
      device: '', browser: '', inApp: '', lang: '', country: '', botFamily: 'ai_user', botName: 'ChatGPT-User', botCheck: 'verified',
    },
    newVisitor: false,
  }]);
  assert.deepEqual(asked.ranges, [['openai-chatgpt-user', '203.0.113.7']]);
  assert.deepEqual(asked.visitors, [], 'a robot is not a visitor');
  assert.deepEqual(asked.countries, [], 'and has no country');
});

test('the ChatGPT agent is known by its signature header', () => {
  const { audience, hits } = setup();
  audience.visit(request({ headers: { 'signature-agent': '"https://chatgpt.com"' } }), 'fr');
  assert.deepEqual([hits[0].hit.botFamily, hits[0].hit.botName], ['ai_user', 'ChatGPT-Agent']);
});

test('a tap on a store button: its origin comes from the tag only, never from the Referer (the site itself)', () => {
  const { audience, hits, asked } = setup();
  audience.storeTap(request({ headers: { referer: 'https://www.pinterest.com/pin/1/' }, query: { utm_source: 'pinterest' } }), 'apple', 'fr');
  audience.storeTap(request({ headers: { referer: 'https://www.pinterest.com/pin/1/' } }), 'play', 'en');
  assert.deepEqual(hits.map(({ hit, newVisitor }) => [hit.kind, hit.store, hit.origin, hit.originFrom, hit.tagged, hit.device, hit.lang, hit.country, newVisitor]), [
    ['store_tap', 'apple', 'pinterest.com', 'tag', true, 'iphone', 'fr', 'FR', false],
    ['store_tap', 'play', '', '', false, 'iphone', 'en', 'FR', false],
  ]);
  assert.deepEqual(asked.visitors, [], 'visitors are counted on visits');
});

test('a robot that follows a store button is counted as a robot', () => {
  const { audience, hits } = setup();
  audience.storeTap(request({ headers: { 'user-agent': CHATGPT } }), 'apple', 'fr');
  assert.deepEqual([hits[0].hit.kind, hits[0].hit.store, hits[0].hit.botName, hits[0].hit.device], ['store_tap', 'apple', 'ChatGPT-User', '']);
});

test('headers given several times are read by their first value; a missing address is no address', () => {
  const { audience, hits, asked } = setup();
  audience.visit(request({ ip: undefined, headers: { 'user-agent': [SAFARI, 'x'], referer: ['https://chatgpt.com/', 'https://example.com/'] } }), 'fr');
  assert.equal(hits[0].hit.origin, 'chatgpt.com');
  assert.equal(hits[0].hit.device, 'iphone');
  assert.deepEqual(asked.visitors, [['diandian.overridedev.com', '', SAFARI]]);
});

for (const part of ['counter', 'visitors', 'ipRanges', 'countries'] as const) {
  test(`a broken ${part} never costs the page`, () => {
    const { audience } = setup({ [part]: true });
    assert.doesNotThrow(() => audience.visit(request(), 'fr'));
    assert.doesNotThrow(() => audience.visit(request({ headers: { 'user-agent': CHATGPT } }), 'fr'));
    assert.doesNotThrow(() => audience.storeTap(request(), 'apple', 'fr'));
  });
}

test('a request of an unexpected shape never throws', () => {
  const { audience } = setup();
  assert.doesNotThrow(() => audience.visit({} as AudienceRequest, 'fr'));
  assert.doesNotThrow(() => audience.visit({ method: 'GET', ip: undefined, headers: {}, query: {} }, 'fr'));
  assert.equal(audience.objects({} as AudienceRequest), false);
});
