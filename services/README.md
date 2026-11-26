# Buggy backend services

The five services follow [ADR 001](../docs/adr/ADR-001-backend-architecture.md) and [ADR 002](../docs/adr/ADR-002-backend-service-boundaries.md). The scaffold uses Java 21 and Spring Boot 4.1.2 based on the proposed stack in [ADR 003](../docs/adr/ADR-003-backend-language-and-framework.md). Each directory contains a standalone Maven build and can be packaged and deployed independently.

| Service | Local port | Database | Login | Local password variable |
| --- | --- | --- | --- | --- |
| [Customer / Identity](bgy-account-service) | 8081 | `bgy-account-db` | `bgy_account` | `BUGGY_ACCOUNT_DB_PASSWORD` |
| [Restaurant Catalog](bgy-rest-catalog-service) | 8082 | `bgy-menu-db` | `bgy_catalog` | `BUGGY_CATALOG_DB_PASSWORD` |
| [Order Management](bgy-order-service) | 8083 | `bgy-order-db` | `bgy_order` | `BUGGY_ORDER_DB_PASSWORD` |
| [Payments](bgy-payment-service) | 8084 | `bgy-payment-db` | `bgy_payment` | `BUGGY_PAYMENT_DB_PASSWORD` |
| [Delivery & Logistics](bgy-logistics-service) | 8085 | `bgy-delivery-db` | `bgy_logistics` | `BUGGY_LOGISTICS_DB_PASSWORD` |

## Run locally

### Docker Compose

From the repository root, copy `.env.example` to `.env` and fill in the six password variables. Then build and start the five backends and PostgreSQL.

```powershell
Copy-Item .env.example .env
# Fill in the passwords in .env before starting Compose.
docker compose up --build -d --wait
docker compose ps
```

Compose publishes the five backend ports above on `127.0.0.1`. The services wait for PostgreSQL, connect on the Compose network using their own logins, and apply their Flyway migrations at startup. `--wait` waits for all readiness checks to pass. Use `docker compose logs bgy-order-service` to inspect one service and `docker compose down` to stop the stack while keeping PostgreSQL data.

### Run a service directly

With JDK 21 and Maven 3.9 installed, run these commands from the repository root. Substitute a service directory and port to run any other service. Set the `PORT` environment variable to override the listed port.

```sh
mvn -f services/bgy-order-service/pom.xml verify
java -jar services/bgy-order-service/target/bgy-order-service-0.1.0.jar
```

Each service exposes `GET /actuator/health`, `GET /actuator/health/liveness`, and `GET /actuator/health/readiness`. The `postgres` profile adds the database check to readiness. The versioned OpenAPI document at `/openapi/v1.yaml` describes those probes. Local development uses HTTP. Deploy behind an HTTPS ingress for external access. Spring Security allows GET requests to the probes and document and denies other requests.

```sh
curl http://localhost:8083/actuator/health/readiness
curl http://localhost:8083/openapi/v1.yaml
```

OpenTelemetry tracing is wired through Spring Boot. Set `MANAGEMENT_OPENTELEMETRY_TRACING_EXPORT_OTLP_ENDPOINT` to the deployment's OTLP HTTP trace endpoint to export spans.

## Run PostgreSQL with Compose and services from your IDE

After setting up `.env` as above, start only PostgreSQL.

```powershell
docker compose up -d --wait postgres
```

Compose starts one PostgreSQL 16 instance on `127.0.0.1:5433`. A fresh volume gets five databases and five database-owner logins. Each login can connect to its own database. The named volume retains data between runs. Initialization runs only on a fresh volume, so changes to `.env` passwords for an existing volume require updating the PostgreSQL roles as well.

Start each service with the `postgres` profile. For example, in an Order service terminal, use the same order password you set in `.env`.

```powershell
$env:SPRING_PROFILES_ACTIVE = 'postgres'
$env:SPRING_DATASOURCE_URL = 'jdbc:postgresql://127.0.0.1:5433/bgy-order-db'
$env:SPRING_DATASOURCE_USERNAME = 'bgy_order'
$env:SPRING_DATASOURCE_PASSWORD = Read-Host 'Order database password' -MaskInput
mvn -f services/bgy-order-service/pom.xml verify
java -jar services/bgy-order-service/target/bgy-order-service-0.1.0-SNAPSHOT.jar
```

Start the other services in separate terminals with the database, login, password, and service directory from the table. Each service applies `V1__initial_schema.sql` from its own `src/main/resources/db/migration` directory at startup. Check the readiness URL on its local port and inspect `flyway_schema_history` for a successful version `1`. For example, verify the Order migration from another terminal.

```powershell
curl.exe --fail http://localhost:8083/actuator/health/readiness
docker compose exec postgres psql -h 127.0.0.1 -U bgy_order -W -d bgy-order-db -c 'SELECT version, success FROM flyway_schema_history;'
```

## Managed PostgreSQL on Amazon RDS

Provision each logical database and its service login on a reachable RDS for PostgreSQL instance. Give each login permission to connect and apply Flyway migrations in its own database. Restrict access to the other service databases. From a host with network access to RDS, run the same JAR and `postgres` profile with the RDS JDBC URL and that service's credentials. Use the [RDS CA bundle and hostname verification](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html).

```text
jdbc:postgresql://<rds-endpoint>:5432/bgy-order-db?sslmode=verify-full&sslrootcert=<path-to-rds-ca-bundle>
```

## Domain implementation

The initial schemas follow the [DDD entity graph](../docs/buggy-entity-graph.md). They enforce database-local integrity while storing cross-service references as IDs. Money uses integer minor units and a currency code. The application layer handles aggregate rules such as requiring order items at placement, restricting edits after payment, and checking partner eligibility at claim time. Business APIs, identity issuance and verification, and repository implementations are future work.

For the order-to-payout flow, Order Management owns the delivery transition and must commit it with the payout request in a local transaction through a durable outbox. Payments owns Razorpay webhook verification, idempotency, separate payout records per recipient, and reconciliation before retrying ambiguous transfers.
