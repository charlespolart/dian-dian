/**
 * The audience counter of the site, one for the process: started when this
 * module is first imported (routes/landing.ts). What it counts and what it
 * never keeps: src/audience/index.ts.
 */
import { startAudience } from '../audience/index.js';
import { KNOWN_SITES } from '../audience/origin.js';
import { db } from '../db/index.js';
import { env } from './env.js';

export const SITE_HOST = 'diandian.overridedev.com';

export const siteAudience = startAudience({
  domain: SITE_HOST,
  knownSites: KNOWN_SITES,
  tagFallback: env.AUDIENCE_TAG_FALLBACK,
  downloads: env.AUDIENCE_DOWNLOADS,
}, db);
