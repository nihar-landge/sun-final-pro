#!/usr/bin/env bash
# One-time recovery from the 2026-09-29 OOM crash-cycle (same playbook as
# SESSION-HANDOFF W9/W10): stop everything, drop the removed sentiment stub,
# then boot one JVM at a time so boot-time memory spikes never overlap.
set -euo pipefail
NS=feedbackapp

echo "== Scaling all deployments to zero =="
kubectl -n "$NS" scale deploy --all --replicas=0

echo "== Deleting the removed sentiment-service deployment =="
kubectl -n "$NS" delete deploy/sentiment-service || echo "(already gone)"

echo "== Waiting for all pods to terminate =="
while [ "$(kubectl -n "$NS" get pods --no-headers 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; do
  sleep 2
done
kubectl -n "$NS" get pods 2>/dev/null || echo "(no pods — clean slate)"

for svc in auth-service poll-service feedback-service notification-service api-gateway; do
  echo
  echo "== Booting $svc =="
  kubectl -n "$NS" scale deploy/$svc --replicas=1
  kubectl -n "$NS" wait --for=condition=ready pod -l app=$svc --timeout=300s \
    && echo "$svc READY"
done

echo
echo "== Final state =="
kubectl -n "$NS" get pods
