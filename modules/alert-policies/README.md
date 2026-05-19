# Alert Policies Submódulo

Crea alert policies de Cloud Monitoring para monitoreo preventivo de clusters GKE.

## Alertas implementadas

| Alerta | Métrica/Filtro | Tipo | Toggle | Default Umbral | Descripción |
|--------|---------------|------|--------|----------------|-------------|
| CPU alta | `kubernetes.io/container/cpu/limit_utilization` | Threshold | `enable_cpu_alert` | 80% | Ratio de uso vs limit de CPU |
| Memoria alta | `kubernetes.io/container/memory/limit_utilization` | Threshold | `enable_memory_alert` | 85% | Ratio de uso vs limit de memoria |
| Reinicios | `kubernetes.io/container/restart_count` | Threshold | `enable_restart_alert` | 3 reinicios | Reinicios en ventana de 10 min |
| Pods no saludables | Logs: `jsonPayload.reason` = BackOff/Unhealthy/FailedScheduling | Log-based | `enable_pod_unhealthy_alert` | N/A | Eventos de pods problemáticos |
| Disco en nodos | MQL: ratio `used_bytes/total_bytes` de ephemeral storage | MQL | `enable_node_disk_alert` | 85% | Uso de disco en nodos GKE |
| Disco en PV | `kubernetes.io/pod/volume/utilization` | Threshold | `enable_pv_disk_alert` | 85% | Uso de PersistentVolumes |
| Nodos NotReady | `kubernetes.io/node/status_condition` (Ready=False) | Threshold | `enable_node_not_ready_alert` | >0 | Nodos en estado NotReady |

## Prerequisitos

- GKE con **Cloud Monitoring** y **Cloud Logging** habilitados
- Contenedores con **limits definidos** para alertas de CPU y memoria
- Métricas visibles en Metrics Explorer: `kubernetes.io/*`

## Uso

```hcl
module "alert_policies" {
  source = "./modules/alert-policies"

  project_id               = "mi-proyecto"
  cluster_name             = "mi-cluster"
  namespace_filter         = "production"  # Opcional
  notification_channel_ids = ["projects/.../notificationChannels/..."]

  # Habilitar/deshabilitar alertas
  enable_cpu_alert           = true
  enable_memory_alert        = true
  enable_restart_alert       = true
  enable_pod_unhealthy_alert = true
  enable_node_disk_alert     = true
  enable_pv_disk_alert       = true
  enable_node_not_ready_alert = true

  # Umbrales personalizados
  thresholds = {
    cpu_utilization       = 0.8
    memory_utilization    = 0.85
    restart_count         = 3
    node_disk_utilization = 0.85
    pv_utilization        = 0.85
  }

  labels = {
    environment = "production"
    team        = "devops"
  }
}
```

## Filtros para validación

Para probar los filtros antes de aplicar:

### CPU (Metrics Explorer)
```
resource.type="k8s_container"
resource.labels.cluster_name="CLUSTER_NAME"
metric.type="kubernetes.io/container/cpu/limit_utilization"
```

### Logs (Logs Explorer)
```
resource.type="k8s_pod"
resource.labels.cluster_name="CLUSTER_NAME"
jsonPayload.reason="BackOff"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | ID del proyecto GCP | `string` | n/a | yes |
| cluster_name | Nombre del cluster GKE | `string` | n/a | yes |
| namespace_filter | Namespace a monitorear (vacío = todos) | `string` | `""` | no |
| notification_channel_ids | Lista de IDs de canales de notificación | `list(string)` | `[]` | no |
| enable_*_alert | Toggles individuales para cada alerta | `bool` | `true` | no |
| thresholds | Umbrales de alertas | `object` | Ver variables.tf | no |
| durations | Duraciones de condiciones | `object` | Ver variables.tf | no |
| alert_auto_close | Auto-cierre de incidentes | `string` | `86400s` | no |
| labels | Etiquetas comunes | `map(string)` | `{}` | no |
| pod_unhealthy_log_filter | Filtro log personalizado | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| alert_policy_ids | Mapa de IDs de todas las alertas creadas |
| alert_policy_names | Mapa de nombres de display |
| enabled_alerts_summary | Lista de alertas efectivamente habilitadas |

## Recursos

- `google_monitoring_alert_policy.threshold_alerts`: 5 alertas threshold-based (for_each)
- `google_monitoring_alert_policy.node_disk`: Alerta MQL de disco en nodos
- `google_monitoring_alert_policy.pod_unhealthy`: Alerta log-based de pods no saludables
