# Terraform state migration

Example showing migration of Terraform object between old and new state files, as Volterra Terraform provider does not support Terraform import at time of writing this.

## Instructions

1. Deploy [old/](./old/)
  ```
  terraform -chdir=old apply -auto-approve
  ```
2. Remove `volterra_http_loadbalancer.app` in [old/main.tf](./old/main.tf)
  ```
  mv old/main.tf old/main.tf.bkp
  ```
3. Migrate state from [old/](./old/) to [new/](./new/)
  ```
  % terraform -chdir=old state mv -state=terraform.tfstate -state-out=../new/terraform.tfstate volterra_http_loadbalancer.app volterra_http_loadbalancer.app
  Move "volterra_http_loadbalancer.app" to "volterra_http_loadbalancer.app"
  ```
4. Run plan in [new/](./new/) to verify no changes are required
  ```
  % terraform -chdir=new plan
  volterra_http_loadbalancer.app: Refreshing state... [id=d56995f2-db93-4c7d-ae65-8c4d9b97a027]

  No changes. Your infrastructure matches the configuration.
  ```
