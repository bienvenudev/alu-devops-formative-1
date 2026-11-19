output "role_arn" {
  description = "ARN of the IAM role that GitHub Actions assumes to deploy"
  value       = aws_iam_role.github_actions.arn
}
