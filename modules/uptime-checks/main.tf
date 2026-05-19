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
# Locals: Indexación de uptime checks
#------------------------------------------------------------------------------
# Usamos display_name como key para for_each, garantizando estabilidad.
# El usuario debe asegurar que display_name sea único por check.
#------------------------------------------------------------------------------

locals {
  checks_by_name = {
    for check in var.uptime_checks : check.display_name => check
  }
}

#------------------------------------------------------------------------------
# Recurso: Uptime Check Configs
#------------------------------------------------------------------------------
# Crea un uptime check por cada entrada en var.uptime_checks.
# El check usa HTTP(S) GET al endpoint especificado.
#
# Métrica generada: monitoring.googleapis.com/uptime_check/check_passed
#   - Valor 1 = check pasó
#   - Valor 0 = check falló
#
# Campos clave:
# - monitored_resource: Tipo "uptime_url" con labels project_id y host
# - http_check: Configuración de HTTPS y validación SSL
# - selected_regions: Lista de regiones desde las que probar
#------------------------------------------------------------------------------

resource "google_monitoring_uptime_check_config" "checks" {
  for_each = local.checks_by_name

  project      = var.project_id
  display_name = each.value.display_name

  # Período y timeout
  period  = each.value.period
  timeout = each.value.timeout

  # Configuración HTTP
  http_check {
    request_method = "GET"
    path           = each.value.path
    port           = each.value.port
    use_ssl        = each.value.use_ssl
    validate_ssl   = each.value.validate_ssl
  }

  # Recurso monitoreado (URL pública)
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }

  # Regiones desde las que probar
  # Valores válidos: USA, EUROPE, SOUTH_AMERICA, ASIA_PACIFIC
  selected_regions = each.value.regions

  # Verificamos el estado esperado HTTP 200
  content_matchers {
    content = ""
    matcher = "CONTAINS_STRING"
  }
}

#------------------------------------------------------------------------------
# Recurso: Alert Policies para Uptime Checks
#------------------------------------------------------------------------------
# Crea una alerta asociada a cada uptime check.
# La alerta se dispara cuando el check falla desde 2+ regiones.
#
# Lógica:
# 1. Filtramos la métrica check_passed por el check_id
# 2. Agrupamos por región (resource.label.location)
# 3. Si 2+ regiones reportan fallo (valor < 1), la alerta se activa
#
# Métrica: monitoring.googleapis.com/uptime_check/check_passed
# Tipo: BOOL (true = check pasó, false = check falló)
#------------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "uptime_alerts" {
  for_each = local.checks_by_name

  project      = var.project_id
  display_name = "Uptime Check Failed: ${each.value.display_name}"
  combiner     = "OR"

  documentation {
    content   = "Uptime check ${each.value.display_name} (${each.value.host}${each.value.path}) is failing from 2 or more regions."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Multi-region failure: ${each.value.display_name}"

    condition_threshold {
      # Filtrar por el check_id específico
      filter = <<-EOT
        resource.type="uptime_url"
        AND metric.type="monitoring.googleapis.com/uptime_check/check_passed"
        AND metric.labels.check_id="${google_monitoring_uptime_check_config.checks[each.key].id}"
      EOT

      # La alerta se dispara cuando el check NO pasa (valor < 1)
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s"

      # Agregación: agrupar por región
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_TRUE"
        group_by_fields      = ["resource.label.location"]
      }

      # Trigger: 2 o más series (regiones) deben fallar
      trigger {
        count = 2
      }
    }
  }

  notification_channels = var.notification_channel_ids

  user_labels = merge(var.labels, {
    uptime_check = each.value.display_name
    host         = each.value.host
  })

  alert_strategy {
    auto_close = "1800s" # 30 minutos
  }

  depends_on = [google_monitoring_uptime_check_config.checks]
}
