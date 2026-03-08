output "vpc_id"             { value = aws_vpc.main.id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_app_subnet_ids" { value = aws_subnet.private_app[*].id }
output "data_subnet_ids"    { value = aws_subnet.data[*].id }
output "vpc_security_group_id" { value = aws_security_group.allow_all_outbound.id }

# Route Table Outputs
output "public_route_table_id" { value = aws_route_table.public.id }
output "private_route_table_ids" { value = aws_route_table.private[*].id }
output "data_route_table_ids" { value = aws_route_table.data[*].id }

# VPC Endpoint Outputs
output "vpc_endpoints_security_group_id" { value = aws_security_group.vpc_endpoints.id }
output "s3_endpoint_id" { value = aws_vpc_endpoint.s3.id }
output "dynamodb_endpoint_id" { value = aws_vpc_endpoint.dynamodb.id }
output "ecr_api_endpoint_id" { value = aws_vpc_endpoint.ecr_api.id }
output "ecr_dkr_endpoint_id" { value = aws_vpc_endpoint.ecr_dkr.id }
output "logs_endpoint_id" { value = aws_vpc_endpoint.logs.id }
output "monitoring_endpoint_id" { value = aws_vpc_endpoint.monitoring.id }
output "sts_endpoint_id" { value = aws_vpc_endpoint.sts.id }