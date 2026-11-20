# Ansible

Configures the two servers created by Terraform: the bastion (public entry point and NAT instance) and the application server (Docker and the Isoko container).

## What the playbook does

`site.yml` has two plays:

| Play | Hosts | Roles | What happens |
| --- | --- | --- | --- |
| 1 | `bastion` | `security`, `bastion` | Firewall (SSH and port 80 only, forwarding allowed for the NAT), SSH hardening, fail2ban, then nginx as the reverse proxy to the application server |
| 2 | `app` | `docker`, `app`, `security` | Docker and Compose, then the Isoko container pulled from the private registry, then the firewall (SSH and port 8000 from the VPC only) and SSH hardening |

The application server has no public address. Ansible reaches it through the bastion with an SSH `ProxyCommand` that is defined in the inventory. Running the playbook again changes nothing when the servers are already configured.

| Role | What it does |
| --- | --- |
| `docker` | Installs Docker Engine and the Compose plugin from Docker's repository, starts Docker, lets the `ubuntu` user use it |
| `app` | Logs in to the registry, writes the `.env` file (mode 0600) and the compose file, pulls the image, starts the service, waits until `/ready` answers, removes unused images |
| `bastion` | Installs nginx, writes the proxy configuration, checks it with `nginx -t`, checks that IP forwarding is on |
| `security` | Installs ufw, fail2ban and automatic updates, opens only the listed ports, hardens SSH (keys only, no root login) |

## Prerequisites

- Ansible 2.15 or newer on Linux, macOS or WSL (Windows Subsystem for Linux). Check with `ansible --version`.
- The servers from Terraform and the private key `~/.ssh/isoko-key`.
- The IP of the bastion in the SSH security group (the variable `allowed_ssh_cidr` of Terraform).

## Inventory

`inventory/hosts.yml` has the groups `bastion` and `app`. The addresses are read from environment variables, so no IP is written in the repository:

| Variable | Meaning |
| --- | --- |
| `BASTION_PUBLIC_IP` | Public IP of the bastion (`terraform output bastion_public_ip`) |
| `APP_PRIVATE_IP` | Private IP of the application server (`terraform output app_private_ip`) |
| `ISOKO_SSH_KEY` | Path of the private key. The default is `~/.ssh/isoko-key`. |

## How to run it by hand

The CD pipeline normally runs the playbook. To run it yourself:

1. Install the collections:

   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   ```

2. Set the addresses:

   ```bash
   export BASTION_PUBLIC_IP=$(terraform -chdir=../terraform output -raw bastion_public_ip)
   export APP_PRIVATE_IP=$(terraform -chdir=../terraform output -raw app_private_ip)
   ```

3. Check that Ansible reaches both servers. The application server answers through the bastion:

   ```bash
   ansible all -m ping
   ```

   You should see `pong` twice.

4. Run the playbook. The application settings come from a file, so that the database password is never typed on the command line (the file below is only an example, and must not be committed):

   ```bash
   ansible-playbook site.yml -e @deploy_vars.json
   ```

   with a `deploy_vars.json` such as:

   ```json
   {
     "app_image": "<registry>/isoko-dev-price-service:<commit>",
     "app_version": "<commit>",
     "app_ecr_registry": "<registry>",
     "app_ecr_password": "<output of: aws ecr get-login-password>",
     "app_db_host": "<terraform output db_address>",
     "app_db_password": "<password from the Secrets Manager secret>"
   }
   ```

5. Run step 4 a second time. The summary should show `changed=0`.

## Variables

| Role | Variable | Default | Meaning |
| --- | --- | --- | --- |
| `app` | `app_dir` | `/opt/isoko` | Folder on the server |
| `app` | `app_image` | none, required | Full image name with the tag |
| `app` | `app_version` | `dev` | Version shown by `/ready` (the git commit) |
| `app` | `app_host_port` | `8000` | Port of the service on the server |
| `app` | `app_log_level` | `info` | Log detail |
| `app` | `app_db_host` | none, required | Database host name |
| `app` | `app_db_port` | `5432` | Database port |
| `app` | `app_db_name` | `isoko` | Database name |
| `app` | `app_db_user` | `isoko_admin` | Database user |
| `app` | `app_db_password` | none, required | Database password |
| `app` | `app_db_sslmode` | `require` | SSL mode of the database connection |
| `app` | `app_pull_policy` | `always` | When to pull the image |
| `app` | `app_ecr_registry` | empty | Registry to log in to |
| `app` | `app_ecr_password` | empty | Registry token |
| `bastion` | `bastion_upstream_host` | the application server | Where nginx forwards traffic |
| `bastion` | `bastion_upstream_port` | `8000` | Port of the application |
| `bastion` | `bastion_nat_instance` | `true` | Check that IP forwarding is on. Set to `false` when a managed NAT gateway is used. |
| `security` | `security_ssh_port` | `22` | SSH port |
| `security` | `security_open_ports` | `[22]` | Ports opened in the firewall (set per group in `group_vars/`) |
| `security` | `security_allowed_source` | `any` | Where the ports may be reached from |
| `security` | `security_allow_routed` | `false` | Allow forwarded traffic. Needed on the bastion for the NAT. |

## Security notes

- The firewall (`ufw`) opens only the listed ports. On the bastion it also allows forwarded traffic, otherwise the private server would lose internet access.
- Ports published by Docker bypass `ufw`. The AWS security groups created by Terraform are the main protection.
- SSH accepts keys only, root login is off, and `fail2ban` blocks repeated failed logins. TCP forwarding stays on because the bastion hop needs it.
- Secrets (the registry token and the database password) are passed with `-e @file`, written with mode 0600 and hidden from the Ansible output with `no_log`.
- Our CI runs `ansible-playbook --syntax-check` and `ansible-lint` on every pull request.
