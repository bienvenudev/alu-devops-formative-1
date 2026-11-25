module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  create_nat_gateway   = var.create_nat_gateway
}

module "security" {
  source = "./modules/security"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  private_subnet_cidrs = var.private_subnet_cidrs
  allowed_ssh_cidr     = var.allowed_ssh_cidr
  app_port             = var.app_port
}

module "registry" {
  source = "./modules/registry"

  project_name = var.project_name
  environment  = var.environment
}

module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.network.private_subnet_ids
  db_sg_id             = module.security.db_sg_id
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
}

module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  public_subnet_id       = module.network.public_subnet_id
  app_subnet_id          = module.network.private_subnet_ids[0]
  private_route_table_id = module.network.private_route_table_id
  bastion_sg_id          = module.security.bastion_sg_id
  app_sg_id              = module.security.app_sg_id
  nat_gateway_id         = module.network.nat_gateway_id
  bastion_instance_type  = var.bastion_instance_type
  app_instance_type      = var.app_instance_type
  root_volume_size       = var.root_volume_size
  ssh_public_key         = var.ssh_public_key
}

module "github_oidc" {
  source = "./modules/github_oidc"

  project_name              = var.project_name
  environment               = var.environment
  github_repository         = var.github_repository
  github_subject_repository = var.github_subject_repository
  create_oidc_provider      = var.create_oidc_provider
  ecr_repository_arn        = module.registry.repository_arn
  db_secret_arn             = module.database.db_secret_arn
  bastion_sg_arn            = module.security.bastion_sg_arn
}
