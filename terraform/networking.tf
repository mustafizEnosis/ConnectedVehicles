# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# NAT Gateways (one per public subnet for AZ resiliency)
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  vpc = true

  tags = {
    Name        = "${var.environment}-nat-eip-${count.index}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name        = "${var.environment}-natgw-${count.index}"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index}"
    Environment = var.environment
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index}"
    Environment = var.environment
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Tables
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "${var.environment}-private-rt-${count.index}"
    Environment = var.environment
  }
}

# Associations
# Public Subnet Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Private Subnet Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

# S3 Endpoint (for private access to S3 from private subnets)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.private[*].id] # Associate with all private route tables

  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
  }
}

# Security Groups
# Security Group for ECS tasks (allow outbound to internet for pulling images and to IoT Core, MSK, etc.)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Allow ECS tasks to communicate outbound"
  vpc_id      = aws_vpc.main.id

  # Outbound: allow all traffic (we can restrict later)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# Security Group for MSK (allow inbound from VPC on Kafka port)
resource "aws_security_group" "msk" {
  name        = "${var.environment}-msk-sg"
  description = "Allow inbound traffic to MSK brokers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kafka client traffic"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Allow from within the VPC
  }

  # Allow inbound from same SG for inter-broker communication
  ingress {
    description = "Inter-broker communication"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    security_groups = [aws_security_group.msk.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-msk-sg"
    Environment = var.environment
  }
}

# Security Group for Amazon MQ (allow inbound on ActiveMQ ports: 61616 for STOMP, 8161 for Web UI, etc.)
# We'll allow the standard ActiveMQ OpenWire port (61616) and the Web console (8161) from within the VPC.
resource "aws_security_group" "mq" {
  name        = "${var.environment}-mq-sg"
  description = "Allow inbound traffic to Amazon MQ broker"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ActiveMQ OpenWire"
    from_port   = 61616
    to_port     = 61616
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "ActiveMQ Web Console"
    from_port   = 8161
    to_port     = 8161
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow inbound from same SG (if needed)
  ingress {
    description = "Inter-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.mq.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-mq-sg"
    Environment = var.environment
  }
}

# Security Group for IoT Core (not directly applicable, but we might need to allow the VPC to IoT Core? Actually, IoT Core is a public service, so we don't need a SG for it.
# However, we might want to allow outbound from ECS tasks to IoT Core on port 443 or 8883 (MQTT over TLS). We'll handle that in the egress of the ECS tasks SG (already open).