# Security posture and hardening

This document distinguishes controls already defined in Terraform from controls that should be added before a production deployment. It is an implementation guide, not a compliance attestation.

## Current controls

| Control | Current implementation |
| --- | --- |
| Data Lake identity | Storage account is StorageV2 with hierarchical namespace enabled (ADLS Gen2). |
| Transport security | Storage account requires TLS 1.2 or later. |
| Workload identity | Azure Data Factory has a system-assigned managed identity. |
| Data-plane access | The Data Factory identity receives `Storage Blob Data Contributor` on the storage account. |
| Secret-store authorization | Key Vault uses Azure RBAC authorization rather than access policies. |
| Vault recovery | Key Vault soft delete retention is set to seven days. |
| State separation | Terraform is configured to use an AzureRM backend, with backend location supplied at initialisation. |

## Gaps to resolve before production

The following are not present in the current Terraform configuration and should be designed, implemented, and tested for the target environment:

- Restrict public network access and use private endpoints/private DNS for Storage, Key Vault, Data Factory, and Log Analytics where architecture permits.
- Define explicit NSG rules. The existing NSG has no rules beyond Azure defaults, and the data subnet has no NSG association.
- Disable storage public blob access where required; choose a secure shared-key policy and consider Microsoft Entra ID-only data-plane access.
- Enable diagnostic settings for all resources and route them to Log Analytics and/or a central security destination.
- Configure Defender for Cloud, Azure Policy, activity-log alerts, and resource locks according to the organisation’s baseline.
- Assign least-privilege Key Vault data-plane roles to named managed identities; no Key Vault role assignment is currently declared.
- Decide whether purge protection, a longer soft-delete retention, customer-managed keys, and zone/geo resilience are required. Purge protection is currently disabled and storage uses LRS.
- Establish data-retention, classification, privacy, backup, and incident-evidence requirements for `raw` and `processed` data.
- Pin Terraform, provider, and CI/CD action versions; ensure infrastructure changes are peer-reviewed and policy-checked.

## Identity and access model

Use workload identities instead of client secrets whenever possible. Separate deployment identities from runtime identities:

| Identity | Intended permissions |
| --- | --- |
| Terraform deployer | Scope-limited resource management plus permission to create required role assignments. |
| Data Factory managed identity | `Storage Blob Data Contributor` only on the required storage account or narrower supported scope. |
| Operators | Read-only monitoring access by default; time-bound elevated access for remediation. |
| CI/CD identity | Federated, environment-scoped permissions and access to the remote state backend. |

Review role assignments regularly. Avoid granting `Owner` to application identities, avoid using account keys in pipelines, and remove privileges that are not actively required.

## Secrets and state

Terraform state and plan files can contain resource identifiers, configuration, and potentially sensitive values. Store state in a dedicated protected Azure Storage container, restrict read/write access, enable retention/versioning according to policy, and never publish it as a public artifact.

Do not commit secrets, service-principal credentials, storage keys, `backend.hcl`, generated `.tfplan` files, or live environment variable files. The repository currently tracks `terraform/terraform.tfvars` and `terraform/tfplan`; migrate their deployment-specific contents to secure configuration/artifact handling and remove them from version control through your approved change process.

## Security review checklist

Before each production release, confirm:

- The Terraform plan was created for the intended subscription, environment, and remote state key.
- Network paths are private or explicitly approved and documented.
- Diagnostic settings and relevant alert rules are enabled and tested.
- Data Factory, Key Vault, Storage, and CI/CD identities have only the permissions they need.
- Security logs have an accountable destination and defined retention.
- The incident runbook and escalation contacts are current.

For operational detection and response guidance, see [monitoring/alerts.md](../monitoring/alerts.md) and [incident/runbook.md](../incident/runbook.md).
