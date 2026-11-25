# Demo video guide

A checklist for the Summative demo video. It tells you **what to show** for each of the 10 prompts and **what to think about while you talk**. It is not a script: the video must be narrated live, in your own words, with your face visible. Do not read this aloud.

Live application: `http://54.73.218.151` (the address is also in the README).

## Before you record

- [ ] Increase the font size of the terminal, the browser and the editor so that everything is readable at 720p.
- [ ] Open these tabs and windows in advance, in this order: the GitHub repository, the Projects board, the Actions tab, the editor with the project, a terminal inside the project folder, the live URL.
- [ ] Do a 1-minute test recording first: check that your face, your voice and the screen are all clear.
- [ ] Close notifications, chat apps and anything private.
- [ ] Record in one continuous take, 10 to 15 minutes (about 1 to 1.5 minutes per prompt). Say the prompt number aloud before each part, for example "Prompt 1, project foundation".
- [ ] Tools: OBS Studio, Zoom local recording or QuickTime. Show your face in a small overlay.
- [ ] You do **not** need AWS access. Everything that touches AWS is shown through GitHub (the Actions logs, the code) and through the live URL.

## Prompt 1: Project foundation (F1)

Show on GitHub:
- The **Projects** board with the columns and the issues (labels, assignees, milestones Formative 1, 2, 3 and Summative).
- **Settings → Branches → the rule for `main`**: pull request required, 1 approval, stale approvals dismissed, conversations resolved, administrators included, and the 8 required checks.
- A **pull request with a review comment** (for example one from the Summative).

Think about: why can nobody push directly to `main`, and what each rule prevents.

## Prompt 2: Application baseline (F1)

In the terminal:

```bash
cd services/price-service
python3 -m venv venv && source venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app
```

Then in the browser open `http://127.0.0.1:8000/docs` and try a request, and show `curl "http://127.0.0.1:8000/prices/cheapest?crop=maize"`. Run `pytest` and show it passes. Show the README sections "Getting Started" and the setup instructions.

Think about: could another engineer follow your README on their first try?

## Prompt 3: Containerization (F2)

Show the `Dockerfile` and point at: the pinned base image, the two stages, the non-root user, the health check. Then:

```bash
docker build -t isoko-demo .
docker run --rm -p 8000:8000 isoko-demo
curl http://127.0.0.1:8000/health
```

Think about: why a multi-stage build, why a non-root user, what the health check is for.

## Prompt 4: CI pipeline (F2)

On the **Actions** tab show:
- A **passing run** with the eight green jobs.
- A **failing run that caught a real problem**. Real examples in this repository: the pull request with the market coverage test (its first run failed on `test`, the second passed), and the first run of the CI workflow, where the container smoke test failed because it called the container before it had started, and was fixed by retrying.

Think about: what each job protects against, and why the failing run is evidence that the pipeline works.

## Prompt 5: Infrastructure as Code

In the editor open `terraform/` and walk through:
- The **structure**: `main.tf` connects the modules, `variables.tf`, `outputs.tf`, and the folder `modules/` with `network`, `security`, `compute`, `database`, `registry`, `github_oidc`.
- One or two modules: for example `network` (public and private subnets) and `security` (who may talk to whom).
- Recent plan output: open `docs/summative-run/terraform-plan.txt` and point at the key resources (VPC, bastion, application server in a private subnet, RDS, ECR, security groups). Also show the `terraform-validate` and `iac-scan` jobs in a pull request.

Think about: why the application server and the database are in private subnets, why everything is a variable.

## Prompt 6: Configuration management

In the editor open `ansible/` and show:
- `inventory/hosts.yml`: two groups, and how the private server is reached through the bastion.
- `site.yml` and the four roles.
- Recent execution: on the **Actions** tab open the latest **CD** run, the `deploy` job, and the Ansible output (the `PLAY RECAP`).

Point at the task that matters most for serving traffic: for example the `app` role starting the container and waiting for `/ready`, or nginx on the bastion forwarding to the private server.

Think about: what "idempotent" means (a second run changes nothing), and why Ansible and not a shell script.

## Prompt 7: Security scanning

On the **Actions** tab open a pull request run and the `iac-scan` or `image-scan` job. Then open `SECURITY.md` and pick **one real finding**:
- the Checkov rule `CKV2_AWS_69` (database encryption in transit): found, fixed with `rds.force_ssl`, or
- the Trivy finding in the zlib1g package (Formative 3): fixed by updating the image, or
- an accepted risk such as the public HTTP port: show the `#checkov:skip` comment in the code and its written reason.

Think about: the difference between fixing a finding and accepting a risk, and why an accepted risk needs a reason.

## Prompt 8: Full pipeline and deployment

1. Make a small change on a branch, for example a text change in the README, and open a pull request. Show the 8 checks running.
2. Get it approved and merge it.
3. Open the **CD** run on the Actions tab and walk through the stages as they run: `ci`, `build-and-push`, `deploy`.
4. When it finishes, open the live URL and show `/ready`. The `version` field is the git commit of the change you just merged, which proves the new code is running. Then use the service: `/prices`, `/prices/cheapest?crop=maize`, and report a price with the `/docs` page.

Think about: what makes the pipeline stop if something is wrong, and what the user sees if it stops (the old version keeps running).

## Prompt 9: Observability

Show one or more runtime signals and explain what each tells an operator:

```bash
curl http://<bastion-ip>/health
curl http://<bastion-ip>/ready
```

`/health` answers "is the process alive", `/ready` answers "can it reach its database". You can also show the container logs (the line `starting version=... repository=postgres`) or the `healthy` status of the container.

Think about: what a `503` on `/ready` would mean right now, and what you would check first.

## Prompt 10: Reflection and ownership

Show the commit history from Formative 1 to the Summative:

```bash
git log --oneline --graph | head -60
```

Then answer the three questions in your own words, on camera:
1. **What was the single most important design decision across the project?** (candidates: pull requests with required checks, the private network with a bastion, deploying from `main` only, the database password living only in Secrets Manager)
2. **What is the weakest part of the pipeline today?** (candidates: HTTP only, the bastion is also the NAT and a single point of failure, one database zone, Terraform state is local, the deployment key is stored in GitHub)
3. **If this went live tomorrow, what would you fix first?** (be specific and give a reason)

Be honest. A clear view of the weaknesses scores better than a claim that everything is perfect. Say clearly what you did yourself and what the team lead did.

## After recording

- [ ] Upload to YouTube as **unlisted** (not private, not public).
- [ ] Title: `[Your Name] - Amani Market Systems - Summative Demo` (the format the course asks for).
- [ ] Open the link in a private window to make sure it plays without signing in.
- [ ] Upload at least 24 hours before the deadline, because YouTube needs time to process the video.
- [ ] Send the link to Bienvenu, who submits the repository URL, the live URL, the pull request URL and the video link on Canvas.
