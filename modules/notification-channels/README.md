# Notification Channels Submódulo

Crea canales de notificación de Cloud Monitoring para ser usados por alert policies.

## Uso

```hcl
module "notification_channels" {
  source = "./modules/notification-channels"

  project_id = "mi-proyecto"

  notification_channels = [
    # Email — sin credenciales
    {
      type         = "email"
      display_name = "DevOps Team"
      labels       = { email_address = "devops@example.com" }
    },

    # Slack — auth_token en sensitive_labels (nunca en labels)
    # Cómo obtener el token: https://cloud.google.com/monitoring/support/notification-options#slack
    # Crear Slack Bot Token:  https://api.slack.com/authentication/token-types#bot
    {
      type         = "slack"
      display_name = "Slack Alerts"
      labels       = { channel_name = "#gke-alerts" }
      sensitive_labels = {
        auth_token = "xoxb-..."   # Bot token de Slack (requerido)
      }
    },

    # PagerDuty — service_key en sensitive_labels
    # Cómo obtener la key: https://cloud.google.com/monitoring/support/notification-options#pagerduty
    # Crear Integration Key: https://support.pagerduty.com/docs/services-and-integrations
    {
      type         = "pagerduty"
      display_name = "PagerDuty Critical"
      labels       = {}
      sensitive_labels = {
        service_key = "abc123..."   # Integration Key de PagerDuty (requerido)
      }
    },

    # Webhook con token Bearer — auth_token en sensitive_labels
    # Referencia: https://cloud.google.com/monitoring/support/notification-options#webhooks
    {
      type         = "webhook_tokenauth"
      display_name = "Mi Webhook"
      labels       = { url = "https://hooks.example.com/alerts" }
      sensitive_labels = {
        auth_token = "mi-token-secreto"   # Token Bearer (requerido)
      }
    },
  ]
}
```

## Tipos de canal soportados

| Tipo | Provider Type | `labels` requeridos | `sensitive_labels` requeridos | Cómo obtener el token/key |
|------|--------------|---------------------|-------------------------------|---------------------------|
| `email` | `email` | `email_address` | — | — |
| `slack` | `slack` | `channel_name` | `auth_token` ✱ | [Configurar Slack en GCP][slack-docs] → [Crear Slack App y Bot Token][slack-token] |
| `pagerduty` | `pagerduty` | — | `service_key` ✱ | [Configurar PagerDuty en GCP][pd-docs] → [Obtener Integration Key en PagerDuty][pd-key] |
| `webhook` | `webhook_basicauth` | `url` | `password` (opcional) | [Webhooks en GCP][webhook-docs] |
| `webhook_tokenauth` | `webhook_tokenauth` | `url` | `auth_token` ✱ | [Webhooks en GCP][webhook-docs] |

✱ Campo obligatorio. Omitirlo causa el error `400: labels[auth_token/service_key] is missing`.

> **¿Por qué `sensitive_labels` y no `labels`?**  
> El provider de Terraform abstrae los valores sensibles en el bloque `sensitive_labels` para que no aparezcan en la salida de `plan`/`apply`. Internamente, el provider los envía al campo `labels` que exige la API de GCP. El error `labels[auth_token] is missing` ocurre cuando ese bloque no se renderiza (porque `sensitive_labels = {}`).

[slack-docs]: https://cloud.google.com/monitoring/support/notification-options#slack
[slack-token]: https://api.slack.com/authentication/token-types#bot
[pd-docs]: https://cloud.google.com/monitoring/support/notification-options#pagerduty
[pd-key]: https://support.pagerduty.com/docs/services-and-integrations#create-a-generic-events-api-integration
[webhook-docs]: https://cloud.google.com/monitoring/support/notification-options#webhooks

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
