# High Priority Fixes for Helm Chart

## 1. Fix _helpers.tpl - Missing Standard Labels

Add these standard Kubernetes label helpers:

```yaml
{{- define "test-devops-app.labels" -}}
helm.sh/chart: {{ include "test-devops-app.chart" . }}
{{ include "test-devops-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "test-devops-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "test-devops-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "test-devops-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

## 2. Add Health Checks to Deployment

```yaml
# Add to deployment.yaml containers section:
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3
```

## 3. Fix Chart.yaml

```yaml
apiVersion: v2
name: test-devops-app
description: Test DevOps Node.js app with DogStatsD metrics and Vault integration
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - nodejs
  - datadog
  - vault
  - monitoring
maintainers:
  - name: DevSecOps Team
    email: devsecops@extosoft.app
```

## 4. Standardize Values Structure

All environment values files should have consistent structure:

```yaml
# Standard structure for all values-*.yaml files
replicaCount: 1
image:
  tag: "latest"
env:
  serviceName: "test-devops"
  nodeEnv: "develop"  # change per env

# Vault configuration (standardized)
vault:
  enabled: true
  address: "https://vault-devops.extosoft.app"
  skipTLSVerify: "true"
  roleName: "k8s-app"
  serviceAccount: "vault-auth"
  secrets:
    secretPath: "secret/data/k8s/test-devops-develop"  # change per env
    fields:
      appName: "APP_NAME"
      datadogApiKey: "DATA_DOG_API_KEY"
      nodeEnv: "NODE_ENV"

# Datadog configuration (standardized)
datadog:
  enabled: true
  useVaultSecrets: true
  site: "datadoghq.com"
```

## 5. Add Missing ServiceAccount

```yaml
# templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "test-devops-app.serviceAccountName" . }}
  labels:
    {{- include "test-devops-app.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
```

## 6. Add PodDisruptionBudget for Production

```yaml
# templates/poddisruptionbudget.yaml
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "test-devops-app.fullname" . }}
  labels:
    {{- include "test-devops-app.labels" . | nindent 4 }}
spec:
  {{- if .Values.podDisruptionBudget.minAvailable }}
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if .Values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "test-devops-app.selectorLabels" . | nindent 6 }}
{{- end }}
```