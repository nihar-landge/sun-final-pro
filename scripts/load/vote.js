// k6 load test for the vote path (the p95 < 200 ms blueprint target).
//
// Setup: infra + all services running.
// Run:  k6 run -e GW=http://localhost:8080 scripts/load/vote.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    voting: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '20s', target: 20 },
        { duration: '40s', target: 20 },
        { duration: '10s', target: 0 },
      ],
    },
  },
  thresholds: {
    // Blueprint success metric: API response time p95 < 200 ms.
    'http_req_duration{name:results}': ['p(95)<200'],
    checks: ['rate>0.99'],
  },
};

const GW = __ENV.GW || 'http://localhost:8080';

// The virtual user logs in once (dev-echo OTP) then polls live results,
// mimicking the read-heavy traffic of an open poll.
export function setup() {
  const otpRes = http.post(`${GW}/api/v1/auth/otp/send`,
    JSON.stringify({ phone: '9876543210' }),
    { headers: { 'Content-Type': 'application/json' } });
  const otp = otpRes.json('data.devOtp');
  const login = http.post(`${GW}/api/v1/auth/otp/verify`,
    JSON.stringify({ phone: '9876543210', code: otp }),
    { headers: { 'Content-Type': 'application/json' } });
  return { token: login.json('data.accessToken') };
}

export default function (data) {
  const params = {
    headers: { Authorization: `Bearer ${data.token}` },
    tags: { name: 'results' },
  };
  const res = http.get(`${GW}/api/v1/polls/1/results`, params);
  check(res, { 'results 200': (r) => r.status === 200 });
  sleep(1);
}
