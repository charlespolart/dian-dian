/**
 * Which robot a request comes from, when it says so.
 *
 * A table kept by hand names the robots worth telling apart — those of the
 * AI assistants above all, where "a person asked ChatGPT to read the page"
 * (ChatGPT-User) and "OpenAI is collecting training text" (GPTBot) say very
 * different things. Anything else `isbot` recognises is counted under the
 * name found. Sources, per operator: docs/research/notes/Mesure de trafic
 * auto hébergée/robots_et_ia.md.
 *
 * REVIEW EVERY QUARTER against ai.robots.txt and crawler-user-agents
 * (github.com/ai-robots-txt/ai.robots.txt, github.com/monperrus/crawler-user-agents):
 * operators add and rename robots several times a year.
 *
 * A User-Agent is whatever the sender writes: a name here is a claim, and
 * ipRanges.ts says whether the address backs it.
 */
import { isbotMatch } from 'isbot';
import { classifyClient } from './classify.js';

export type BotFamily =
  | 'ai_user' // an assistant reading the page because a person asked
  | 'ai_search' // the index of an AI search
  | 'ai_training' // text collected to train models
  | 'search' // classic search engines
  | 'preview' // link previews: someone shared the link
  | 'other'
  | 'fake'; // a name that never appears in a real User-Agent

/**
 * `ranges`: the name of the list of IP ranges that covers this robot (a key
 * of RANGE_SOURCES in ipRanges.ts), when its operator publishes one.
 */
export type Bot = { family: BotFamily; name: string; ranges: string | null };

const row = (family: BotFamily, ranges: string | null, ...names: string[]): Array<Bot & { token: string }> =>
  names.map((name) => ({ token: name.toLowerCase(), family, name, ranges }));

const TABLE = [
  ...row('ai_user', 'openai-chatgpt-user', 'ChatGPT-User'),
  ...row('ai_user', 'anthropic', 'Claude-User'),
  ...row('ai_user', 'perplexity-user', 'Perplexity-User'),
  ...row('ai_user', 'mistral-user', 'MistralAI-User'),
  ...row('ai_user', 'duckduckgo', 'DuckAssistBot'),
  ...row('ai_user', 'google-user-triggered-agents', 'Google-Agent'),
  ...row('ai_user', null, 'Amzn-User', 'meta-externalfetcher', 'Google-GeminiNotebook'),
  ...row('ai_search', 'openai-searchbot', 'OAI-SearchBot'),
  ...row('ai_search', 'anthropic', 'Claude-SearchBot'),
  ...row('ai_search', 'perplexitybot', 'PerplexityBot'),
  ...row('ai_search', 'mistral-index', 'MistralAI-Index'),
  ...row('ai_search', null, 'Amzn-SearchBot', 'meta-webindexer'),
  ...row('ai_training', 'openai-gptbot', 'GPTBot'),
  ...row('ai_training', 'anthropic', 'ClaudeBot', 'anthropic-ai'),
  ...row('ai_training', 'commoncrawl', 'CCBot'),
  ...row('ai_training', null, 'Bytespider', 'meta-externalagent', 'Amazonbot', 'MistralAI-Training'),
  ...row('search', 'google-common-crawlers', 'Googlebot'),
  ...row('search', 'apple', 'Applebot'),
  ...row('search', null, 'bingbot', 'DuckDuckBot', 'YandexBot'),
  // `Pinterest/0.2` is Pinterest's crawler; its app says `[Pinterest/iOS]` and is a person.
  ...row('preview', null, 'Pinterestbot', 'Pinterest/0.2', 'facebookexternalhit', 'WhatsApp', 'Discordbot', 'Twitterbot', 'Slackbot', 'TelegramBot', 'GoogleMessages'),
  ...row('other', 'openai-adsbot', 'OAI-AdsBot'),
  ...row('other', 'google-common-crawlers', 'GoogleOther', 'Google-CloudVertexBot'),
  // These two are robots.txt tokens: no crawler sends them, so a request that does is not what it says.
  ...row('fake', null, 'Google-Extended', 'Applebot-Extended'),
  // The longest first, so that `Applebot-Extended` is not read as `Applebot`.
].sort((a, b) => b.token.length - a.token.length);

/** As in classify.ts: no expression and no search ever sees a longer string. */
const MAX_LENGTH = 512;
const NAME = /[A-Za-z0-9._-]/;

/**
 * The product name around what `isbot` matched (`Bot` in `AhrefsBot/7.0`
 * gives `AhrefsBot`), reduced to plain characters and 40 of them: this
 * string comes from the request and ends up in a table.
 */
function nameAround(ua: string, match: string): string {
  let start = Math.max(0, ua.indexOf(match));
  let end = start;
  while (start > 0 && NAME.test(ua[start - 1])) start--;
  while (end < ua.length && NAME.test(ua[end])) end++;
  const name = ua.slice(start, end).replace(/^[._-]+|[._-]+$/g, '').slice(0, 40);
  return name === '' ? 'other' : name;
}

export function detectBot(userAgent: string | undefined, signatureAgent: string | undefined): Bot | null {
  const ua = (userAgent ?? '').slice(0, MAX_LENGTH);
  const lower = ua.toLowerCase();
  const known = TABLE.find((entry) => lower.includes(entry.token));
  if (known) return { family: known.family, name: known.name, ranges: known.ranges };

  // ChatGPT's agent drives a real browser with a real User-Agent; it signs
  // its requests (Web Bot Auth) and names itself in this header. The
  // signature itself is not checked here: it stays "unverifiable".
  if (/^"?https:\/\/chatgpt\.com\/?"?$/i.test((signatureAgent ?? '').trim())) return { family: 'ai_user', name: 'ChatGPT-Agent', ranges: null };

  // Every browser sends a User-Agent: a request without one is a script.
  if (ua.trim() === '') return { family: 'other', name: 'none', ranges: null };
  // A person in an app's built-in browser, whatever a list of robots makes of the app's name.
  if (classifyClient(ua).inApp !== '') return null;
  const match = isbotMatch(ua);
  return match === null ? null : { family: 'other', name: nameAround(ua, match), ranges: null };
}
