# TERRAFORM AND AWS PROVIDER
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.16.2"
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "cally_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# SUBNETS
# ------------------------------------------------------------
# Public Subnet
# Frontend
# Availability Zone: eu-west-2a
# ------------------------------------------------------------
resource "aws_subnet" "cally_public_subnet" {
  vpc_id                  = aws_vpc.cally_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-cally-public-subnet"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Private Subnet
# Backend
# Availability Zone: eu-west-2b
# ------------------------------------------------------------
resource "aws_subnet" "cally_private_subnet" {
  vpc_id            = aws_vpc.cally_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_availability_zone

  tags = {
    Name        = "${var.project_name}-cally-private-subnet"
    Environment = var.environment
  }
}


# ------------------------------------------------------------
# Database Subnet
# RDS
# Availability Zone: eu-west-2c
# ------------------------------------------------------------

resource "aws_subnet" "cally_database_subnet" {
  vpc_id            = aws_vpc.cally_vpc.id
  cidr_block        = var.database_subnet_cidr
  availability_zone = var.database_availability_zone

  tags = {
    Name        = "${var.project_name}-cally-database-subnet"
    Environment = var.environment
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "cally_igw" {
  vpc_id = aws_vpc.cally_vpc.id

  tags = {
    Name        = "${var.project_name}-cally-igw"
    Environment = var.environment
  }
}

# ROUTE TABLES
# ------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cally_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cally_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rt_ass" {
  subnet_id      = aws_subnet.cally_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------------------------------
# Private Route Table
# ------------------------------------------------------------

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cally_vpc.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }


  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}


resource "aws_route_table_association" "private_rt_ass" {
  subnet_id      = aws_subnet.cally_private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------------------------------------------------
# Database Route Table
# ------------------------------------------------------------
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.cally_vpc.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }


  tags = {
    Name        = "${var.project_name}-database-rt"
    Environment = var.environment
  }
}


resource "aws_route_table_association" "database_rt_ass" {
  subnet_id      = aws_subnet.cally_database_subnet.id
  route_table_id = aws_route_table.database_rt.id
}


# NAT Gateway lives in the PUBLIC subnet

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "cally_ng" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.cally_public_subnet.id

  depends_on = [
    aws_internet_gateway.cally_igw
  ]

  tags = {
    Name        = "${var.project_name}-cally-ng"
    Environment = var.environment
  }
}

# Private subnet uses NAT Gateway for outbound internet access
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.cally_ng.id
}


# ============================================================
# SECURITY GROUPS
# ============================================================

# ------------------------------------------------------------
# Public / Frontend Security Group
# ------------------------------------------------------------

resource "aws_security_group" "public_sg" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public frontend resources"
  vpc_id      = aws_vpc.cally_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-public-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Private / Backend Security Group
# ------------------------------------------------------------

resource "aws_security_group" "private_sg" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private backend resources"
  vpc_id      = aws_vpc.cally_vpc.id

  ingress {
    description     = "Backend traffic from frontend"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-private-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# Database Security Group
# ------------------------------------------------------------
resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.cally_vpc.id

  ingress {
    description     = "PostgreSQL from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.private_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-database-sg"
    Environment = var.environment
  }
}

# COMPUTE SERVICES 
# ============================================================
# UBUNTU AMI LOOKUP
# ============================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ============================================================
# FRONTEND EC2
# ============================================================

resource "aws_instance" "frontend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id = aws_subnet.cally_public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.public_sg.id
  ]

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment

  }
}

# BACKEND EC2
resource "aws_instance" "backend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id = aws_subnet.cally_private_subnet.id

  vpc_security_group_ids = [
    aws_security_group.private_sg.id
  ]

  tags = {
    Name        = "${var.project_name}-backend-server"
    Environment = var.environment
  }
}

# ============================================================
# RDS DATABASE SUBNET GROUP
# ============================================================
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    aws_subnet.cally_private_subnet.id,
    aws_subnet.cally_database_subnet.id
  ]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}
# RDS POSTGRESQL
resource "aws_db_instance" "db_server" {
  identifier     = "${var.project_name}-database"
  engine         = "postgres"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.database_sg.id
  ]

  publicly_accessible = false

  backup_retention_period = 0

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-database"
    Environment = var.environment
    Tier        = "database"
  }
}