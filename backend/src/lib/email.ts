import { Resend } from 'resend';
import { env } from './env.js';

const resend = new Resend(env.RESEND_API_KEY);
const FROM = 'Dian Dian <noreply@mydiandian.app>';

export async function sendPasswordResetEmail(to: string, token: string) {
  const link = `${env.APP_URL}/reset-password?token=${token}`;
  await resend.emails.send({
    from: FROM,
    to,
    subject: 'Reset your password — Dian Dian',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;">
        <h2 style="color:#9090b0;">Dian Dian (点点)</h2>
        <p>You requested a password reset. Click the link below to set a new password:</p>
        <p><a href="${link}" style="display:inline-block;padding:12px 24px;background:#d8e8c8;border-radius:8px;color:#708060;text-decoration:none;font-weight:bold;">Reset my password</a></p>
        <p style="color:#999;font-size:13px;">This link expires in 1 hour. If you didn't request this, ignore this email.</p>
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
