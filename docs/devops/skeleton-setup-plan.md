# Walking skeleton setup plan

- **Status** — In progress
- **Last updated** — 2026-11-25
- **Release** — 0.1.0 · Walking skeleton ([open decision 16](../open-decisions.md#16-release-versioning-and-scope))

This is a step-by-step plan for setting up Buggy's build and hosting by hand, so each piece is understood before it is automated. It lists what to do and how to check it worked, not how to do it.

**Approach**

- Take **one service, `bgy-account-service`, through every phase first**. Add the other four only after it works end to end.
- Do everything locally and for free first. Move to AWS only when the local version works.
- Build AWS by hand in the console once to learn it, then rebuild it as code (phase 7), as [AWS hosting](aws-hosting.md#rules) asks.

---

## Phase 0 — Prepare the AWS account

Do this before creating anything that costs money.

- [ ] Create the AWS account.
- [ ] Turn on MFA for the root user.
- [ ] Create a separate admin user (IAM Identity Center or IAM), and stop using the root user.
- [ ] Create an **AWS Budget** alert, for example at $20 a month.
- [ ] Choose the region, for example `ap-south-1` (Mumbai), and record it in [AWS hosting](aws-hosting.md#still-to-decide).
- [ ] Install the AWS CLI and sign in with the admin user.
- [ ] Install Docker Desktop.

**Done when** — `aws sts get-caller-identity` shows the admin user, not root, and the budget alert is listed in **Billing → Budgets**.

---

## Phase 1 — Run everything locally

### 1.1 Database

- [x] Run PostgreSQL in a Docker container.
- [x] Create the five databases: `bgy-account-db`, `bgy-menu-db`, `bgy-order-db`, `bgy-payment-db`, `bgy-delivery-db`.
- [x] Create one database user per service, allowed to reach only its own database ([ADR 004](../adr/ADR-004-backend-databases.md)).

**Done when** — the account user can connect to `bgy-account-db` and is refused on `bgy-order-db`.

### 1.2 Account service on your machine

- [ ] Configure the account service to read its database URL, user, and password from environment variables.
- [ ] Run it against the local database.

**Done when** — `/actuator/health/readiness` returns `UP`.

### 1.3 Account service in a container

- [x] Write a Dockerfile for the account service.
- [x] Build the image and run it, passing the database settings as environment variables.

**Done when** — the container reaches the database and the readiness check returns `UP`.

### 1.4 All services together

- [x] Write Dockerfiles for the other four services.
- [x] Write a `docker-compose.yml` with PostgreSQL and all five services (`compose.yaml`, one shared `services/Dockerfile`).
- [ ] Optional: add Caddy as the local gateway ([API gateway](api-gateway.md)).

**Done when** — `docker compose up` starts everything and all five readiness checks return `UP`.

---

## Phase 2 — Jenkins locally

### 2.1 Run Jenkins

- [ ] Decide where the repository lives: GitHub or Azure DevOps ([open decision 15](../open-decisions.md#15-repository-and-pipeline-hosting)).
- [ ] Run Jenkins in a Docker container on your machine.
- [ ] Install the plugins needed for pipelines, Docker, and the chosen repository host.
- [ ] Add the repository credentials to the Jenkins credentials store.
- [ ] Create a multibranch pipeline pointing at the repository.

**Done when** — Jenkins discovers the branches in the repository.

### 2.2 Write the CI part of the `Jenkinsfile`

Build it up one step at a time, and run each step before adding the next.

- [ ] A pipeline with one stage that prints a message.
- [ ] A stage that builds and tests the account service in a Maven + Java 21 container.
- [ ] Publish JUnit test reports in a `post` block.
- [ ] Guard the stage with `when { changeset ... }`.
- [ ] Add stages for the other four services.
- [ ] Add the portal stage (Node 24).
- [ ] Add the two Flutter app stages (Android only for now; see [Not covered yet](#not-covered-yet)).
- [ ] Run the independent stages inside a `parallel` block.

**Done when**

- [ ] A change to one service builds only that service.
- [ ] A pull request with a failing test shows a failed build.
- [ ] Test reports appear on the build page.

---

## Phase 3 — AWS by hand, for dev

### 3.1 Network

- [ ] Create a VPC with public subnets in at least two availability zones.
- [ ] Create security groups: one for the load balancer (open to the internet on HTTPS), one for the services (open only to the load balancer), one for the database (open only to the services).

**Done when** — you can explain which security group allows which traffic, and why nothing but the load balancer is reachable from the internet.

### 3.2 ECR

- [ ] Create an ECR repository for the account service.
- [ ] Sign in to ECR from Docker, then tag and push the account image by hand.

**Done when** — the image appears in the ECR console with its tag.

### 3.3 RDS

- [ ] Create an RDS for PostgreSQL instance (`db.t4g.micro`) in the database security group.
- [ ] Connect with `psql` and create the five databases and users, as in phase 1.1.

**Done when** — the account user can connect to `bgy-account-db` and is refused on the others.

### 3.4 Secrets Manager

- [ ] Store the account service's database password in Secrets Manager.

**Done when** — the secret is listed, and its value is not in Git or in the image.

### 3.5 ECS on Fargate

- [ ] Create an ECS cluster.
- [ ] Create a task definition for the account service: the ECR image, the database settings, the password from Secrets Manager, and logs sent to CloudWatch.
- [ ] Create an ECS service that runs one copy of the task.

**Done when** — the task stays running and its CloudWatch logs show the service started and connected to the database.

### 3.6 Application Load Balancer

- [ ] Request an HTTPS certificate in AWS Certificate Manager.
- [ ] Create a target group that checks `/actuator/health/readiness`.
- [ ] Create the ALB with an HTTPS listener and a path rule sending `/v1/accounts/*` to the account service.
- [ ] Optional for the skeleton: attach AWS WAF with a rate-based rule.

**Done when** — calling the account service through the ALB address works, and the target shows as healthy.

### 3.7 IAM

- [ ] Write down every "access denied" error you hit, and which role and permission fixed it.

**Done when** — you can name each role in the setup (ECS task execution role, task role) and what it is allowed to do.

---

## Phase 4 — Jenkins on AWS, deploying to dev

### 4.1 Move Jenkins to EC2

- [ ] Launch an EC2 `t3.medium` with an attached EBS disk for Jenkins' data.
- [ ] Install Docker and Jenkins.
- [ ] Give the instance an IAM role that can push to ECR and update ECS services. Do not store AWS access keys in Jenkins.
- [ ] Recreate the multibranch pipeline and repository credentials.
- [ ] Set up the repository webhook so pushes trigger builds.

**Done when** — a push triggers a build on the EC2 Jenkins, and the phase 2 checks still pass.

### 4.2 Add the deploy stages

- [ ] On `main` only: build the Docker image and push it to ECR, tagged with the Git commit ID.
- [ ] On `main` only: update the ECS service in dev to the new image.

**Done when** — merging a small visible change into `main` reaches dev without any manual step, and ECS replaces the old task only after the new one is healthy.

---

## Phase 5 — The other four services

For each of catalog, order, payment, and logistics:

- [ ] ECR repository and image push.
- [ ] Database user and secret.
- [ ] Task definition and ECS service.
- [ ] Target group and ALB path rule.
- [ ] Jenkins build, push, and deploy stages.

**Done when** — all five services run in dev behind the ALB and deploy from Jenkins on merge.

---

## Phase 6 — Staging

- [ ] Create staging as a second copy of dev: its own RDS instance, secrets, ECS services, and ALB.
- [ ] Add a Jenkins stage that waits for manual approval, then deploys the same image already running in dev. Do not rebuild it.
- [ ] Add the stage that runs on `v*` tags and adds the version tag to existing images ([ADR 011](../adr/ADR-011-release-versioning.md)).

**Done when** — an approved build in Jenkins deploys to staging, and staging runs the exact image tested in dev.

---

## Phase 7 — Rebuild as code

- [ ] Choose Terraform or AWS CDK ([AWS hosting](aws-hosting.md#still-to-decide)).
- [ ] Tear down the hand-built dev environment (see phase 8).
- [ ] Rebuild dev from code, then staging.
- [ ] Record the agreed hosting setup in ADR 010 and mark [open decision 9](../open-decisions.md#9-hosting-and-delivery-pipeline) as decided.

**Done when** — one command creates an environment and one command removes it completely.

---

## Phase 8 — Tear down and check the bill

Do this whenever the environments are not needed. See [Stopping is not enough](aws-hosting.md#stopping-is-not-enough).

- [ ] Delete the ALBs and any NAT gateway.
- [ ] Release public IPv4 addresses.
- [ ] Delete the secrets.
- [ ] Delete or stop the RDS instances. A stopped instance restarts by itself after 7 days.
- [ ] Set ECS services to 0 tasks or delete them.
- [ ] Stop the Jenkins EC2 instance.
- [ ] The next day, check **Billing → Bills** and **Cost Explorer**.

**Done when** — the next day's costs show nothing unexpected still charging.

---

## Not covered yet

Release 0.1.0 also needs these. Each depends on a decision that is still open.

- [ ] **Portal hosting** — [AWS hosting](aws-hosting.md) covers only the five services. Decide where the built portal is served from, for example S3 with CloudFront.
- [ ] **Sign-in** — users must be able to sign in to each app ([open decision 2](../open-decisions.md)).
- [ ] **Traces** — choose where traces go ([open decision 11](../open-decisions.md#11-observability-backend)). CloudWatch and AWS X-Ray are the natural choice on AWS.
- [ ] **iOS builds** — need a macOS agent. EC2 Mac instances must be rented for at least 24 hours at a time. Leave iOS out of the skeleton until a macOS agent is available.
- [ ] **Merge blocking** — confirm Jenkins reports build status to the repository host so failed builds block merges.
