---
# Internal Utility Service (Production-Ready Deployment)

## 📌 Overview

This project transforms a locally run Flask application into a **secure, automated, production-ready system** using DevOps best practices.

Originally, the application:
- Ran manually on a developer’s laptop
- Had hardcoded environment variables
- Had no CI/CD pipeline
- Had no HTTPS or security controls

This project solves those problems by introducing:
- Docker containerization (multi-stage build)
- CI/CD automation with GitHub Actions
- Secure secrets management
- Automated deployment to AWS EC2
- Nginx reverse proxy with HTTPS (Let’s Encrypt)
- Health checks and rollback strategy

The goal is to move from **manual deployment and insecure configuration** to a **fully automated, secure, and scalable architecture**.

---


## 🏗️ Architecture Diagram

![Architecture](screenshots/Architecture%20Diagram.png)

---


## ⚙️ Containerization Strategy

The application is containerized using a **multi-stage Docker build**.

### Why multi-stage?
- Reduces image size
- Improves security
- Removes unnecessary dependencies

### Dockerfile Structure
- Builder stage installs dependencies
- Final stage runs the application
- Runs as a non-root user
- Includes `HEALTHCHECK`
- Uses `.dockerignore` to reduce build context

---


## 🔁 CI/CD Pipeline (GitHub Actions)

The CI/CD pipeline automates testing, building, and deployment.

### Pipeline Steps:
1. Code is pushed to GitHub
2. GitHub Actions is triggered
3. Runs:
   - `flake8` (linting)
   - `pytest` (testing)
4. If tests pass:
   - Docker image is built
   - Image is pushed to Docker Hub
5. Deployment to EC2 is triggered automatically

### Evidence

- CI Pipeline Success  
  👉 [View Screenshot](screenshots/8-ci-success.png)

- CI Pipeline Failure (test failure simulation)  
  👉 [View Screenshot](screenshots/9-ci-failure.png)

---


## 📦 Docker Image Management

Images are stored in Docker Hub.

### Tagging Strategy:
- `latest` → most recent stable build
- `v1.0.0` → versioned release
- SHA commit-based tags

### Why this strategy?
- Easy rollback to previous versions
- Clear version tracking
- Supports production debugging

### Evidence

- Docker Hub Image Tags  
  👉 [View Screenshot](screenshots/10-dockerhub-tags.png)

---


## 🔐 Secrets Management

Secrets are handled securely using:

### GitHub Secrets (CI/CD)
- Docker credentials
- EC2 SSH key

### AWS Secrets Manager (Runtime)
- `SECRET_KEY`
- `APP_ENV`

### Secret Injection Strategy
Secrets are injected:
- During deployment (via GitHub Actions)
- Passed into the container as environment variables

### Why this approach?
- Separates CI secrets from runtime secrets
- Prevents exposure in code, logs, or images

### Evidence

👉 [GitHub Secrets](screenshots/13-github-secrets.png)  
👉 [AWS Secrets](screenshots/14a-aws-secrets.png)

---


## ☁️ Deployment (AWS EC2)

The application is deployed on an AWS EC2 instance.

### Setup includes:
- Docker installed
- Security groups configured
- Only required ports open (80, 443)

### Deployment is handled by:
```bash
deploy.sh

### Deployment Process
- Pull latest Docker image  
- Stop old container  
- Start new container  
- Perform health check  
- Rollback if failure occurs  

### Evidence
- Auto Deployment Trigger  
👉 [View Screenshot](screenshots/11a-github%20trigger%20for%20autodeployment.png)

- EC2 Container Updated  
👉 [View Screenshot](screenshots/11b-ec2-container-updated.png)

---


## 🌐 Nginx Reverse Proxy & HTTPS

Nginx is used as a reverse proxy.

### Responsibilities
- Routes traffic to the container  
- Handles HTTP → HTTPS redirection  
- Manages SSL  

### HTTPS Setup
- SSL certificates from Let’s Encrypt  
- Secure browser access enabled  

### Evidence
- HTTPS Working  
👉 [View Screenshot](screenshots/1-https.png)

- SSL Certificate Details  
👉 [View Screenshot](screenshots/2-ssl-certificate-details.png)

- HTTP → HTTPS Redirect  
👉 [View Screenshot](screenshots/4-http-to-https-redirect.png)

---


## ❤️ Health Checks & Monitoring

Health checks ensure the application is running correctly.

### Implemented using
- Docker `HEALTHCHECK`  
- `/health` endpoint  

### Behavior
- Healthy → continues running  
- Unhealthy → restart triggered  

### Evidence
👉 [View Screenshot](screenshots/6-health-%20check.png)

---


## 🔄 Deployment Strategy (Rolling Update)

A rolling update strategy is implemented.

### Process
1. Pull new image  
2. Stop old container  
3. Start new container  
4. Run health check  
5. Rollback if failure occurs  

### Benefits
- Minimal downtime  
- Safe deployments  

---


## 🔙 Rollback Strategy

If deployment fails:
- Previous version is restored  
- Container restarted using last stable image  

### Evidence
👉 [View Screenshot](screenshots/16-deployment-failure-rollback.png)

---


## 🐳 Docker Runtime Evidence

- Docker Container Running  
👉 [View Screenshot](screenshots/5-docker%20running.png)

- Container Restart Proof  
👉 [View Screenshot](screenshots/12-container-restart.png)

---


## 🔐 Security Configuration

- AWS Security Group Configuration  
👉 [View Screenshot](screenshots/15-security-group.png)

---


## ⚖️ Trade-offs Made

- **Single EC2 instance**
  - Chosen for simplicity and cost (free-tier)
  - Trade-off: single point of failure

- **Nginx on same instance**
  - Easier setup
  - Trade-off: not fully scalable

- **Rolling update instead of blue-green**
  - Simpler to implement
  - Trade-off: small risk during deployment

- **No advanced monitoring tools**
  - Reduced complexity
  - Trade-off: limited observability

- **Manual domain (DuckDNS)**
  - Free and easy to configure
  - Trade-off: less control than managed DNS

These trade-offs were made to balance **simplicity, cost, and functionality** while still achieving a production-like system.

---



## 🧠 Reflection Questions

### 1. Why did you structure the Dockerfile the way you did?

I structured the Dockerfile to separate the build environment from the runtime environment and to make the final container safer and smaller. The first stage is used to install dependencies and prepare the application, while the final stage contains only what is needed to run the app in production.

This structure improves maintainability because another engineer can quickly understand which part is responsible for building and which part is responsible for running the application. I also included a non-root user and a Docker `HEALTHCHECK` to align the image with production practices rather than development-only usage.

---

### 2. Why multi-stage?

Multi-stage builds were chosen mainly to reduce image size and improve security. In a single-stage build, build tools and extra files often remain in the final image even though they are not needed at runtime. That increases the attack surface and makes the image heavier.

With a multi-stage build, the final image contains only the runtime dependencies and the application code. This makes the image faster to pull, faster to deploy, and easier to manage in production. It also follows container best practices by keeping the production image as minimal as possible.

---

### 3. Why that tagging strategy?

I used a tagging strategy based on `latest` and a semantic version such as `v1.0.0`, with the intention of also supporting commit-based traceability. The `latest` tag is useful for normal deployments because it points to the newest approved build, while the version tag provides a stable reference for rollback and auditing.

This approach is helpful because it balances convenience and control. Operations can deploy `latest` for normal automated updates, but if something goes wrong, a known stable version such as `v1.0.0` can be redeployed immediately. That makes troubleshooting and recovery easier.

---

### 4. Why GitHub Secrets + AWS Secrets Manager split?

The split exists because the two systems solve different problems. GitHub Secrets is used for CI/CD secrets, such as Docker Hub credentials and the SSH key used by GitHub Actions during deployment. These are needed by the pipeline itself.

AWS Secrets Manager is used for runtime secrets, such as `SECRET_KEY` and `APP_ENV`, because those belong to the application environment rather than the build pipeline. This separation reduces risk and keeps secrets closer to where they are actually needed. It also avoids putting runtime application secrets directly into the source code, Docker image, or workflow file.

---

### 5. How does your deployment avoid downtime?

The deployment process reduces downtime by using a rolling-update style replacement process. The deployment script pulls the new image, stops the old container, starts the new one, and then verifies the application through a health check. If the new deployment is healthy, it stays in place. If it fails, the script rolls back to the previous stable image.

This approach avoids leaving the system in a broken state after an update. Although it is not a full enterprise blue-green deployment with a separate second environment, it still introduces safer update behavior and recovery logic compared to manual replacement.

---

### 6. How would you scale to multiple EC2 instances?

To scale this design, I would place multiple EC2 instances behind a load balancer such as an AWS Application Load Balancer. Each instance would run the same containerized application, and traffic would be distributed across them. This would improve availability, support higher traffic, and reduce the risk of a single instance failure taking down the service.

I would also externalize more components, such as logs, monitoring, and possibly shared configuration, so that all instances behave consistently. At that point, manual instance-based deployment becomes harder to manage, so I would consider moving to ECS or Kubernetes for orchestration.

---

### 7. What security risks still exist?

Some security risks still remain. The biggest is that this project uses a single EC2 instance, which creates a single point of failure. Another limitation is that the deployment relies on SSH-based automation, which works for the project but is not as strong as more advanced approaches such as AWS SSM or private deployment runners.

Monitoring and alerting are also limited. If the application becomes unhealthy repeatedly, the restart policy helps, but there is no full observability stack in place yet. Finally, because this is a student-friendly and cost-conscious implementation, some design choices were simplified for free-tier constraints rather than maximum enterprise security.

---

### 8. How would you evolve this into Kubernetes?

To evolve this into Kubernetes, I would package the application into a Deployment and run multiple replicas of the container for high availability. Nginx responsibilities could be replaced or supplemented by an Ingress controller, and secrets would be managed using Kubernetes Secrets or an external secrets integration with AWS.

Health checks would map naturally to Kubernetes liveness and readiness probes, and rolling updates would become easier and safer through native Deployment strategies. Over time, Kubernetes would make scaling, self-healing, and multi-instance management much easier, but it would also increase operational complexity. For this project, EC2 was a practical stepping stone before moving to full orchestration

---


## Screenshots

1. [HTTPS Working](screenshots/1-https.png)
2. [SSL Certificate Details](screenshots/2-ssl-certificate-details.png)
3. [Browser Secure (HTTPS Lock)](screenshots/3-ssl-browser-secure.png)
4. [HTTP to HTTPS Redirect](screenshots/4-http-to-https-redirect.png)
5. [Docker Container Running](screenshots/5-docker%20running.png)
6. [Health Check Passing](screenshots/6-health-%20check.png)
7. [Nginx Reverse Proxy Configuration](screenshots/7-nginx-config.png)
8. [CI/CD Pipeline Success](screenshots/8-ci-success.png)
9. [CI/CD Pipeline Failure Simulation](screenshots/9-ci-failure.png)
10. [Docker Hub Image Tags](screenshots/10-dockerhub-tags.png)
11. [GitHub Trigger for Auto Deployment](screenshots/11a-github%20trigger%20for%20autodeployment.png)
12. [EC2 Container Updated After Deployment](screenshots/11b-ec2-container-updated.png)
13. [Container Restart Proof](screenshots/12-container-restart.png)
14. [GitHub Secrets Configuration](screenshots/13-github-secrets.png)
15. [AWS Secrets Stored](screenshots/14a-aws-secrets.png)
16. [AWS Secrets Manager Console](screenshots/14b-aws-secret%20manager.png)
17. [AWS Security Group Configuration](screenshots/15-security-group.png)
18. [Deployment Failure and Rollback](screenshots/16-deployment-failure-rollback.png)
19. [Architecture Diagram](screenshots/Architecture%20Diagram.png)
