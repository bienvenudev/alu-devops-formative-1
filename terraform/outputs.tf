output "bastion_public_ip" {
  description = "Public IP address of the bastion, also the public address of the service"
  value       = module.compute.bastion_public_ip
}

output "app_url" {
  description = "Public URL of the service"
  value       = "http://${module.compute.bastion_public_ip}"
}

output "app_private_ip" {
  description = "Private IP address of the application server"
  value       = module.compute.app_private_ip
}

output "ecr_repository_url" {
  description = "URL of the private container registry repository"
  value       = module.registry.repository_url
}

output "db_address" {
  description = "Host name of the database"
  value       = module.database.db_address
}

output "db_secret_arn" {
  description = "ARN of the secret that holds the database password"
  value       = module.database.db_secret_arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role that GitHub Actions assumes to deploy"
  value       = module.github_oidc.role_arn
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group, opened temporarily by the pipeline"
  value       = module.security.bastion_sg_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "ssh_command" {
  description = "Command to connect to the bastion"
  value       = "ssh -i ~/.ssh/isoko-key ubuntu@${module.compute.bastion_public_ip}"
}
