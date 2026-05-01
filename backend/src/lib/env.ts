import 'dotenv/config';

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
  // Email providers: at least one of these must be set. MailerSend is
  // preferred when both are configured (transition period from Resend).
  MAILERSEND_API_TOKEN: process.env.MAILERSEND_API_TOKEN,
  RESEND_API_KEY: process.env.RESEND_API_KEY,
  PORT: parseInt(process.env.PORT || '3000', 10),
  CORS_ORIGIN: process.env.CORS_ORIGIN || 'http://localhost:8081',
  APP_URL: process.env.APP_URL || 'http://localhost:8081',
  // Bundle ids accepted as Apple identity-token `aud`. Must include each iOS
  // app id that uses Sign in with Apple (e.g. app.mydiandian).
  APPLE_BUNDLE_IDS: commaList('APPLE_BUNDLE_IDS'),
  // Google OAuth 2.0 client ids accepted as ID-token `aud` (iOS + Android +
  // Web each have their own client id in Google Cloud Console).
  GOOGLE_CLIENT_IDS: commaList('GOOGLE_CLIENT_IDS'),
};

if (!env.MAILERSEND_API_TOKEN && !env.RESEND_API_KEY) {
  throw new Error('Set MAILERSEND_API_TOKEN or RESEND_API_KEY');
}
