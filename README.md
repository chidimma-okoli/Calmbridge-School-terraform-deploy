# AWS Infrastructure with Terraform

Terraform infrastructure for deploying an application environment on AWS with EC2, RDS PostgreSQL, VPC networking, NAT Gateway, route tables, and security groups.

## Project Overview

This project demonstrates how to provision and manage AWS infrastructure using **Terraform Infrastructure as Code (IaC)** instead of creating resources manually through the AWS Console.

The infrastructure is designed with separate network tiers for the application frontend, backend, and database.

## Architecture

```text
                         Internet
                            │
                            ▼
                    Internet Gateway
                            │
                  ┌─────────┴─────────┐
                  │   Public Subnet   │
                  │                   │
                  │   Frontend EC2    │
                  │                   │
                  │   NAT Gateway     │
                  └─────────┬─────────┘
                            │
                         NAT Route
                            │
                  ┌─────────▼─────────┐
                  │  Private Subnet   │
                  │                   │
                  │    Backend EC2    │
                  └─────────┬─────────┘
                            │
                         Port 5432
                            │
                  ┌─────────▼─────────┐
                  │ Database Subnet   │
                  │                   │
                  │   RDS PostgreSQL  │
                  └───────────────────┘
```

## AWS Resources

Terraform provisions the following resources:

* VPC
* Public, private, and database subnets
* Internet Gateway
* Public, private, and database route tables
* NAT Gateway
* Security Groups
* EC2 instances for frontend and backend
* RDS PostgreSQL database
* RDS DB subnet group
* Ubuntu AMI lookup

## Network Design

The VPC uses:

```text
VPC:              10.0.0.0/16
Public subnet:    10.0.1.0/24
Private subnet:   10.0.2.0/24
Database subnet:  10.0.3.0/24
```

The subnets are distributed across different Availability Zones.

### Public Subnet

The public subnet hosts the frontend EC2 instance and NAT Gateway.

It has a route to the Internet Gateway.

### Private Subnet

The private subnet hosts the backend EC2 instance.

Outbound internet traffic can be routed through the NAT Gateway without exposing the backend directly to the internet.

### Database Subnet

The database tier hosts the RDS PostgreSQL instance.

The database is not publicly accessible and is protected by a dedicated security group.

## Security

Traffic is controlled using security groups:

```text
Internet
   │
   ▼
Frontend SG
   │
   ▼
Backend SG
   │
   ▼
Database SG
```

The database security group allows PostgreSQL traffic on port `5432` from the backend security group.

The database is configured as:

```text
publicly_accessible = false
```

## Terraform Structure

```text
.
├── main.tf
├── backend.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── config.tf
├── .gitignore
└── .github/
    └── workflows/
        ├── terraform_deploy.yaml
        └── terraform_destroy.yaml
```

### File Purpose

| File               | Purpose                                                     |
| ------------------ | ----------------------------------------------------------- |
| `main.tf`          | Defines AWS infrastructure resources                        |
| `backend.tf`       | Configures the remote Terraform state in S3                 |
| `variables.tf`     | Defines Terraform input variables                           |
| `terraform.tfvars` | Provides environment-specific variable values               |
| `outputs.tf`       | Displays useful infrastructure information                  |
| `.gitignore`       | Prevents sensitive and generated files from being committed |

## Terraform Backend

Terraform state is stored remotely in an Amazon S3 bucket.

```hcl
terraform {
  backend "s3" {
    bucket = "cally-terraform-state-2026"
    key    = "terraform-practice/terraform.tfstate"
    region = "us-east-1"
  }
}
```

The infrastructure itself is deployed in:

```text
eu-west-2
```

## Prerequisites

Before deploying, make sure you have:

* AWS account
* AWS CLI
* Terraform
* AWS credentials configured
* An existing S3 bucket for Terraform state
* Appropriate AWS permissions

Check the installations:

```bash
terraform version
aws --version
```

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Format the configuration

```bash
terraform fmt
```

### 4. Validate the configuration

```bash
terraform validate
```

### 5. Review the infrastructure plan

```bash
terraform plan
```

Always review the plan before applying changes, especially when working with paid AWS resources.

### 6. Apply the infrastructure

```bash
terraform apply
```

Review the proposed changes and confirm before Terraform creates the resources.

## Destroying the Infrastructure

When the infrastructure is no longer required:

```bash
terraform destroy
```

Review the destruction plan carefully before confirming.

> **Note:** Destroying the infrastructure can permanently remove resources and data. Make sure important database data is backed up before destruction.

## Security and Secrets

Sensitive values such as database passwords should not be committed to GitHub.

`terraform.tfvars` is excluded through `.gitignore`.

Never commit:

```text
terraform.tfvars
*.tfstate
*.tfstate.*
.env
*.pem
*.key
```

For production environments, secrets should be managed using an appropriate secrets-management solution rather than storing them in Terraform variable files.

## Learning Objectives

This project demonstrates practical understanding of:

* Infrastructure as Code
* Terraform configuration and state
* AWS VPC networking
* Public and private subnets
* Route tables and routing
* Internet Gateway
* NAT Gateway
* Security Groups
* EC2 provisioning
* RDS PostgreSQL
* Terraform variables and outputs
* Remote Terraform state
* Infrastructure deployment and destruction

## Project Status

This is a hands-on DevOps infrastructure project developed as part of my practical learning and portfolio development.

The infrastructure is designed to demonstrate how application environments can be provisioned consistently and managed through code using Terraform.
