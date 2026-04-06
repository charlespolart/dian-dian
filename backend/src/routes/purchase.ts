import { Router } from 'express';
import { z } from 'zod';
import { db } from '../db/index.js';
import { subscriptions, users } from '../db/schema.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { eq, and } from 'drizzle-orm';

const router = Router();

const verifySchema = z.object({
  store: z.enum(['apple', 'google']),
  productId: z.string().min(1),
  verificationData: z.string().min(1),
  transactionId: z.string().optional(),
});

// Verify a purchase receipt
router.post('/verify', requireAuth, validate(verifySchema), async (req, res) => {
  try {
    const { store, productId, verificationData, transactionId } = req.body;
    const userId = req.userId!;

    let valid = false;
    let originalTransactionId = transactionId || '';
    let expiresAt: Date | null = null;

    if (store === 'apple') {
      const result = await verifyAppleReceipt(verificationData);
      valid = result.valid;
      originalTransactionId = result.originalTransactionId || originalTransactionId;
      expiresAt = result.expiresAt ?? null;
    } else if (store === 'google') {
      const result = await verifyGoogleReceipt(productId, verificationData);
      valid = result.valid;
      originalTransactionId = result.originalTransactionId || originalTransactionId;
      expiresAt = result.expiresAt ?? null;
    }

    if (!valid) {
      res.status(400).json({ error: 'Invalid receipt', premium: false });
      return;
    }

    // Upsert subscription record
    const existing = await db.select()
      .from(subscriptions)
      .where(eq(subscriptions.originalTransactionId, originalTransactionId))
      .limit(1);

    if (existing.length > 0) {
      await db.update(subscriptions)
        .set({
          active: true,
          expiresAt,
          updatedAt: new Date(),
        })
        .where(eq(subscriptions.originalTransactionId, originalTransactionId));
    } else {
      await db.insert(subscriptions).values({
        userId,
        store,
        productId,
        originalTransactionId,
        expiresAt,
        active: true,
      });
    }

    res.json({ ok: true, premium: true });
  } catch (err) {
    console.error('Purchase verify error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Check subscription status
router.get('/status', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const [sub] = await db.select()
      .from(subscriptions)
      .where(and(
        eq(subscriptions.userId, userId),
        eq(subscriptions.active, true),
      ))
      .limit(1);

    if (!sub) {
      res.json({ premium: false });
      return;
    }

    // Check if expired
    if (sub.expiresAt && sub.expiresAt < new Date()) {
      await db.update(subscriptions)
        .set({ active: false, updatedAt: new Date() })
        .where(eq(subscriptions.id, sub.id));
      res.json({ premium: false });
      return;
    }

    res.json({ premium: true, productId: sub.productId, expiresAt: sub.expiresAt });
  } catch (err) {
    console.error('Purchase status error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ── Apple receipt verification ──

async function verifyAppleReceipt(receiptData: string): Promise<{
  valid: boolean;
  originalTransactionId?: string;
  expiresAt?: Date;
}> {
  // Apple App Store Server API v2 uses the receipt/transaction directly
  // For StoreKit 2: the verificationData is a signed JWS transaction
  // For StoreKit 1: it's a base64 receipt

  // Verify with Apple's verifyReceipt endpoint
  const isProduction = process.env.NODE_ENV === 'production';
  const url = isProduction
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET || '',
        'exclude-old-transactions': true,
      }),
    });

    const data = await response.json() as any;

    // Status 21007 = sandbox receipt sent to production → retry on sandbox
    if (data.status === 21007 && isProduction) {
      return verifyAppleReceiptSandbox(receiptData);
    }

    if (data.status !== 0) {
      console.error('Apple verify failed, status:', data.status);
      return { valid: false };
    }

    // Find the latest subscription transaction
    const latestReceipt = data.latest_receipt_info;
    if (!latestReceipt || latestReceipt.length === 0) {
      return { valid: false };
    }

    // Get the most recent transaction
    const latest = latestReceipt.reduce((a: any, b: any) =>
      Number(a.expires_date_ms) > Number(b.expires_date_ms) ? a : b
    );

    const expiresAt = new Date(Number(latest.expires_date_ms));
    const isActive = expiresAt > new Date();

    return {
      valid: isActive,
      originalTransactionId: latest.original_transaction_id,
      expiresAt,
    };
  } catch (err) {
    console.error('Apple receipt verification error:', err);
    return { valid: false };
  }
}

async function verifyAppleReceiptSandbox(receiptData: string): Promise<{
  valid: boolean;
  originalTransactionId?: string;
  expiresAt?: Date;
}> {
  try {
    const response = await fetch('https://sandbox.itunes.apple.com/verifyReceipt', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET || '',
        'exclude-old-transactions': true,
      }),
    });

    const data = await response.json() as any;

    if (data.status !== 0) {
      return { valid: false };
    }

    const latestReceipt = data.latest_receipt_info;
    if (!latestReceipt || latestReceipt.length === 0) {
      return { valid: false };
    }

    const latest = latestReceipt.reduce((a: any, b: any) =>
      Number(a.expires_date_ms) > Number(b.expires_date_ms) ? a : b
    );

    const expiresAt = new Date(Number(latest.expires_date_ms));

    return {
      valid: expiresAt > new Date(),
      originalTransactionId: latest.original_transaction_id,
      expiresAt,
    };
  } catch (err) {
    console.error('Apple sandbox verification error:', err);
    return { valid: false };
  }
}

// ── Google receipt verification ──

async function verifyGoogleReceipt(productId: string, purchaseToken: string): Promise<{
  valid: boolean;
  originalTransactionId?: string;
  expiresAt?: Date;
}> {
  // Google Play requires OAuth2 service account credentials
  // For now, use the Google Play Developer API
  const packageName = process.env.GOOGLE_PACKAGE_NAME || 'app.mydiandian';
  const serviceAccountKey = process.env.GOOGLE_SERVICE_ACCOUNT_KEY;

  if (!serviceAccountKey) {
    console.error('GOOGLE_SERVICE_ACCOUNT_KEY not configured');
    // Fallback: trust the purchase (configure service account for production)
    return { valid: true, originalTransactionId: purchaseToken };
  }

  try {
    const accessToken = await getGoogleAccessToken(serviceAccountKey);

    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`;

    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      console.error('Google verify failed:', response.status);
      return { valid: false };
    }

    const data = await response.json() as any;

    // paymentState: 0 = pending, 1 = received, 2 = free trial, 3 = deferred
    const isActive = data.paymentState === 1 || data.paymentState === 2;
    const expiresAt = data.expiryTimeMillis
      ? new Date(Number(data.expiryTimeMillis))
      : undefined;

    return {
      valid: isActive && (!expiresAt || expiresAt > new Date()),
      originalTransactionId: data.orderId || purchaseToken,
      expiresAt,
    };
  } catch (err) {
    console.error('Google receipt verification error:', err);
    return { valid: false };
  }
}

async function getGoogleAccessToken(serviceAccountKeyJson: string): Promise<string> {
  // Parse service account credentials
  const key = JSON.parse(serviceAccountKeyJson);
  const now = Math.floor(Date.now() / 1000);

  // Create JWT for Google OAuth2
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })).toString('base64url');

  const { createSign } = await import('crypto');
  const sign = createSign('RSA-SHA256');
  sign.update(`${header}.${payload}`);
  const signature = sign.sign(key.private_key, 'base64url');

  const jwt = `${header}.${payload}.${signature}`;

  // Exchange JWT for access token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json() as any;
  return data.access_token;
}

export default router;
