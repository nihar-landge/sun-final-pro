#!/usr/bin/env bash
# Boots the full CivicPulse services locally (host-run jars + compose MySQL).
#
#   infra/docker-compose.yml  →  MySQL on host port 3307 (a local Homebrew
#   MySQL can occupy 127.0.0.1:3306 and shadow the container)
#
# Usage:
#   scripts/run-local.sh          # start (expects jars built: ./mvnw -DskipTests package)
#   scripts/run-local.sh stop     # stop everything
set -euo pipefail
cd "$(dirname "$0")/../services"

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-3307}"

SERVICES=(auth-service poll-service feedback-service notification-service api-gateway)

if [ "${1:-}" = "stop" ]; then
  pkill -f "java -jar.*SNAPSHOT.jar" 2>/dev/null || true
  echo "stopped"
  exit 0
fi

for svc in "${SERVICES[@]}"; do
  jar="$svc/target/$svc-0.1.0-SNAPSHOT.jar"
  [ -f "$jar" ] || { echo "missing $jar — run: ./mvnw -DskipTests package"; exit 1; }
  nohup java -jar "$jar" > "/tmp/$svc.log" 2>&1 &
  echo "started $svc (log: /tmp/$svc.log)"
  sleep 2
done

echo "waiting for health on :8080-:8084 ..."
for _ in $(seq 1 60); do
  ok=true
  for port in 8080 8081 8082 8083 8084; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 2 "localhost:$port/actuator/health" || true)
    [ "$code" = "200" ] || ok=false
  done
  $ok && { echo "ALL 5 SERVICES HEALTHY"; exit 0; }
  sleep 3
done
echo "TIMED OUT — check /tmp/*.log"; exit 1
