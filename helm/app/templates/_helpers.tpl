{{- define "test-devops-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "test-devops-app.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "test-devops-app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
