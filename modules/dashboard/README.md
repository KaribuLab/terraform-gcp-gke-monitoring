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

Los filtros de cada widget se construyen en `locals` del módulo y se pasan al template con `jsonencode()`, de modo que las comillas de la sintaxis de Monitoring no rompan el JSON (no se interpolan strings con comillas dentro de otro string JSON a mano).

Variables sustituidas en el template:

| Variable | Descripción |
|----------|-------------|
| `dashboard_title` | Título del dashboard |
| `filter_cpu_json` | Literal JSON (string codificado) del filtro CPU |
| `filter_memory_json` | Idem memoria |
| `filter_restart_json` | Idem reinicios |
| `filter_disk_json` | Idem disco en nodos |
| `filter_pv_json` | Idem PersistentVolume |
| `filter_uptime_json` | Idem uptime |

Los inputs del módulo (`project_id`, `cluster_name`, `cluster_location`, `namespace_filter`) siguen usándose solo en `main.tf` para armar esos valores.

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
