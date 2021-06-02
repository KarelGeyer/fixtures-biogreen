## Projects

| Project Branch | production | staging |
|----------------|----|----|
{{- range $key, $value :=  (ds "m") }}
| [{{ $key }}](src/{{ $key }}) | {{ if (has $value "production") }}{{ if (has $value.production "project_id") }}{{ $value.production.project_id }}{{ end }}{{ end }} | {{ if (has $value "staging") }}{{ if (has $value.staging "project_id") }}{{ $value.staging.project_id }}{{ end }}{{ end }} |
{{- end }}
