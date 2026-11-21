locals {
  use_nat_instance = var.nat_gateway_id == ""
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "bastion" {
  #checkov:skip=CKV2_AWS_41:The bastion does not call any AWS API, so it needs no IAM role.
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = var.bastion_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  key_name               = aws_key_pair.deploy.key_name
  ebs_optimized          = true
  monitoring             = true
  source_dest_check      = !local.use_nat_instance

  user_data = templatefile("${path.module}/nat-user-data.sh.tftpl", {
    vpc_cidr   = var.vpc_cidr
    enable_nat = local.use_nat_instance
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
    Role = "bastion"
  }
}

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-eip"
  }
}

resource "aws_instance" "app" {
  #checkov:skip=CKV2_AWS_41:The server does not call any AWS API. The image is pulled with a short-lived token passed by the pipeline.
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.app_instance_type
  subnet_id                   = var.app_subnet_id
  vpc_security_group_ids      = [var.app_sg_id]
  key_name                    = aws_key_pair.deploy.key_name
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
    Role = "app"
  }
}

resource "aws_route" "private_default" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.use_nat_instance ? null : var.nat_gateway_id
  network_interface_id   = local.use_nat_instance ? aws_instance.bastion.primary_network_interface_id : null
}
