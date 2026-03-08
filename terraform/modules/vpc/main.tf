# Data Sources
data "aws_region" "current" {}

# Local values for consistent tagging
locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "vpc"
    }
  )
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-${var.environment}"
    }
  )
}

# Internet Gateway (for public subnets)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                     = "${var.project_name}-public-${var.azs[count.index]}"
      "kubernetes.io/role/elb" = "1"  # For future EKS ALB
      Tier                     = "Public"
    }
  )
}

# Private App Subnets (for EKS nodes, services)
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name                              = "${var.project_name}-private-app-${var.azs[count.index]}"
      "kubernetes.io/role/internal-elb" = "1"
      Tier                              = "Private-App"
    }
  )
}

# Data Subnets (isolated for RDS, Redis, etc. — no direct internet)
resource "aws_subnet" "data" {
  count             = length(var.data_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-data-${var.azs[count.index]}"
      Tier = "Data"
    }
  )
}

# NAT Gateways + EIPs (one per AZ for HA)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.azs) : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-nat-eip-${count.index}"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.azs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id  # NAT in public subnet

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-nat-${var.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-rt"
      Tier = "Public"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[count.index].id : null
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-private-rt-${var.azs[count.index]}"
      Tier = "Private"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Separate Route Tables for Data Subnets (NO internet access)
resource "aws_route_table" "data" {
  count = length(var.azs)

  vpc_id = aws_vpc.main.id

  # No default route - data subnets cannot reach internet
  # They can only communicate within VPC and via VPC endpoints

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-data-rt-${var.azs[count.index]}"
      Tier = "Data"
    }
  )
}

resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data[count.index].id
}

# Baseline Security Groups (expand later)
resource "aws_security_group" "allow_all_outbound" {
  name        = "${var.project_name}-allow-outbound"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-sg-outbound"
    }
  )
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name              = "/vpc/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-logs"
    }
  )
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-endpoints-sg"
    }
  )
}

# S3 Gateway Endpoint (no charge)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    aws_route_table.data[*].id
  )

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-s3-endpoint"
      Service      = "S3"
      EndpointType = "Gateway"
    }
  )
}

# DynamoDB Gateway Endpoint (no charge)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    aws_route_table.data[*].id
  )

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-dynamodb-endpoint"
      Service      = "DynamoDB"
      EndpointType = "Gateway"
    }
  )
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-ecr-api-endpoint"
      Service      = "ECR-API"
      EndpointType = "Interface"
    }
  )
}

# ECR DKR Interface Endpoint (for Docker image pulls)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-ecr-dkr-endpoint"
      Service      = "ECR-DKR"
      EndpointType = "Interface"
    }
  )
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-logs-endpoint"
      Service      = "CloudWatch-Logs"
      EndpointType = "Interface"
    }
  )
}

# CloudWatch Monitoring Interface Endpoint
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-monitoring-endpoint"
      Service      = "CloudWatch-Monitoring"
      EndpointType = "Interface"
    }
  )
}

# STS Interface Endpoint
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name         = "${var.project_name}-sts-endpoint"
      Service      = "STS"
      EndpointType = "Interface"
    }
  )
}