# Dashboard Template: gke_dashboard.json.tpl

Este template JSON genera un dashboard de Cloud Monitoring para visualización de métricas GKE.

## Variables del template

Cada campo `filter` del JSON usa una variable `*_json` producida con `jsonencode()` en el módulo, para que el resultado sea un fragmento JSON válido (evita comillas sin escapar al mezclar la sintaxis de filtros de Monitoring con el template).

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `dashboard_title` | string | Título completo del dashboard |
| `filter_cpu_json` | string | Literal JSON del filtro del widget CPU |
| `filter_memory_json` | string | Idem memoria |
| `filter_restart_json` | string | Idem reinicios |
| `filter_disk_json` | string | Idem disco en nodos |
| `filter_pv_json` | string | Idem PersistentVolume |
| `filter_uptime_json` | string | Idem uptime |

`project_id`, `cluster_name` y `namespace_filter` son inputs del módulo Terraform; el armado de filtros ocurre en `modules/dashboard/main.tf`, no en el `.tpl`.

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

El módulo construye `template_vars` con `jsonencode()` por widget. Patrón equivalente:

```hcl
locals {
  namespace_clause     = var.namespace_filter != "" ? " AND resource.labels.namespace_name = \"${var.namespace_filter}\"" : ""
  cluster_name_filter  = "resource.labels.cluster_name = \"${var.cluster_name}\""
  filter_k8s_container = "resource.type=\"k8s_container\" AND ${local.cluster_name_filter}${local.namespace_clause}"
  template_vars = {
    dashboard_title  = "GKE ${var.cluster_name}"
    filter_cpu_json  = jsonencode("${local.filter_k8s_container} AND metric.type=\"kubernetes.io/container/cpu/limit_utilization\"")
    # ... demás widgets
  }
}

resource "google_monitoring_dashboard" "gke" {
  dashboard_json = templatefile("${path.module}/templates/gke_dashboard.json.tpl", local.template_vars)
}
```

En el `.tpl`, cada filtro se inserta sin comillas extra: `"filter": ${filter_cpu_json},`.

## Referencias

- [Dashboard JSON Format](https://cloud.google.com/monitoring/dashboards/api-dashboard-json)
- [GKE Metrics](https://cloud.google.com/monitoring/api/metrics_kubernetes)
