# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-XX-XX

### Added

- Initial release of terraform-gcp-gke-monitoring module
- **Alert Policies** (7 alerts with individual toggles):
  - CPU utilization alert for containers (`kubernetes.io/container/cpu/limit_utilization`)
  - Memory utilization alert for containers (`kubernetes.io/container/memory/limit_utilization`)
  - Pod restart count alert (`kubernetes.io/container/restart_count`)
  - Unhealthy pods alert (log-based, detecting BackOff/Unhealthy/FailedScheduling events)
  - Node ephemeral storage utilization alert (MQL-based ratio calculation)
  - PersistentVolume utilization alert (`kubernetes.io/pod/volume/utilization`)
  - Node NotReady alert (`kubernetes.io/node/status_condition`)
- **Notification Channels** supporting:
  - Email
  - Slack (with sensitive auth_token)
  - PagerDuty
  - Webhook (token auth)
- **Uptime Checks** with automatic alert policies:
  - HTTP/HTTPS endpoint monitoring
  - Multi-region failure detection (triggers when 2+ regions fail)
- **Cloud Monitoring Dashboard** (optional):
  - JSON-based dashboard template with widgets for CPU, memory, restarts, disk, PV, and pod status
- **Full Terragrunt support** with examples for prod/staging environments
- **CI/CD** with GitHub Actions workflow for validation and terraform-docs
- **Documentation**: README with terraform-docs tables, per-submodule READMEs, and inline code documentation

### Notes

- Requires Terraform >= 1.3.0
- Requires Google Provider >= 5.0.0
- All resources target GCP Cloud Monitoring API (no in-cluster agents required)
- GKE cluster must have Cloud Monitoring/Logging enabled for metrics/logs to be available

[1.0.0]: https://github.com/your-org/terraform-gcp-gke-monitoring/releases/tag/v1.0.0
