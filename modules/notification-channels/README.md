# Notification Channels Submódulo

Crea canales de notificación de Cloud Monitoring para ser usados por alert policies.

## Uso

```hcl
module "notification_channels" {
  source = "./modules/notification-channels"

  project_id = "mi-proyecto"

  notification_channels = [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = "devops@example.com"
      }
    },
    {
      type         = "slack"
      display_name = "Slack Alerts"
      labels = {
        channel_name = "#gke-alerts"
      }
      sensitive_labels = {
        auth_token = "xoxb-..."
      }
    }
  ]
}
```

## Tipos de canal soportados

| Tipo | Provider Type | Labels requeridos | Sensitive labels |
|------|--------------|-------------------|------------------|
| email | `email` | `email_address` | Ninguno |
| slack | `slack` | `channel_name` | `auth_token` |
| pagerduty | `pagerduty` | Ninguno | `service_key` |
| webhook | `webhook_tokenauth` | `url` | `username`, `password` (opcional) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | ID del proyecto de GCP | `string` | n/a | yes |
| notification_channels | Lista de canales a crear | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| notification_channel_ids | Mapa de display_name → ID completo del canal |
| notification_channel_names | Mapa de display_name → display_name |
| notification_channel_types | Mapa de display_name → tipo de canal |

## Recursos creados

- `google_monitoring_notification_channel.channels`: Un recurso por cada entrada en `notification_channels`.
