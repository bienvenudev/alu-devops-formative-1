resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  #checkov:skip=CKV_AWS_149:The secret is encrypted with the AWS-managed key. A customer-managed KMS key adds cost.
  #checkov:skip=CKV2_AWS_57:Automatic rotation needs a Lambda function. The password is rotated by hand (see the operations manual), so the app is never broken by a surprise rotation.
  name                    = "${var.project_name}-${var.environment}-db-credentials"
  description             = "Administrator credentials of the Isoko database"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnets"
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-postgres16"
  family = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = "ddl"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_157:A single-zone database keeps the cost low. Production should use Multi-AZ.
  #checkov:skip=CKV_AWS_118:Enhanced monitoring needs an extra IAM role and adds cost. Basic CloudWatch metrics are enabled.
  #checkov:skip=CKV_AWS_293:Deletion protection stays off so that the course environment can be destroyed. Turn it on in production.
  #checkov:skip=CKV_AWS_161:The application connects with the generated password stored in Secrets Manager. IAM authentication is a possible improvement.
  #checkov:skip=CKV_AWS_353:Performance Insights is not enabled to keep the cost low and because it is not available on every small instance class.
  identifier                          = "${var.project_name}-${var.environment}-db"
  engine                              = "postgres"
  engine_version                      = "16"
  instance_class                      = var.db_instance_class
  allocated_storage                   = var.db_allocated_storage
  storage_type                        = "gp3"
  storage_encrypted                   = true
  db_name                             = var.db_name
  username                            = var.db_username
  password                            = random_password.db.result
  db_subnet_group_name                = aws_db_subnet_group.main.name
  parameter_group_name                = aws_db_parameter_group.main.name
  vpc_security_group_ids              = [var.db_sg_id]
  publicly_accessible                 = false
  multi_az                            = false
  backup_retention_period             = 1
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  skip_final_snapshot                 = true
  deletion_protection                 = false
  iam_database_authentication_enabled = false

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
