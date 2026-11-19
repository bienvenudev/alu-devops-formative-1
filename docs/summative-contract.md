# Summative contract

Everyone writes their files against these names, so the parts fit together without waiting for each other.

## Architecture in one paragraph

A VPC in `eu-west-1` has one public subnet and two private subnets. The **bastion** (public subnet, Elastic IP) is the only server reachable from the internet. It runs nginx, which forwards web traffic to the **application server** in a private subnet, and it works as a **NAT instance** so that the private subnets can download packages and images. The application server runs the Isoko container. The container talks to a **PostgreSQL database** (RDS) in the private subnets. The image comes from a **private registry** (ECR). GitHub Actions logs in to AWS with a role (OIDC, no stored keys), pushes the image, and runs Ansible through the bastion.

## Terraform: `terraform/`

Root files (Bienvenu): `versions.tf`, `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars.example`.

| Module (folder in `terraform/modules/`) | Files | Owner | Needs from other modules |
| --- | --- | --- | --- |
| `network` | `main.tf`, `variables.tf`, `outputs.tf` | Victor | nothing |
| `security` | `main.tf`, `variables.tf`, `outputs.tf` | Victor | `vpc_id` |
| `compute` | `main.tf`, `variables.tf`, `outputs.tf`, `nat-user-data.sh.tftpl` | Adeline | subnet, route table and security group IDs |
| `database` | `main.tf`, `variables.tf`, `outputs.tf` | Bienvenu | private subnets, `db_sg_id` |
| `registry` | `main.tf`, `variables.tf`, `outputs.tf` | Bienvenu | nothing |
| `github_oidc` | `main.tf`, `variables.tf`, `outputs.tf` | Bienvenu | registry ARN, secret ARN, bastion security group ARN |

Every module folder already contains `versions.tf` (from the foundation). Never edit it.

### Module inputs and outputs

**network** inputs: `project_name`, `environment`, `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidrs`, `availability_zones`, `create_nat_gateway`.
Outputs: `vpc_id`, `vpc_cidr`, `public_subnet_id`, `private_subnet_ids`, `private_route_table_id`, `nat_gateway_id`.

**security** inputs: `project_name`, `environment`, `vpc_id`, `private_subnet_cidrs`, `allowed_ssh_cidr`, `app_port`.
Outputs: `bastion_sg_id`, `bastion_sg_arn`, `app_sg_id`, `db_sg_id`.

**compute** inputs: `project_name`, `environment`, `vpc_cidr`, `public_subnet_id`, `app_subnet_id`, `private_route_table_id`, `bastion_sg_id`, `app_sg_id`, `nat_gateway_id`, `bastion_instance_type`, `app_instance_type`, `root_volume_size`, `ssh_public_key`.
Outputs: `bastion_public_ip`, `bastion_instance_id`, `app_private_ip`, `app_instance_id`, `key_name`.

**database** inputs: `project_name`, `environment`, `private_subnet_ids`, `db_sg_id`, `db_instance_class`, `db_allocated_storage`, `db_name`, `db_username`.
Outputs: `db_address`, `db_port`, `db_name`, `db_username`, `db_secret_arn`.

**registry** inputs: `project_name`, `environment`, `images_to_keep`. Outputs: `repository_url`, `repository_arn`, `repository_name`.

**github_oidc** inputs: `project_name`, `environment`, `github_repository`, `github_branch`, `create_oidc_provider`, `ecr_repository_arn`, `db_secret_arn`, `bastion_sg_arn`. Output: `role_arn`.

## Ansible: `ansible/`

- Inventory: `inventory/hosts.yml`, groups `bastion` (host `isoko-bastion`) and `app` (host `isoko-app`). The addresses come from the environment variables `BASTION_PUBLIC_IP` and `APP_PRIVATE_IP`, the key from `ISOKO_SSH_KEY` (default `~/.ssh/isoko-key`).
- Playbook `site.yml`: play 1 on `bastion` runs the roles `security` and `bastion`. Play 2 on `app` runs `docker`, `app` and `security`.
- Roles: `docker` (done in F3), `security` (changed by Adeline), `bastion` (Victor), `app` (Bienvenu).
- Variables per group are in `group_vars/`. Role variables:
  - `security`: `security_ssh_port`, `security_open_ports`, `security_allowed_source`, `security_allow_routed`
  - `bastion`: `bastion_upstream_host`, `bastion_upstream_port`, `bastion_nat_instance`
  - `app`: `app_dir`, `app_image`, `app_version`, `app_host_port`, `app_log_level`, `app_db_host`, `app_db_port`, `app_db_name`, `app_db_user`, `app_db_password`, `app_db_sslmode`, `app_pull_policy`, `app_ecr_registry`, `app_ecr_password`

## Pipeline

- `.github/workflows/ci.yml`: eight jobs (`lint`, `test`, `docker-build`, `dependency-scan`, `image-scan`, `iac-scan`, `terraform-validate`, `ansible-check`). It also runs when called by `cd.yml`.
- `.github/workflows/cd.yml`: runs on every merge to `main`: CI, then build, scan and push the image, then deploy with Ansible.
- Only Bienvenu edits the two workflow files.

## Fixed values

- Cloud: AWS, region `eu-west-1`. Server user: `ubuntu`. App port: `8000`. Health: `/health`, readiness: `/ready`.
- Only Bienvenu runs `terraform apply`, `terraform destroy` and `ansible-playbook` against the real servers.
