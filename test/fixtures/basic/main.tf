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
# Test Fixture: Configuración básica para validación
#------------------------------------------------------------------------------
# Este fixture se usa en CI para validar el módulo con terraform validate.
# No crea recursos reales (usa variables placeholder).
#------------------------------------------------------------------------------

module "test_gke_monitoring" {
  source = "../../.."

  # Variables placeholder para validación
  project_id       = "test-project"
  cluster_name     = "test-cluster"
  cluster_location = "us-central1"

  # Sin notificaciones (para validación rápida)
  notification_channels = []

  # Sin uptime checks
  uptime_checks = []

  # Solo alertas core habilitadas
  enable_cpu_alert            = true
  enable_memory_alert         = true
  enable_restart_alert        = true
  enable_pod_unhealthy_alert  = false # Log-based requiere más config
  enable_node_disk_alert      = false
  enable_pv_disk_alert        = false
  enable_node_not_ready_alert = false

  # Sin dashboard
  enable_dashboard = false

  # Etiquetas mínimas
  labels = {
    test = "true"
  }
}
