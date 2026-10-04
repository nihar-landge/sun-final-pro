'use strict';

const request = require('supertest');
const { app } = require('../src/server');

const KEY = 'dev-service-key'; // default test key (no env overrides in tests)
const validBody = {
  email: 'citizen@example.com',
  name: 'Citizen',
  reportId: 123,
  reportTitle: 'Road Damage',
  oldStatus: 'OPEN',
  newStatus: 'IN_PROGRESS',
};

describe('email service', () => {
  test('rejects requests without the service key', async () => {
    const res = await request(app).post('/api/email/report-status').send(validBody);
    expect(res.status).toBe(401);
  });

  test('rejects requests with a wrong service key', async () => {
    const res = await request(app)
      .post('/api/email/report-status')
      .set('X-Service-Key', 'wrong-key')
      .send(validBody);
    expect(res.status).toBe(401);
  });

  test('rejects payloads missing required fields', async () => {
    const res = await request(app)
      .post('/api/email/report-status')
      .set('X-Service-Key', KEY)
      .send({ email: 'citizen@example.com' });
    expect(res.status).toBe(400);
  });

  test('rejects invalid recipient emails', async () => {
    const res = await request(app)
      .post('/api/email/report-status')
      .set('X-Service-Key', KEY)
      .send({ ...validBody, email: 'not-an-email' });
    expect(res.status).toBe(400);
  });

  test('accepts a valid payload and reports the email outcome', async () => {
    // Dev mode (no SMTP env in tests) logs and returns 200.
    const res = await request(app)
      .post('/api/email/report-status')
      .set('X-Service-Key', KEY)
      .send(validBody);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('health endpoint reports mode', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
