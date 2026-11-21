# Security

This page explains how we check the Isoko project for security problems, what the checks found, and what we did about it. Findings are from 7 November 2026 (Formative 3) and 18 November 2026 (Summative).

## Reporting a vulnerability

Please open a GitHub issue with the label `security` and describe the problem without publishing exploit details, or contact the team lead through the repository owner's GitHub profile.

## Security scans in CI

All scans run on every push to a branch other than `main` and on every pull request to `main`. A failing scan blocks the merge, because all eight checks are required in branch protection. The image scan runs a second time in the CD pipeline, before the image is pushed to the registry.

| Scan | Tool | CI job | What it checks | When it fails |
| --- | --- | --- | --- | --- |
| Dependency scan | pip-audit 2.10.1 | `dependency-scan` | Python packages in `requirements.txt` | Any known vulnerability |
| Image scan | Trivy (action v0.36.0, Trivy v0.70.0) | `image-scan` | Operating system and Python packages in the Docker image | A HIGH or CRITICAL vulnerability that has a fix available |
| IaC scan | Checkov 3.4.3 | `iac-scan` | Terraform files in `terraform/` | Any failed rule. A rule can only be skipped with a written reason in the code. |

We ignore vulnerabilities that have no fix yet in the image scan, because we cannot fix them ourselves. They are listed below as accepted risk and are shown again by every new scan.

## Findings and how we addressed them

The sections below follow the project. Formative 3 findings come first, then the Summative findings.

### Formative 3: dependency scan

- **Finding:** the first scan of `requirements.txt` reported 14 entries (7 different advisories, each listed twice: PYSEC-2026-248, 249, 161, 1941, 1942, 2280 and 2281) in `starlette 0.41.3`, which FastAPI installs. The fixed versions range from 0.47.2 to 1.3.1.
- **Fix:** we upgraded `fastapi` from 0.115.6 to 0.162.2 and `uvicorn` from 0.34.0 to 0.54.0. This installs Starlette 1.10.0. pip-audit now reports no known vulnerabilities. We ran the 14 tests and started the container again to confirm that nothing broke.

### Formative 3: image scan

- **Finding:** the first scan of the image (built on `python:3.12-slim`, Debian 13.7) found 2 HIGH vulnerabilities in the `zlib1g` package (CVE-2026-76844 and CVE-2026-85091). A fixed version already existed.
- **Fix:** the Dockerfile now runs `apt-get upgrade` in the final stage, so the image always includes the security updates released after the base image was built. The scan then reports 0 HIGH and 0 CRITICAL vulnerabilities with a fix.
- **Accepted risk:** a scan without the "fix available" filter still lists 189 findings in the base operating system: 47 HIGH (all without a fix), 79 MEDIUM (5 with a fix) and 63 LOW (1 with a fix). The 47 HIGH have no fixed version from Debian yet, so we cannot remove them. The 6 MEDIUM and LOW findings with a fix are below our blocking level and will be removed when the base image is refreshed. To reduce the exposure we use the slim image, run the container as a non-root user, expose only port 8000, and scan again on every pull request.

### Formative 3: infrastructure as code scan

The first draft of the Terraform code passed 10 rules and failed 9. We fixed 7 and accepted 2.

| Rule | What it checks | Resource | Result |
| --- | --- | --- | --- |
| CKV_AWS_135 | Server is EBS optimized | `aws_instance.app` | Fixed: `ebs_optimized = true` |
| CKV_AWS_126 | Detailed monitoring is on | `aws_instance.app` | Fixed: `monitoring = true` |
| CKV_AWS_79 | Metadata service version 1 is off | `aws_instance.app` | Fixed: `http_tokens = "required"` |
| CKV_AWS_130 | Subnet does not give public IPs by default | `aws_subnet.public` | Fixed: `map_public_ip_on_launch = false`, the server gets an Elastic IP instead |
| CKV_AWS_382 | No egress to all ports | `aws_security_group.app` | Fixed: outgoing traffic only on ports 443, 80 and 53 |
| CKV_AWS_23 | Every security group rule has a description | `aws_security_group.app` | Fixed: descriptions added |
| CKV2_AWS_12 | Default security group allows no traffic | `aws_vpc.main` | Fixed: `aws_default_security_group` with no rules |
| CKV2_AWS_11 | VPC flow logs are on | `aws_vpc.main` | **Accepted.** Flow logs need a log group and an IAM role, which adds cost and complexity for one test server. To be enabled in production. |
| CKV2_AWS_41 | An IAM role is attached to the server | `aws_instance.app` | **Accepted.** The server does not call any AWS API, so it needs no role. |

The final scan shows 19 rules passed, 0 failed and 2 skipped. Each skip has its reason in a `#checkov:skip` comment in the code.

### Summative: the modular Terraform code

The Summative replaced the single server with a private network, a bastion, a private application server, a managed database, a private registry and a role for the pipeline. The first scan of the new modules passed 152 rules and failed 4. We fixed 2 and accepted 2.

| Rule | What it checks | Resource | Result |
| --- | --- | --- | --- |
| CKV2_AWS_69 | Database encryption in transit | `aws_db_instance.main` | Fixed: the parameter group sets `rds.force_ssl = 1`, and the application connects with `sslmode=require` |
| CKV_AWS_394 | The availability zones are pinned by name | `aws_availability_zones.selected` | Fixed: the zones are a variable and the data source filters on them |
| CKV_AWS_24 | No SSH from `0.0.0.0/0` | `aws_vpc_security_group_ingress_rule.app_ssh` | **Accepted as a false positive.** The source of the rule is the bastion security group, not the internet. The rule is reported because it has no CIDR block. |
| CKV_AWS_353 | Performance Insights is on | `aws_db_instance.main` | **Accepted.** It is not enabled, to keep the cost low and because it is not available on every small instance class. |

The final scan shows **157 rules passed, 0 failed and 16 skipped**. Every skip has its reason in a `#checkov:skip` comment in the code. The skips are:

| Rule | Resource | Reason |
| --- | --- | --- |
| CKV2_AWS_11 | VPC | Flow logs add cost for a single test environment. Enable them in production. |
| CKV2_AWS_5 (three times) | The three security groups | Each group is attached to its server in another module, which the scan cannot see. |
| CKV_AWS_260 | Bastion HTTP rule | It is the public web endpoint. Production should add HTTPS behind a load balancer. |
| CKV_AWS_24 | Application server SSH rule | False positive, see above. |
| CKV2_AWS_41 (twice) | Bastion and application server | The servers do not call any AWS API, so they need no IAM role. The image is pulled with a short-lived token passed by the pipeline. |
| CKV_AWS_157 | Database | A single-zone database keeps the cost low. Production should use Multi-AZ. |
| CKV_AWS_118 | Database | Enhanced monitoring needs an extra role and adds cost. Basic CloudWatch metrics are on. |
| CKV_AWS_293 | Database | Deletion protection is off so that the course environment can be destroyed. |
| CKV_AWS_161 | Database | The application uses the generated password from Secrets Manager. IAM authentication is a possible improvement. |
| CKV_AWS_353 | Database | Performance Insights is off, see above. |
| CKV_AWS_136 | Registry | The AWS-managed key is used. A customer-managed key adds cost. |
| CKV_AWS_149 | Database secret | The AWS-managed key is used. A customer-managed key adds cost. |
| CKV2_AWS_57 | Database secret | Automatic rotation needs a Lambda function. The password is rotated by hand, so that an automatic rotation can never break the running service. |

### Summative: dependencies and image

- Adding PostgreSQL support brought two packages: `psycopg 3.3.9` and `psycopg-pool 3.3.3`. `pip-audit` reports no known vulnerabilities for the full list.
- The image scan of the final image (Trivy v0.70.0) reports 0 HIGH and 0 CRITICAL vulnerabilities with a fix. The same scan runs in the CD pipeline before the image is pushed, so a vulnerable image is never deployed.
- The private registry scans every pushed image as well (`scan_on_push`), tags are immutable, and only the last ten images are kept.

### Summative: controls in the design

- **Network:** only the bastion is public. The application server and the database are in private subnets. The database accepts connections only from the application server, and only with SSL.
- **Access:** SSH uses keys only and is allowed from one admin address. The CD pipeline opens SSH for its own address during a deployment and closes it again afterwards. The role it uses can only touch the bastion security group.
- **Pipeline credentials:** GitHub Actions logs in to AWS with OIDC and short-lived credentials. Only the `main` branch of this repository can assume the role. No AWS keys are stored in GitHub.
- **Secrets:** the database password is generated, stored in Secrets Manager and written to the server with file mode 0600. It is hidden from the pipeline logs. The only secret stored in GitHub is the deployment SSH key.

## Other known risks we accept

- **No HTTPS.** The service is served over plain HTTP by nginx on the bastion and only returns sample data. A production version should use HTTPS behind a load balancer.
- **Single points of failure.** The bastion is also the NAT instance and the public entry point, and the database has one zone. This keeps the cost low. A managed NAT gateway (`create_nat_gateway`), a load balancer and Multi-AZ would remove them.
- **Docker bypasses the firewall.** Ports published by Docker are not filtered by `ufw`. The AWS security groups are the real protection.
- **Local Terraform state.** The state file contains the generated database password. It is ignored by git and stays on the team lead's machine. A production version should use an encrypted remote backend.
- **Deployment key in GitHub.** The SSH key used by the pipeline is stored as a GitHub secret. A production version should use AWS Systems Manager Session Manager instead of SSH.
- **Secrets.** No secret is stored in the repository. `.env`, `terraform.tfvars`, `*.tfstate` and private keys are ignored by git.

## Running the scans yourself

```bash
pip install pip-audit checkov
pip-audit -r services/price-service/requirements.txt
checkov -d terraform --framework terraform
docker build -t isoko-price-service:scan .
trivy image --severity HIGH,CRITICAL --ignore-unfixed isoko-price-service:scan
```
