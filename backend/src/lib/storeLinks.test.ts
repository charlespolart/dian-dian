import assert from 'node:assert/strict';
import { test } from 'node:test';
import { APP_STORE_URL, PLAY_STORE_URL, campaignQuery, storeLinks } from './storeLinks.js';

const PIN = { utm_source: 'pinterest', utm_campaign: 'mood-en' };

test('without a campaign the store links are plain', () => {
  assert.deepEqual(storeLinks({}, 'PT123'), { apple: APP_STORE_URL, play: PLAY_STORE_URL });
  assert.deepEqual(storeLinks({ utm_campaign: 'mood-en' }, 'PT123'), { apple: APP_STORE_URL, play: PLAY_STORE_URL }, 'a campaign without a source is none');
});

test('Google Play gets the source and the campaign in its referrer', () => {
  assert.equal(storeLinks(PIN, '').play, `${PLAY_STORE_URL}&referrer=utm_source%3Dpinterest%26utm_campaign%3Dmood-en`);
  assert.equal(storeLinks({ utm_source: 'chatgpt.com' }, '').play, `${PLAY_STORE_URL}&referrer=utm_source%3Dchatgptcom`);
});

test('the App Store gets one campaign name per source: Apple only shows a name from 5 downloads on', () => {
  assert.equal(storeLinks(PIN, 'PT123').apple, `${APP_STORE_URL}?pt=PT123&ct=pinterest&mt=8`);
  assert.equal(storeLinks({ utm_source: 'pinterest', utm_campaign: 'sleep-fr' }, 'PT123').apple, `${APP_STORE_URL}?pt=PT123&ct=pinterest&mt=8`, 'another pin, the same name');
  assert.equal(storeLinks({ utm_source: 'chatgpt.com' }, 'PT123').apple, `${APP_STORE_URL}?pt=PT123&ct=chatgptcom&mt=8`);
});

test('without a provider token the App Store link stays plain', () => {
  assert.equal(storeLinks(PIN, '').apple, APP_STORE_URL);
});

test('a campaign is cleaned before it is relayed', () => {
  assert.equal(storeLinks({ utm_source: 'Pin<script>', utm_campaign: 'a b&c=d' }, 'PT123').apple, `${APP_STORE_URL}?pt=PT123&ct=pinscript&mt=8`);
  assert.equal(storeLinks({ utm_source: ['a', 'b'] }, '').play, PLAY_STORE_URL, 'only a plain string is a campaign');
  // What Express makes of ?utm_source[toString]=x: an object String() cannot convert.
  assert.deepEqual(storeLinks({ utm_source: { toString: 'x' }, utm_campaign: { toString: 'y' } }, 'PT123'), { apple: APP_STORE_URL, play: PLAY_STORE_URL });
  assert.equal(campaignQuery({ utm_source: { toString: 'x' } }), '');
  assert.equal(storeLinks({ utm_source: 'x'.repeat(100) }, '').play, `${PLAY_STORE_URL}&referrer=utm_source%3D${'x'.repeat(40)}`);
});

test('the query relayed to the store buttons holds the cleaned campaign and nothing else', () => {
  assert.equal(campaignQuery({}), '');
  assert.equal(campaignQuery({ lang: 'fr' }), '');
  assert.equal(campaignQuery({ utm_campaign: 'mood-en' }), '');
  assert.equal(campaignQuery({ utm_source: 'pinterest' }), '?utm_source=pinterest');
  assert.equal(campaignQuery({ ...PIN, lang: 'fr', other: 'x' }), '?utm_source=pinterest&utm_campaign=mood-en');
  assert.equal(campaignQuery({ utm_source: 'Pin"><script>', utm_campaign: 'a&b' }), '?utm_source=pinscript&utm_campaign=ab');
});
