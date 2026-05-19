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
# Output: IDs de alert policies threshold-based
#------------------------------------------------------------------------------

output "threshold_alert_ids" {
  description = <<EOT
Mapa de IDs de las alertas threshold-based creadas.
Keys: cpu, memory, restart, pv_disk, node_not_ready
Values: IDs completos (projects/PROJECT_ID/alertPolicies/POLICY_ID)
EOT
  value       = { for key, policy in google_monitoring_alert_policy.threshold_alerts : key => policy.id }
}

#------------------------------------------------------------------------------
# Output: IDs combinados de todas las alert policies
#------------------------------------------------------------------------------

output "alert_policy_ids" {
  description = <<EOT
Mapa de IDs de TODAS las alert policies creadas por este módulo.
Keys: cpu, memory, restart, pv_disk, node_not_ready, node_disk, pod_unhealthy
Values: IDs completos (projects/PROJECT_ID/alertPolicies/POLICY_ID)

Nota: node_disk y pod_unhealthy solo aparecen si están habilitadas.
EOT
  value = merge(
    { for key, policy in google_monitoring_alert_policy.threshold_alerts : key => policy.id },
    local.enable_node_disk ? { node_disk = google_monitoring_alert_policy.node_disk[0].id } : {},
    local.enable_pod_unhealthy ? { pod_unhealthy = google_monitoring_alert_policy.pod_unhealthy[0].id } : {}
  )
}

#------------------------------------------------------------------------------
# Output: Nombres de display de todas las alertas
#------------------------------------------------------------------------------

output "alert_policy_names" {
  description = <<EOT
Mapa de nombres de display de las alert policies creadas.
Keys: cpu, memory, restart, pv_disk, node_not_ready, node_disk, pod_unhealthy
Values: Strings con los display_name asignados
EOT
  value = merge(
    { for key, policy in google_monitoring_alert_policy.threshold_alerts : key => policy.display_name },
    local.enable_node_disk ? { node_disk = google_monitoring_alert_policy.node_disk[0].display_name } : {},
    local.enable_pod_unhealthy ? { pod_unhealthy = google_monitoring_alert_policy.pod_unhealthy[0].display_name } : {}
  )
}

#------------------------------------------------------------------------------
# Output: Resumen de alertas habilitadas
#------------------------------------------------------------------------------

output "enabled_alerts_summary" {
  description = "Lista de nombres de alertas que fueron habilitadas y creadas."
  value       = keys(local.enabled_alerts)
}
