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
# Outputs: Todos los recursos creados
#------------------------------------------------------------------------------

output "alert_policy_ids" {
  description = "IDs de todas las alert policies creadas."
  value       = module.gke_monitoring.alert_policy_ids
}

output "alert_policy_names" {
  description = "Nombres de todas las alert policies."
  value       = module.gke_monitoring.alert_policy_names
}

output "notification_channel_ids" {
  description = "IDs de los canales de notificación."
  value       = module.gke_monitoring.notification_channel_ids
}

output "uptime_check_ids" {
  description = "IDs de los uptime checks (si están configurados)."
  value       = module.gke_monitoring.uptime_check_ids
}

output "dashboard_id" {
  description = "ID del dashboard de Cloud Monitoring."
  value       = module.gke_monitoring.dashboard_id
}

output "monitored_cluster" {
  description = "Nombre del cluster monitoreado."
  value       = module.gke_monitoring.monitored_cluster
}
