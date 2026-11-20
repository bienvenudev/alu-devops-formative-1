#!/usr/bin/env bash
# Stores the Terraform outputs in GitHub as repository variables, and the private SSH key as a secret.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-bienvenudev/alu-devops-formative-1}"
KEY_FILE="${ISOKO_SSH_KEY:-$HOME/.ssh/isoko-key}"
TF="terraform -chdir=terraform"

command -v gh >/dev/null || { echo "The GitHub CLI (gh) is not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Run 'gh auth login' first"; exit 1; }
[ -f "$KEY_FILE" ] || { echo "Private key not found: $KEY_FILE"; exit 1; }

repository_url="$($TF output -raw ecr_repository_url)"

set_var() {
  echo "variable $1"
  gh variable set "$1" --repo "$REPO" --body "$2"
}

set_var AWS_ROLE_ARN "$($TF output -raw github_actions_role_arn)"
region="$(grep -E '^aws_region' terraform/terraform.tfvars 2>/dev/null | cut -d'"' -f2 || true)"
set_var AWS_REGION "${region:-eu-west-1}"
set_var ECR_REGISTRY "${repository_url%%/*}"
set_var ECR_REPOSITORY "${repository_url#*/}"
set_var BASTION_PUBLIC_IP "$($TF output -raw bastion_public_ip)"
set_var APP_PRIVATE_IP "$($TF output -raw app_private_ip)"
set_var BASTION_SG_ID "$($TF output -raw bastion_security_group_id)"
set_var DB_SECRET_ARN "$($TF output -raw db_secret_arn)"
set_var DB_ADDRESS "$($TF output -raw db_address)"

echo "secret DEPLOY_SSH_KEY (value not shown)"
gh secret set DEPLOY_SSH_KEY --repo "$REPO" < "$KEY_FILE"

echo "Done. The CD pipeline can now deploy."
