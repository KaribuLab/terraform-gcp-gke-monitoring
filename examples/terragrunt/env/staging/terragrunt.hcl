#------------------------------------------------------------------------------
# Terragrunt: Configuración de Staging
#------------------------------------------------------------------------------
# Este archivo configura el módulo de monitoreo GKE para el entorno de
# staging. Es más ligero que producción, con menos canales de notificación
# y umbrales más permisivos.
#------------------------------------------------------------------------------

# Incluir la configuración raíz (backend, providers)
include "root" {
  path = find_in_parent_folders()
}

# Fuente del módulo Terraform
terraform {
  # Usar el módulo local (staging suele usar la última versión)
  source = "${get_repo_root()}"
}

#------------------------------------------------------------------------------
# Locals: Configuración específica de staging
#------------------------------------------------------------------------------

locals {
  environment = "staging"
  project_id  = "rekodi-saas-staging"
  cluster_name = "rekodi-staging-cluster"

  # Solo email para staging (menos ruido)
  notification_channels = [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = "devops-staging@tudominio.com"
      }
      sensitive_labels = {}
    }
  ]

  # Solo un uptime check para staging
  uptime_checks = [
    {
      display_name = "Staging App Health"
      host         = "app.staging.rekodi.cl"
      path         = "/health"
      port         = 443
      use_ssl      = true
      validate_ssl = true
      timeout      = "10s"
      period       = "300s"  # Menos frecuente en staging
      regions      = ["USA", "EUROPE"]
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
  namespace_filter = ""  # Monitorear todo en staging

  # Notificaciones (solo email)
  notification_channels = local.notification_channels

  # Uptime checks
  uptime_checks = local.uptime_checks

  # Alertas principales habilitadas
  enable_cpu_alert            = true
  enable_memory_alert         = true
  enable_restart_alert        = true
  enable_pod_unhealthy_alert  = true

  # Alertas avanzadas deshabilitadas en staging
  enable_node_disk_alert      = false
  enable_pv_disk_alert        = false
  enable_node_not_ready_alert = true

  # Dashboard habilitado (útil para debugging)
  enable_dashboard = true

  # Umbrales más permisivos para staging
  thresholds = {
    cpu_utilization       = 0.85  # 85% (más permisivo)
    memory_utilization    = 0.90  # 90%
    restart_count         = 5     # 5 reinicios
    node_disk_utilization = 0.90 # 90%
    pv_utilization        = 0.95  # 95%
  }

  # Duraciones más cortas para feedback rápido
  durations = {
    cpu_duration     = "180s"  # 3 minutos
    memory_duration  = "180s"
    restart_duration = "300s"  # 5 minutos
    disk_duration    = "180s"
    pv_duration      = "180s"
  }

  # Etiquetas
  labels = {
    environment = local.environment
    team        = "devops"
    app         = "rekodi"
    tier        = "staging"
  }
}
