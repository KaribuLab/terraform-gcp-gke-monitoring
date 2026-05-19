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
# Outputs: Alert Policies
#------------------------------------------------------------------------------

output "alert_policy_ids" {
  description = <<EOT
Mapa de IDs de las alert policies creadas por el submódulo alert-policies.
Keys: cpu, memory, restart, pod_unhealthy, node_disk, pv_disk, node_not_ready.
Values: IDs completos (projects/PROJECT_ID/alertPolicies/POLICY_ID).
EOT
  value       = module.alert_policies.alert_policy_ids
}

output "alert_policy_names" {
  description = <<EOT
Mapa de nombres de display de las alert policies creadas.
Keys: cpu, memory, restart, pod_unhealthy, node_disk, pv_disk, node_not_ready.
Values: Strings con los display_name asignados.
EOT
  value       = module.alert_policies.alert_policy_names
}

#------------------------------------------------------------------------------
# Outputs: Notification Channels
#------------------------------------------------------------------------------

output "notification_channel_ids" {
  description = <<EOT
Mapa de IDs de los notification channels creados.
Keys: display_name de cada canal.
Values: IDs completos (projects/PROJECT_ID/notificationChannels/CHANNEL_ID).
EOT
  value       = module.notification_channels.notification_channel_ids
}

#------------------------------------------------------------------------------
# Outputs: Uptime Checks
#------------------------------------------------------------------------------

output "uptime_check_ids" {
  description = <<EOT
Mapa de IDs de los uptime checks creados.
Keys: display_name de cada uptime check.
Values: IDs completos de las configuraciones de uptime check.
Solo se crean si var.uptime_checks no está vacío.
EOT
  value       = length(var.uptime_checks) > 0 ? module.uptime_checks[0].uptime_check_ids : {}
}

output "uptime_alert_policy_ids" {
  description = <<EOT
Mapa de IDs de las alert policies asociadas a los uptime checks.
Keys: display_name de cada uptime check.
Values: IDs completos de las alert policies que detectan fallos multi-región.
Solo se crean si var.uptime_checks no está vacío.
EOT
  value       = length(var.uptime_checks) > 0 ? module.uptime_checks[0].uptime_alert_policy_ids : {}
}

#------------------------------------------------------------------------------
# Outputs: Dashboard
#------------------------------------------------------------------------------

output "dashboard_id" {
  description = <<EOT
ID del dashboard de Cloud Monitoring creado (si var.enable_dashboard = true).
Formato: projects/PROJECT_ID/dashboards/DASHBOARD_ID.
Será null si el dashboard no fue creado.
EOT
  value       = var.enable_dashboard ? module.dashboard[0].dashboard_id : null
}

#------------------------------------------------------------------------------
# Outputs: Información del cluster monitoreado
#------------------------------------------------------------------------------

output "monitored_cluster" {
  description = "Nombre del cluster GKE que está siendo monitoreado por este módulo."
  value       = var.cluster_name
}

output "monitored_project" {
  description = "ID del proyecto GCP donde se crearon los recursos de monitoreo."
  value       = var.project_id
}
