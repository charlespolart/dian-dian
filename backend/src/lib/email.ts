import { MailerSend, EmailParams, Sender, Recipient } from 'mailersend';
import { Resend } from 'resend';
import { env } from './env.js';

// Pick a provider once at module load. MailerSend wins when both keys are
// present so the prod cutover happens the moment MAILERSEND_API_TOKEN lands
// in the environment — no code change required.
type Provider = 'mailersend' | 'resend';
const provider: Provider = env.MAILERSEND_API_TOKEN ? 'mailersend' : 'resend';

const mailerSend = env.MAILERSEND_API_TOKEN
    ? new MailerSend({ apiKey: env.MAILERSEND_API_TOKEN })
    : null;
const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : null;

// MailerSend is set up on the diandian.* subdomain so each app stays isolated;
// Resend was on the apex while we only had one app — the subdomain isn't
// verified there yet, so during the transition Resend keeps using the apex.
const FROM_EMAIL_MAILERSEND = 'noreply@diandian.overridedev.com';
const FROM_EMAIL_RESEND = 'noreply@overridedev.com';
const FROM_NAME = 'Dian Dian';

console.log(`[email] using ${provider}`);

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  /** Display name for the From header. Defaults to "Dian Dian". */
  fromName?: string;
  /** Address used when the recipient hits Reply. */
  replyTo?: string;
}

export async function sendEmail(opts: EmailOptions): Promise<void> {
  if (provider === 'mailersend') {
    await sendViaMailerSend(opts);
  } else {
    await sendViaResend(opts);
  }
}

async function sendViaMailerSend(opts: EmailOptions): Promise<void> {
  if (!mailerSend) throw new Error('MailerSend not configured');
  const sender = new Sender(FROM_EMAIL_MAILERSEND, opts.fromName ?? FROM_NAME);
  const params = new EmailParams()
    .setFrom(sender)
    .setTo([new Recipient(opts.to)])
    .setSubject(opts.subject)
    .setHtml(opts.html);
  if (opts.replyTo) {
    params.setReplyTo(new Sender(opts.replyTo));
  }
  await mailerSend.email.send(params);
}

async function sendViaResend(opts: EmailOptions): Promise<void> {
  if (!resend) throw new Error('Resend not configured');
  const fromName = opts.fromName ?? FROM_NAME;
  await resend.emails.send({
    from: `${fromName} <${FROM_EMAIL_RESEND}>`,
    to: opts.to,
    replyTo: opts.replyTo,
    subject: opts.subject,
    html: opts.html,
  });
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

export async function sendPasswordResetEmail(to: string, code: string) {
  await sendEmail({
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
  await sendEmail({
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
  await sendEmail({
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
