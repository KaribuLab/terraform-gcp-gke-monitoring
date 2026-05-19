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
# Output: IDs de uptime checks
#------------------------------------------------------------------------------

output "uptime_check_ids" {
  description = <<EOT
Mapa de IDs de las configuraciones de uptime check creadas.
Keys: display_name de cada uptime check.
Values: IDs completos (projects/PROJECT_ID/uptimeCheckConfigs/CONFIG_ID).

Estos IDs pueden usarse para referenciar los checks en otras configuraciones
o para consultar métricas manualmente.
EOT
  value       = { for name, check in google_monitoring_uptime_check_config.checks : name => check.id }
}

output "uptime_check_names" {
  description = "Mapa de nombres de los uptime checks. Keys: display_name, Values: display_name."
  value       = { for name, check in google_monitoring_uptime_check_config.checks : name => check.display_name }
}

#------------------------------------------------------------------------------
# Output: IDs de alert policies de uptime
#------------------------------------------------------------------------------

output "uptime_alert_policy_ids" {
  description = <<EOT
Mapa de IDs de las alert policies asociadas a los uptime checks.
Keys: display_name de cada uptime check.
Values: IDs completos de alert policies (projects/PROJECT_ID/alertPolicies/POLICY_ID).

Estas alertas detectan fallos multi-región (2+ regiones fallando).
EOT
  value       = { for name, policy in google_monitoring_alert_policy.uptime_alerts : name => policy.id }
}

output "uptime_alert_policy_names" {
  description = "Mapa de nombres de display de las alertas de uptime."
  value       = { for name, policy in google_monitoring_alert_policy.uptime_alerts : name => policy.display_name }
}

#------------------------------------------------------------------------------
# Output: URLs monitoreadas
#------------------------------------------------------------------------------

output "monitored_endpoints" {
  description = <<EOT
Mapa de endpoints que están siendo monitoreados.
Keys: display_name del check.
Values: URLs completas (https://host:port/path o http://host:port/path).
EOT
  value = {
    for name, check in local.checks_by_name : name => (
      check.use_ssl ? "https://${check.host}:${check.port}${check.path}" : "http://${check.host}:${check.port}${check.path}"
    )
  }
}
