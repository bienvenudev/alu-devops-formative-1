# Terraform

Creates the AWS infrastructure for the Isoko price service.

## What it creates

- A VPC (`10.0.0.0/16`) with a public subnet (`10.0.1.0/24`), an internet gateway and a route table
- The default security group of the VPC, locked so that it allows no traffic
- A security group for the application: SSH from one address, the API port from anywhere, outgoing traffic only for web downloads (ports 80 and 443) and DNS (port 53)
- An SSH key pair, built from your public key
- One Ubuntu 24.04 EC2 server with an encrypted disk, detailed monitoring and the metadata service set to version 2 only
- An Elastic IP (a fixed public address) attached to the server

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer. Check with `terraform --version`.
- An AWS account and the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), configured with `aws configure`. Check with `aws sts get-caller-identity`, which must print your account.
- An SSH key pair. Create one with:

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
| `instance_type` | `t3.micro` | Server size |
| `root_volume_size` | `20` | Disk size in GB |
| `app_port` | `8000` | Port of the API |
| `allowed_ssh_cidr` | none, required | Address allowed to use SSH, for example `203.0.113.10/32`. `0.0.0.0/0` is rejected. |
| `ssh_public_key` | none, required | Content of your `.pub` file |

## How to use it

1. Go to the folder and create your values file:

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars`. Find your public IP with `curl https://checkip.amazonaws.com` and write it with `/32` at the end (for example `"203.0.113.10/32"`). Paste the content of `~/.ssh/isoko-key.pub` as `ssh_public_key`. The file `terraform.tfvars` is ignored by git and must never be committed.

3. Initialize (downloads the AWS provider):

   ```bash
   terraform init
   ```

4. See what will be created, without creating anything:

   ```bash
   terraform plan
   ```

5. Create the infrastructure. Type `yes` when asked:

   ```bash
   terraform apply
   ```

6. Read the outputs:

   ```bash
   terraform output
   ```

## Outputs

| Name | Description |
| --- | --- |
| `instance_public_ip` | Public IP of the server (use it in the Ansible inventory) |
| `instance_id` | ID of the EC2 instance |
| `vpc_id` | ID of the VPC |
| `public_subnet_id` | ID of the public subnet |
| `security_group_id` | ID of the application security group |
| `ssh_command` | Ready-to-use SSH command |

## Remove everything

```bash
terraform destroy
```

Type `yes` when asked. Do this when you finish, so that you are not charged.

## Cost and safety

- The server runs 24 hours a day until you destroy it. Detailed monitoring and the Elastic IP can add small costs. Destroy the infrastructure after use.
- Terraform stores what it created in a local `terraform.tfstate` file. It can contain sensitive values, so it is ignored by git. Never commit it.
- No secrets are written in the code. Region, addresses and the SSH key all come from variables.
- Our CI runs `terraform fmt`, `terraform validate` and the Checkov security scan on every pull request.
