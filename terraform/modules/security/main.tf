resource "aws_security_group" "bastion" {
  #checkov:skip=CKV2_AWS_5:The group is attached to the bastion instance in the compute module.
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Bastion: SSH from one address, public web traffic, NAT for the private subnets"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

resource "aws_security_group" "app" {
  #checkov:skip=CKV2_AWS_5:The group is attached to the application instance in the compute module.
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Application server: reachable only from the bastion"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

resource "aws_security_group" "db" {
  #checkov:skip=CKV2_AWS_5:The group is attached to the database instance in the database module.
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Database: reachable only from the application server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from the admin address only"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidr
}

resource "aws_vpc_security_group_ingress_rule" "bastion_http" {
  #checkov:skip=CKV_AWS_260:This is the public web endpoint of the service. Production should add HTTPS behind a load balancer.
  security_group_id = aws_security_group.bastion.id
  description       = "Public web traffic, forwarded by nginx to the application server"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_nat_https" {
  count = length(var.private_subnet_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "NAT: HTTPS from the private subnets"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.private_subnet_cidrs[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "bastion_nat_http" {
  count = length(var.private_subnet_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "NAT: HTTP from the private subnets"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.private_subnet_cidrs[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "bastion_nat_dns" {
  count = length(var.private_subnet_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "NAT: DNS from the private subnets"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = var.private_subnet_cidrs[count.index]
}

resource "aws_vpc_security_group_egress_rule" "bastion_https" {
  security_group_id = aws_security_group.bastion.id
  description       = "HTTPS for downloads and NAT traffic"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_http" {
  security_group_id = aws_security_group.bastion.id
  description       = "HTTP for apt mirrors and NAT traffic"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_dns" {
  security_group_id = aws_security_group.bastion.id
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_app_ssh" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "SSH to the application server"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_app_port" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "Forward web traffic to the application port"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  #checkov:skip=CKV_AWS_24:The source is the bastion security group, not the internet. The rule is reported by mistake because it has no CIDR block.
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from the bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "app_port" {
  security_group_id            = aws_security_group.app.id
  description                  = "Isoko API from the bastion"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS for package and image downloads, through the NAT"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP for apt mirrors, through the NAT"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_dns" {
  security_group_id = aws_security_group.app.id
  description       = "DNS"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "PostgreSQL to the database"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from the application server"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}
