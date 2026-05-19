#------------------------------------------------------------------------------
# Terragrunt Root Configuration
#------------------------------------------------------------------------------
# Este archivo configura el backend remoto y los providers comunes
# para todos los entornos (prod, staging).
#------------------------------------------------------------------------------

# Configuración del backend remoto (GCS)
remote_state {
  backend = "gcs"

  config = {
    # NOTA: Configura tu bucket de GCS aquí
    bucket = "my-terraform-state-bucket"
    prefix = "gke-monitoring/${path_relative_to_include()}"

    # Opcional: encriptación con KMS
    # encryption_key = "projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Generar configuración de providers
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<EOF
provider "google" {
  project = var.project_id
  region  = var.cluster_location
}

provider "google-beta" {
  project = var.project_id
  region  = var.cluster_location
}
EOF
}

# Variables comunes para todos los entornos
inputs = {
  # Estas variables se pueden sobrescribir en cada entorno
  cluster_location = "us-central1"
}
