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
# Output: ID del dashboard
#------------------------------------------------------------------------------

output "dashboard_id" {
  description = <<EOT
ID completo del dashboard de Cloud Monitoring creado.
Formato: projects/PROJECT_ID/dashboards/DASHBOARD_ID.

Se puede usar para construir URLs directas al dashboard:
https://console.cloud.google.com/monitoring/dashboards/custom/DASHBOARD_ID?project=PROJECT_ID
EOT
  value       = google_monitoring_dashboard.gke_dashboard.id
}

output "dashboard_name" {
  description = "Nombre del dashboard (título visible en Cloud Monitoring)."
  value       = local.dashboard_title
}

#------------------------------------------------------------------------------
# Output: JSON del dashboard (para referencia/debug)
#------------------------------------------------------------------------------

output "dashboard_json_rendered" {
  description = <<EOT
JSON renderizado del dashboard (útil para debugging).
Muestra el resultado del templatefile con las variables sustituidas.
EOT
  value       = google_monitoring_dashboard.gke_dashboard.dashboard_json
  sensitive   = false
}
