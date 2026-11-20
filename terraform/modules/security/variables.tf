variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups are created"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "IP ranges of the private subnets, allowed to use the bastion as a NAT instance"
  type        = list(string)
}

variable "allowed_ssh_cidr" {
  description = "Address allowed to connect to the bastion over SSH, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Use a valid CIDR block and do not open SSH to the whole internet (0.0.0.0/0)."
  }
}

variable "app_port" {
  description = "Port where the Isoko API listens on the application server"
  type        = number
}
