# ADR 009 — Use Jenkins for continuous integration

- **Status** — Accepted
- **Date** — 2026-11-25

## Context

Buggy has five Spring Boot services (Java 21, Maven), the React and TypeScript portal (Node 24, Vite), and two Flutter apps for Android and iOS. Nothing builds or tests these automatically. The only check is a local pre-push hook that blocks direct pushes to `main`, following the [branching strategy](../branching-strategy.md). End-to-end tests are planned for all three frontends. Those tests need browsers for the portal, Android and iOS devices for the Flutter apps, and running backend services with PostgreSQL ([ADR 004](ADR-004-backend-databases.md)).

## Decision

Use **Jenkins** for continuous integration, with the pipeline defined as code in a declarative `Jenkinsfile` at the repository root.

- Use a **multibranch pipeline** so every feature branch and pull request gets a build. A pull request may merge into `main` only after its build passes.
- Run each stage in a container with pinned tool versions: Maven with Java 21 for the services, Node 24 for the portal, and the Flutter SDK version from the [frontend README](../../frontends/README.md) for the mobile apps.
- Build only the parts a commit changes. Each service and each frontend gets its own stage, guarded by a `when { changeset ... }` condition. Pushes to `main` build everything.
- Run portal browser tests and Android tests on Linux agents. iOS builds and tests need a macOS agent.
- Keep secrets, such as Razorpay Test Mode keys ([ADR 005](ADR-005-external-payment-sandbox.md)) and database passwords, in the Jenkins credentials store. Never commit them to the repository.
- Publish test reports (JUnit XML) and failure artifacts, such as screenshots and traces, with each build.

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Jenkins | Self-hosted and free, with full control over agents, including macOS and KVM-capable Linux machines for emulators, and a large plugin ecosystem. Buggy must run, upgrade, back up and secure the controller and its agents. |
| Azure Pipelines | Hosted Linux, Windows and macOS agents, and close integration with Azure Boards. YAML in the repo. Hosted parallel jobs and macOS minutes have limits and cost. |
| GitHub Actions | Hosted runners, including macOS, defined in the repo next to the code. Fits GitHub Flow if the repo is hosted on GitHub. macOS minutes are billed at a higher rate. |

## Consequences and review triggers

Someone must own the Jenkins controller: plugin updates, security patches, backups of job configuration and credentials, and agent capacity. Keep all pipeline logic in the `Jenkinsfile` rather than in job settings made through the UI, so it is reviewed like code and can be rebuilt.

Before relying on the pipeline, verify that a pull request with a failing test is blocked from merging, that a change to one service builds only that service, and that the e2e stages publish reports and screenshots. Check that an Android emulator starts reliably on the Linux agent and that a macOS agent can sign and test the iOS builds.

Revisit this decision if maintaining the controller takes more effort than the team can give, if no macOS agent can be provided for iOS, or if build queues regularly delay pull requests.
