output "vpc_id"             { value = aws_vpc.main.id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_app_subnet_ids" { value = aws_subnet.private_app[*].id }
output "data_subnet_ids"    { value = aws_subnet.data[*].id }
output "vpc_security_group_id" { value = aws_security_group.allow_all_outbound.id }