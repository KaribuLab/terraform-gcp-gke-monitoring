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
# Local: Mapeo de tipos internos a tipos del provider GCP
#------------------------------------------------------------------------------
# Los tipos de notification channel en GCP son:
# - email, slack, pagerduty, webhook_tokenauth, etc.
#------------------------------------------------------------------------------

locals {
  # Mapeo de tipos abstractos a tipos del provider
  # webhook_tokenauth: auth_token va en labels (campo público en la API de GCP)
  # webhook_basicauth: username en labels, password en sensitive_labels
  channel_type_map = {
    email              = "email"
    slack              = "slack"
    pagerduty          = "pagerduty"
    webhook            = "webhook_basicauth"
    webhook_tokenauth  = "webhook_tokenauth"
  }

  # Indexar canales por display_name para for_each
  # display_name debe ser único por canal
  channels_by_name = {
    for ch in var.notification_channels : ch.display_name => ch
  }
}

#------------------------------------------------------------------------------
# Recurso: Google Cloud Monitoring Notification Channels
#------------------------------------------------------------------------------
# Crea un canal de notificación por cada entrada en var.notification_channels.
# Usa for_each con display_name como key para mantener canales estables.
#
# Nota: Los valores sensibles (auth_token, service_key, password) van en
# sensitive_labels para evitar que aparezcan en plan/apply output.
#------------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "channels" {
  for_each = local.channels_by_name

  project      = var.project_id
  display_name = each.value.display_name
  type         = local.channel_type_map[each.value.type]

  # Labels públicos (no sensibles)
  labels = each.value.labels

  # Labels sensibles (bloque dinámico, solo si hay valores sensibles)
  # Campos soportados: auth_token (Slack), password (webhook), service_key (PagerDuty)
  dynamic "sensitive_labels" {
    for_each = length(each.value.sensitive_labels) > 0 ? [each.value.sensitive_labels] : []
    content {
      auth_token   = lookup(sensitive_labels.value, "auth_token", null)   # Para Slack
      password     = lookup(sensitive_labels.value, "password", null)     # Para webhook_basicauth
      service_key  = lookup(sensitive_labels.value, "service_key", null)  # Para PagerDuty
    }
  }

  # Habilitado por defecto
  enabled = true

  # Descripción opcional derivada del tipo
  description = "Canal de notificación ${each.value.type}: ${each.value.display_name}"
}
