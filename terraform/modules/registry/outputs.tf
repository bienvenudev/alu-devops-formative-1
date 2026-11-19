output "repository_url" {
  description = "URL of the container registry repository, without a tag"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ARN of the container registry repository"
  value       = aws_ecr_repository.app.arn
}

output "repository_name" {
  description = "Name of the container registry repository"
  value       = aws_ecr_repository.app.name
}
