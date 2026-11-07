variable "aws_region" {
  description = "AWS region where everything is created"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Short name used in resource names and tags"
  type        = string
  default     = "isoko"
}

variable "environment" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IP range of the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range of the public subnet, inside vpc_cidr"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the server disk in GB"
  type        = number
  default     = 20
}

variable "app_port" {
  description = "Port where the Isoko API listens"
  type        = number
  default     = 8000
}

variable "allowed_ssh_cidr" {
  description = "Address allowed to connect over SSH, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Use a valid CIDR block and do not open SSH to the whole internet (0.0.0.0/0)."
  }
}

variable "ssh_public_key" {
  description = "Content of the SSH public key (the .pub file) used to log in to the server"
  type        = string
}
