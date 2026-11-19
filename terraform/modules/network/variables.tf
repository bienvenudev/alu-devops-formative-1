variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range of the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "IP range of the public subnet, inside vpc_cidr"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "IP ranges of the two private subnets, inside vpc_cidr, one per availability zone"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Give exactly two private subnet ranges: the database needs two availability zones."
  }
}

variable "availability_zones" {
  description = "Names of the two availability zones to use, for example eu-west-1a and eu-west-1b"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Give exactly two availability zones."
  }
}

variable "create_nat_gateway" {
  description = "Create a managed NAT gateway for the private subnets. Costs more than the NAT instance on the bastion."
  type        = bool
  default     = false
}
