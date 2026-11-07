# Formative 3 contract

Everyone writes their files against these names, so the parts fit together without waiting for each other.

## Cloud and server
- Cloud: AWS, region `eu-west-1` (a variable), one Ubuntu 24.04 server, user `ubuntu`
- App port: `8000`, health check: `/health`
- Only Bienvenu runs `terraform apply`, `terraform destroy` and the Ansible playbook against the real server

## Terraform (`terraform/`)

Variables (all defined in `variables.tf`, do not redefine them): `aws_region`, `project_name`, `environment`, `vpc_cidr`, `public_subnet_cidr`, `instance_type`, `root_volume_size`, `app_port`, `allowed_ssh_cidr`, `ssh_public_key`.

| File | Owner | Resource names |
| --- | --- | --- |
| `versions.tf`, `providers.tf`, `variables.tf`, `terraform.tfvars.example` | Bienvenu | provider and variables |
| `network.tf` | Victor | `aws_vpc.main`, `aws_default_security_group.default`, `aws_internet_gateway.main`, `aws_subnet.public`, `aws_route_table.public`, `aws_route_table_association.public` |
| `security.tf` | Adeline | `aws_security_group.app` |
| `compute.tf` | Adeline | `aws_key_pair.deploy`, `aws_instance.app`, `aws_eip.app` |
| `outputs.tf` | Adeline | `instance_public_ip`, `instance_id`, `vpc_id`, `public_subnet_id`, `security_group_id`, `ssh_command` |
| `README.md` | Olive | none |

## Ansible (`ansible/`)

- Inventory group: `isoko`, file `inventory/hosts.ini`
- Playbook: `site.yml` runs the roles `docker`, `app`, `security` in this order
- Roles: `docker` (Adeline), `security` (Victor), `app` (Bienvenu)
- The app is deployed by cloning this repository on the server into `/opt/isoko` and running `docker compose up -d --build`
- Variables of the `app` role: `app_repo_url`, `app_version`, `app_dir`, `app_host_port`, `app_log_level`
- Variables of the `security` role: `security_ssh_port`, `security_app_port`
- `README.md`: Olive

## CI jobs (`.github/workflows/ci.yml`)

`lint`, `test`, `docker-build` (existing), plus `dependency-scan` (pip-audit), `image-scan` (Trivy), `iac-scan` (Checkov), `terraform-validate`, `ansible-check`.

## Other files
- `SECURITY.md`: Olive
- Root `README.md` F3 sections: Olive
- AI Use Annex: Bienvenu
