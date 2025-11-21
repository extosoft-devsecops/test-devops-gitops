{{/*
Expand the name of the chart.
*/}}
{{- define "test-devops.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "test-devops.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "test-devops.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "test-devops.labels" -}}
helm.sh/chart: {{ include "test-devops.chart" . }}
{{ include "test-devops.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.podLabels }}
{{ toYaml .Values.podLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "test-devops.selectorLabels" -}}
app.kubernetes.io/name: {{ include "test-devops.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
App-specific labels
*/}}
{{- define "test-devops.app.labels" -}}
{{ include "test-devops.labels" . }}
app.kubernetes.io/component: application
{{- end }}

{{/*
App selector labels
*/}}
{{- define "test-devops.app.selectorLabels" -}}
{{ include "test-devops.selectorLabels" . }}
app.kubernetes.io/component: application
{{- end }}

{{/*
Graphite-specific labels
*/}}
{{- define "test-devops.graphite.labels" -}}
{{ include "test-devops.labels" . }}
app.kubernetes.io/component: monitoring
{{- end }}

{{/*
Graphite selector labels
*/}}
{{- define "test-devops.graphite.selectorLabels" -}}
{{ include "test-devops.selectorLabels" . }}
app.kubernetes.io/component: monitoring
{{- end }}

{{/*
Create the name of the service account to use for the application
*/}}
{{- define "test-devops.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "test-devops.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create app image name
*/}}
{{- define "test-devops.app.image" -}}
{{- if .Values.app.image.registry }}
{{- printf "%s/%s:%s" .Values.app.image.registry .Values.app.image.repository (.Values.app.image.tag | default .Chart.AppVersion) }}
{{- else }}
{{- printf "%s:%s" .Values.app.image.repository (.Values.app.image.tag | default .Chart.AppVersion) }}
{{- end }}
{{- end }}

{{/*
Create Graphite image name
*/}}
{{- define "test-devops.graphite.image" -}}
{{- if .Values.graphite.image.registry }}
{{- printf "%s/%s:%s" .Values.graphite.image.registry .Values.graphite.image.repository .Values.graphite.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.graphite.image.repository .Values.graphite.image.tag }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "test-devops.annotations" -}}
{{- with .Values.podAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Security context for app
*/}}
{{- define "test-devops.app.securityContext" -}}
{{- if .Values.app.securityContext }}
{{ toYaml .Values.app.securityContext }}
{{- end }}
{{- end }}

{{/*
Security context for Graphite
*/}}
{{- define "test-devops.graphite.securityContext" -}}
{{- if .Values.graphite.securityContext }}
{{ toYaml .Values.graphite.securityContext }}
{{- end }}
{{- end }}