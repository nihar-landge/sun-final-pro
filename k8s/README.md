# Kubernetes manifests (weeks 9-10)

Pattern manifests for the API gateway + auth-service. Add poll/feedback/
notification/sentiment deployments by copying `auth-service.yaml` and
changing names/ports/images. Deploy once the phase-4 work begins:

```bash
kubectl apply -f k8s/base/
kubectl -n feedbackapp rollout status deployment/api-gateway
```

Secrets (`k8s/base/secret.yaml` contains placeholder values) must be filled
from a real secret store before any real deployment.
