{{/* Regenerate the full component name, e.g. civicpulse-auth-service */}}
{{- define "civicpulse.name" -}}
{{- printf "%s-%s" (include "civicpulse.fullname" .) .name -}}
{{- end -}}

{{- define "civicpulse.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "civicpulse.labels" -}}
app.kubernetes.io/name: civicpulse
app.kubernetes.io/instance: {{ include "civicpulse.fullname" . }}
app.kubernetes.io/component: {{ .name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
