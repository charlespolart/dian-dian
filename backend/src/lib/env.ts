import 'dotenv/config';
import { envFlag } from './envFlag.js';

function required(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing environment variable: ${key}`);
  return value;
}

function commaList(key: string): string[] {
  return (process.env[key] || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

export const env = {
  DATABASE_URL: required('DATABASE_URL'),
  JWT_SECRET: required('JWT_SECRET'),
  RESEND_API_KEY: required('RESEND_API_KEY'),
  PORT: parseInt(process.env.PORT || '3000', 10),
  CORS_ORIGIN: process.env.CORS_ORIGIN || 'http://localhost:8081',
  APP_URL: process.env.APP_URL || 'http://localhost:8081',
  // Bundle ids accepted as Apple identity-token `aud`. Must include each iOS
  // app id that uses Sign in with Apple (e.g. app.mydiandian).
  APPLE_BUNDLE_IDS: commaList('APPLE_BUNDLE_IDS'),
  // Google OAuth 2.0 client ids accepted as ID-token `aud` (iOS + Android +
  // Web each have their own client id in Google Cloud Console).
  GOOGLE_CLIENT_IDS: commaList('GOOGLE_CLIENT_IDS'),
  // The site's audience counter (src/audience). Without a Referer, a
  // `utm_source` of a closed list is read as the site of origin; `off`
  // turns that fallback off.
  AUDIENCE_TAG_FALLBACK: envFlag(process.env.AUDIENCE_TAG_FALLBACK, true),
  // Whether the counter downloads the robots' IP ranges and the country
  // database (DB-IP, 4 MB) at start. In production only, unless set to `on`
  // or `off`: a dev server restarts at every save.
  AUDIENCE_DOWNLOADS: envFlag(process.env.AUDIENCE_DOWNLOADS, process.env.NODE_ENV === 'production'),
};
