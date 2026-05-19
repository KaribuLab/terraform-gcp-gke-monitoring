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
# Variables: Configuración del proyecto GCP
#------------------------------------------------------------------------------
# Estas variables deben configurarse en terraform.tfvars
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se crearán los recursos de monitoreo."
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE a monitorear."
  type        = string
}

variable "cluster_location" {
  description = "Ubicación del cluster GKE (zona o región)."
  type        = string
  default     = "us-central1"
}

variable "notification_email" {
  description = "Dirección de email para recibir notificaciones de alertas."
  type        = string
  default     = ""
}
