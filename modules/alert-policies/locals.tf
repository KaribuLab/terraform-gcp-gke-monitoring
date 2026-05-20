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
# Locals: Filtros comunes para métricas GKE
#------------------------------------------------------------------------------
# Estos filtros se usan en las alert policies de Cloud Monitoring.
# Para validarlos, copiar en Metrics Explorer > MQL o en el campo Filter.
#
# Documentación de filtros de Cloud Monitoring:
# https://cloud.google.com/monitoring/api/v3/filters
#------------------------------------------------------------------------------

locals {
  # Filtro base para filtrar por cluster_name
  # Usado en todas las alertas que monitorean un cluster específico
  cluster_filter = "resource.labels.cluster_name = \"${var.cluster_name}\""

  # Sufijo opcional para filtrar por namespace
  # Solo se añade si namespace_filter no está vacío
  namespace_suffix = var.namespace_filter != "" ? " AND resource.labels.namespace_name = \"${var.namespace_filter}\"" : ""

  #------------------------------------------------------------------------------
  # Alerta: CPU alta en contenedores
  #------------------------------------------------------------------------------
  # Métrica: kubernetes.io/container/cpu/limit_utilization
  # Tipo de recurso: k8s_container
  # Unidad: Ratio (0.0 - 1.0)
  #
  # IMPORTANTE: Esta métrica solo existe si el contenedor tiene limits.cpu definido.
  # Para validar: Metrics Explorer > kubernetes.io/container/cpu/limit_utilization
  #------------------------------------------------------------------------------
  cpu_metric_type = "kubernetes.io/container/cpu/limit_utilization"
  cpu_filter      = "resource.type = \"k8s_container\" AND ${local.cluster_filter}${local.namespace_suffix}"

  #------------------------------------------------------------------------------
  # Alerta: Memoria alta en contenedores
  #------------------------------------------------------------------------------
  # Métrica: kubernetes.io/container/memory/limit_utilization
  # Tipo de recurso: k8s_container
  # Unidad: Ratio (0.0 - 1.0)
  #
  # IMPORTANTE: Esta métrica solo existe si el contenedor tiene limits.memory definido.
  #------------------------------------------------------------------------------
  memory_metric_type = "kubernetes.io/container/memory/limit_utilization"
  memory_filter      = "resource.type = \"k8s_container\" AND ${local.cluster_filter}${local.namespace_suffix}"

  #------------------------------------------------------------------------------
  # Alerta: Reinicios excesivos de pods
  #------------------------------------------------------------------------------
  # Métrica: kubernetes.io/container/restart_count
  # Tipo de recurso: k8s_container
  # Estrategia de agregación: ALIGN_DELTA sobre ventana de 600s
  #
  # La agregación ALIGN_DELTA calcula el cambio en el contador de reinicios
  # durante el período especificado (10 minutos por defecto).
  #------------------------------------------------------------------------------
  restart_metric_type = "kubernetes.io/container/restart_count"
  restart_filter      = "resource.type = \"k8s_container\" AND ${local.cluster_filter}"

  #------------------------------------------------------------------------------
  # Alerta: Pods no saludables (log-based)
  #------------------------------------------------------------------------------
  # Tipo de recurso: k8s_pod
  # Filtro de logs: Detecta eventos BackOff, Unhealthy, FailedScheduling
  #
  # Para validar en Logs Explorer:
  #   resource.type="k8s_pod" AND resource.labels.cluster_name="CLUSTER_NAME"
  #   AND (jsonPayload.reason="BackOff" OR jsonPayload.reason="Unhealthy" OR jsonPayload.reason="FailedScheduling")
  #
  # Nota: Esta alerta usa condition_matched_log que NO puede combinarse con
  # otras condiciones en la misma alert policy.
  #------------------------------------------------------------------------------
  pod_unhealthy_log_filter_default = "resource.type=\"k8s_pod\" AND ${local.cluster_filter}${local.namespace_suffix} AND (jsonPayload.reason=\"BackOff\" OR jsonPayload.reason=\"Unhealthy\" OR jsonPayload.reason=\"FailedScheduling\")"
  pod_unhealthy_log_filter         = var.pod_unhealthy_log_filter != null ? var.pod_unhealthy_log_filter : local.pod_unhealthy_log_filter_default

  #------------------------------------------------------------------------------
  # Alerta: Uso de disco en nodos (MQL)
  #------------------------------------------------------------------------------
  # Métricas:
  #   - kubernetes.io/node/ephemeral_storage/used_bytes
  #   - kubernetes.io/node/ephemeral_storage/total_bytes
  # Tipo de recurso: k8s_node
  #
  # Query MQL: Calcula el ratio used/total y alerta cuando supera el umbral.
  # MQL Reference: https://cloud.google.com/monitoring/mql
  #------------------------------------------------------------------------------
  node_disk_mql = <<-EOT
    fetch k8s_node
    | filter (resource.cluster_name == '${var.cluster_name}')
    | {
        metric 'kubernetes.io/node/ephemeral_storage/used_bytes'
        | group_by [resource.cluster_name, resource.node_name], [value_used: mean(value.used_bytes)]
      ;
        metric 'kubernetes.io/node/ephemeral_storage/total_bytes'
        | group_by [resource.cluster_name, resource.node_name], [value_total: mean(value.total_bytes)]
    }
    | join
    | div
    | condition val() > ${var.thresholds.node_disk_utilization}
  EOT

  #------------------------------------------------------------------------------
  # Alerta: Uso de disco en PersistentVolumes
  #------------------------------------------------------------------------------
  # Métrica: kubernetes.io/pod/volume/utilization
  # Tipo de recurso: k8s_pod
  # Unidad: Ratio (0.0 - 1.0)
  #
  # Esta métrica reporta la utilización de volúmenes montados en pods.
  #------------------------------------------------------------------------------
  pv_metric_type = "kubernetes.io/pod/volume/utilization"
  pv_filter      = "resource.type = \"k8s_pod\" AND ${local.cluster_filter}"

  #------------------------------------------------------------------------------
  # Alerta: Nodos NotReady
  #------------------------------------------------------------------------------
  # Métrica: kubernetes.io/node/status_condition
  # Tipo de recurso: k8s_node
  # Labels de métrica:
  #   - condition: "Ready"
  #   - status: "False" (indica NotReady)
  #
  # Para detectar nodos NotReady, buscamos:
  #   metric.labels.condition = "Ready" AND metric.labels.status = "False"
  #------------------------------------------------------------------------------
  node_status_metric_type = "kubernetes.io/node/status_condition"
  node_not_ready_filter   = "resource.type = \"k8s_node\" AND ${local.cluster_filter} AND metric.labels.condition = \"Ready\" AND metric.labels.status = \"False\""

  #------------------------------------------------------------------------------
  # Mapa de alertas habilitadas para for_each
  #------------------------------------------------------------------------------
  # Usamos merge con condicionales para construir un mapa dinámico.
  # Esto evita el uso de count para condicionales y mantiene recursos estables.
  #------------------------------------------------------------------------------
  enabled_alerts = merge(
    var.enable_cpu_alert ? {
      cpu = {
        display_name     = "GKE ${var.cluster_name}: High CPU Utilization"
        filter           = local.cpu_filter
        metric_type      = local.cpu_metric_type
        threshold        = var.thresholds.cpu_utilization
        duration         = var.durations.cpu_duration
        comparison       = "COMPARISON_GT"
        alignment_period = "60s"
        aligner          = "ALIGN_MEAN"
        description      = "CPU utilization exceeds ${var.thresholds.cpu_utilization * 100}% of limit for ${var.durations.cpu_duration}"
      }
    } : {},

    var.enable_memory_alert ? {
      memory = {
        display_name     = "GKE ${var.cluster_name}: High Memory Utilization"
        filter           = local.memory_filter
        metric_type      = local.memory_metric_type
        threshold        = var.thresholds.memory_utilization
        duration         = var.durations.memory_duration
        comparison       = "COMPARISON_GT"
        alignment_period = "60s"
        aligner          = "ALIGN_MEAN"
        description      = "Memory utilization exceeds ${var.thresholds.memory_utilization * 100}% of limit for ${var.durations.memory_duration}"
      }
    } : {},

    var.enable_restart_alert ? {
      restart = {
        display_name     = "GKE ${var.cluster_name}: High Pod Restart Count"
        filter           = local.restart_filter
        metric_type      = local.restart_metric_type
        threshold        = var.thresholds.restart_count
        duration         = var.durations.restart_duration
        comparison       = "COMPARISON_GT"
        alignment_period = "600s"
        aligner          = "ALIGN_DELTA"
        description      = "Container restarted more than ${var.thresholds.restart_count} times in ${var.durations.restart_duration}"
      }
    } : {},

    var.enable_pv_disk_alert ? {
      pv_disk = {
        display_name     = "GKE ${var.cluster_name}: High PV Utilization"
        filter           = local.pv_filter
        metric_type      = local.pv_metric_type
        threshold        = var.thresholds.pv_utilization
        duration         = var.durations.pv_duration
        comparison       = "COMPARISON_GT"
        alignment_period = "60s"
        aligner          = "ALIGN_MEAN"
        description      = "PersistentVolume utilization exceeds ${var.thresholds.pv_utilization * 100}% for ${var.durations.pv_duration}"
      }
    } : {},

    var.enable_node_not_ready_alert ? {
      node_not_ready = {
        display_name     = "GKE ${var.cluster_name}: Node NotReady"
        filter           = local.node_not_ready_filter
        metric_type      = local.node_status_metric_type
        threshold        = 0
        duration         = "300s"
        comparison       = "COMPARISON_GT"
        alignment_period = "60s"
        aligner          = "ALIGN_NEXT_OLDER"
        description      = "Node has been in NotReady state for more than 5 minutes"
      }
    } : {}
  )

  #------------------------------------------------------------------------------
  # Configuración de alertas MQL y log-based (no entran en el mapa anterior)
  #------------------------------------------------------------------------------
  enable_node_disk     = var.enable_node_disk_alert
  enable_pod_unhealthy = var.enable_pod_unhealthy_alert
}
