# ADR 003 — Use Java and Spring Boot for backend services

- **Status** — Proposed
- **Date** — 2026-11-19

## Context

[ADR 001](ADR-001-backend-architecture.md) selects microservices, and [ADR 002](ADR-002-backend-service-boundaries.md) defines five services. Those services expose HTTPS APIs and handle persistent state, authentication, and cross-service workflows. Payments also processes Razorpay webhooks, and Order Management needs a local transaction for writing the delivery transition and its payout request.

## Options considered

| Language and framework | Benefits | Costs |
| --- | --- | --- |
| Java 21 and Spring Boot | Spring provides HTTP APIs, security, validation, transaction management for compatible data stores, and health and metrics endpoints. Java provides static typing for domain models and service contracts. | Each JVM process adds startup and memory costs. Spring configuration and dependency upgrades need ownership. |
| TypeScript and NestJS | A common JavaScript runtime and NestJS modules provide a consistent structure for HTTP services. | Request types need runtime validation, and transaction behavior depends on the data client chosen for each service. |
| Go and the standard HTTP library | Compiled binaries simplify packaging, and the standard library covers HTTP and request cancellation. | The team would assemble conventions and libraries for authentication, validation, persistence, and observability. |

## Proposed decision

Use **Java 21 and Spring Boot** for Customer / Identity, Restaurant Catalog, Order Management, Payments, and Delivery & Logistics. At implementation time, choose a supported Spring Boot release that supports Java 21 and pin the version in each service build.

Spring Boot gives all five services a common approach to HTTP APIs, security, validation, and observability. For Order Management, use transaction support appropriate to its data store so the delivery transition and outbox entry commit together. Use each service's own storage client where appropriate. Document service interfaces with OpenAPI so frontend apps and other services can integrate through versioned contracts.

## Consequences and review triggers

Standardize the Java toolchain, health checks, and request tracing across the services. Each service retains an independent build and release. Measure startup time, memory per replica, and request latency during initial testing. Revisit this choice if those measurements miss deployment requirements or if the team cannot support the stack operationally.
