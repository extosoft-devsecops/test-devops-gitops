# Security Improvements for Helm Chart

## 1. Add Security Context for Application

```yaml
# Add to deployment.yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 1001
            runAsGroup: 1001
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
```

## 2. Add Network Policies

```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "test-devops-app.fullname" . }}
  labels:
    {{- include "test-devops-app.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "test-devops-app.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: {{ .Values.networkPolicy.allowedNamespaces | default .Release.Namespace }}
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to: []
      ports:
        - protocol: TCP
          port: 443  # HTTPS
        - protocol: TCP
          port: 53   # DNS
        - protocol: UDP
          port: 53   # DNS
{{- end }}
```

## 3. Vault Security Enhancements

```yaml
# Add to vault-datadog-secretprovider.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-datadog-secret
  namespace: {{ .Release.Namespace }}
spec:
  provider: vault
  parameters:
    vaultAddress: {{ .Values.vault.address | quote }}
    vaultSkipTLSVerify: {{ .Values.vault.skipTLSVerify | quote }}
    vaultCACertPath: "/vault/tls/ca.crt"  # Add TLS verification
    roleName: {{ .Values.vault.roleName | quote }}
    objects: |
      - objectName: "app-name"
        secretPath: {{ .Values.vault.secrets.secretPath | quote }}
        secretKey: {{ .Values.vault.secrets.fields.appName | quote }}
      - objectName: "datadog-api-key"
        secretPath: {{ .Values.vault.secrets.secretPath | quote }}
        secretKey: {{ .Values.vault.secrets.fields.datadogApiKey | quote }}
      - objectName: "node-env"
        secretPath: {{ .Values.vault.secrets.secretPath | quote }}
        secretKey: {{ .Values.vault.secrets.fields.nodeEnv | quote }}
```