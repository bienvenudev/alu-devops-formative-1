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

variable "private_subnet_cidrs" {
  description = "IP ranges of the two private subnets, inside vpc_cidr"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Names of the two availability zones to use. They must belong to aws_region."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "create_nat_gateway" {
  description = "Use a managed NAT gateway instead of the NAT instance on the bastion. More reliable, but costs more."
  type        = bool
  default     = false
}

variable "bastion_instance_type" {
  description = "EC2 instance type of the bastion"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type of the application server"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of each server disk in GB"
  type        = number
  default     = 20
}

variable "app_port" {
  description = "Port where the Isoko API listens on the application server"
  type        = number
  default     = 8000
}

variable "allowed_ssh_cidr" {
  description = "Address allowed to connect to the bastion over SSH, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Use a valid CIDR block and do not open SSH to the whole internet (0.0.0.0/0)."
  }
}

variable "ssh_public_key" {
  description = "Content of the SSH public key (the .pub file) used to log in to both servers"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database created inside the instance"
  type        = string
  default     = "isoko"
}

variable "db_username" {
  description = "Administrator user name of the database"
  type        = string
  default     = "isoko_admin"
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in the form owner/name"
  type        = string
  default     = "bienvenudev/alu-devops-formative-1"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the AWS account already has one."
  type        = bool
  default     = true
}
