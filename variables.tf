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
# Variables: Identificación del proyecto y cluster GKE
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se crearán los recursos de monitoreo."
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE a monitorear. Se usa como filtro principal en métricas y logs."
  type        = string
}

variable "cluster_location" {
  description = "Ubicación del cluster GKE (zona o región). Se utiliza principalmente en el dashboard."
  type        = string
  default     = ""
}

variable "namespace_filter" {
  description = <<EOT
Namespace específico a monitorear en alertas de contenedores.
Si está vacío, se monitorean todos los namespaces del cluster.
Solo aplica a alertas de CPU, memoria y pods no saludables.
EOT
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Variables: Canales de notificación
#------------------------------------------------------------------------------

variable "notification_channels" {
  description = <<EOT
Lista de canales de notificación a crear y asociar a las alertas.

Atributos por tipo:
- email:             labels.email_address (requerido)
- slack:             labels.channel_name (requerido), sensitive_labels.auth_token (requerido)
- pagerduty:         sensitive_labels.service_key (requerido)
- webhook:           labels.url (requerido), sensitive_labels.password (opcional) — usa webhook_basicauth
- webhook_tokenauth: labels.url (requerido), labels.auth_token (requerido) — auth_token va en labels, NO en sensitive_labels
EOT
  type = list(object({
    type             = string
    display_name     = string
    labels           = map(string)
    sensitive_labels = optional(map(string), {})
  }))
  default = []
}

#------------------------------------------------------------------------------
# Variables: Uptime checks
#------------------------------------------------------------------------------

variable "uptime_checks" {
  description = <<EOT
Lista de endpoints HTTP/HTTPS para monitorear con uptime checks.
Cada entrada crea un uptime check y su alerta asociada.
La alerta se dispara cuando fallan probes desde 2+ regiones simultáneamente.
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
}

#------------------------------------------------------------------------------
# Variables: Toggles para habilitar/deshabilitar alertas
#------------------------------------------------------------------------------

variable "enable_cpu_alert" {
  description = "Habilitar alerta de alta utilización de CPU en contenedores. Requiere que los pods tengan limits.cpu definidos."
  type        = bool
  default     = true
}

variable "enable_memory_alert" {
  description = "Habilitar alerta de alta utilización de memoria en contenedores. Requiere que los pods tengan limits.memory definidos."
  type        = bool
  default     = true
}

variable "enable_restart_alert" {
  description = "Habilitar alerta de reinicios excesivos de pods (restart_count > umbral en ventana de 10 minutos)."
  type        = bool
  default     = true
}

variable "enable_pod_unhealthy_alert" {
  description = "Habilitar alerta log-based para pods en estado no saludable (BackOff, Unhealthy, FailedScheduling)."
  type        = bool
  default     = true
}

variable "enable_node_disk_alert" {
  description = "Habilitar alerta de uso de disco en nodos (MQL calculando ratio used/total de ephemeral storage)."
  type        = bool
  default     = true
}

variable "enable_pv_disk_alert" {
  description = "Habilitar alerta de uso de disco en PersistentVolumes."
  type        = bool
  default     = true
}

variable "enable_node_not_ready_alert" {
  description = "Habilitar alerta para nodos que pasan a estado NotReady."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Variables: Dashboard
#------------------------------------------------------------------------------

variable "enable_dashboard" {
  description = "Crear dashboard de Cloud Monitoring para visualizar métricas del cluster GKE."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Variables: Umbrales personalizables
#------------------------------------------------------------------------------

variable "thresholds" {
  description = <<EOT
Umbrales personalizados para las alertas métricas.
- cpu_utilization: Ratio de uso de CPU vs limit (0.0 - 1.0). Default: 0.8 (80%)
- memory_utilization: Ratio de uso de memoria vs limit (0.0 - 1.0). Default: 0.85 (85%)
- restart_count: Número de reinicios en ventana de 10 minutos. Default: 3
- node_disk_utilization: Ratio de uso de disco en nodos (0.0 - 1.0). Default: 0.85 (85%)
- pv_utilization: Ratio de uso de PersistentVolume (0.0 - 1.0). Default: 0.85 (85%)
EOT
  type = object({
    cpu_utilization       = optional(number, 0.8)
    memory_utilization    = optional(number, 0.85)
    restart_count         = optional(number, 3)
    node_disk_utilization = optional(number, 0.85)
    pv_utilization        = optional(number, 0.85)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Variables: Duraciones de condiciones
#------------------------------------------------------------------------------

variable "durations" {
  description = <<EOT
Duraciones de las condiciones de alerta (cuánto tiempo debe violarse el umbral para activar).
Formato: número seguido de 's' (segundos). Múltiplos de 60s recomendados.
- cpu_duration: Default "300s" (5 minutos)
- memory_duration: Default "300s" (5 minutos)
- restart_duration: Default "600s" (10 minutos) - ventana de agregación para contar reinicios
- disk_duration: Default "300s" (5 minutos)
- pv_duration: Default "300s" (5 minutos)
EOT
  type = object({
    cpu_duration     = optional(string, "300s")
    memory_duration  = optional(string, "300s")
    restart_duration = optional(string, "600s")
    disk_duration    = optional(string, "300s")
    pv_duration      = optional(string, "300s")
  })
  default = {}
}

#------------------------------------------------------------------------------
# Variables: Estrategia de alertas y etiquetas
#------------------------------------------------------------------------------

variable "alert_auto_close" {
  description = "Duración después de la cual un incidente se cierra automáticamente si no hay nuevos datos. Default: 86400s (24 horas)."
  type        = string
  default     = "86400s"
}

variable "labels" {
  description = <<EOT
Etiquetas comunes para aplicar a todas las alert policies creadas.
Útil para organización, billing, y filtrado posterior en Cloud Monitoring.
Ejemplo: { environment = "production", team = "devops" }
EOT
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Variables: Filtros personalizados
#------------------------------------------------------------------------------

variable "pod_unhealthy_log_filter" {
  description = <<EOT
Filtro de Logs personalizado para la alerta de pods no saludables.
Si es null, se usa el filtro por defecto que detecta:
- jsonPayload.reason = "BackOff"
- jsonPayload.reason = "Unhealthy"
- jsonPayload.reason = "FailedScheduling"

Para validar tu filtro personalizado, usa Logs Explorer en GCP:
resource.type="k8s_pod" AND tu_filtro_aqui
EOT
  type        = string
  default     = null
}
