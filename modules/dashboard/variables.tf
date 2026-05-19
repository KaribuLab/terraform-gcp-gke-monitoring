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
# Variables: Identificación del proyecto y cluster
#------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se creará el dashboard."
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE para título del dashboard y filtros."
  type        = string
}

variable "cluster_location" {
  description = "Ubicación del cluster GKE (zona o región). Usado en el título del dashboard."
  type        = string
  default     = ""
}

variable "namespace_filter" {
  description = <<EOT
Namespace opcional para filtrar widgets del dashboard.
Si se especifica, los widgets mostrarán solo recursos de ese namespace.
Si está vacío, se muestran todos los namespaces.
EOT
  type        = string
  default     = ""
}
