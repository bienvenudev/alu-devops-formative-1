variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in the form owner/name"
  type        = string
}

variable "github_branch" {
  description = "Branch whose workflow runs are allowed to deploy"
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the AWS account already has one."
  type        = bool
  default     = true
}

variable "ecr_repository_arn" {
  description = "ARN of the container registry repository the pipeline may push to"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database password secret the pipeline may read"
  type        = string
}

variable "bastion_sg_arn" {
  description = "ARN of the bastion security group the pipeline may open temporarily for SSH"
  type        = string
}
