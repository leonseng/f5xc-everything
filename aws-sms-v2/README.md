# Secure Mesh Site v2 for AWS

- Deploys AWS VPC and supporting network objects
- Creates XC Secure Mesh Site v2 and token objects
- Deploys XC CE in AWS VPC

## Prerequisite

1. XC API certificate for Terraform provider to authenticate

## Steps

1. Create `terraform.tfvars` based on [variables.tf](./variables.tf).
1. Run `terraform apply -auto-approve`

CE will auto register itself to XC control plane.
