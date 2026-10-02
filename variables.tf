# AWS
variable "aws_region" {
  description = "AWS region where infrastructure will be created"
  type        = string
}

# PROJECT
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# SUBNETS
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
}

# AVAILABILITY ZONES
variable "public_availability_zone" {
  description = "Availability Zone for the public subnet"
  type        = string
}

variable "private_availability_zone" {
  description = "Availability Zone for the private subnet"
  type        = string
}

variable "database_availability_zone" {
  description = "Availability Zone for the database subnet"
  type        = string
}


# EC2
variable "ec2_instance_type" {
  description = "EC2 instance type for frontend and backend"
  type        = string
}


# RDS
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL database username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}