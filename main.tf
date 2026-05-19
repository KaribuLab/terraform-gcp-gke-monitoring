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
# Módulo Terraform: Monitoreo Preventivo GKE
#------------------------------------------------------------------------------
# Este módulo crea recursos de Cloud Monitoring para clusters GKE:
# 1. Notification Channels (email, slack, pagerduty, webhook)
# 2. Alert Policies (7 tipos de alertas métricas y log-based)
# 3. Uptime Checks (endpoints HTTP/HTTPS con alertas multi-región)
# 4. Dashboard (visualización de métricas clave del cluster)
#
# Orden de creación:
#   1. notification_channels (sin dependencias)
#   2. alert_policies, uptime_checks (dependen de notification_channels)
#   3. dashboard (condicional, sin dependencias de otros módulos)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Submódulo: Notification Channels
#------------------------------------------------------------------------------
# Crea canales de notificación que serán referenciados por todas las alertas.
# No tiene dependencias.
#------------------------------------------------------------------------------

module "notification_channels" {
  source = "./modules/notification-channels"

  project_id            = var.project_id
  notification_channels = var.notification_channels
}

#------------------------------------------------------------------------------
# Submódulo: Alert Policies
#------------------------------------------------------------------------------
# Crea 7 tipos de alertas para el cluster GKE:
# - CPU utilization (containers)
# - Memory utilization (containers)
# - Pod restart count
# - Unhealthy pods (log-based)
# - Node disk usage (MQL)
# - PV disk usage
# - Node NotReady
#
# Dependencias: requiere IDs de notification channels.
#------------------------------------------------------------------------------

module "alert_policies" {
  source = "./modules/alert-policies"

  project_id               = var.project_id
  cluster_name             = var.cluster_name
  namespace_filter         = var.namespace_filter
  notification_channel_ids = values(module.notification_channels.notification_channel_ids)

  # Toggles de habilitación
  enable_cpu_alert            = var.enable_cpu_alert
  enable_memory_alert         = var.enable_memory_alert
  enable_restart_alert        = var.enable_restart_alert
  enable_pod_unhealthy_alert  = var.enable_pod_unhealthy_alert
  enable_node_disk_alert      = var.enable_node_disk_alert
  enable_pv_disk_alert        = var.enable_pv_disk_alert
  enable_node_not_ready_alert = var.enable_node_not_ready_alert

  # Umbrales y duraciones
  thresholds       = var.thresholds
  durations        = var.durations
  alert_auto_close = var.alert_auto_close
  labels           = var.labels

  # Filtro personalizado para alerta de pods no saludables
  pod_unhealthy_log_filter = var.pod_unhealthy_log_filter
}

#------------------------------------------------------------------------------
# Submódulo: Uptime Checks
#------------------------------------------------------------------------------
# Crea uptime checks HTTP/HTTPS y alertas asociadas.
# La alerta se dispara cuando fallan probes desde 2+ regiones.
#
# Dependencias: requiere IDs de notification channels.
# Solo se crea si hay uptime_checks definidos.
#------------------------------------------------------------------------------

module "uptime_checks" {
  source = "./modules/uptime-checks"
  count  = length(var.uptime_checks) > 0 ? 1 : 0

  project_id               = var.project_id
  uptime_checks            = var.uptime_checks
  notification_channel_ids = values(module.notification_channels.notification_channel_ids)
  labels                   = var.labels
}

#------------------------------------------------------------------------------
# Submódulo: Dashboard
#------------------------------------------------------------------------------
# Crea un dashboard de Cloud Monitoring con widgets para visualizar
# métricas del cluster: CPU, memoria, restarts, disk usage, PV usage, pod status.
#
# No tiene dependencias de otros módulos (usa solo variables del cluster).
# Solo se crea si enable_dashboard = true.
#------------------------------------------------------------------------------

module "dashboard" {
  source = "./modules/dashboard"
  count  = var.enable_dashboard ? 1 : 0

  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.cluster_location
  namespace_filter = var.namespace_filter
}
