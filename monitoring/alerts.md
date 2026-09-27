# Monitoring and alerting

The Terraform configuration creates a Log Analytics workspace but does not configure diagnostic settings, data collection rules, KQL queries, or Azure Monitor alert rules. This document defines the minimum alerting design to implement once telemetry is connected.

## Monitoring objectives

- Detect failed or delayed security-data ingestion.
- Detect loss of Data Factory access to the Data Lake.
- Detect unexpected changes to high-value resources and role assignments.
- Maintain sufficient context for rapid triage and post-incident investigation.

## Recommended alerts

| Signal | Condition | Severity | Response |
| --- | --- | --- | --- |
| Data Factory pipeline failure | Any production pipeline run fails, grouped by pipeline/activity and error code. | High | Page the on-call owner; investigate run output and storage access. |
| Ingestion freshness | No successful ingestion/pipeline completion within the defined data freshness objective. | High | Validate source availability, pipeline status, identity, and landing-zone access. |
| Data Factory authorization failure | Activity output contains authentication/authorization failures to ADLS Gen2. | High | Validate the managed identity and storage RBAC; use the incident runbook. |
| Storage availability or access anomaly | Storage diagnostic telemetry reports sustained failures or rejected authorized traffic. | High | Assess client impact, networking, authentication, and Azure service health. |
| RBAC change | An Activity Log event creates, deletes, or modifies a role assignment at the resource group, storage account, Data Factory, or Key Vault scope. | High | Verify the change owner and change record; investigate unauthorised changes immediately. |
| Key Vault access or configuration change | Key Vault audit logs show denied access or control-plane configuration changes. | Medium/High | Investigate identity, source, change record, and potential secret exposure. |
| Log collection gap | Expected diagnostic tables or ingestion volume stop arriving. | High | Confirm diagnostic settings, workspace routing, quotas, and source health. |

Set alert thresholds from observed normal behavior and agreed service objectives; do not apply generic thresholds blindly. Route actionable alerts to an owned action group with an escalation path and test it regularly.

## Telemetry onboarding order

1. Create diagnostic settings for Storage, Data Factory, Key Vault, and Azure Activity Log.
2. Route the required categories to the Log Analytics workspace or designated central workspace.
3. Create KQL queries and test them against real, non-production telemetry.
4. Create action groups, alert rules, severity mappings, suppression windows, and ownership metadata.
5. Test an alert end-to-end, including acknowledgement and the associated runbook.

The included [queries.kql](queries.kql) file is currently a placeholder. Add only tested queries with comments stating required log tables, time window, expected result, and alert threshold.

## Alert response standard

Every alert should include the environment, resource ID, affected pipeline/workload, UTC time range, severity, a dashboard/query link, and a runbook link. An operator should acknowledge, assess impact, gather evidence, resolve or escalate, then document the outcome. Follow [incident/runbook.md](../incident/runbook.md) for a production incident.

## Health check

The PowerShell health check is a deployment verification aid, not an alerting system:

```powershell
./powershell/Test-PlatformHealth.ps1 -ResourceGroupName "rg-cyber-sre-dev"
```

Schedule it only after deciding how its result is collected and alerted on. A process exit code alone does not create an Azure Monitor alert.
