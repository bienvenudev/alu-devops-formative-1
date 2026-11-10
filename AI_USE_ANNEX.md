# AI Use Annex

This annex documents how AI tools were used in this project, as required by the Formative 3 AI policy.

## Tools used

| Tool | Where it was used |
| --- | --- |
| Claude (Claude Code in the terminal) | Planning the work split, drafting the Terraform, Ansible, CI security scan jobs, `SECURITY.md` and READMEs, preparing instructions for teammates, checking pull requests, and assisting with the AWS deployment |
| GitHub Copilot | Editor suggestions, git commit messages, and automatic pull request reviews |

## How we used AI

- **Formative 1:** AI assisted with the project idea and the application code (the FastAPI price service).
- **Formative 2:** AI assisted with the understanding of Dockerfile format, the Docker Compose file and the CI workflow.
- **Formative 3:** AI produced first drafts of most of the infrastructure and security files. The team reviewed, tested and corrected them, committed them in small steps on their own branches, and explained them in their pull requests. We wrote our own Ansible Docker role and our own first version of the Terraform security group and server.
- **Prompts:** we asked Claude to plan the F3 work split, prepare the files and instructions for each teammate, check pull requests, and assist with the deployment.
- **What we checked:** every file was checked with `terraform validate`, `ansible-lint` and the security scanners before it was committed. The scanners found real problems in the first drafts (vulnerable Python packages, two HIGH image vulnerabilities and nine failed Terraform rules), which we fixed or documented in `SECURITY.md`. I ran the real deployment on AWS myself and approved each `apply` and `destroy`.

## What the AI did not do

- It did not choose the project idea or the team roles.
- Merging, approving pull requests, and the AWS account and billing were done by people.
