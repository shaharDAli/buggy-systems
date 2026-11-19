# ADR 001 — Use microservices for the Buggy backend

- **Status** — Accepted
- **Date** — 2026-11-19

## Context

Buggy connects customers, restaurant staff, and delivery partners through three frontends. An order moves from checkout and Razorpay payment confirmation through preparation, pickup, delivery, and payouts. The [current C4 container diagram](../c4-diagrams/buggy-container.md) sketches five backend services, each with its own data store. The design documentation provides domain boundaries and workflows. It does not establish production traffic, separate teams, or independent release and availability requirements for those domains.

The decision is how to deploy the backend initially while preserving data ownership and keeping the order lifecycle reliable.

## Options considered

| Option | Benefits | Costs |
| --- | --- | --- |
| Microservices for the five bounded contexts | Each service can be deployed and scaled independently. Separate processes and data stores can contain failures when dependencies are designed for partial outages. | Each workflow spans network and deployment boundaries. The team must operate service deployments, monitor cross-service requests, manage contract compatibility, and recover from partial failures across stores. |
| Modular monolith with five modules | A single backend deployment simplifies local development, releases, and tracing an order across domains. Internal calls avoid network failures between modules. Module-owned data and explicit interfaces provide a starting point for later extraction. | Modules share a release cycle and runtime resources. A backend outage can affect all workflows, and scaling the backend adds capacity for every module. Code and database boundaries require active enforcement. |

## Decision

Start with **microservices** for the Buggy backend, following the C4 container diagram. Deploy Customer / Identity, Restaurant Catalog, Order Management, Payments, and Delivery & Logistics independently. Each service owns its data store and migrations. Services exchange data through explicit contracts. Keep the three frontend applications and the Razorpay integration.

This gives Payments its own deployment boundary for Razorpay integration and lets Delivery & Logistics scale tracking independently of checkout. These are design benefits. Production demand and team structure are still unknown.

- Order Management owns order status. Restaurant Catalog owns menus and staff memberships. Customer / Identity owns sign-in and customer profiles. Payments owns Razorpay integration and payment and payout records. Delivery & Logistics owns assignment and delivery tracking.
- Payments verifies Razorpay webhooks and handles repeat deliveries idempotently. Order Management records the `Delivered` transition and a payout request in the same local transaction using a durable outbox. Payments processes the request idempotently, tracks each recipient’s payout separately, and reconciles ambiguous provider outcomes before retrying a transfer.

## Consequences and review triggers

The team operates five independent backend deployments and data stores. Workflows cross network boundaries, so the team must maintain compatible service contracts, trace requests across services, and recover from partial failures. Track webhook processing delays, payout backlog, and failed order transitions.

Revisit this decision if release coordination, cross-service recovery, or operational overhead consistently outweighs the benefits of independent deployment and scaling.
