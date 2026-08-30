# Mini DevOps Pipeline

A complete, working CI/CD pipeline built to demonstrate end-to-end DevOps practices: a Flask web app is version-controlled, containerized, provisioned onto AWS via Terraform, automatically built/tested/deployed by Jenkins on every push, served through an Nginx reverse proxy, and also deployed to Kubernetes (Minikube) to demonstrate orchestration.

## Architecture
Developer
│ git push
▼
GitHub (SSH auth) ──webhook──▶ Jenkins (Docker container, local)
│
├─ Checkout
├─ Build Docker image
├─ Test (health check inside container)
├─ Push image ──▶ Docker Hub
├─ Deploy ──SSH──▶ AWS EC2 (Terraform-provisioned)
│ │
│ ├─ Docker container (Gunicorn)
│ └─ Nginx reverse proxy (port 80)
└─ Verify (curl the live endpoint)

Same image also deployed to:
Minikube (local) ──▶ Deployment (2 replicas) + Service (NodePort, load-balanced)
## Tech stack and what each piece demonstrates

| Component | Purpose | Concept demonstrated |
|---|---|---|
| Flask + Gunicorn | The application | Production WSGI serving (not the dev server) |
| Docker | Containerization | Layer caching, non-root user, healthchecks |
| Git/GitHub | Version control | SSH auth, commit discipline, webhook triggers |
| Terraform | Infrastructure as Code | Reproducible AWS provisioning (EC2, security groups) |
| AWS EC2 | Cloud hosting | Real cloud deployment target |
| Nginx | Reverse proxy | Standard-port (80) access, header forwarding |
| Jenkins | CI/CD orchestration | Pipeline as Code, credentials management, automated gates |
| Docker Hub | Image registry | Versioned, tagged image distribution |
| Kubernetes (Minikube) | Orchestration | Self-healing, load balancing, declarative deployment |
| Bash + cron | Ops scripting | Health monitoring, auto-recovery, backup rotation |

## Repository structure
app/ Flask application, Dockerfile, requirements.txt
terraform/ AWS infrastructure as code (EC2, security group, key pair)
nginx/ Reverse proxy config (documentation copy of what's live on EC2)
k8s/ Kubernetes Deployment and Service manifests
scripts/ Health-check/auto-recovery/backup Bash script (documentation copy)
Jenkinsfile The CI/CD pipeline definition (Pipeline as Code)

## How the pipeline works

1. A `git push` to `main` fires a GitHub webhook to Jenkins.
2. Jenkins checks out the latest code and builds a Docker image, tagged with the Jenkins build number (never overwriting a previous tag) and also `:latest`.
3. **Test stage**: the image is run as a temporary container and its `/health` endpoint is checked via `docker exec` (avoiding host-port conflicts). If this fails, the pipeline stops — nothing broken reaches later stages.
4. The image is pushed to Docker Hub.
5. Jenkins SSHes into the EC2 instance (provisioned by Terraform), pulls the new image, and replaces the running container.
6. **Verify stage**: the live public endpoint is curled to confirm the deploy actually succeeded, not just that the commands ran.

## Running it yourself

- `terraform/`: `terraform init && terraform plan -out=tfplan && terraform apply tfplan` provisions the EC2 instance.
- `app/`: `docker build -t mini-devops-app .` builds the image locally.
- `k8s/`: `kubectl apply -f deployment.yaml -f service.yaml` deploys to a running Minikube cluster.
- The Jenkins pipeline runs automatically on push once configured with the credentials described in the report (Docker Hub token, EC2 SSH key).

## Notable problems solved during development

- **Docker-outside-of-Docker networking gap**: Jenkins runs in a container and controls the host's Docker daemon via the mounted socket — but `localhost` means something different inside Jenkins' container vs. on the host. Fixed by testing containers via `docker exec` instead of published host ports.
- **Docker Hub case-sensitive authentication**: the account's display name (`AhadKhanx25`) failed login everywhere, while the lowercase form (`ahadkhanx25`) succeeded — isolated by testing Docker Hub's API directly with `curl`, independent of the Docker CLI.
- **Groovy string interpolation leaking secrets into shell commands**: fixed by switching to single-quoted shell blocks so secrets are resolved by the shell at runtime, not baked in by Groovy beforehand.
- **Test-stage port collisions across builds**: fixed with `try/finally` cleanup and dynamic ports, so a failed build's leftovers can never block the next one.

## Author

Ahad Khan — DecodeLabs Industrial Training Kit, Batch 2026
