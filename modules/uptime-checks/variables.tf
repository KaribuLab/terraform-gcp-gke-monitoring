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
  description = "ID del proyecto de GCP donde se crearán los uptime checks."
  type        = string
}

#------------------------------------------------------------------------------
# Variable: Configuración de uptime checks
#------------------------------------------------------------------------------
# Cada entrada crea:
# 1. Un uptime check (google_monitoring_uptime_check_config)
# 2. Una alert policy asociada que se dispara cuando 2+ regiones reportan fallo
#
# Referencia de la API:
# https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.uptimeCheckConfigs
#------------------------------------------------------------------------------

variable "uptime_checks" {
  description = <<EOT
Lista de endpoints HTTP/HTTPS para monitorear con uptime checks.

Cada check incluye:
- display_name: Nombre descriptivo único (usado como key en for_each)
- host: Hostname o IP a monitorear (ej: "api.example.com")
- path: Ruta del endpoint (ej: "/health", "/healthz")
- port: Puerto TCP (default: 443)
- use_ssl: Usar HTTPS (default: true)
- validate_ssl: Validar certificado SSL (default: true)
- timeout: Timeout de cada probe (default: "10s")
- period: Frecuencia de chequeo (default: "60s")
- regions: Regiones desde las que probar (default: ["USA", "EUROPE", "ASIA_PACIFIC"])

Nota: La alerta asociada se dispara cuando 2 o más regiones reportan fallo
simultáneamente, lo que reduce falsos positivos por problemas regionales.
EOT
  type = list(object({
    display_name = string
    host         = string
    path         = string
    port         = optional(number, 443)
    use_ssl      = optional(bool, true)
    validate_ssl = optional(bool, true)
    timeout      = optional(string, "10s")
    period       = optional(string, "60s")
    regions      = optional(list(string), ["USA", "EUROPE", "ASIA_PACIFIC"])
  }))
  default = []

  validation {
    condition = alltrue([
      for check in var.uptime_checks : contains([60, 300, 600, 900], tonumber(trimsuffix(check.period, "s")))
    ])
    error_message = "El periodo debe ser uno de: 60s, 300s, 600s, 900s."
  }
}

#------------------------------------------------------------------------------
# Variable: Canales de notificación
#------------------------------------------------------------------------------

variable "notification_channel_ids" {
  description = <<EOT
Lista de IDs de canales de notificación para las alertas de uptime checks.
Debe contener los IDs completos (projects/PROJECT_ID/notificationChannels/CHANNEL_ID).
Típicamente pasados desde el módulo notification-channels.
EOT
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Variable: Etiquetas comunes
#------------------------------------------------------------------------------

variable "labels" {
  description = "Etiquetas comunes para aplicar a las alert policies de uptime checks."
  type        = map(string)
  default     = {}
}
