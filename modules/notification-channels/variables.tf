/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#------------------------------------------------------------------------------
# Variable: Identificación del proyecto
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se crearán los canales de notificación."
  type        = string
}

#------------------------------------------------------------------------------
# Variable: Canales de notificación
#------------------------------------------------------------------------------
# Mapeo de tipos de canal internos a tipos del provider de GCP:
# - "email"             -> "email"             (hashicorp/google)
# - "slack"             -> "slack"             (hashicorp/google)
# - "pagerduty"         -> "pagerduty"         (hashicorp/google)
# - "webhook"           -> "webhook_basicauth"  (hashicorp/google) — username/password
# - "webhook_tokenauth" -> "webhook_tokenauth"  (hashicorp/google) — token bearer
#
# Para slack y webhook_tokenauth, auth_token va en sensitive_labels.
# El provider Terraform lo traduce internamente al campo labels de la API de GCP.
# Omitir auth_token provoca el error 400: labels[auth_token] is missing.
#
# Referencia: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel
#------------------------------------------------------------------------------

variable "notification_channels" {
  description = <<EOT
Lista de canales de notificación a crear en Cloud Monitoring.

Cada canal debe especificar:
- type: Tipo de canal ("email", "slack", "pagerduty", "webhook", "webhook_tokenauth")
- display_name: Nombre descriptivo único (se usa como key en for_each)
- labels: Mapa de labels según el tipo de canal
- sensitive_labels: Mapa para valores sensibles (auth_token, service_key, password)

Configuración por tipo:

1. email:
   labels = { email_address = "alerts@example.com" }

2. slack:
   labels = { channel_name = "#alerts" }
   sensitive_labels = { auth_token = "xoxb-..." }   # REQUERIDO
   Obtener token: https://cloud.google.com/monitoring/support/notification-options#slack

3. pagerduty:
   sensitive_labels = { service_key = "..." }        # REQUERIDO
   Obtener service key: https://cloud.google.com/monitoring/support/notification-options#pagerduty

4. webhook (autenticación básica):
   labels = { url = "https://hooks.example.com/alerts" }
   sensitive_labels = { password = "..." }           # opcional
   Referencia: https://cloud.google.com/monitoring/support/notification-options#webhooks

5. webhook_tokenauth (autenticación por token Bearer):
   labels = { url = "https://hooks.example.com/alerts" }
   sensitive_labels = { auth_token = "mi-token" }    # REQUERIDO
   Referencia: https://cloud.google.com/monitoring/support/notification-options#webhooks
EOT
  type = list(object({
    type             = string
    display_name     = string
    labels           = map(string)
    sensitive_labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for ch in var.notification_channels : contains(["email", "slack", "pagerduty", "webhook", "webhook_tokenauth"], ch.type)
    ])
    error_message = "El tipo de canal debe ser uno de: email, slack, pagerduty, webhook, webhook_tokenauth."
  }

  validation {
    condition = alltrue([
      for ch in var.notification_channels :
      ch.type != "slack" || can(ch.sensitive_labels["auth_token"])
    ])
    error_message = "Los canales de tipo 'slack' requieren 'auth_token' en sensitive_labels."
  }

  validation {
    condition = alltrue([
      for ch in var.notification_channels :
      ch.type != "webhook_tokenauth" || can(ch.sensitive_labels["auth_token"])
    ])
    error_message = "Los canales de tipo 'webhook_tokenauth' requieren 'auth_token' en sensitive_labels."
  }

  validation {
    condition = alltrue([
      for ch in var.notification_channels :
      ch.type != "pagerduty" || can(ch.sensitive_labels["service_key"])
    ])
    error_message = "Los canales de tipo 'pagerduty' requieren 'service_key' en sensitive_labels."
  }
}
