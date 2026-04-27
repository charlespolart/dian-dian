import { createRemoteJWKSet, jwtVerify } from 'jose';

const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
const APPLE_ISSUER = 'https://appleid.apple.com';

const GOOGLE_JWKS = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));
const GOOGLE_ISSUERS = ['https://accounts.google.com', 'accounts.google.com'];

export interface OAuthClaims {
  subject: string;
  email?: string;
  emailVerified?: boolean;
}

/**
 * Verifies an Apple identity token (JWT) and returns the user's stable subject
 * id and (on first sign-in) their email. The audience must match an iOS bundle
 * id we recognize.
 */
export async function verifyAppleIdentityToken(
  token: string,
  expectedAudiences: string[],
): Promise<OAuthClaims> {
  const { payload } = await jwtVerify(token, APPLE_JWKS, {
    issuer: APPLE_ISSUER,
    audience: expectedAudiences,
  });
  if (!payload.sub) throw new Error('Apple token missing sub');
  return {
    subject: payload.sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    emailVerified: payload.email_verified === true || payload.email_verified === 'true',
  };
}

/**
 * Verifies a Google ID token (JWT) issued for one of our OAuth client ids.
 * Returns the user's `sub` and verified email.
 */
export async function verifyGoogleIdToken(
  token: string,
  expectedAudiences: string[],
): Promise<OAuthClaims> {
  const { payload } = await jwtVerify(token, GOOGLE_JWKS, {
    audience: expectedAudiences,
  });
  if (!GOOGLE_ISSUERS.includes(payload.iss as string)) {
    throw new Error('Unexpected Google issuer');
  }
  if (!payload.sub) throw new Error('Google token missing sub');
  return {
    subject: payload.sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    emailVerified: payload.email_verified === true,
  };
}
