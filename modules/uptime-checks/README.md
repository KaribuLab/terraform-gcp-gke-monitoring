# Uptime Checks Submódulo

Crea uptime checks de Cloud Monitoring y alertas asociadas para endpoints HTTP/HTTPS.

## Características

- **Uptime checks** desde múltiples regiones (USA, EUROPE, ASIA_PACIFIC)
- **Alertas multi-región**: Solo se dispara si fallan 2+ regiones simultáneamente
- **Reducción de falsos positivos**: Requiere consenso de múltiples probes

## Lógica de la alerta multi-región

```
Métrica: monitoring.googleapis.com/uptime_check/check_passed
├── Probes desde USA        → check_passed = 0 (fallo)
├── Probes desde EUROPE     → check_passed = 1 (ok)
└── Probes desde ASIA_PACIFIC → check_passed = 0 (fallo)

Agrupación por location: 2 regiones reportan fallo
Trigger count = 2: Alerta se activa
```

## Uso

```hcl
module "uptime_checks" {
  source = "./modules/uptime-checks"

  project_id = "mi-proyecto"

  uptime_checks = [
    {
      display_name = "API Health"
      host         = "api.miapp.com"
      path         = "/health"
      regions      = ["USA", "EUROPE", "ASIA_PACIFIC"]
    },
    {
      display_name = "App Health"
      host         = "app.miapp.com"
      path         = "/healthz"
      use_ssl      = true
      validate_ssl = true
    }
  ]

  notification_channel_ids = ["projects/.../notificationChannels/..."]

  labels = {
    service = "public-api"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | ID del proyecto GCP | `string` | n/a | yes |
| uptime_checks | Lista de checks a crear | `list(object)` | `[]` | no |
| notification_channel_ids | IDs de canales de notificación | `list(string)` | `[]` | no |
| labels | Etiquetas para alertas | `map(string)` | `{}` | no |

### uptime_checks object

| Field | Description | Default |
|-------|-------------|---------|
| display_name | Nombre único del check | n/a |
| host | Hostname o IP | n/a |
| path | Ruta del endpoint | n/a |
| port | Puerto TCP | 443 |
| use_ssl | Usar HTTPS | true |
| validate_ssl | Validar certificado | true |
| timeout | Timeout de probe | 10s |
| period | Frecuencia de chequeo | 60s |
| regions | Regiones de probe | ["USA", "EUROPE", "ASIA_PACIFIC"] |

## Outputs

| Name | Description |
|------|-------------|
| uptime_check_ids | Mapa de display_name → ID del uptime check |
| uptime_alert_policy_ids | Mapa de display_name → ID de alert policy |
| monitored_endpoints | Mapa de display_name → URL completa |

## Recursos

- `google_monitoring_uptime_check_config.checks`: Configuraciones de uptime check
- `google_monitoring_alert_policy.uptime_alerts`: Alertas de fallo multi-región
