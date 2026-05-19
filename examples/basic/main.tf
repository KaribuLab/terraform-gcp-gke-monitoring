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
# Ejemplo Básico: GKE Monitoring
#------------------------------------------------------------------------------
# Este ejemplo muestra la configuración mínima del módulo de monitoreo GKE.
# Crea solo las alertas core con un canal de notificación por email.
# No incluye uptime checks ni dashboard (para simplificar).
#------------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.cluster_location
}

#------------------------------------------------------------------------------
# Módulo: GKE Monitoring (configuración básica)
#------------------------------------------------------------------------------

module "gke_monitoring" {
  source = "../.."

  # Identificación del proyecto y cluster
  project_id       = var.project_id
  cluster_name     = var.cluster_name
  cluster_location = var.cluster_location

  # Sin filtro de namespace (monitorea todo el cluster)
  namespace_filter = ""

  #------------------------------------------------------------------------------
  # Canales de notificación
  #------------------------------------------------------------------------------
  # Configuramos un solo canal de email para simplificar.
  # El email puede configurarse via variable o dejarse vacío.
  #------------------------------------------------------------------------------
  notification_channels = var.notification_email != "" ? [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = var.notification_email
      }
      sensitive_labels = {}
    }
  ] : []

  #------------------------------------------------------------------------------
  # Sin uptime checks en ejemplo básico
  #------------------------------------------------------------------------------
  uptime_checks = []

  #------------------------------------------------------------------------------
  # Alertas habilitadas: solo las 4 core
  #------------------------------------------------------------------------------
  # Deshabilitamos algunas alertas avanzadas para mantener el ejemplo simple.
  #------------------------------------------------------------------------------
  enable_cpu_alert            = true
  enable_memory_alert         = true
  enable_restart_alert        = true
  enable_pod_unhealthy_alert  = true
  enable_node_disk_alert      = false # Requiere MQL, deshabilitado en básico
  enable_pv_disk_alert        = false # Deshabilitado en básico
  enable_node_not_ready_alert = false # Deshabilitado en básico

  #------------------------------------------------------------------------------
  # Sin dashboard en ejemplo básico
  #------------------------------------------------------------------------------
  enable_dashboard = false

  #------------------------------------------------------------------------------
  # Umbrales por defecto (sin personalización)
  #------------------------------------------------------------------------------
  thresholds = {}

  #------------------------------------------------------------------------------
  # Etiquetas para las alertas
  #------------------------------------------------------------------------------
  labels = {
    environment = "basic-example"
    managed_by  = "terraform"
  }
}
