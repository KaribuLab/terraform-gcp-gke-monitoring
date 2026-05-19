#------------------------------------------------------------------------------
# Terragrunt: Configuración de Producción
#------------------------------------------------------------------------------
# Este archivo configura el módulo de monitoreo GKE para el entorno de
# producción. Incluye todas las alertas, uptime checks, y notificaciones.
#------------------------------------------------------------------------------

# Incluir la configuración raíz (backend, providers)
include "root" {
  path = find_in_parent_folders()
}

# Fuente del módulo Terraform
# En producción, se recomienda usar una versión específica del módulo
terraform {
  # Opción 1: Usar el módulo desde GitHub con versión fija
  # source = "github.com/tu-org/terraform-gcp-gke-monitoring//?ref=v1.0.0"

  # Opción 2: Usar el módulo local (para desarrollo)
  source = "${get_repo_root()}"
}

#------------------------------------------------------------------------------
# Locals: Configuración específica de producción
#------------------------------------------------------------------------------

locals {
  environment = "production"
  project_id  = "rekodi-saas-prod"
  cluster_name = "rekodi-prod-cluster"

  # Canales de notificación para producción
  notification_channels = [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = "devops-team@tudominio.com"
      }
      sensitive_labels = {}
    },
    {
      type         = "slack"
      display_name = "Platform Alerts"
      labels = {
        channel_name = "#platform-alerts"
      }
      sensitive_labels = {
        # Configurar via variable de entorno: TF_VAR_slack_token
        auth_token = get_env("TF_VAR_slack_token", "")
      }
    },
    {
      type         = "pagerduty"
      display_name = "PagerDuty Critical"
      labels       = {}
      sensitive_labels = {
        # Configurar via variable de entorno: TF_VAR_pagerduty_key
        service_key = get_env("TF_VAR_pagerduty_key", "")
      }
    }
  ]

  # Uptime checks para producción
  uptime_checks = [
    {
      display_name = "Rekodi App Health"
      host         = "app.rekodi.cl"
      path         = "/health"
      port         = 443
      use_ssl      = true
      validate_ssl = true
      timeout      = "10s"
      period       = "60s"
      regions      = ["USA", "EUROPE", "ASIA_PACIFIC"]
    },
    {
      display_name = "Rekodi API Health"
      host         = "api.rekodi.cl"
      path         = "/healthz"
      port         = 443
      use_ssl      = true
      validate_ssl = true
      timeout      = "10s"
      period       = "60s"
      regions      = ["USA", "EUROPE", "ASIA_PACIFIC"]
    }
  ]
}

#------------------------------------------------------------------------------
# Inputs: Variables para el módulo
#------------------------------------------------------------------------------

inputs = {
  # Identificación
  project_id       = local.project_id
  cluster_name     = local.cluster_name
  cluster_location = "us-central1"
  namespace_filter = "production"

  # Notificaciones
  notification_channels = local.notification_channels

  # Uptime checks
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

  # Umbrales más conservadores para producción
  thresholds = {
    cpu_utilization       = 0.75  # 75%
    memory_utilization    = 0.80  # 80%
    restart_count         = 3     # 3 reinicios
    node_disk_utilization = 0.80 # 80%
    pv_utilization        = 0.85  # 85%
  }

  # Etiquetas para organización
  labels = {
    environment = local.environment
    team        = "devops"
    app         = "rekodi"
    tier        = "platform"
    cost_center = "infrastructure"
  }
}
