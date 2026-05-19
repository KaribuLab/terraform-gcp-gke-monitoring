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
# Output: IDs de canales de notificación
#------------------------------------------------------------------------------

output "notification_channel_ids" {
  description = <<EOT
Mapa de IDs completos de los canales de notificación creados.
Keys: display_name de cada canal (como se definió en var.notification_channels).
Values: ID completo (projects/PROJECT_ID/notificationChannels/CHANNEL_ID).

Estos IDs se usan para referenciar los canales en alert policies.
Ejemplo de uso en otro módulo:
notification_channels = values(module.notification_channels.notification_channel_ids)
EOT
  value       = { for name, ch in google_monitoring_notification_channel.channels : name => ch.id }
}

output "notification_channel_names" {
  description = "Mapa de nombres de los canales creados. Keys: display_name, Values: display_name (redundante pero útil para consistencia)."
  value       = { for name, ch in google_monitoring_notification_channel.channels : name => ch.display_name }
}

output "notification_channel_types" {
  description = "Mapa de tipos de los canales creados. Keys: display_name, Values: tipo de canal (email, slack, pagerduty, webhook)."
  value       = { for name, ch in google_monitoring_notification_channel.channels : name => ch.type }
}
