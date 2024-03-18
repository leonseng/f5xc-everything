
output "vpc_id" {
  value = aws_vpc.main.id
}

# output "aws_sg_ce_slo" {
#   value = aws_security_group.ce_slo.id
# }

# output "aws_sg_ce_sli" {
#   value = aws_security_group.ce_sli.id
# }

# output "aws_outside_subnets" {
#   value = aws_subnet.outside[*].id
# }

# output "aws_inside_subnets" {
#   value = aws_subnet.inside[*].id
# }

output "node_subnets" {
  value = [for i in range(var.aws_az_count) : {
    az : data.aws_availability_zones.available.names[i]
    outside_subnet = aws_subnet.outside[i].id
    inside_subnet  = aws_subnet.inside[i].id
  }]
}
