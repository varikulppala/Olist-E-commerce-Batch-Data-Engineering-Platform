# Terraform Infrastructure as Code

## Overview

Terraform is used in the Olist e-commerce batch data platform to define and manage selected AWS infrastructure as code.

The current Terraform implementation focuses on the AWS resources that were explicitly brought under Terraform management:

- Amazon S3
- AWS Glue

The Terraform configuration was validated against the deployed AWS infrastructure and the final plan reported no pending infrastructure changes.

Terraform is therefore used as an infrastructure-management layer rather than as a replacement for the application's data-processing code.

---

## Terraform Directory

The Terraform configuration is located at:

```text
Terraform/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── .terraform.lock.hcl
```

The configuration is maintained separately from the application and analytics code.

---

## Terraform Provider

The project uses the AWS Terraform provider.

The validated provider version is:

```text
AWS provider: 6.63.0
```

The provider is used to manage resources in the AWS environment hosting the batch data platform.

The project AWS region is:

```text
ap-south-1
```

which corresponds to the Mumbai AWS region.

---

## Terraform State and Lock File

Terraform uses its state mechanism to track resources managed by the configuration.

The repository also contains:

```text
.terraform.lock.hcl
```

The lock file records the selected provider dependency so that Terraform operations use a consistent provider version.

The `.terraform/` working directory and local Terraform state files are excluded from version control through `.gitignore`.

---

## Managed Resources

The current Terraform configuration manages the following infrastructure components.

### Amazon S3 Bucket

Terraform manages the project's primary S3 bucket:

```text
olist-aws-batch-data-platform-adhi-2026
```

The bucket is used by the AWS batch data platform for raw and processed data storage.

The Terraform configuration captures the relevant bucket configuration rather than uploading the dataset itself into the Git repository.

---

### S3 Versioning

S3 bucket versioning is managed through Terraform.

Versioning provides object-level historical versions and supports safer object lifecycle management.

The deployed bucket was validated as having versioning enabled.

---

### S3 Public Access Block

The S3 bucket uses a public-access-block configuration.

The validated configuration blocks public access through the S3 public-access controls.

This supports the project's security requirement that the data bucket should not be publicly accessible.

---

### S3 Server-Side Encryption

The S3 bucket uses server-side encryption.

The validated encryption configuration uses:

```text
AES256
```

The bucket key configuration is also enabled.

These settings provide encryption at rest for objects stored in the managed bucket.

---

### AWS Glue Job

Terraform also manages the AWS Glue ETL job:

```text
olist-raw-to-processed-etl
```

The Glue job performs the raw-to-processed transformation stage of the AWS batch pipeline.

The validated job configuration includes:

```text
Glue version: 5.1
Worker type: G.1X
Number of workers: 2
Execution class: STANDARD
Maximum concurrent runs: 1
Timeout: 480 minutes
Maximum retries: 0
```

The job script is stored in S3.

The validated script location is:

```text
s3://aws-glue-assets-970722351160-ap-south-1/scripts/olist-raw-to-processed-etl.py
```

---

## Glue IAM Role

The Glue job uses the existing AWS IAM service role:

```text
AWSGlueServiceRole-OlistDataPlatform
```

with ARN:

```text
arn:aws:iam::970722351160:role/AWSGlueServiceRole-OlistDataPlatform
```

The Terraform documentation does not claim that this IAM role is currently created by the Terraform configuration.

The role is documented because it is part of the deployed Glue job configuration.

---

## Terraform Configuration Scope

The current infrastructure-as-code scope is intentionally limited.

```text
Terraform
   |
   +--> S3 bucket
   |     +--> Versioning
   |     +--> Public access block
   |     +--> Encryption
   |
   +--> AWS Glue ETL job
```

The following AWS services are part of the overall platform but are not currently represented as Terraform-managed resources in the validated Terraform configuration:

- AWS Lambda
- EventBridge Scheduler
- CloudWatch
- CloudTrail
- IAM roles and policies used outside the managed resources
- Secrets Manager

These services remain part of the deployed architecture and are documented separately.

---

## Why the Scope Is Limited

Terraform should accurately represent the infrastructure that is actually under its management.

The project therefore does not add placeholder or speculative Terraform resources simply to make the configuration appear more complete.

This avoids creating a mismatch between:

```text
Terraform configuration
```

and:

```text
Actual deployed infrastructure
```

The current configuration is intentionally limited to the resources that were imported or managed and subsequently validated.

---

## Existing Infrastructure Management

The S3 bucket and Glue infrastructure already existed in the AWS environment before Terraform management was finalized.

The Terraform configuration was aligned with the existing deployed resources rather than creating duplicate infrastructure.

This approach allowed the project to introduce infrastructure as code while preserving the existing working batch pipeline.

The important objective was:

```text
Existing AWS infrastructure
          |
          v
Terraform configuration
          |
          v
Infrastructure state alignment
```

rather than rebuilding the platform from scratch.

---

## Terraform Validation

The Terraform configuration was validated using the standard Terraform workflow.

### Formatting

Terraform formatting was applied to the configuration.

The goal is to keep Terraform files consistently formatted and readable.

### Initialization

Terraform was initialized with the required AWS provider.

The provider dependency was resolved using the Terraform lock file.

### Validation

Terraform configuration validation completed successfully.

The result was:

```text
Success! The configuration is valid.
```

This confirms that the Terraform configuration is syntactically and structurally valid.

---

## Terraform Plan

The final Terraform plan was executed against the configured infrastructure.

The plan reported:

```text
No changes.
```

This is an important validation result.

It indicates that Terraform's configuration and state were aligned with the infrastructure represented by the current Terraform scope.

The project therefore does not require an additional Terraform apply for the validated configuration.

---

## No-Change Plan Interpretation

A `No changes` plan should not be interpreted as meaning that every AWS resource in the project is managed by Terraform.

It means that the resources represented by the current Terraform configuration are already aligned with Terraform's state and the deployed infrastructure.

The distinction is:

```text
Overall AWS architecture
        |
        +--> Many services
        |
        v
Terraform-managed subset
        |
        +--> S3
        +--> Glue
```

This distinction is intentionally preserved in the project documentation.

---

## Relationship to AWS Batch Pipeline

Terraform manages infrastructure used by the AWS batch-processing path.

The runtime architecture is:

```text
EventBridge Scheduler
        |
        v
AWS Lambda
        |
        v
AWS Glue
        |
        v
Amazon S3
```

Terraform currently represents the S3 and Glue portions of this path.

Lambda and EventBridge remain deployed AWS services but are outside the current validated Terraform resource scope.

---

## Relationship to Databricks

Terraform is focused on the AWS infrastructure portion of the project.

Databricks resources and analytical workloads are not represented as Terraform-managed resources in the current configuration.

The broader architecture is:

```text
AWS Infrastructure
       |
       v
S3 Processed
       |
       v
Databricks
       |
       v
Gold / SQL Analytics
       |
       v
dbt
       |
       v
Apache Superset
```

Terraform therefore complements rather than replaces the Databricks and analytics configuration.

---

## Security Considerations

Terraform configuration should never contain sensitive credentials directly.

The project follows these principles:

- Do not commit AWS access keys
- Do not commit secret values
- Do not commit Databricks tokens
- Do not commit Superset credentials
- Keep local environment files out of Git
- Use IAM roles for AWS service-to-service access where applicable
- Use AWS Secrets Manager for secrets that require managed storage

The repository `.gitignore` excludes common Terraform state, environment, secret, and local configuration files.

---

## Data Handling

Terraform does not contain the Olist dataset itself.

The large raw dataset remains outside the Git repository.

Terraform defines infrastructure that supports data storage and processing, while the actual data flows through:

```text
Olist Dataset
      |
      v
S3 Raw
      |
      v
AWS Glue
      |
      v
S3 Processed
```

This separation keeps infrastructure code lightweight and avoids committing large data artifacts.

---

## Operational Relationship

Terraform is an infrastructure lifecycle tool.

Runtime execution is handled by the deployed AWS services:

```text
EventBridge Scheduler
        |
        v
Lambda
        |
        v
Glue
        |
        v
S3
```

Terraform defines the infrastructure configuration for its managed subset.

CloudWatch and CloudTrail provide monitoring and auditing of the runtime AWS environment.

---

## Repository Placement

The final repository structure includes:

```text
AWS-BIG-DATA/
├── Terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── .terraform.lock.hcl
│
├── docs/
│   └── terraform.md
│
└── .gitignore
```

The Terraform directory contains infrastructure configuration while the documentation explains its scope, validation, and relationship to the overall architecture.

---

## Reproducibility Considerations

The Terraform configuration improves reproducibility for the resources under its management.

A future infrastructure workflow can use Terraform to inspect and manage the declared S3 and Glue resources rather than relying exclusively on manual console configuration.

However, full one-command reproduction of the entire platform is not claimed because several deployed components are outside the current Terraform scope.

This is an intentional documentation boundary.

---

## Current Status

The Terraform infrastructure-as-code layer is partially implemented and validated.

Completed:

- Terraform project structure
- AWS provider configuration
- Provider lock file
- S3 bucket management
- S3 versioning management
- S3 public-access-block management
- S3 encryption management
- AWS Glue job management
- Terraform formatting
- Terraform validation
- Terraform plan validation
- Existing infrastructure/state alignment

Current validated plan result:

```text
No changes.
```

Not currently Terraform-managed:

- Lambda
- EventBridge Scheduler
- CloudWatch
- CloudTrail
- Databricks
- Superset

These remain documented as deployed or configured components of the broader platform, but they are not claimed as resources in the current Terraform configuration.

---

## Future Expansion

Terraform coverage can be expanded in a future iteration if infrastructure-as-code coverage becomes a project requirement.

Potential candidates include:

- Lambda
- EventBridge Scheduler
- IAM resources
- CloudWatch resources
- Additional S3 configuration
- Other AWS infrastructure components

Such expansion should only be performed after comparing the existing deployed infrastructure with the desired Terraform state.

The current project does not require these resources to be added simply for completeness.

---

## Summary

Terraform provides infrastructure as code for the validated AWS infrastructure subset of the Olist batch data platform.

The current configuration manages:

```text
Amazon S3
    |
    +--> Versioning
    +--> Public Access Block
    +--> AES256 Encryption

AWS Glue
    |
    +--> olist-raw-to-processed-etl
```

Terraform validation succeeded, and the final plan reported no changes.

The implementation intentionally documents the difference between the complete AWS architecture and the smaller set of resources currently managed by Terraform.

This provides an accurate and reproducible infrastructure baseline without claiming infrastructure coverage that has not been implemented.
