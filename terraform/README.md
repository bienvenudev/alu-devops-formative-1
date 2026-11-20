# Terraform

Creates the AWS infrastructure for Isoko: a private network, a bastion host, an application server in a private subnet, a managed PostgreSQL database, a private container registry, and the role that lets GitHub Actions deploy.

## What it creates

| Module | Resources |
| --- | --- |
| `modules/network` | A VPC, one public subnet and two private subnets in two availability zones, an internet gateway, route tables, and the VPC default security group locked so that it allows no traffic. Optionally a managed NAT gateway. |
| `modules/security` | Security groups for the bastion, the application server and the database. SSH to the bastion only from one address, port 80 to the bastion from anywhere, the application server only from the bastion, the database only from the application server. |
| `modules/compute` | An SSH key pair, the bastion (public subnet, Elastic IP, NAT instance, encrypted disk) and the application server (private subnet, no public address, encrypted disk), plus the route that sends private traffic through the NAT instance. |
| `modules/database` | A PostgreSQL 16 database on RDS in the private subnets, encrypted, SSL required, with a generated password stored in Secrets Manager. |
| `modules/registry` | A private container registry (ECR) with scan on push, immutable tags and a rule that keeps the last ten images. |
| `modules/github_oidc` | The GitHub OIDC provider and an IAM role that only the `main` branch of this repository can assume. It may push to the registry, read the database secret and open SSH on the bastion. |

`main.tf` connects the modules. The module inputs and outputs are listed in [docs/summative-contract.md](../docs/summative-contract.md).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer. Check with `terraform --version`.
- An AWS account and the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Check with `aws sts get-caller-identity`, which must print your account.
- An SSH key pair:

  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/isoko-key -C "isoko"
  ```

  This creates `~/.ssh/isoko-key` (private, never share it) and `~/.ssh/isoko-key.pub` (public).

## Variables

| Name | Default | Description |
| --- | --- | --- |
| `aws_region` | `eu-west-1` | AWS region |
| `project_name` | `isoko` | Used in resource names and tags |
| `environment` | `dev` | Used in resource names and tags |
| `vpc_cidr` | `10.0.0.0/16` | IP range of the VPC |
| `public_subnet_cidr` | `10.0.1.0/24` | IP range of the public subnet |
| `private_subnet_cidrs` | `["10.0.11.0/24", "10.0.12.0/24"]` | IP ranges of the two private subnets |
| `availability_zones` | `["eu-west-1a", "eu-west-1b"]` | The two zones to use. They must belong to `aws_region`. |
| `create_nat_gateway` | `false` | Use a managed NAT gateway instead of the NAT instance on the bastion. More reliable, but costs more. |
| `bastion_instance_type` | `t3.micro` | Server size of the bastion |
| `app_instance_type` | `t3.micro` | Server size of the application server |
| `root_volume_size` | `20` | Disk size of each server in GB |
| `app_port` | `8000` | Port of the API on the application server |
| `allowed_ssh_cidr` | none, required | Address allowed to use SSH on the bastion, for example `203.0.113.10/32`. `0.0.0.0/0` is rejected. |
| `ssh_public_key` | none, required | Content of your `.pub` file |
| `db_instance_class` | `db.t3.micro` | Database size |
| `db_allocated_storage` | `20` | Database storage in GB |
| `db_name` | `isoko` | Name of the database |
| `db_username` | `isoko_admin` | Administrator user of the database |
| `github_repository` | `bienvenudev/alu-devops-formative-1` | Repository allowed to deploy, as `owner/name` |
| `create_oidc_provider` | `true` | Create the GitHub OIDC provider. Set to `false` if the AWS account already has one. |

## How to use it

1. Log in to AWS. Terraform does not read an `aws login` session, so also run:

   ```bash
   eval "$(aws configure export-credentials --format env)"
   ```

2. Go to the folder and create your values file:

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars`. Find your public IP with `curl https://checkip.amazonaws.com` and write it with `/32` at the end. Paste the content of `~/.ssh/isoko-key.pub` as `ssh_public_key`. The file `terraform.tfvars` is ignored by git and must never be committed.

4. Initialize, preview and create:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

   Type `yes` when asked. The database takes about 5 to 10 minutes.

5. Read the outputs:

   ```bash
   terraform output
   ```

6. Store the outputs in GitHub so that the CD pipeline can use them (needs the GitHub CLI, logged in as a repository admin):

   ```bash
   cd ..
   bash scripts/set-github-config.sh
   ```

## Outputs

| Name | Description |
| --- | --- |
| `bastion_public_ip` | Public IP of the bastion, also the public address of the service |
| `app_url` | Public URL of the service |
| `app_private_ip` | Private IP of the application server |
| `ecr_repository_url` | URL of the private container registry |
| `db_address` | Host name of the database |
| `db_secret_arn` | Secret that holds the database credentials |
| `github_actions_role_arn` | Role that GitHub Actions assumes |
| `bastion_security_group_id` | Security group that the pipeline opens for SSH during a deployment |
| `vpc_id` | ID of the VPC |
| `ssh_command` | Ready-to-use SSH command for the bastion |

## Remove everything

```bash
terraform destroy
```

Type `yes` when asked. Do this when you finish, so that you are not charged.

## Cost and safety

- With the NAT instance, the setup costs about 1.3 USD per day. A managed NAT gateway adds about 1.2 USD per day. These are approximate `eu-west-1` prices, so check the AWS pricing pages.
- Terraform keeps what it created in a local `terraform.tfstate` file. It contains the generated database password, so it is ignored by git and must never be committed. A production setup should keep the state in an encrypted remote backend.
- No secrets are written in the code. The region, addresses and the SSH key come from variables, and the database password is generated.
- Our CI runs `terraform fmt`, validates every module and runs the Checkov security scan on every pull request.
