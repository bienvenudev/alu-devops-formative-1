output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "bastion_sg_arn" {
  description = "ARN of the bastion security group"
  value       = aws_security_group.bastion.arn
}

output "app_sg_id" {
  description = "ID of the application server security group"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}
