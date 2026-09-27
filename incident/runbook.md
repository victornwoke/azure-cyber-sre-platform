# Incident response runbook

Use this runbook for a production cyber-SRE platform incident, especially an ingestion failure, loss of Data Lake access, or potentially unauthorised Azure change. Adapt the escalation contacts, severity objectives, and approval requirements to your organisation before use.

## 1. Stabilise and assess

1. Acknowledge the alert and create an incident record.
2. Record the alert name, environment, affected resources, first-seen time in UTC, and current customer/business impact.
3. Determine whether security telemetry is delayed, missing, corrupted, or inaccessible.
4. Do not delete pipelines, data, identities, logs, or state while investigating. Preserve evidence and avoid unreviewed broad permissions.
5. Escalate immediately if unauthorised access, suspected data exposure, or an active security threat is indicated.

## 2. Initial checks

Authenticate using an approved operational identity, then run:

```powershell
Get-AzContext
./powershell/Test-PlatformHealth.ps1 -ResourceGroupName "rg-cyber-sre-dev"
```

Capture the output in the incident record. The script checks only Azure authentication plus resource discovery for the resource group, Data Factory, and Log Analytics workspace; it does not prove that ingestion or data-plane access works.

Next, inspect:

- Azure Data Factory Monitor for pipeline and activity run IDs, errors, and duration.
- The resource group Azure Activity Log for deployment, RBAC, networking, or configuration changes.
- Storage account role assignments and networking configuration.
- Relevant Log Analytics queries and diagnostic logs, if diagnostic settings have been deployed.
- Azure service health for the deployed region.

## 3. Data Factory to ADLS Gen2 access failure

This is the most likely scenario represented by the current implementation.

1. Identify the Data Factory system-assigned managed identity principal ID.
2. Confirm it has `Storage Blob Data Contributor` on the intended storage account scope.
3. Check whether a recent Terraform deployment, RBAC change, storage network change, or identity recreation coincides with the failure.
4. Validate the Data Factory linked service/dataset and activity error message.
5. Restore the smallest correct role assignment through the approved Terraform workflow where possible.
6. Rerun one affected workload and verify its output in the expected filesystem.
7. Monitor the next scheduled run before resolving the incident.

Avoid granting `Owner`, using storage account keys, or making broad emergency role assignments merely to restore service. If a temporary exception is required, obtain approval, document an expiry time, and remove it after remediation.

## 4. Escalation and communications

| Situation | Action |
| --- | --- |
| Ingestion failure within service objective | On-call platform/data owner investigates and updates the incident record. |
| Sustained ingestion outage or alerting blind spot | Escalate to platform lead and security operations; provide scope and estimated telemetry gap. |
| Suspected unauthorised RBAC, Key Vault, or network change | Escalate to security incident response immediately; preserve Activity Logs and avoid altering evidence. |
| Suspected data exposure, loss, or corruption | Notify security, privacy, and data owners per organisational policy; preserve evidence and stop destructive actions. |

Provide updates that state the known impact, affected environment, actions taken, next investigation step, and next update time. Do not include credentials, secrets, or sensitive event payloads in broad channels.

## 5. Resolution and follow-up

Resolve only when the affected workload is functioning, the expected data is available or the gap is documented, monitoring is healthy, and the incident owner agrees that risk is acceptable.

Complete a postmortem for high-severity incidents or recurring failures. Use [postmortem.md](postmortem.md), capturing timeline, root cause, contributing factors, corrective actions, owners, and due dates. Update Terraform and this runbook when the permanent fix changes the platform.
