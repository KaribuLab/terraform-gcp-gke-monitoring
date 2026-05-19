# Terraform GCP GKE Monitoring Module

[![Terraform Validate](https://github.com/your-org/terraform-gcp-gke-monitoring/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/your-org/terraform-gcp-gke-monitoring/actions/workflows/terraform-validate.yml)
[![Terraform Docs](https://img.shields.io/badge/terraform-docs-blue.svg)](https://terraform-docs.io/)

Módulo Terraform para monitoreo preventivo de clusters GKE en Google Cloud Platform.

## Descripción

Este módulo crea recursos de **Cloud Monitoring** y **Cloud Logging** para monitoreo preventivo de clusters GKE, usando únicamente APIs nativas de GCP. No requiere instalar agentes dentro del cluster.

### Características

- **7 alertas predefinidas** para métricas críticas de GKE
- **Notification channels** soportando Email, Slack, PagerDuty y Webhook
- **Uptime checks** HTTP/HTTPS con detección de fallos multi-región
- **Dashboard** de Cloud Monitoring con widgets clave
- **Totalmente configurable** via variables (toggles, umbrales, duraciones)
- **Compatible con Terragrunt** para gestión multi-entorno

## Tabla de Compatibilidad

| Componente | Versión Requerida |
|------------|------------------|
| Terraform | >= 1.3.0 |
| Google Provider | >= 5.0.0, < 8.0.0 |
| GKE | Cualquier versión con Cloud Monitoring habilitado |

## Prerrequisitos

Antes de usar este módulo, asegúrate de que:

1. **Cloud Monitoring** está habilitado en tu proyecto GCP
2. **Cloud Logging** está habilitado para recibir logs del cluster
3. El cluster GKE tiene **System metrics** habilitados
4. Tus contenedores tienen **resource limits** definidos (para alertas de CPU/memoria)

Para verificar que las métricas están disponibles:
```bash
gcloud monitoring metrics list --filter="metric.type:kubernetes.io"
```

## Uso Básico

```hcl
module "gke_monitoring" {
  source  = "github.com/tu-org/terraform-gcp-gke-monitoring"
  version = "~> 1.0"

  project_id       = "mi-proyecto"
  cluster_name     = "mi-cluster"
  cluster_location = "us-central1"

  notification_channels = [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = "devops@miempresa.com"
      }
    }
  ]
}
```

## Uso con Terragrunt

```hcl
# terragrunt.hcl
terraform {
  source = "github.com/tu-org/terraform-gcp-gke-monitoring//?ref=v1.0.0"
}

inputs = {
  project_id       = "rekodi-saas-prod"
  cluster_name     = "rekodi-prod-cluster"
  cluster_location = "us-central1"

  notification_channels = [
    {
      type         = "email"
      display_name = "DevOps Team"
      labels = {
        email_address = "devops-team@tudominio.com"
      }
    }
  ]

  uptime_checks = [
    {
      display_name = "App Health"
      host         = "app.miempresa.com"
      path         = "/health"
    }
  ]

  labels = {
    environment = "production"
    team        = "devops"
  }
}
```

## Matriz de Alertas

| Alerta | Métrica / Filtro | Tipo | Toggle | Default Umbral |
|--------|-----------------|------|--------|----------------|
| **CPU alta** | `kubernetes.io/container/cpu/limit_utilization` | Threshold | `enable_cpu_alert` | 80% |
| **Memoria alta** | `kubernetes.io/container/memory/limit_utilization` | Threshold | `enable_memory_alert` | 85% |
| **Reinicios** | `kubernetes.io/container/restart_count` | Threshold | `enable_restart_alert` | 3 en 10 min |
| **Pods no saludables** | Logs: `jsonPayload.reason` = BackOff/Unhealthy/FailedScheduling | Log-based | `enable_pod_unhealthy_alert` | N/A |
| **Disco en nodos** | MQL: ratio `used_bytes/total_bytes` | MQL | `enable_node_disk_alert` | 85% |
| **Disco en PV** | `kubernetes.io/pod/volume/utilization` | Threshold | `enable_pv_disk_alert` | 85% |
| **Nodos NotReady** | `kubernetes.io/node/status_condition` (Ready=False) | Threshold | `enable_node_not_ready_alert` | >0 |

### Notas de Operación

- **CPU/Memoria**: Requieren que los pods tengan `resources.limits` definidos
- **Disco en nodos**: Usa MQL porque requiere calcular un ratio entre dos métricas
- **Pods no saludables**: Alerta log-based que detecta eventos de Kubernetes

## Ejemplos

- [Ejemplo Básico](examples/basic/) - Configuración mínima con alertas core
- [Ejemplo Completo](examples/complete/) - Todas las features: Slack, PagerDuty, uptime checks
- [Ejemplo Terragrunt](examples/terragrunt/) - Multi-entorno con prod/staging

## Contribución

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-feature`)
3. Aplica cambios con `terraform fmt -recursive`
4. Valida con `terraform validate` en el módulo raíz y ejemplos
5. Commit (`git commit -m 'feat: nueva feature'`)
6. Push (`git push origin feature/nueva-feature`)
7. Abre un Pull Request

### Pre-commit hooks

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Documentación del Código

Cada submódulo tiene su propio README con detalles técnicos:

- [alert-policies](modules/alert-policies/) - Detalle de alertas y filtros
- [notification-channels](modules/notification-channels/) - Tipos de canales soportados
- [uptime-checks](modules/uptime-checks/) - Lógica de detección multi-región
- [dashboard](modules/dashboard/) - Widgets del dashboard JSON

## License

Apache 2.0 - Ver [LICENSE](LICENSE)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
