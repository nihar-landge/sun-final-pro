'use strict';

/**
 * CivicPulse email service (Node.js + Express).
 *
 * One job: turn a report-status-change payload into an email and send it.
 * It owns no database and holds no CivicPulse business logic — Spring Boot
 * services call it over HTTP with a shared service key.
 *
 * Contract:
 *   POST /api/email/report-status   { email, name, reportId, reportTitle, oldStatus, newStatus }
 *   Header: X-Service-Key: <EXPRESS_SERVICE_KEY>
 *
 * Behaviour:
 *   - Development (EMAIL_DEV_MODE=true, no SMTP env): logs the email, 200.
 *   - Production (SMTP_HOST etc. set): sends via nodemailer;
 *     SMTP failure → HTTP 502 so the caller can log it (and move on).
 */

const express = require('express');
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());

const SERVICE_KEY = process.env.EXPRESS_SERVICE_KEY || 'dev-service-key';
const DEV_MODE = process.env.EMAIL_DEV_MODE === 'true' || !process.env.SMTP_HOST;
const FROM = process.env.EMAIL_FROM || 'CivicPulse <no-reply@civicpulse.in>';
const SMTP = {
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: process.env.SMTP_SECURE === 'true',
  auth: process.env.SMTP_USER
    ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
    : undefined,
};

const transporter = DEV_MODE ? null : nodemailer.createTransport({ ...SMTP });

function safeEqual(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i += 1) diff |= ab[i] ^ bb[i];
  return diff === 0;
}

function renderHtml(mail) {
  return [
    '<div style="font-family:Arial,sans-serif;max-width:480px">',
    `<h2 style="margin:0 0 8px">Report update: ${mail.reportTitle}</h2>`,
    `<p>Hi ${mail.name || 'there'},</p>`,
    `<p>Your report <strong>#${mail.reportId} — ${mail.reportTitle}</strong> moved from`,
    ` <strong>${mail.oldStatus}</strong> to <strong>${mail.newStatus}</strong>.</p>`,
    '<p>Open the CivicPulse app to see the full history and comments.</p>',
    '<p style="color:#888;font-size:12px">CivicPulse — civic engagement for your city</p>',
    '</div>',
  ].join('\n');
}

function renderText(mail) {
  return `Hi ${mail.name || 'there'},\n\n`
    + `Your report #${mail.reportId} — ${mail.reportTitle} moved from `
    + `${mail.oldStatus} to ${mail.newStatus}.\n\n— CivicPulse`;
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok', mode: DEV_MODE ? 'development' : 'smtp' });
});

app.post('/api/email/report-status', async (req, res) => {
  // 1. Service authentication — this endpoint is for Spring Boot services only.
  if (!safeEqual(req.get('X-Service-Key') || '', SERVICE_KEY)) {
    return res.status(401).json({ success: false, message: 'Invalid service key' });
  }

  // 2. Request validation.
  const { email, name, reportId, reportTitle, oldStatus, newStatus } = req.body || {};
  if (!email || !reportId || !reportTitle || !oldStatus || !newStatus) {
    return res.status(400).json({
      success: false,
      message: 'email, reportId, reportTitle, oldStatus and newStatus are required',
    });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(String(email))) {
    return res.status(400).json({ success: false, message: 'Invalid recipient email' });
  }

  const mail = { email, name, reportId, reportTitle, oldStatus, newStatus };

  // 3. Development mode: log instead of sending, so demos never need SMTP.
  if (DEV_MODE) {
    console.log('[email:dev] would send ->', JSON.stringify({
      to: email,
      subject: `Report #${reportId} is now ${newStatus}`,
      text: renderText(mail),
    }));
    return res.json({ success: true, message: 'Email logged (development mode)' });
  }

  // 4. Production: really send. Failure is reported back to the caller,
  //    which logs it — the citizen workflow never depends on this.
  try {
    await transporter.sendMail({
      from: FROM,
      to: email,
      subject: `Report #${reportId} is now ${newStatus}`,
      text: renderText(mail),
      html: renderHtml(mail),
    });
    return res.json({ success: true, message: 'Email sent' });
  } catch (err) {
    console.error('[email:smtp] send failed:', err.message);
    return res.status(502).json({ success: false, message: 'Email delivery failed' });
  }
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('[email] unhandled:', err.message);
  res.status(400).json({ success: false, message: 'Malformed request' });
});

module.exports = { app, DEV_MODE };
