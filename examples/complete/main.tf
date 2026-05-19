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
# Ejemplo Completo: GKE Monitoring con todas las features
#------------------------------------------------------------------------------
# Este ejemplo muestra todas las capacidades del módulo:
# - Todos los tipos de canales de notificación (email, slack, pagerduty)
# - Todas las alertas habilitadas
# - Uptime checks con alertas multi-región
# - Dashboard de Cloud Monitoring
# - Umbrales y duraciones personalizadas
#------------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.cluster_location
}

#------------------------------------------------------------------------------
# Local: Construir lista de canales de notificación dinámicamente
#------------------------------------------------------------------------------
# Solo incluimos canales que tienen sus variables configuradas.
#------------------------------------------------------------------------------

locals {
  notification_channels = concat(
    # Canal de email (siempre incluido)
    [{
      type         = "email"
      display_name = "DevOps Team Email"
      labels = {
        email_address = "devops@example.com"
      }
      sensitive_labels = {}
    }],

    # Canal de Slack (solo si se proporciona token)
    var.slack_auth_token != "" ? [{
      type         = "slack"
      display_name = "Slack Alerts"
      labels = {
        channel_name = var.slack_channel != "" ? var.slack_channel : "#gke-alerts"
      }
      sensitive_labels = {
        auth_token = var.slack_auth_token
      }
    }] : [],

    # Canal de PagerDuty (solo si se proporciona service key)
    var.pagerduty_service_key != "" ? [{
      type         = "pagerduty"
      display_name = "PagerDuty Critical"
      labels       = {}
      sensitive_labels = {
        service_key = var.pagerduty_service_key
      }
    }] : []
  )

  # Uptime checks (solo si se proporciona host)
  uptime_checks = var.uptime_check_host != "" ? [
    {
      display_name = "API Health Check"
      host         = var.uptime_check_host
      path         = "/health"
      port         = 443
      use_ssl      = true
      validate_ssl = true
      timeout      = "10s"
      period       = "60s"
      regions      = ["USA", "EUROPE", "ASIA_PACIFIC"]
    },
    {
      display_name = "App Health Check"
      host         = var.uptime_check_host
      path         = "/healthz"
      port         = 443
      use_ssl      = true
      validate_ssl = true
      timeout      = "10s"
      period       = "60s"
      regions      = ["USA", "EUROPE", "ASIA_PACIFIC"]
    }
  ] : []
}

#------------------------------------------------------------------------------
# Módulo: GKE Monitoring (configuración completa)
#------------------------------------------------------------------------------

module "gke_monitoring" {
  source = "../.."

  # Identificación del proyecto y cluster
  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.cluster_location
  namespace_filter = var.namespace_filter

  # Canales de notificación dinámicos
  notification_channels = local.notification_channels

  # Uptime checks (si están configurados)
  uptime_checks = local.uptime_checks

  # Todas las alertas habilitadas
  enable_cpu_alert            = true
  enable_memory_alert         = true
  enable_restart_alert        = true
  enable_pod_unhealthy_alert  = true
  enable_node_disk_alert      = true
  enable_pv_disk_alert        = true
  enable_node_not_ready_alert = true

  # Dashboard habilitado
  enable_dashboard = true

  #------------------------------------------------------------------------------
  # Umbrales personalizados
  #------------------------------------------------------------------------------
  thresholds = {
    cpu_utilization       = 0.75 # 75% en lugar de 80%
    memory_utilization    = 0.80 # 80% en lugar de 85%
    restart_count         = 5    # 5 reinicios en lugar de 3
    node_disk_utilization = 0.80 # 80% en lugar de 85%
    pv_utilization        = 0.90 # 90% para PV
  }

  #------------------------------------------------------------------------------
  # Duraciones personalizadas
  #------------------------------------------------------------------------------
  durations = {
    cpu_duration     = "300s"
    memory_duration  = "300s"
    restart_duration = "600s"
    disk_duration    = "300s"
    pv_duration      = "300s"
  }

  # Auto-cierre de incidentes
  alert_auto_close = "86400s" # 24 horas

  # Etiquetas comunes
  labels = {
    environment = "production"
    team        = "platform"
    managed_by  = "terraform"
    cost_center = "infrastructure"
  }
}
