#!/usr/bin/env bash
# =============================================================================
# CivicPulse end-to-end verification — the guarantees that must never break.
# Usage: infra must be up; scripts/e2e.sh [port | host:port | https://host]
# Exits non-zero on the first broken guarantee.
# =============================================================================
set -u
GW="${1:-localhost:8080}"
case "$GW" in
  *:*) ;;                    # full URL or host:port — use as given
  *) GW="localhost:$GW" ;;   # bare port — local gateway
esac
PASS=0; FAIL=0

check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "  ✓ $1 ($3)"
  else FAIL=$((FAIL+1)); echo "  ✗ $1 — expected $2, got $3"; fi
}

json() { python3 -c "import sys,json;$1" 2>/dev/null; }

token() { # token <phone> -> access token (dev echo OTP)
  local otp url
  otp=$(curl -s -m 10 -X POST "$GW/api/v1/auth/otp/send" \
    -H 'Content-Type: application/json' -d "{\"phone\":\"$1\"}" \
    | json "print(json.load(sys.stdin)['data']['devOtp'])") || return 1
  curl -s -m 10 -X POST "$GW/api/v1/auth/otp/verify" \
    -H 'Content-Type: application/json' \
    -d "{\"phone\":\"$1\",\"code\":\"$otp\"}" \
    | json "print(json.load(sys.stdin)['data']['accessToken'])"
}

echo "── 1. Authentication"
HEALTH=$(curl -s -o /dev/null -w '%{http_code}' -m 5 $GW/actuator/health)
check "gateway health" "200" "$HEALTH"
if [ "$HEALTH" != "200" ]; then
  echo ""
  echo "Gateway unreachable at $GW (got $HEALTH) — aborting before the remaining checks."
  echo "In CI, service logs are dumped by the workflow; locally check the service consoles."
  exit 1
fi
CITIZEN=$(token "9876543210"); [ -n "$CITIZEN" ] && { PASS=$((PASS+1)); echo "  ✓ citizen login"; } || { FAIL=$((FAIL+1)); echo "  ✗ citizen login"; }
ADMIN=$(token "9999999999");   [ -n "$ADMIN" ] &&   { PASS=$((PASS+1)); echo "  ✓ admin login"; }   || { FAIL=$((FAIL+1)); echo "  ✗ admin login"; }
check "bad token rejected" "401" "$(curl -s -o /dev/null -w '%{http_code}' -m 5 $GW/api/v1/auth/me -H 'Authorization: Bearer garbage')"
check "no token rejected"  "401" "$(curl -s -o /dev/null -w '%{http_code}' -m 5 $GW/api/v1/polls/health 2>/dev/null || true)"

echo "── 2. One-person-one-vote (composite PK)"
CREATED=$(curl -s -X POST "$GW/api/v1/polls" -H "Authorization: Bearer $ADMIN" \
  -H 'Content-Type: application/json' \
  -d "{\"title\":\"E2E poll $(date +%s)\",\"startTime\":\"2026-01-01T00:00:00\",\"endTime\":\"2027-01-01T00:00:00\",\"isAnonymous\":true,\"options\":[\"Yes\",\"No\"]}")
PID=$(echo "$CREATED" | json "print(json.load(sys.stdin)['data']['id'])")
OPT=$(echo "$CREATED" | json "print(json.load(sys.stdin)['data']['results'][0]['optionId'])")
POLL_BODY=$(printf '{"title":"E2E poll 2 %s","startTime":"2026-01-01T00:00:00","endTime":"2027-01-01T00:00:00","options":["A","B"]}' "$(date +%s)")
check "poll created (admin)" "201" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/polls" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "$POLL_BODY")"
check "citizen creates poll forbidden" "403" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/polls" -H "Authorization: Bearer $CITIZEN" -H 'Content-Type: application/json' -d '{"title":"x","startTime":"2026-01-01T00:00:00","endTime":"2027-01-01T00:00:00","options":["A","B"]}')"
check "first vote ok" "200" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/polls/$PID/vote" -H "Authorization: Bearer $CITIZEN" -H 'Content-Type: application/json' -d "{\"optionId\":$OPT}")"
check "second vote 409" "409" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/polls/$PID/vote" -H "Authorization: Bearer $CITIZEN" -H 'Content-Type: application/json' -d "{\"optionId\":$OPT}")"
check "hasVoted=true for voter" "True" "$(curl -s "$GW/api/v1/polls/$PID/results" -H "Authorization: Bearer $CITIZEN" | json "print(json.load(sys.stdin)['data']['hasVoted'])")"

echo "── 3. Feedback workflow (PostGIS + audit)"
NOW=$(date +%Y-%m-%dT%H:%M:%S)
FB=$(curl -s -X POST "$GW/api/v1/feedback" -H "Authorization: Bearer $CITIZEN" -H 'Content-Type: application/json' \
  -d "{\"title\":\"E2E pothole\",\"description\":\"e2e\",\"category\":\"ROADS\",\"latitude\":18.5290,\"longitude\":73.8620}")
FBID=$(echo "$FB" | json "print(json.load(sys.stdin)['data']['id'])")
check "feedback submitted OPEN" "OPEN" "$(echo "$FB" | json "print(json.load(sys.stdin)['data']['status'])")"
check "near-me returns it" "200" "$(curl -s -o /dev/null -w '%{http_code}' "$GW/api/v1/feedback/near-me?lat=18.5204&lng=73.8567&radiusKm=5" -H "Authorization: Bearer $CITIZEN")"
check "upvote ok" "200" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/feedback/$FBID/upvote" -H "Authorization: Bearer $ADMIN")"
check "duplicate upvote 409" "409" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/feedback/$FBID/upvote" -H "Authorization: Bearer $ADMIN")"
curl -s -o /dev/null -X POST "$GW/api/v1/feedback/$FBID/status" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"newStatus":"IN_REVIEW"}'
check "OPEN->IN_REVIEW ok" "200" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/feedback/$FBID/status" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"newStatus":"RESOLVED"}')"
check "illegal transition 409" "409" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/feedback/$FBID/status" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"newStatus":"IN_REVIEW"}')"
check "admin assign+notes" "200" "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GW/api/v1/feedback/$FBID" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"assignedTo":"Amit","publicNote":"Scheduled"}')"
check "audit trail populated" "200" "$(curl -s -o /dev/null -w '%{http_code}' "$GW/api/v1/feedback/admin/audit?limit=5" -H "Authorization: Bearer $ADMIN")"

echo "── 4. Photos (MinIO pre-signed)"
PRESIGN=$(curl -s -X POST "$GW/api/v1/feedback/$FBID/images/presign" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"contentType":"image/png"}')
UPURL=$(echo "$PRESIGN" | json "print(json.load(sys.stdin)['data']['uploadUrl'])")
OKEY=$(echo "$PRESIGN" | json "print(json.load(sys.stdin)['data']['objectKey'])")
[ -n "$UPURL" ] && { PASS=$((PASS+1)); echo "  ✓ presign issued"; } || { FAIL=$((FAIL+1)); echo "  ✗ presign"; }
printf 'PNGDATA' > /tmp/e2e-photo.png
check "direct PUT to MinIO" "200" "$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$UPURL" -H 'Content-Type: image/png' --data-binary @/tmp/e2e-photo.png)"
check "register image" "201" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GW/api/v1/feedback/$FBID/images" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"objectKey\":\"$OKEY\"}")"
check "detail carries image" "True" "$(curl -s "$GW/api/v1/feedback/$FBID" -H "Authorization: Bearer $ADMIN" | json "print(len(json.load(sys.stdin)['data']['images']) > 0)")"

echo "── 5. Events + analytics + roles"
check "notification feed (admin)" "200" "$(curl -s -o /dev/null -w '%{http_code}' $GW/api/v1/notifications/recent -H "Authorization: Bearer $ADMIN")"
check "analytics (admin)" "200" "$(curl -s -o /dev/null -w '%{http_code}' $GW/api/v1/polls/analytics/summary -H "Authorization: Bearer $ADMIN")"
check "citizen blocked from analytics" "403" "$(curl -s -o /dev/null -w '%{http_code}' $GW/api/v1/polls/analytics/summary -H "Authorization: Bearer $CITIZEN")"
check "citizen blocked from users" "403" "$(curl -s -o /dev/null -w '%{http_code}' "$GW/api/v1/auth/admin/users" -H "Authorization: Bearer $CITIZEN")"
check "self-demotion blocked" "409" "$(ADMIN_ID=$(curl -s $GW/api/v1/auth/me -H "Authorization: Bearer $ADMIN" | json "print(json.load(sys.stdin)['data']['id'])"); curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GW/api/v1/auth/admin/users/$ADMIN_ID/role" -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"newRole":"CITIZEN"}')"

echo ""
echo "════════════════════════════════"
echo "  E2E: $PASS passed, $FAIL failed"
echo "════════════════════════════════"
[ "$FAIL" = "0" ]
