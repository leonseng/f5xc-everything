# AWS BYO CE

Based on https://github.com/f5devcentral/terraform-xc-aws-ce/tree/main/examples/single_node_single_nic_existing_vpc_existing_subnet

```
terraform apply -auto-approve -target module.aws_vpc  # get rid of dependency errors!
terraform apply -auto-approve  # apply the rest
```