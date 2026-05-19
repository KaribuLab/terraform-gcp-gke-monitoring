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
# Variables: Identificación del proyecto y cluster
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se crearán las alert policies."
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE a monitorear. Se usa en filtros de métricas y logs como resource.labels.cluster_name."
  type        = string
}

variable "namespace_filter" {
  description = <<EOT
Namespace específico para filtrar alertas de contenedores.
Si está vacío, se monitorean todos los namespaces.
Se añade como sufijo al filtro de cluster en alertas de CPU, memoria y pods no saludables.
EOT
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Variable: Canales de notificación
#------------------------------------------------------------------------------

variable "notification_channel_ids" {
  description = <<EOT
Lista de IDs de canales de notificación a asociar a todas las alertas.
Debe contener los IDs completos (projects/PROJECT_ID/notificationChannels/CHANNEL_ID).
Típicamente se pasa desde el output del módulo notification-channels:
values(module.notification_channels.notification_channel_ids)
EOT
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Variables: Toggles de habilitación
#------------------------------------------------------------------------------

variable "enable_cpu_alert" {
  description = "Habilitar alerta de alta utilización de CPU. Requiere que los contenedores tengan limits.cpu definidos."
  type        = bool
  default     = true
}

variable "enable_memory_alert" {
  description = "Habilitar alerta de alta utilización de memoria. Requiere que los contenedores tengan limits.memory definidos."
  type        = bool
  default     = true
}

variable "enable_restart_alert" {
  description = "Habilitar alerta de reinicios excesivos de contenedores."
  type        = bool
  default     = true
}

variable "enable_pod_unhealthy_alert" {
  description = "Habilitar alerta log-based para pods en estado no saludable."
  type        = bool
  default     = true
}

variable "enable_node_disk_alert" {
  description = "Habilitar alerta de uso de disco en nodos (ephemeral storage)."
  type        = bool
  default     = true
}

variable "enable_pv_disk_alert" {
  description = "Habilitar alerta de uso de disco en PersistentVolumes."
  type        = bool
  default     = true
}

variable "enable_node_not_ready_alert" {
  description = "Habilitar alerta para nodos en estado NotReady."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Variables: Umbrales
#------------------------------------------------------------------------------

variable "thresholds" {
  description = <<EOT
Umbrales para las alertas. Todos son ratios (0.0-1.0) excepto restart_count.
- cpu_utilization: Ratio CPU usada / CPU limit. Default: 0.8
- memory_utilization: Ratio memoria usada / memoria limit. Default: 0.85
- restart_count: Número de reinicios en ventana de 10 minutos. Default: 3
- node_disk_utilization: Ratio disco usado / disco total en nodos. Default: 0.85
- pv_utilization: Ratio PV usado / PV total. Default: 0.85
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
# Variables: Duraciones
#------------------------------------------------------------------------------

variable "durations" {
  description = <<EOT
Duraciones de las condiciones de alerta (cuánto tiempo debe durar la violación).
Formato: número seguido de 's' (segundos). Deben ser múltiplos de 60s.
- cpu_duration, memory_duration, disk_duration, pv_duration: Default 300s (5 min)
- restart_duration: Default 600s (10 min, ventana de agregación para contar reinicios)
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
# Variables: Estrategia de alertas
#------------------------------------------------------------------------------

variable "alert_auto_close" {
  description = "Tiempo de auto-cierre de incidentes sin nuevos datos. Default: 86400s (24 horas)."
  type        = string
  default     = "86400s"
}

variable "labels" {
  description = "Etiquetas (labels) comunes para todas las alert policies."
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Variable: Filtro personalizado para alerta de pods no saludables
#------------------------------------------------------------------------------

variable "pod_unhealthy_log_filter" {
  description = <<EOT
Filtro de Logs personalizado para la alerta de pods no saludables.
Si es null, se usa el filtro por defecto:
  resource.type="k8s_pod" AND resource.labels.cluster_name="CLUSTER_NAME"
  AND (jsonPayload.reason="BackOff" OR jsonPayload.reason="Unhealthy" OR jsonPayload.reason="FailedScheduling")
Para validar: usar Logs Explorer en GCP con el filtro propuesto.
EOT
  type        = string
  default     = null
}
