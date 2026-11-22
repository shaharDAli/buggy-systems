# ADR 004 — Use PostgreSQL for all five backend services

- **Status** — Accepted
- **Date** — 2026-11-21

## Context

[ADR 002](ADR-002-backend-service-boundaries.md) assigns each backend service ownership of its data and migrations. The [C4 container diagram](../c4-diagrams/buggy-container.md) identifies PostgreSQL for Customer / Identity. The remaining services need durable storage for related records and transactional updates, including order state and payout requests, payment deduplication, and concurrent delivery claims.

## Decision

Use **PostgreSQL as the system of record for all five services** in the initial release. Give each service its own logical database, runtime credentials, and versioned migrations. Restrict database access to the owning service and its migration tooling. Services access each other's data through service contracts and store external identifiers as references. Foreign keys and transactions stay within the owning database.

| Service | Database | Workload and integrity requirements |
| --- | --- | --- |
| Customer / Identity (`bgy-account-service`) | `bgy-account-db` | Store identities, profiles, and saved addresses. Enforce unique sign-in identifiers and link saved addresses to their owners. |
| Restaurant Catalog (`bgy-rest-catalog-service`) | `bgy-menu-fb` | Store restaurants, staff memberships, menus, prices, hours, and availability. Enforce relationships between restaurants, staff memberships, and menu records. |
| Order Management (`bgy-order-service`) | `bgy-order-db` | Store orders, line items, checkout snapshots, and status. Commit the `Delivered` transition and its durable payout outbox entry in the same transaction. |
| Payments (`bgy-payment-service`) | `bgy-payment-db` | Store payment records, provider event IDs, and separate payouts for the restaurant and delivery partner. Use unique keys to deduplicate webhook events and payout requests. Reconcile ambiguous Razorpay outcomes before retrying a transfer. |
| Delivery & Logistics (`bgy-logistics-service`) | `bgy-delivery-db` | Store delivery jobs, partners, vehicles, availability, and tracking data. Claim an available job with an atomic conditional update so concurrent claims yield one winner. |

One PostgreSQL instance may host the five logical databases for local development. Production instance placement depends on availability, recovery, and capacity requirements. Databases on a shared instance share its failure and resource contention risks.

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| PostgreSQL per service | Local transactions and relational constraints cover the initial workloads. A common engine simplifies operations while each service retains its own schema and migration lifecycle. |
| One shared application database | Cross-domain joins and transactions are easier, but direct access across service boundaries couples schema changes and weakens ownership. |
| Different engines by workload | A document store could suit document-shaped catalog reads, and a specialized geospatial or time-series store could suit tracking. Each engine adds its own deployment, monitoring, and recovery procedures. The initial design has no measured workload that requires a second engine. |

## Consequences and review triggers

- Deploy and roll out migrations per service. Track connection usage, query latency, and storage growth. Test backup and restore against each service's recovery requirements.
- Cross-service workflows can be temporarily inconsistent. Deliver outbox messages with retries and make consumers idempotent so a repeated payout request has the same business outcome.
- Revisit Logistics storage if tracking writes or location queries miss latency or capacity targets after tuning. Revisit physical isolation if shared capacity or recovery tests show that one service can prevent another from meeting its objectives.

[PostgreSQL documentation on transactions](https://www.postgresql.org/docs/18/tutorial-transactions.html) · [PostgreSQL documentation on constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
