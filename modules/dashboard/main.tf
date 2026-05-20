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
# Local: Preparación de variables para el template
#------------------------------------------------------------------------------
# Construimos un mapa de variables para pasar al template JSON.
# El template usa estos valores para personalizar filtros y títulos.
#------------------------------------------------------------------------------

locals {
  # Título del dashboard con ubicación si está disponible
  dashboard_title = var.cluster_location != "" ? "GKE ${var.cluster_name} (${var.cluster_location})" : "GKE ${var.cluster_name}"

  # Filtro de namespace para los widgets (vacío = todos)
  namespace_clause = var.namespace_filter != "" ? " AND resource.labels.namespace_name = \"${var.namespace_filter}\"" : ""

  # Parte común del filtro de Monitoring (sintaxis con comillas; jsonencode() en template_vars evita JSON inválido al interpolar)
  cluster_name_filter = "resource.labels.cluster_name = \"${var.cluster_name}\""

  filter_k8s_container_ns = "resource.type=\"k8s_container\" AND ${local.cluster_name_filter}${local.namespace_clause}"
  filter_k8s_node         = "resource.type=\"k8s_node\" AND ${local.cluster_name_filter}"
  filter_k8s_pod_ns       = "resource.type=\"k8s_pod\" AND ${local.cluster_name_filter}${local.namespace_clause}"

  # Variables para el template: *_json son literales JSON (incluyen comillas y escapes) para usar como "filter": ${filter_..._json}
  template_vars = {
    dashboard_title     = local.dashboard_title
    filter_cpu_json     = jsonencode("${local.filter_k8s_container_ns} AND metric.type=\"kubernetes.io/container/cpu/limit_utilization\"")
    filter_memory_json  = jsonencode("${local.filter_k8s_container_ns} AND metric.type=\"kubernetes.io/container/memory/limit_utilization\"")
    filter_restart_json = jsonencode("${local.filter_k8s_container_ns} AND metric.type=\"kubernetes.io/container/restart_count\"")
    filter_disk_json    = jsonencode("${local.filter_k8s_node} AND metric.type=\"kubernetes.io/node/ephemeral_storage/used_bytes\"")
    filter_pv_json      = jsonencode("${local.filter_k8s_pod_ns} AND metric.type=\"kubernetes.io/pod/volume/utilization\"")
    filter_uptime_json  = jsonencode("${local.filter_k8s_container_ns} AND metric.type=\"kubernetes.io/container/uptime\"")
  }
}

#------------------------------------------------------------------------------
# Recurso: Google Cloud Monitoring Dashboard
#------------------------------------------------------------------------------
# Crea un dashboard usando un template JSON personalizado.
# El template define widgets para visualizar métricas clave del cluster GKE.
#
# Widgets incluidos (ver templates/README.md para detalles):
# - CPU utilization por pod
# - Memory utilization por pod
# - Container restart count
# - Node disk usage
# - PersistentVolume utilization
# - Pod status
#------------------------------------------------------------------------------

resource "google_monitoring_dashboard" "gke_dashboard" {
  project = var.project_id

  dashboard_json = templatefile(
    "${path.module}/templates/gke_dashboard.json.tpl",
    local.template_vars
  )
}
