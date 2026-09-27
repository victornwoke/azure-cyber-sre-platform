# Incident postmortem: Data Factory access to ADLS Gen2

**Status:** Example completed incident

**Severity:** To be classified against the organisation's incident policy

**Affected service:** Cybersecurity telemetry ingestion

**Incident window:** Record verified UTC start and end times in the incident system

## Summary

Azure Data Factory could not access the Azure Data Lake Storage Gen2 account used by the cybersecurity ingestion workflow. As a result, affected telemetry ingestion was interrupted until the Data Factory managed identity’s required storage role assignment was restored through Terraform.

## Impact

- Security telemetry ingestion was interrupted.
- The exact data gap, affected sources, and downstream reporting impact must be established from pipeline-run history and source-system records.
- No conclusion about data loss or unauthorised access should be made without supporting evidence.

## Detection

The failure was identified through Azure Data Factory monitoring and Log Analytics. In a production implementation, the supporting alert should include the failed pipeline/activity, error code, storage resource ID, and first-seen UTC timestamp.

## Timeline

| Time (UTC) | Event |
| --- | --- |
| `<record time>` | Ingestion pipeline failure first observed. |
| `<record time>` | On-call engineer acknowledged and began investigation. |
| `<record time>` | Missing `Storage Blob Data Contributor` assignment for the Data Factory managed identity confirmed. |
| `<record time>` | Approved Terraform change applied to restore the assignment. |
| `<record time>` | Pipeline rerun succeeded and output was validated. |
| `<record time>` | Incident resolved; follow-up actions opened. |

## Root cause

The Data Factory system-assigned managed identity no longer had the `Storage Blob Data Contributor` role on the Data Lake storage account. That permission is required for the factory to perform the intended data-plane operations.

## Contributing factors

- RBAC drift was not detected before it affected ingestion.
- The platform did not yet have a tested alert for failed ingestion or role-assignment changes.
- The precise initiating change and change owner should be confirmed from Azure Activity Log records before assigning fault.

## Resolution and validation

Terraform recreated the missing role assignment. The team reran the affected pipeline successfully and should retain evidence that the expected data arrived in the intended filesystem. The health-check script can confirm that the Data Factory exists but does not validate this data-plane permission on its own.

## Corrective and preventive actions

| Action | Owner | Due date | Status |
| --- | --- | --- | --- |
| Manage Data Factory storage RBAC exclusively through Terraform and review plan changes. | Platform owner | `<date>` | Open |
| Alert on failed production pipeline runs and ingestion freshness. | Observability owner | `<date>` | Open |
| Alert on role-assignment changes at Data Factory and storage scopes. | Security operations | `<date>` | Open |
| Enable and retain relevant diagnostic and Activity Log telemetry. | Platform owner | `<date>` | Open |
| Add a data-plane access validation to release verification. | Engineering owner | `<date>` | Open |
| Periodically review infrastructure drift and privileged role assignments. | Security owner | `<date>` | Open |

## Lessons learned

Managed identities reduce secret-management risk, but their RBAC assignments are still critical production dependencies. Treat role assignments, network rules, and diagnostics as tested infrastructure code; pair each key dependency with monitoring and an actionable response path.
