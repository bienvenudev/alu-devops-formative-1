variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range of the VPC, translated by the NAT instance"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the bastion runs"
  type        = string
}

variable "app_subnet_id" {
  description = "ID of the private subnet where the application server runs"
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the route table used by the private subnets"
  type        = string
}

variable "bastion_sg_id" {
  description = "ID of the bastion security group"
  type        = string
}

variable "app_sg_id" {
  description = "ID of the application server security group"
  type        = string
}

variable "nat_gateway_id" {
  description = "ID of a managed NAT gateway. Leave empty to use the bastion as a NAT instance."
  type        = string
  default     = ""
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

variable "ssh_public_key" {
  description = "Content of the SSH public key (the .pub file) used to log in to both servers"
  type        = string
}
