import { Router } from 'express';

const router = Router();

function layout(title: string, content: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title} — Dian Dian</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DotGothic16&family=Silkscreen:wght@400;700&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #f5f0d0;
      color: #5c4a2a;
      font-family: 'DotGothic16', 'Silkscreen', monospace;
      font-size: 15px;
      line-height: 1.7;
      min-height: 100vh;
      padding: 24px 16px 64px;
    }
    .container {
      max-width: 640px;
      margin: 0 auto;
    }
    .back-link {
      display: inline-block;
      margin-bottom: 24px;
      color: #a0855b;
      text-decoration: none;
      font-family: 'Silkscreen', monospace;
      font-size: 13px;
      border: 2px solid #a0855b;
      padding: 4px 12px;
      transition: background 0.15s, color 0.15s;
    }
    .back-link:hover {
      background: #a0855b;
      color: #f5f0d0;
    }
    h1 {
      font-family: 'Silkscreen', monospace;
      font-size: 26px;
      color: #3b2e14;
      margin-bottom: 8px;
    }
    .subtitle {
      font-size: 13px;
      color: #a0855b;
      margin-bottom: 32px;
    }
    h2 {
      font-family: 'Silkscreen', monospace;
      font-size: 17px;
      color: #3b2e14;
      margin-top: 28px;
      margin-bottom: 8px;
    }
    p, li {
      margin-bottom: 10px;
    }
    ul {
      padding-left: 24px;
      margin-bottom: 12px;
    }
    a {
      color: #7a6240;
      text-decoration: underline;
    }
    a:hover {
      color: #3b2e14;
    }
    hr {
      border: none;
      border-top: 2px dashed #d4c99a;
      margin: 32px 0;
    }
    .footer {
      margin-top: 48px;
      font-size: 12px;
      color: #a0855b;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <a class="back-link" href="/">&larr; Back to app</a>
    ${content}
    <div class="footer">Dian Dian (点点) &mdash; mydiandian.app</div>
  </div>
</body>
</html>`;
}

// ── Privacy Policy ──────────────────────────────────────────────────────────

router.get('/privacy', (_req, res) => {
  const html = layout('Privacy Policy', `
    <h1>Privacy Policy</h1>
    <p class="subtitle">Last updated: March 26, 2026</p>

    <h2>1. Introduction</h2>
    <p>
      Dian Dian ("we", "us", "our") operates the mydiandian.app website and
      service. This Privacy Policy explains how we collect, use, and protect
      your personal information when you use our service.
    </p>

    <h2>2. Data We Collect</h2>
    <ul>
      <li><strong>Account information:</strong> email address and password (stored securely hashed — we never store your password in plain text).</li>
      <li><strong>Tracker data:</strong> the pages, day cells, colors, and legend entries you create within the app.</li>
      <li><strong>Technical data:</strong> basic server logs (IP address, request timestamps) for security and troubleshooting purposes.</li>
    </ul>

    <h2>3. How We Use Your Data</h2>
    <ul>
      <li>To provide and maintain the Dian Dian service.</li>
      <li>To authenticate you and keep your account secure.</li>
      <li>To sync your tracker data across your devices.</li>
    </ul>
    <p>We do <strong>not</strong> use your data for advertising, profiling, or any purpose beyond operating the service.</p>

    <h2>4. Third-Party Tracking</h2>
    <p>
      We do <strong>not</strong> use any third-party analytics, tracking scripts, or advertising
      networks. No data is shared with or sold to third parties.
    </p>

    <h2>5. Cookies</h2>
    <p>
      We use cookies <strong>solely for authentication</strong> (session and refresh tokens).
      We do not use tracking cookies, advertising cookies, or any non-essential cookies.
    </p>

    <h2>6. Data Storage &amp; Security</h2>
    <p>
      Your data is stored on our own servers. Passwords are hashed using Argon2.
      All connections are encrypted via HTTPS. We take reasonable measures to
      protect your data, but no system is 100% secure.
    </p>

    <h2>7. Data Retention &amp; Deletion</h2>
    <p>
      We retain your data for as long as your account is active. You can
      <strong>delete your account and all associated data</strong> at any time
      from within the app. Once deleted, your data is permanently removed from
      our servers.
    </p>

    <h2>8. Your Rights (GDPR)</h2>
    <p>If you are in the European Economic Area, you have the right to:</p>
    <ul>
      <li>Access the personal data we hold about you.</li>
      <li>Request correction of inaccurate data.</li>
      <li>Request deletion of your data.</li>
      <li>Export your data in a portable format.</li>
      <li>Object to or restrict processing of your data.</li>
    </ul>
    <p>To exercise any of these rights, please contact us at <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>.</p>

    <h2>9. Children</h2>
    <p>
      Dian Dian is not intended for children under 13. We do not knowingly
      collect data from children under 13. If you believe a child has provided
      us with personal data, please contact us and we will delete it.
    </p>

    <h2>10. Changes to This Policy</h2>
    <p>
      We may update this policy from time to time. We will notify registered
      users of any material changes via email. Continued use of the service
      after changes constitutes acceptance of the updated policy.
    </p>

    <h2>11. Contact</h2>
    <p>
      If you have questions about this Privacy Policy, please reach out at
      <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>.
    </p>
  `);

  res.type('html').send(html);
});

// ── Terms of Use ────────────────────────────────────────────────────────────

router.get('/terms', (_req, res) => {
  const html = layout('Terms of Use', `
    <h1>Terms of Use</h1>
    <p class="subtitle">Last updated: March 26, 2026</p>

    <h2>1. Acceptance</h2>
    <p>
      By accessing or using Dian Dian ("the Service"), you agree to be bound by
      these Terms. If you do not agree, please do not use the Service.
    </p>

    <h2>2. Eligibility</h2>
    <p>
      You must be at least <strong>13 years of age</strong> to use Dian Dian.
      By creating an account, you represent that you meet this age requirement.
    </p>

    <h2>3. Your Account</h2>
    <ul>
      <li>You are responsible for keeping your login credentials secure.</li>
      <li>You are responsible for all activity that occurs under your account.</li>
      <li>Notify us immediately if you suspect unauthorized access.</li>
    </ul>

    <h2>4. Your Content</h2>
    <p>
      All tracker data, pages, and content you create within Dian Dian
      <strong>belongs to you</strong>. We do not claim ownership of your content.
      We only access it as necessary to provide and maintain the Service.
    </p>

    <h2>5. Acceptable Use</h2>
    <p>You agree <strong>not</strong> to:</p>
    <ul>
      <li>Use the Service for any unlawful purpose.</li>
      <li>Attempt to gain unauthorized access to any part of the Service.</li>
      <li>Interfere with or disrupt the Service or its infrastructure.</li>
      <li>Automate access to the Service (bots, scrapers, etc.) without permission.</li>
      <li>Use the Service to harass, abuse, or harm others.</li>
    </ul>

    <h2>6. Service Availability</h2>
    <p>
      The Service is provided <strong>"as is" and "as available"</strong> without
      warranties of any kind, express or implied. We do not guarantee that the
      Service will be uninterrupted, error-free, or secure at all times.
    </p>

    <h2>7. Limitation of Liability</h2>
    <p>
      To the fullest extent permitted by law, Dian Dian and its developer shall
      not be liable for any indirect, incidental, special, consequential, or
      punitive damages, including loss of data, arising from your use of the
      Service.
    </p>

    <h2>8. Account Termination</h2>
    <ul>
      <li>You may delete your account at any time from within the app.</li>
      <li>We reserve the right to suspend or terminate accounts that violate
          these Terms or abuse the Service, with or without notice.</li>
    </ul>

    <h2>9. Changes to These Terms</h2>
    <p>
      We may update these Terms from time to time. Material changes will be
      communicated to registered users via email. Continued use of the Service
      after changes constitutes acceptance.
    </p>

    <h2>10. Governing Law</h2>
    <p>
      These Terms shall be governed by and construed in accordance with
      applicable law, without regard to conflict of law principles.
    </p>

    <h2>11. Contact</h2>
    <p>
      Questions about these Terms? Reach out at
      <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>.
    </p>
  `);

  res.type('html').send(html);
});

// ── About ───────────────────────────────────────────────────────────────────

router.get('/about', (_req, res) => {
  const html = layout('About', `
    <h1>About Dian Dian</h1>
    <p class="subtitle">点点 &mdash; dot by dot, day by day</p>

    <h2>What is Dian Dian?</h2>
    <p>
      Dian Dian is a visual year tracker that lets you <strong>color-code each
      day</strong> of the year. Create custom pages with your own color legends,
      then fill in each day to build a beautiful pixel-art overview of your year.
    </p>
    <p>
      Track habits, moods, workouts, reading days, side-project progress — anything
      you want to see at a glance across 365 days.
    </p>

    <h2>How It Works</h2>
    <ul>
      <li>Create a page and define your color legend (e.g., green = gym, blue = reading).</li>
      <li>Tap a day to cycle through your colors.</li>
      <li>Watch your year fill up, one dot at a time.</li>
      <li>Your data syncs across devices in real time.</li>
    </ul>

    <h2>Built by an Indie Developer</h2>
    <p>
      Dian Dian is designed, built, and maintained by a solo indie developer.
      No big team, no venture capital — just a love for pixel aesthetics and
      useful tools.
    </p>
    <p>
      Have feedback, ideas, or just want to say hi?
      <a href="/contact">Get in touch</a>.
    </p>

    <hr />

    <p style="text-align:center; font-family:'Silkscreen',monospace; font-size:13px; color:#a0855b;">
      Made with care &mdash; one pixel at a time.
    </p>
  `);

  res.type('html').send(html);
});

// ── Contact ─────────────────────────────────────────────────────────────────

router.get('/contact', (_req, res) => {
  const html = layout('Contact', `
    <h1>Contact</h1>
    <p class="subtitle">We'd love to hear from you</p>

    <form id="contactForm" style="margin-top:20px;">
      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">Name</label>
      <input type="text" name="name" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;" />

      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">Email</label>
      <input type="email" name="email" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;" />

      <label style="font-family:'Silkscreen',monospace;font-size:12px;display:block;margin-bottom:4px;">Message</label>
      <textarea name="message" rows="5" required
        style="width:100%;padding:10px;font-family:'DotGothic16',monospace;font-size:14px;border:2px solid #d4c99a;border-radius:8px;background:#faf6e8;color:#5c4a2a;margin-bottom:14px;outline:none;resize:vertical;"></textarea>

      <button type="submit" id="submitBtn"
        style="font-family:'Silkscreen',monospace;font-size:13px;padding:10px 24px;background:#d8e8c8;border:2px solid #b0c8a0;border-radius:10px;color:#708060;cursor:pointer;width:100%;transition:transform 0.15s;">
        Send message
      </button>
    </form>

    <div id="formMsg" style="text-align:center;margin-top:16px;font-size:14px;display:none;"></div>

    <hr />

    <p style="text-align:center;font-size:13px;color:#a0855b;">
      Or email us directly at <a href="mailto:contact@mydiandian.app">contact@mydiandian.app</a>
    </p>

    <p style="font-size:13px;color:#a0855b;margin-top:16px;">
      As a solo indie project, please allow up to <strong>48 hours</strong> for
      a response. We read every message.
    </p>

    <script>
      document.getElementById('contactForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('submitBtn');
        const msg = document.getElementById('formMsg');
        const form = e.target;
        btn.disabled = true;
        btn.textContent = 'Sending...';
        msg.style.display = 'none';
        try {
          const res = await fetch('/api/contact', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              name: form.name.value,
              email: form.email.value,
              message: form.message.value,
            }),
          });
          if (res.ok) {
            msg.style.color = '#708060';
            msg.textContent = 'Message sent! We\\'ll get back to you soon.';
            form.reset();
          } else {
            msg.style.color = '#c0392b';
            msg.textContent = 'Failed to send. Please try again or email us directly.';
          }
        } catch {
          msg.style.color = '#c0392b';
          msg.textContent = 'Network error. Please try again.';
        }
        msg.style.display = 'block';
        btn.disabled = false;
        btn.textContent = 'Send message';
      });
    </script>
  `);

  res.type('html').send(html);
});

export default router;
