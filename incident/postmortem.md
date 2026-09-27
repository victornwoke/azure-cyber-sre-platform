# Incident Postmortem

## Incident

Cybersecurity ingestion pipeline unable to access ADLS (Azure Data Lake Storage).

## Impact

Security telemetry ingestion was interrupted.

## Detection

Failure detected through Azure Data Factory monitoring and
Log Analytics.

## Root Cause

The Data Factory managed identity lost the Storage Blob Data
Contributor role on the Data Lake storage account.

## Remediation

Terraform recreated the missing RBAC assignment.

## Validation

Pipeline rerun completed successfully.

## Preventive Actions

- Manage RBAC through Terraform
- Review infrastructure plans before deployment
- Monitor failed pipeline runs
- Alert on ingestion failures
- Maintain incident runbooks
- Periodically check infrastructure drift
