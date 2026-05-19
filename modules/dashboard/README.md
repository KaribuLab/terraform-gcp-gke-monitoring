# Dashboard Submódulo

Crea un dashboard de Cloud Monitoring para visualización de métricas GKE.

## Widgets incluidos

| Widget | Métrica | Descripción |
|--------|---------|-------------|
| CPU by Pod | `kubernetes.io/container/cpu/limit_utilization` | Gráfico de líneas con CPU por pod |
| Memory by Pod | `kubernetes.io/container/memory/limit_utilization` | Gráfico de líneas con memoria por pod |
| Container Restarts | `kubernetes.io/container/restart_count` | Contador de reinicios (delta) |
| Node Disk Usage | MQL: ratio ephemeral storage | Uso de disco en nodos del cluster |
| PV Utilization | `kubernetes.io/pod/volume/utilization` | Uso de PersistentVolumes |
| Pod Status | `kubernetes.io/container/uptime` | Estado general de pods |

## Template JSON

El dashboard se genera usando `templatefile()` con un template JSON ubicado en `templates/gke_dashboard.json.tpl`.

Las siguientes variables se sustituyen en el template:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `project_id` | ID del proyecto | `my-project` |
| `cluster_name` | Nombre del cluster | `production-cluster` |
| `dashboard_title` | Título del dashboard | `GKE production-cluster (us-central1)` |
| `namespace_filter` | Namespace filtrado (si aplica) | `production` o `""` |
| `namespace_clause` | Cláusula AND para filtros | ` AND resource.labels.namespace_name = "production"` |
| `cluster_filter` | Filtro base del cluster | `resource.labels.cluster_name = "production-cluster"` |

## Uso

```hcl
module "dashboard" {
  source = "./modules/dashboard"

  project_id       = "mi-proyecto"
  cluster_name     = "mi-cluster"
  cluster_location = "us-central1"
  namespace_filter = "production"  # Opcional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | ID del proyecto GCP | `string` | n/a | yes |
| cluster_name | Nombre del cluster | `string` | n/a | yes |
| cluster_location | Ubicación del cluster | `string` | `""` | no |
| namespace_filter | Namespace a filtrar | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_id | ID completo del dashboard |
| dashboard_name | Título del dashboard |
| dashboard_json_rendered | JSON renderizado (para debug) |

## Recursos

- `google_monitoring_dashboard.gke_dashboard`: Dashboard personalizado

## Referencias

- [Cloud Monitoring Dashboards API](https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards)
- [Dashboard JSON Format](https://cloud.google.com/monitoring/dashboards/api-dashboard-json)
