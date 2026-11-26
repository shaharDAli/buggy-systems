# Open backend decisions

This list tracks the backend decisions to make before and during service development. The accepted ADRs already cover the architecture, service boundaries, databases, payment sandbox, and frontend frameworks. Work through the items in order. When an item is decided, record it in a new ADR under [`adr/`](adr), link the ADR in the item, and tick its checkbox.

**Status values** — Open · In discussion · Decided

## Summary

| # | Decision | Needed before | Status | ADR |
| --- | --- | --- | --- | --- |
| 1 | [Accept the backend language and framework](#1-accept-the-backend-language-and-framework) | Business endpoints | Open | [ADR 003](adr/ADR-003-backend-language-and-framework.md) |
| 2 | [Authentication and identity](#2-authentication-and-identity) | Business endpoints | In discussion | [ADR 010](adr/ADR-010-authentication-and-identity.md) (proposed) |
| 3 | [Communication between services](#3-communication-between-services) | Business endpoints | In discussion | — |
| 4 | [API conventions](#4-api-conventions) | Business endpoints | Open | — |
| 5 | [Shared code across services](#5-shared-code-across-services) | Business endpoints | Open | — |
| 6 | [Order state machine](#6-order-state-machine) | Order flow | Open | — |
| 7 | [Pricing, fees, and payouts](#7-pricing-fees-and-payouts) | Order flow | Open | — |
| 8 | [Real-time updates and tracking](#8-real-time-updates-and-tracking) | Order flow | Open | — |
| 9 | [Hosting and delivery pipeline](#9-hosting-and-delivery-pipeline) | First deployment | In discussion | [ADR 009](adr/ADR-009-ci-pipeline.md) (CI only) |
| 10 | [App entry point and CORS](#10-app-entry-point-and-cors) | First deployment | In discussion | — |
| 11 | [Observability backend](#11-observability-backend) | First deployment | Open | — |
| 12 | [Testing strategy](#12-testing-strategy) | First deployment | Open | — |
| 13 | [Personal data and compliance](#13-personal-data-and-compliance) | First deployment | Open | — |
| 14 | [Catalog database name](#14-catalog-database-name) | Database provisioning | Decided | — |
| 15 | [Repository and pipeline hosting](#15-repository-and-pipeline-hosting) | First deployment | Open | — |
| 16 | [Release versioning and scope](#16-release-versioning-and-scope) | First deployment | In discussion | [ADR 011](adr/ADR-011-release-versioning.md) (versioning only) |
| 17 | [Caching](#17-caching) | Order flow | In discussion | — |

Items 2, 3, and 4 change code in all five services, so settle them first.

---

## Before business endpoints

### 1. Accept the backend language and framework

- [ ] Decided

[ADR 003](adr/ADR-003-backend-language-and-framework.md) is still marked **Proposed**, but all five services already use Java 21 and Spring Boot 4.1.2.

**To decide**
- Accept ADR 003 as written, or revise it.

**Notes**

---

### 2. Authentication and identity

- [ ] Decided

The [container diagram](c4-diagrams/buggy-container.md) says Customer / Identity issues tokens with a stable identity ID, and each service applies its own domain permissions. Every service's `SecurityConfiguration` currently denies all business requests, so this decision blocks every endpoint.

**To decide**
- ~~**Security framework**~~ — decided 2026-11-25 in [ADR 010](adr/ADR-010-authentication-and-identity.md): Spring Security in every service. All five services already include `spring-boot-starter-security`. Each service will validate tokens as an OAuth2 resource server and apply its own domain permissions.
- **Token issuer** — build it into `bgy-account-service` with Spring Authorization Server, or use a managed identity provider such as Keycloak, Microsoft Entra External ID, Auth0, or Firebase Auth.
- **Sign-in methods** — phone OTP, email and password, or social sign-in, and whether customers, restaurant staff, and delivery partners use the same method.
- **Token format and validation** — for example, a JWT that each service verifies against the issuer's JWKS endpoint. Decide the claims, token lifetime, and refresh flow.
- **Role and permission model** — how an identity links to a customer, a staff membership, and a delivery partner, and which service checks which permission.
- **Service-to-service authentication** — OAuth client credentials, mTLS, or network-level trust.

**Notes**

---

### 3. Communication between services

- [ ] Decided

The diagrams show synchronous HTTPS for every call between services. [ADR 001](adr/ADR-001-backend-architecture.md) and [ADR 004](adr/ADR-004-backend-databases.md) also require a durable outbox for payout requests, with retries and idempotent consumers. [Service communication and caching](service-communication-and-caching.md) proposes synchronous HTTP for the order service's checks against the catalog, and an outbox with an HTTP relay for the four state-change messages.

**To decide**
- **Outbox delivery** — an HTTP outbox relay that polls the outbox table and calls the target service, or a message broker such as Kafka, RabbitMQ, or Azure Service Bus.
- **Which interactions are synchronous and which are asynchronous** — for example, payment confirmation, pickup requests, delivery progress, and payout requests.
- **Retry and timeout policy** — attempts, backoff, and what happens when retries run out.
- **Idempotency** — the header or message field that carries the idempotency key, and how long receivers keep processed keys.

**Notes**

---

### 4. API conventions

- [ ] Decided

All five services and three frontends need to agree on these conventions.

**To decide**
- **Error format** — for example, RFC 9457 Problem Details.
- **Versioning** — URL prefix such as `/v1/...`, or headers. The services already publish `/openapi/v1.yaml`.
- **Pagination and filtering** — cursor or offset pagination, and parameter names.
- **ID format** — for example, UUIDv7.
- **Money** — for example, integer paise with an ISO 4217 currency code.
- **Timestamps** — for example, ISO 8601 in UTC.
- **OpenAPI workflow** — contract-first or code-first, and whether to generate the TypeScript and Dart clients from the OpenAPI documents.

**Notes**

---

### 5. Shared code across services

- [ ] Decided

Each service has an independent Maven build with its own copy of the security and tracing setup.

**To decide**
- A shared parent POM or BOM for dependency versions, or fully independent builds.
- A shared library for security, error handling, and tracing, or copies in each service.
- If shared, how the library is versioned and published.

**Notes**

---

## Before the order flow

### 6. Order state machine

- [ ] Decided

The [order service component diagram](c4-diagrams/buggy-order-service-components.md) names only `PendingPayment`, `Paid`, and `Delivered`.

**To decide**
- **The full set of states** — for example, Accepted, Rejected, Preparing, ReadyForPickup, PickedUp, and Cancelled.
- **Allowed transitions** and which actor or service may trigger each one.
- **Payment timeout** — how long an order stays in `PendingPayment`.
- **Cancellation and refunds** — who can cancel at each stage, and whether and how refunds go through Razorpay.
- **Edit cutoff** — the docs say edits stop when preparation starts. Confirm which edits are allowed before that.

**Notes**

---

### 7. Pricing, fees, and payouts

- [ ] Decided

[ADR 005](adr/ADR-005-external-payment-sandbox.md) requires separate payouts to the restaurant and the delivery partner after delivery.

**To decide**
- How the order total is calculated: item prices, delivery fee, GST, and any platform fee.
- How the total is split into the restaurant payout, the delivery partner payout, and the platform commission.
- **Job assignment** — partner claims, automatic matching, or both. The 3 km eligibility rule is already in the [container diagram](c4-diagrams/buggy-container.md).
- How ETA is calculated.

**Notes**

---

### 8. Real-time updates and tracking

- [ ] Decided

Customers track orders, staff watch an order queue, and delivery partners report progress and location.

**To decide**
- **Update channel for the apps** — polling, WebSockets or server-sent events, or push notifications through FCM and APNs.
- **Location reporting** — how often partners send their location, and whether background location is needed. [ADR 008](adr/ADR-008-buggy-delivery-partner-frontend-framework.md) lists this as a validation item.
- **Location retention** — how long tracking data is kept.

**Notes**

---

### 17. Caching

- [ ] Decided

No service caches anything yet. [Service communication and caching](service-communication-and-caching.md) proposes HTTP caching on catalog reads, a short in-process cache for the order service's checks against the catalog, and no shared cache for the first release.

**To decide**
- Which data may be cached and for how long, and which data must never be cached.
- How long a removed staff member may keep access through a cached permission.
- Whether a shared cache, such as Amazon ElastiCache for Redis, is needed now.

**Notes**

---

## Before the first deployment

### 9. Hosting and delivery pipeline

- [ ] Decided

[ADR 005](adr/ADR-005-external-payment-sandbox.md) needs a public HTTPS staging endpoint for Razorpay webhooks. [AWS hosting](devops/aws-hosting.md) explains the proposed AWS setup.

**To decide**
- **Cloud and runtime** — AWS chosen (2026-11-25). Still to pick the container runtime: Amazon ECS on Fargate or Amazon EKS.
- ~~**Container images**~~ — decided 2026-11-25: one Dockerfile per service. Still to confirm Amazon ECR as the image registry.
- ~~**CI tool**~~ — decided in [ADR 009](adr/ADR-009-ci-pipeline.md): Jenkins with a multibranch pipeline and a declarative `Jenkinsfile`.
- **CD** — how Jenkins, or another tool, deploys the built images to each environment.
- ~~**Environments**~~ — decided 2026-11-25: local, dev, and staging.
- **Secrets management** — AWS chosen (2026-11-25). Still to pick AWS Secrets Manager or Systems Manager Parameter Store, covering database credentials, Razorpay test keys, and webhook secrets.
- **Database hosting** — AWS chosen (2026-11-25). Still to pick Amazon RDS for PostgreSQL or Aurora PostgreSQL, and whether the five logical databases share an instance in each environment.

**Notes**

---

### 10. App entry point and CORS

- [ ] Decided

[API gateway](devops/api-gateway.md) proposes a thin gateway: an Application Load Balancer with AWS WAF in AWS, and Caddy locally. Each service keeps validating tokens.

**To decide**
- Whether the three apps call five service URLs directly, or go through one API gateway or ingress.
- If there is a gateway, whether it validates tokens or only routes.
- CORS rules for Buggy Portal.

**Notes**

---

### 11. Observability backend

- [ ] Decided

OpenTelemetry tracing is wired up in every service, but there is no endpoint to send traces to.

**To decide**
- Where traces, metrics, and logs go, for example Azure Monitor / Application Insights, Grafana, or Jaeger.
- Log format, for example structured JSON, and how logs are correlated with traces.
- Alerts for the signals ADR 001 asks to track: webhook processing delay, payout backlog, and failed order transitions.

**Notes**

---

### 12. Testing strategy

- [ ] Decided

[ADR 005](adr/ADR-005-external-payment-sandbox.md) asks for local fixtures for deterministic payment failures and repeated events.

**To decide**
- Unit and integration test tools, for example JUnit and Testcontainers for PostgreSQL.
- Contract tests between services, for example Pact or Spring Cloud Contract.
- Razorpay fixtures and webhook replay for automated tests.
- Which checks the Jenkins pipeline ([ADR 009](adr/ADR-009-ci-pipeline.md)) must pass before a merge.

**Notes**

---

### 13. Personal data and compliance

- [ ] Decided

Buggy stores phone numbers, addresses, and delivery partner location history, which India's Digital Personal Data Protection Act covers.

**To decide**
- Retention periods for profiles, addresses, order history, and location data.
- Which fields to encrypt beyond database encryption at rest.
- How users request deletion of their data, and how that reaches every service.
- Backup frequency and restore targets for each database, as ADR 004 asks.

**Notes**

---

## Housekeeping

### 14. Catalog database name

- [x] Decided

The Restaurant Catalog database was written as `bgy-menu-fb`, a typo for `-db`. The other four databases end in `-db`.

**Decision** — Renamed to `bgy-menu-db` on 2026-11-25 in ADR 002, ADR 004, the container diagram, the entity graph, and the services README. The local stack added later still used the old name; `compose.yaml` and `infra/postgres/10-provision-databases.sql` were fixed on 2026-11-26. Recreate the local volume (`docker compose down -v`) to get the new name.

---

### 15. Repository and pipeline hosting

- [ ] Decided

The [branching strategy](branching-strategy.md) describes GitHub and GitHub branch protection. [ADR 009](adr/ADR-009-ci-pipeline.md) chooses Jenkins for CI, so merge blocking depends on Jenkins reporting build status to whichever host is chosen.

**To decide**
- Whether the repository and pipelines live on GitHub or Azure DevOps, and update the branching strategy to match.

**Notes**

---

## Releases

### 16. Release versioning and scope

- [ ] Decided

Versioning was decided on 2026-11-25. What each release contains still needs to be confirmed.

~~**Versioning**~~ — decided 2026-11-25 in [ADR 011](adr/ADR-011-release-versioning.md): one Semantic Versioning product version for all five services and three frontends, tagged on `main` as `v<version>`, with no release branches. All components now carry `0.1.0` (`0.1.0+1` in the Flutter apps). Images keep the commit ID tag and get the version as a second tag. Release notes go in `CHANGELOG.md`.

**To confirm — what each release contains**

The table below is a starting proposal that follows the [order flow](READ.md#follow-an-order-from-checkout-to-payout). Confirm, move, or remove each row, and record the agreed scope here.

| Release | Proposed scope | Depends on | Confirmed |
| --- | --- | --- | --- |
| 0.1.0 · Walking skeleton | All five services and three apps build in Jenkins and deploy to dev and staging. Users can sign in to each app. Health checks and traces work. | Items 2, 9, 10, 11 | [ ] |
| 0.2.0 · Browse and order | Staff manage restaurants and menus in Buggy Portal. Customers manage addresses, browse menus, and place an order, which is stored as `PendingPayment`. | Items 3, 4, 5, 6 | [ ] |
| 0.3.0 · Pay | Razorpay Test Mode checkout, webhook confirmation, and `Paid`. Staff see paid orders in their queue and accept or reject them. | Items 6, 7 | [ ] |
| 0.4.0 · Deliver | Staff mark food nearly ready. Delivery partners claim pickups, report progress and location, and complete delivery. Customers track the order. | Items 7, 8 | [ ] |
| 0.5.0 · Pay out | Restaurant and delivery partner payouts through the outbox after delivery, with retries. Cancellations and refunds. | Items 3, 6, 7 | [ ] |
| 1.0.0 · Complete flow | The full flow runs on staging with alerts, data retention and deletion, and backups in place. | Items 11, 12, 13 | [ ] |

**Notes**
