# Dashboard Template: gke_dashboard.json.tpl

Este template JSON genera un dashboard de Cloud Monitoring para visualización de métricas GKE.

## Variables del template

| Variable | Tipo | Descripción | Ejemplo |
|----------|------|-------------|---------|
| `project_id` | string | ID del proyecto GCP | `my-project-123` |
| `cluster_name` | string | Nombre del cluster GKE | `production-cluster` |
| `dashboard_title` | string | Título completo del dashboard | `GKE production-cluster (us-central1)` |
| `namespace_filter` | string | Namespace filtrado (o vacío) | `production` o `""` |
| `namespace_clause` | string | Filtro AND para namespace | ` AND resource.labels.namespace_name = "production"` |
| `cluster_filter` | string | Filtro base del cluster | `resource.labels.cluster_name = "production-cluster"` |

## Widgets del dashboard

### 1. CPU Utilization by Pod
- **Métrica**: `kubernetes.io/container/cpu/limit_utilization`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_MEAN, 60s
- **Descripción**: Muestra el ratio de uso de CPU vs límites definidos por pod

### 2. Memory Utilization by Pod
- **Métrica**: `kubernetes.io/container/memory/limit_utilization`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_MEAN, 60s
- **Descripción**: Muestra el ratio de uso de memoria vs límites definidos por pod

### 3. Container Restart Count
- **Métrica**: `kubernetes.io/container/restart_count`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_DELTA, 600s (10 minutos)
- **Descripción**: Número de reinicios por contenedor en ventana de 10 minutos

### 4. Node Disk Usage (Ephemeral Storage)
- **Métrica**: `kubernetes.io/node/ephemeral_storage/used_bytes`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_MEAN, 60s
- **Unidad**: Bytes
- **Descripción**: Uso de almacenamiento efímero en nodos del cluster

### 5. PersistentVolume Utilization
- **Métrica**: `kubernetes.io/pod/volume/utilization`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_MEAN, 60s
- **Descripción**: Ratio de uso de volúmenes persistentes montados en pods

### 6. Pod Status (Uptime)
- **Métrica**: `kubernetes.io/container/uptime`
- **Tipo**: Gráfico de líneas
- **Alineación**: ALIGN_MEAN, 60s
- **Unidad**: Segundos
- **Descripción**: Tiempo de actividad de contenedores (indicador de estabilidad)

## Formato del dashboard

El dashboard usa el formato **gridLayout** con 2 columnas:
- Widgets organizados en una cuadrícula de 2 columnas
- 6 widgets totales (3 filas)
- Cada widget ocupa 1 celda

## Filtrado por namespace

Cuando `namespace_filter` no está vacío, todos los widgets filtran por:
```
resource.labels.namespace_name = "NAMESPACE"
```

Esto permite dashboards dedicados a namespaces específicos (ej: solo `production`).

## Uso en Terraform

```hcl
resource "google_monitoring_dashboard" "gke" {
  dashboard_json = templatefile(
    "${path.module}/templates/gke_dashboard.json.tpl",
    {
      project_id       = var.project_id
      cluster_name     = var.cluster_name
      dashboard_title  = "GKE ${var.cluster_name}"
      namespace_filter = var.namespace_filter
      namespace_clause = var.namespace_filter != "" ? " AND resource.labels.namespace_name = \"${var.namespace_filter}\"" : ""
      cluster_filter   = "resource.labels.cluster_name = \"${var.cluster_name}\""
    }
  )
}
```

## Referencias

- [Dashboard JSON Format](https://cloud.google.com/monitoring/dashboards/api-dashboard-json)
- [GKE Metrics](https://cloud.google.com/monitoring/api/metrics_kubernetes)
