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
# Alert Policies: Threshold-based alerts (for_each sobre local.enabled_alerts)
#------------------------------------------------------------------------------
# Crea alert policies para:
# - CPU utilization
# - Memory utilization
# - Pod restart count
# - PV utilization
# - Node NotReady
#
# Cada alerta en local.enabled_alerts tiene:
# - display_name: Nombre visible en Cloud Monitoring
# - filter: Filtro de métrica (ver locals.tf para documentación de filtros)
# - metric_type: Tipo de métrica de GKE
# - threshold: Valor umbral para disparar
# - duration: Cuánto tiempo debe mantenerse la condición
# - comparison: COMPARISON_GT (mayor que) o COMPARISON_LT (menor que)
#------------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "threshold_alerts" {
  for_each = local.enabled_alerts

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = "OR"

  documentation {
    content   = each.value.description
    mime_type = "text/markdown"
  }

  conditions {
    display_name = each.value.display_name

    condition_threshold {
      filter          = "metric.type = \"${each.value.metric_type}\" AND ${each.value.filter}"
      duration        = each.value.duration
      comparison      = each.value.comparison
      threshold_value = each.value.threshold

      aggregations {
        alignment_period   = lookup(each.value, "alignment_period", "60s")
        per_series_aligner = lookup(each.value, "aligner", "ALIGN_MEAN")
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channel_ids

  user_labels = var.labels

  alert_strategy {
    auto_close = var.alert_auto_close
  }
}

#------------------------------------------------------------------------------
# Alert Policy: Node Disk Utilization (MQL-based)
#------------------------------------------------------------------------------
# Esta alerta usa Monitoring Query Language (MQL) porque requiere calcular
# un ratio entre dos métricas (used_bytes / total_bytes).
#
# Métricas utilizadas:
# - kubernetes.io/node/ephemeral_storage/used_bytes
# - kubernetes.io/node/ephemeral_storage/total_bytes
#
# Para validar la query: Metrics Explorer > MQL
#------------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "node_disk" {
  count = local.enable_node_disk ? 1 : 0

  project      = var.project_id
  display_name = "GKE ${var.cluster_name}: High Node Disk Utilization"
  combiner     = "OR"

  documentation {
    content   = "Node ephemeral storage utilization exceeds ${var.thresholds.node_disk_utilization * 100}% for ${var.durations.disk_duration}"
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "GKE ${var.cluster_name}: High Node Disk Utilization"

    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_node\n",
        "| metric 'kubernetes.io/node/ephemeral_storage/used_bytes'\n",
        "| filter (resource.cluster_name == '${var.cluster_name}')\n",
        "| group_by [resource.cluster_name, resource.node_name], [used: mean(value.used_bytes)]\n",
        "| {\n",
        "    fetch k8s_node\n",
        "    | metric 'kubernetes.io/node/ephemeral_storage/total_bytes'\n",
        "    | filter (resource.cluster_name == '${var.cluster_name}')\n",
        "    | group_by [resource.cluster_name, resource.node_name], [total: mean(value.total_bytes)]\n",
        "}\n",
        "| join\n",
        "| value val(0) / val(1)\n",
        "| condition val() > ${var.thresholds.node_disk_utilization}"
      ])

      duration = var.durations.disk_duration

      trigger {
        count = 1
      }
    }
  }

  notification_channels = var.notification_channel_ids

  user_labels = var.labels

  alert_strategy {
    auto_close = var.alert_auto_close
  }
}

#------------------------------------------------------------------------------
# Alert Policy: Unhealthy Pods (Log-based)
#------------------------------------------------------------------------------
# Esta alerta usa condition_matched_log que detecta eventos de Kubernetes
# en Cloud Logging: BackOff, Unhealthy, FailedScheduling.
#
# NOTA: Las alertas log-based NO pueden combinarse con otras condiciones
# en la misma alert policy. Esta es una policy separada.
#
# Para validar el filtro: Logs Explorer en GCP
# Filtro base documentado en locals.tf
#------------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "pod_unhealthy" {
  count = local.enable_pod_unhealthy ? 1 : 0

  project      = var.project_id
  display_name = "GKE ${var.cluster_name}: Unhealthy Pods"
  combiner     = "OR"

  documentation {
    content   = "Detected unhealthy pod events (BackOff, Unhealthy, or FailedScheduling) in cluster ${var.cluster_name}"
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "GKE ${var.cluster_name}: Unhealthy Pod Events"

    condition_matched_log {
      filter = local.pod_unhealthy_log_filter

      label_extractors = {
        pod_name      = "EXTRACT(jsonPayload.involvedObject.name)"
        pod_namespace = "EXTRACT(jsonPayload.involvedObject.namespace)"
        reason        = "EXTRACT(jsonPayload.reason)"
        message       = "EXTRACT(jsonPayload.message)"
      }
    }
  }

  notification_channels = var.notification_channel_ids

  user_labels = merge(var.labels, {
    alert_type = "log_based"
  })

  alert_strategy {
    auto_close = var.alert_auto_close
  }
}
