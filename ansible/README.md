# Ansible

Configures the server created by Terraform: installs Docker, deploys the Isoko service and secures the server.

## What the playbook does

`site.yml` runs three roles in this order:

| Role | What it does |
| --- | --- |
| `docker` | Installs Docker and the Compose plugin, starts Docker at boot, lets the login user use Docker |
| `app` | Clones this repository to `/opt/isoko`, writes the `.env` file, runs `docker compose up -d --build`, then waits until `/health` answers |
| `security` | Turns on the firewall (only SSH and the API port are open), disables SSH password login and root login, enables fail2ban and installs automatic security updates (`unattended-upgrades`) |

Running the playbook again changes nothing if the server is already configured.

## Prerequisites

- Ansible 2.15 or newer on Linux, macOS or WSL (Windows Subsystem for Linux). Check with `ansible --version`.
- The server from Terraform, and its public IP (`terraform output instance_public_ip`).
- The private SSH key that matches the public key given to Terraform (`~/.ssh/isoko-key`).

## How to run it

1. Go to the folder and install the required collections:

   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   ```

2. Create your own inventory file. `inventory/hosts.ini` contains a placeholder, so copy it and put in the real IP and key path. The copy is ignored by git.

   ```bash
   cp inventory/hosts.ini inventory/hosts.local.ini
   ```

   Edit `inventory/hosts.local.ini`:

   ```ini
   [isoko]
   isoko-server ansible_host=203.0.113.25 ansible_ssh_private_key_file=~/.ssh/isoko-key
   ```

3. Check that Ansible can reach the server:

   ```bash
   ansible isoko -i inventory/hosts.local.ini -m ping
   ```

   You should see `pong`.

4. Run the playbook:

   ```bash
   ansible-playbook site.yml -i inventory/hosts.local.ini
   ```

5. Check the result from your computer:

   ```bash
   curl http://203.0.113.25:8000/health
   ```

   It must return `{"status":"ok"}`. Use your own IP.

6. Run step 4 a second time. The summary should show `changed=0`, which proves the playbook is safe to repeat.

## Variables

| Role | Variable | Default | Meaning |
| --- | --- | --- | --- |
| `app` | `app_repo_url` | this repository | Repository to deploy |
| `app` | `app_version` | `main` | Branch or tag to deploy |
| `app` | `app_dir` | `/opt/isoko` | Folder on the server |
| `app` | `app_host_port` | `8000` | Port of the API |
| `app` | `app_log_level` | `info` | Log detail |
| `security` | `security_ssh_port` | `22` | SSH port to keep open |
| `security` | `security_app_port` | `8000` | API port to keep open |

Override a value with `-e`, for example `-e app_version=f2-submission`.

## Security notes

- The firewall (`ufw`) denies all incoming traffic except SSH and the API port. Ports published by Docker bypass `ufw`, so the AWS security group created by Terraform is the main protection.
- SSH accepts keys only. Root login is off and `fail2ban` blocks repeated failed logins.
- Our CI runs `ansible-playbook --syntax-check` and `ansible-lint` on every pull request.
