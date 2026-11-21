output "bastion_public_ip" {
  description = "Public IP address of the bastion, also the public address of the service"
  value       = aws_eip.bastion.public_ip
}

output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "app_private_ip" {
  description = "Private IP address of the application server"
  value       = aws_instance.app.private_ip
}

output "app_instance_id" {
  description = "ID of the application server instance"
  value       = aws_instance.app.id
}

output "key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.deploy.key_name
}
