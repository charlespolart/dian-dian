import assert from 'node:assert/strict';
import { test } from 'node:test';
import { detectBot } from './bots.js';

const bot = (ua: string | undefined, signatureAgent?: string) => detectBot(ua, signatureAgent);
const SAFARI = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';

// token, family, the list of IP ranges that covers it (null: its operator publishes none)
const TABLE: Array<[string, string, string | null]> = [
  ['ChatGPT-User', 'ai_user', 'openai-chatgpt-user'], ['Claude-User', 'ai_user', 'anthropic'],
  ['Perplexity-User', 'ai_user', 'perplexity-user'], ['MistralAI-User', 'ai_user', 'mistral-user'],
  ['DuckAssistBot', 'ai_user', 'duckduckgo'], ['Google-Agent', 'ai_user', 'google-user-triggered-agents'],
  ['Amzn-User', 'ai_user', null], ['meta-externalfetcher', 'ai_user', null], ['Google-GeminiNotebook', 'ai_user', null],
  ['OAI-SearchBot', 'ai_search', 'openai-searchbot'], ['Claude-SearchBot', 'ai_search', 'anthropic'],
  ['PerplexityBot', 'ai_search', 'perplexitybot'], ['MistralAI-Index', 'ai_search', 'mistral-index'],
  ['Amzn-SearchBot', 'ai_search', null], ['meta-webindexer', 'ai_search', null],
  ['GPTBot', 'ai_training', 'openai-gptbot'], ['ClaudeBot', 'ai_training', 'anthropic'], ['anthropic-ai', 'ai_training', 'anthropic'],
  ['CCBot', 'ai_training', 'commoncrawl'], ['Bytespider', 'ai_training', null], ['meta-externalagent', 'ai_training', null],
  ['Amazonbot', 'ai_training', null], ['MistralAI-Training', 'ai_training', null],
  ['Googlebot', 'search', 'google-common-crawlers'], ['Applebot', 'search', 'apple'],
  ['bingbot', 'search', null], ['DuckDuckBot', 'search', null], ['YandexBot', 'search', null],
  ['Pinterestbot', 'preview', null], ['facebookexternalhit', 'preview', null], ['WhatsApp', 'preview', null],
  ['Discordbot', 'preview', null], ['Twitterbot', 'preview', null], ['Slackbot', 'preview', null],
  ['TelegramBot', 'preview', null], ['GoogleMessages', 'preview', null],
  ['OAI-AdsBot', 'other', 'openai-adsbot'], ['GoogleOther', 'other', 'google-common-crawlers'], ['Google-CloudVertexBot', 'other', 'google-common-crawlers'],
];

test('every robot of the table is named with its family and its list of ranges', () => {
  for (const [token, family, ranges] of TABLE) {
    assert.deepEqual(bot(`Mozilla/5.0 (compatible; ${token}/1.0; +https://example.com/bot)`), { family, name: token, ranges }, token);
  }
});

test('the token is found anywhere in the string, whatever its case', () => {
  // OAI-SearchBot sends a complete Chrome string: it must not read as a person.
  assert.equal(bot('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36; compatible; OAI-SearchBot/1.4; +https://openai.com/searchbot')?.name, 'OAI-SearchBot');
  assert.equal(bot('Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; chatgpt-user/1.0; +https://openai.com/bot')?.name, 'ChatGPT-User');
  assert.equal(bot('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15 (Applebot/0.1; +http://www.apple.com/go/applebot)')?.family, 'search');
});

test('Pinterest: its crawler is a robot, its app is a person', () => {
  assert.deepEqual(bot('Pinterest/0.2 (+http://www.pinterest.com/bot.html)'), { family: 'preview', name: 'Pinterest/0.2', ranges: null });
  assert.equal(bot('Mozilla/5.0 (compatible; Pinterestbot/1.0; +http://www.pinterest.com/bot.html)')?.name, 'Pinterestbot');
  assert.equal(bot('Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [Pinterest/iOS]'), null);
  assert.equal(bot('Mozilla/5.0 (Linux; Android 14; SM-A546B; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/137.0.0.0 Mobile Safari/537.36 [Pinterest/Android]'), null);
});

test('the other apps with a built-in browser are people too', () => {
  assert.equal(bot('Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 339.0.3.12.91 (iPhone15,2; iOS 18_6; en_US; en; scale=3.00; 1179x2556; 619461904)'), null);
  assert.equal(bot('Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/470.0.0.37.108;FBDV/iPhone14,5]'), null);
  assert.equal(bot('Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 musical_ly_34.5.0 JsSdk/2.0 BytedanceWebview/d8a21c6'), null);
});

test('a name that only exists in robots.txt is a fake', () => {
  assert.deepEqual(bot('Mozilla/5.0 (compatible; Google-Extended/1.0)'), { family: 'fake', name: 'Google-Extended', ranges: null });
  assert.deepEqual(bot('Mozilla/5.0 (Applebot-Extended/0.1; +http://www.apple.com/go/applebot)'), { family: 'fake', name: 'Applebot-Extended', ranges: null }, 'not Applebot');
});

test('names that contain one another are told apart', () => {
  assert.equal(bot('meta-externalagent/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)')?.family, 'ai_training');
  assert.equal(bot('meta-externalfetcher/1.1')?.family, 'ai_user');
  assert.equal(bot('Mozilla/5.0 (compatible; GoogleOther)')?.name, 'GoogleOther');
  assert.equal(bot('Mozilla/5.0 (compatible; Claude-SearchBot/1.0; +Claude-SearchBot@anthropic.com)')?.name, 'Claude-SearchBot');
});

test('the ChatGPT agent browses with a real browser: only its signature header tells', () => {
  assert.deepEqual(bot(SAFARI, '"https://chatgpt.com"'), { family: 'ai_user', name: 'ChatGPT-Agent', ranges: null });
  assert.equal(bot(SAFARI, 'https://chatgpt.com/')?.name, 'ChatGPT-Agent');
  assert.equal(bot(SAFARI, '"https://example.com"'), null, 'another signer is not known');
  assert.equal(bot(SAFARI, ''), null);
});

test('a robot the table does not know is named by what isbot found', () => {
  assert.deepEqual(bot('Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)'), { family: 'other', name: 'AhrefsBot', ranges: null });
  assert.deepEqual(bot('curl/8.7.1'), { family: 'other', name: 'curl', ranges: null });
  assert.equal(bot('python-requests/2.32.3')?.name, 'python-requests');
});

test('a name found is cleaned and bounded: it is written by whoever sends the request', () => {
  const long = bot(`Mozilla/5.0 (compatible; ${'x'.repeat(200)}bot/1.0)`);
  assert.equal(long?.family, 'other');
  assert.ok(long !== null && long.name.length <= 40 && /^[A-Za-z0-9._-]+$/.test(long.name), long?.name);
  const odd = bot('<script>alert(1)</script> bot');
  assert.ok(odd !== null && /^[A-Za-z0-9._-]+$/.test(odd.name), odd?.name);
});

test('a person is not a robot', () => {
  assert.equal(bot(SAFARI), null);
  assert.equal(bot('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0'), null);
});

test('a request with no User-Agent is not a browser: every browser sends one', () => {
  assert.deepEqual(bot(undefined), { family: 'other', name: 'none', ranges: null });
  assert.deepEqual(bot(''), { family: 'other', name: 'none', ranges: null });
  assert.deepEqual(bot('   '), { family: 'other', name: 'none', ranges: null });
});

test('a very long User-Agent costs nothing', () => {
  const long = `${'a'.repeat(20_000)} GPTBot`;
  bot(long); // warm up
  const started = performance.now();
  assert.notEqual(bot(long)?.name, 'GPTBot', 'only the first 512 characters are read');
  assert.ok(performance.now() - started < 5, 'under 5 ms');
});

test('what isbot matched is only kept as a name when it is a product name', () => {
  const name = (ua: string) => bot(ua)?.name;
  // A contact address or a URL in the User-Agent is not the robot's name, and may be a person's.
  assert.equal(name('Mozilla/5.0 (compatible; +mailto:john.smith@example.org)'), 'other');
  assert.equal(name('contact jean.dupont@gmail.com'), 'other');
  assert.equal(name('Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)'), 'other');
  assert.equal(name('Mozilla/5.0'), 'other');
  assert.equal(name('Mozilla/5.0 (compatible)'), 'other');
  // Product names are kept.
  assert.equal(name('Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)'), 'AhrefsBot');
  assert.equal(name('curl/8.7.1'), 'curl');
  assert.equal(name('Go-http-client/2.0'), 'Go-http-client');
  assert.equal(name('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/138.0.0.0 Safari/537.36'), 'HeadlessChrome');
});
