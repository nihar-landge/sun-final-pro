# Kubernetes — deployed on kind (live!)

The platform runs on a local **kind** Kubernetes cluster (v1.35) — this is a
real deployment, verified by the full 27-check E2E suite against the
in-cluster gateway.

## Current topology

```
Phone (adb reverse 8080→8090)  /  laptop curl :8090
        │ kubectl port-forward svc/api-gateway
        ▼
api-gateway  (Deployment + Service + HPA, NodePort 30000)
   ├─ auth-service           ─┐
   ├─ poll-service           │ Pods (1–3 replicas each, startupProbe +
   ├─ feedback-service       │ readinessProbe + livenessProbe)
   ├─ notification-service   │
   └─ sentiment-service      ┘
        │  host.docker.internal
        ▼
Docker Compose data layer: PostgreSQL+PostGIS · Redis · SeaweedFS (S3) · RabbitMQ · Prometheus
```

- **Images**: `civicpulse/<service>:0.1.0`, built from each service's
  layered-jar Dockerfile and loaded with `kind load docker-image`.
- **Stateful layer stays in Compose** (reached via `host.docker.internal`).
  In a real deployment these become in-cluster StatefulSets or managed
  services — see `configmap.yaml` for the single point that changes.
- **Memory tuning**: pods run with `MaxRAMPercentage=70`,
  `MaxMetaspaceSize=128m`, 384Mi limits; `startupProbe` gives slow JVM boots
  up to 5 minutes before liveness kicks in.

## Operating it

```bash
kubectl get pods -n feedbackapp            # fleet status
kubectl scale deployment poll-service -n feedbackapp --replicas=3   # scale out
kubectl logs -n feedbackapp deploy/api-gateway | tail
kubectl port-forward -n feedbackapp svc/api-gateway 8090:8080       # client access
scripts/e2e.sh 8090                        # verify all 27 guarantees
```

## Storage note

MinIO archived its open-source distribution (Docker Hub images removed,
downloads 410). The compose stack now runs **SeaweedFS** on the same S3 API
port 9000 — the MinIO Java client is a standard S3 SigV4 client and works
unchanged. Pre-signed URLs are minted for the public endpoint
(`MINIO_PUBLIC_URL`) with the region pinned, so uploads go directly from
phones/laptops without transiting the services.
