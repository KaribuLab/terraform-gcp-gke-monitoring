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
# Variables: Configuración completa del módulo
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP."
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE."
  type        = string
}

variable "cluster_location" {
  description = "Ubicación del cluster GKE."
  type        = string
  default     = "us-central1"
}

variable "namespace_filter" {
  description = "Namespace específico a monitorear (vacío = todos)."
  type        = string
  default     = ""
}

variable "slack_channel" {
  description = "Nombre del canal de Slack para notificaciones (ej: #alerts)."
  type        = string
  default     = ""
}

variable "slack_auth_token" {
  description = "Token de autenticación de Slack (xoxb-...)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "pagerduty_service_key" {
  description = "Service key de PagerDuty para notificaciones críticas."
  type        = string
  sensitive   = true
  default     = ""
}

variable "uptime_check_host" {
  description = "Hostname para uptime check (ej: api.example.com)."
  type        = string
  default     = ""
}
