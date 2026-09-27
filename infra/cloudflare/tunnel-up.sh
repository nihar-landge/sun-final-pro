#!/usr/bin/env bash
# Brings up the CivicPulse public endpoints on brickbyte.me:
#   https://api.brickbyte.me    -> k8s gateway
#   https://photos.brickbyte.me -> SeaweedFS S3
# Prereq: kind cluster running, cloudflared logged in.
set -e
cd "$(dirname "$0")"

# 1. kubectl port-forward (auto-restart loop — it can drop)
if ! pgrep -f 'kubectl port-forward -n feedbackapp' > /dev/null; then
  nohup bash -c 'while true; do kubectl port-forward -n feedbackapp svc/api-gateway 8090:8080 >> /tmp/port-forward.log 2>&1; sleep 3; done' \
    > /dev/null 2>&1 &
  echo "port-forward loop started"
fi
sleep 2

# 2. cloudflared tunnel (auto-restart loop)
if ! pgrep -f 'cloudflared.*tunnel run civicpulse' > /dev/null; then
  nohup bash -c 'while true; do cloudflared --config ~/.cloudflared/civicpulse-config.yml tunnel run civicpulse >> /tmp/cf-tunnel.log 2>&1; sleep 5; done' \
    > /dev/null 2>&1 &
  echo "tunnel loop started"
fi
sleep 6

curl -s -o /dev/null -w 'api.brickbyte.me: %{http_code}\n' -m 15 https://api.brickbyte.me/actuator/health
curl -s -o /dev/null -w 'photos.brickbyte.me: %{http_code}\n' -m 15 https://photos.brickbyte.me/
