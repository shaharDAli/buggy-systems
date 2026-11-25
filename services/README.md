# Buggy backend services

The five services follow [ADR 001](../docs/adr/ADR-001-backend-architecture.md) and [ADR 002](../docs/adr/ADR-002-backend-service-boundaries.md). The scaffold uses Java 21 and Spring Boot 4.1.2 based on the proposed stack in [ADR 003](../docs/adr/ADR-003-backend-language-and-framework.md). Each directory contains a standalone Maven build and can be packaged and deployed independently.

| Service | Local port | Data store | Owns |
| --- | --- | --- | --- |
| [Customer / Identity](bgy-account-service) | 8081 | `bgy-account-db` | Sign-in, identity IDs, customer profiles, and saved addresses |
| [Restaurant Catalog](bgy-rest-catalog-service) | 8082 | `bgy-menu-db` | Restaurants, staff memberships, menus, pricing, hours, and availability |
| [Order Management](bgy-order-service) | 8083 | `bgy-order-db` | Orders, line items, checkout address snapshots, and order status |
| [Payments](bgy-payment-service) | 8084 | `bgy-payment-db` | Razorpay integration, payment records, and recipient payouts |
| [Delivery & Logistics](bgy-logistics-service) | 8085 | `bgy-delivery-db` | Delivery jobs, partners, vehicles, assignment, and tracking |

## Run locally

With JDK 21 and Maven 3.9 installed, run these commands from the repository root. Substitute a service directory and port to run any other service. Set the `PORT` environment variable to override the listed port.

```sh
mvn -f services/bgy-order-service/pom.xml verify
java -jar services/bgy-order-service/target/bgy-order-service-0.1.0.jar
```

Each service exposes `GET /actuator/health`, `GET /actuator/health/liveness`, and `GET /actuator/health/readiness`. Readiness currently reports application availability. The versioned OpenAPI document at `/openapi/v1.yaml` describes those probes. Local development uses HTTP. Deploy behind an HTTPS ingress for external access. Spring Security allows GET requests to the probes and document and denies other requests.

```sh
curl http://localhost:8083/actuator/health/readiness
curl http://localhost:8083/openapi/v1.yaml
```

OpenTelemetry tracing is wired through Spring Boot. Set `MANAGEMENT_OPENTELEMETRY_TRACING_EXPORT_OTLP_ENDPOINT` to the deployment's OTLP HTTP trace endpoint to export spans.

## PostgreSQL migrations

Each service includes Flyway and the PostgreSQL JDBC driver. To run a service with its database, set `SPRING_PROFILES_ACTIVE=postgres` and supply `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD` for its provisioned database from the table above. For example, the Order service can use `jdbc:postgresql://localhost:5432/bgy-order-db`. The default startup mode runs without a database.

Flyway applies versioned SQL on startup from the owning service's `src/main/resources/db/migration` directory. Name the first schema migration `V1__initial_schema.sql`.

## Domain implementation

Business APIs, identity issuance and verification, storage clients, and initial domain schemas are future work. Define inter-service APIs in each service's OpenAPI document as those routes are implemented.

For the order-to-payout flow, Order Management owns the delivery transition and must commit it with the payout request in a local transaction through a durable outbox. Payments owns Razorpay webhook verification, idempotency, separate payout records per recipient, and reconciliation before retrying ambiguous transfers.
