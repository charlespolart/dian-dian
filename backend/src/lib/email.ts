import { Resend } from 'resend';
import { env } from './env.js';

const resend = new Resend(env.RESEND_API_KEY);
const FROM = 'Dian Dian <noreply@overridedev.com>';

export async function sendPasswordResetEmail(to: string, code: string) {
  await resend.emails.send({
    from: FROM,
    to,
    subject: `${code} is your Dian Dian reset code`,
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;">
        <h2 style="color:#9090b0;">Dian Dian (点点)</h2>
        <p>Use this code in the app to reset your password:</p>
        <p style="text-align:center;margin:24px 0;">
          <span style="display:inline-block;padding:16px 24px;background:#d8e8c8;border-radius:8px;color:#708060;font-size:32px;font-weight:bold;letter-spacing:8px;font-family:monospace;">${code}</span>
        </p>
        <p style="color:#999;font-size:13px;">This code expires in 10 minutes. If you didn't request this, ignore this email.</p>
      </div>
    `,
  });
}

export async function sendVerificationEmail(to: string, token: string) {
  const link = `${env.APP_URL}/verify-email?token=${token}`;
  await resend.emails.send({
    from: FROM,
    to,
    subject: 'Verify your email — Dian Dian',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;">
        <h2 style="color:#9090b0;">Dian Dian (点点)</h2>
        <p>Welcome! Please verify your email address:</p>
        <p><a href="${link}" style="display:inline-block;padding:12px 24px;background:#d8e8c8;border-radius:8px;color:#708060;text-decoration:none;font-weight:bold;">Verify my email</a></p>
        <p style="color:#999;font-size:13px;">This link expires in 24 hours.</p>
      </div>
    `,
  });
}

export async function sendAccountDeletedEmail(to: string) {
  await resend.emails.send({
    from: FROM,
    to,
    subject: 'Account deleted — Dian Dian',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;">
        <h2 style="color:#9090b0;">Dian Dian (点点)</h2>
        <p>Your account and all associated data have been permanently deleted.</p>
        <p>We're sorry to see you go. If you ever want to come back, you can create a new account at any time.</p>
      </div>
    `,
  });
}
