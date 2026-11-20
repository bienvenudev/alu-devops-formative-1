variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets, in two availability zones"
  type        = list(string)
}

variable "db_sg_id" {
  description = "ID of the database security group"
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
