# Security

This page explains how we check the Isoko project for security problems, what the checks found, and what we did about it. Findings are from 7 November 2026.

## Reporting a vulnerability

Please open a GitHub issue with the label `security` and describe the problem without publishing exploit details, or contact the team lead through the repository owner's GitHub profile.

## Security scans in CI

All scans run on every push to a branch other than `main` and on every pull request to `main`. A failing scan blocks the merge once the check is required in branch protection.

| Scan | Tool | CI job | What it checks | When it fails |
| --- | --- | --- | --- | --- |
| Dependency scan | pip-audit 2.10.1 | `dependency-scan` | Python packages in `requirements.txt` | Any known vulnerability |
| Image scan | Trivy (action v0.36.0, Trivy v0.70.0) | `image-scan` | Operating system and Python packages in the Docker image | A HIGH or CRITICAL vulnerability that has a fix available |
| IaC scan | Checkov 3.4.3 | `iac-scan` | Terraform files in `terraform/` | Any failed rule. A rule can only be skipped with a written reason in the code. |

We ignore vulnerabilities that have no fix yet in the image scan, because we cannot fix them ourselves. They are listed below as accepted risk and are shown again by every new scan.

## Findings and how we addressed them

### Dependency scan

- **Finding:** the first scan of `requirements.txt` reported 14 entries (7 different advisories, each listed twice: PYSEC-2026-248, 249, 161, 1941, 1942, 2280 and 2281) in `starlette 0.41.3`, which FastAPI installs. The fixed versions range from 0.47.2 to 1.3.1.
- **Fix:** we upgraded `fastapi` from 0.115.6 to 0.162.2 and `uvicorn` from 0.34.0 to 0.54.0. This installs Starlette 1.10.0. pip-audit now reports no known vulnerabilities. We ran the 14 tests and started the container again to confirm that nothing broke.

### Image scan

- **Finding:** the first scan of the image (built on `python:3.12-slim`, Debian 13.7) found 2 HIGH vulnerabilities in the `zlib1g` package (CVE-2026-76844 and CVE-2026-85091). A fixed version already existed.
- **Fix:** the Dockerfile now runs `apt-get upgrade` in the final stage, so the image always includes the security updates released after the base image was built. The scan then reports 0 HIGH and 0 CRITICAL vulnerabilities with a fix.
- **Accepted risk:** a scan without the "fix available" filter still lists 189 findings in the base operating system: 47 HIGH (all without a fix), 79 MEDIUM (5 with a fix) and 63 LOW (1 with a fix). The 47 HIGH have no fixed version from Debian yet, so we cannot remove them. The 6 MEDIUM and LOW findings with a fix are below our blocking level and will be removed when the base image is refreshed. To reduce the exposure we use the slim image, run the container as a non-root user, expose only port 8000, and scan again on every pull request.
