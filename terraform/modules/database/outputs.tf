output "db_address" {
  description = "Host name of the database"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port of the database"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Administrator user name of the database"
  value       = aws_db_instance.main.username
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the database credentials as JSON with username and password"
  value       = aws_secretsmanager_secret.db.arn
}
