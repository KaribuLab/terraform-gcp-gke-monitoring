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
# - "email"       -> "email" (hashicorp/google)
# - "slack"       -> "slack" (hashicorp/google)
# - "pagerduty"   -> "pagerduty" (hashicorp/google)
# - "webhook"     -> "webhook_tokenauth" (hashicorp/google)
#
# Referencia: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel
#------------------------------------------------------------------------------

variable "notification_channels" {
  description = <<EOT
Lista de canales de notificación a crear en Cloud Monitoring.

Cada canal debe especificar:
- type: Tipo de canal ("email", "slack", "pagerduty", "webhook")
- display_name: Nombre descriptivo único (se usa como key en for_each)
- labels: Mapa de labels según el tipo de canal
- sensitive_labels: Mapa opcional para valores sensibles (auth_token, service_key)

Configuración por tipo:

1. email:
   labels = { email_address = "alerts@example.com" }

2. slack:
   labels = { channel_name = "#alerts" }
   sensitive_labels = { auth_token = "xoxb-..." }

3. pagerduty:
   sensitive_labels = { service_key = "..." }

4. webhook:
   labels = { url = "https://hooks.example.com/alerts" }
   sensitive_labels opcional: { username = "...", password = "..." }
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
      for ch in var.notification_channels : contains(["email", "slack", "pagerduty", "webhook"], ch.type)
    ])
    error_message = "El tipo de canal debe ser uno de: email, slack, pagerduty, webhook."
  }
}
