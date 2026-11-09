output "instance_public_ip" {
  description = "Public IP address of the server"
  value       = aws_eip.app.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "ssh_command" {
  description = "Command to connect to the server"
  value       = "ssh -i ~/.ssh/isoko-key ubuntu@${aws_eip.app.public_ip}"
}
