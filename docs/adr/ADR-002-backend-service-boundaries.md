# ADR 002 — Start with five backend services

- **Status** — Accepted
- **Date** — 2026-11-19

## Context

[ADR 001](ADR-001-backend-architecture.md) selects microservices for Buggy. The initial service count follows the five domains in the [C4 container diagram](../c4-diagrams/buggy-container.md). The three frontend applications and Razorpay are outside the backend service count.

## Decision

Deploy five backend services. Each service owns its data and migrations. Other services access that data through service contracts.

| Service | Owns | Why this boundary |
| --- | --- | --- |
| Customer / Identity (`bgy-account-service`) | Sign-in for all three apps, stable identity IDs, customer profiles, and saved addresses in `bgy-account-db`. | All three apps share a sign-in model. Catalog and Logistics own permissions and records specific to their domains. |
| Restaurant Catalog (`bgy-rest-catalog-service`) | Restaurant onboarding, staff memberships, menus, prices, hours, and availability in `bgy-menu-fb`. | Restaurant staff manage these records together. Order Management uses them when validating orders and staff access. |
| Order Management (`bgy-order-service`) | Orders, line items, checkout address snapshots, and order status in `bgy-order-db`. | A single service enforces order transitions from placement through delivery. |
| Payments (`bgy-payment-service`) | Razorpay integration, customer payments, and restaurant and delivery partner payouts in `bgy-payment-db`. | One service owns provider webhooks, transaction records, and reconciliation. |
| Delivery & Logistics (`bgy-logistics-service`) | Delivery jobs, partner profiles, vehicles, availability, assignment, and tracking in `bgy-delivery-db`. | Assignment depends on partner availability and location. Tracking can scale independently of order processing. |

Payments reports confirmed payments to Order Management. Order Management requests pickup when food is nearly ready, and Logistics reports delivery progress and completion. After Order Management records delivery, it requests payouts through Payments.

## Alternatives and consequences

Combining Orders and Payments would remove a network hop during payment confirmation and payout requests, while coupling order releases to Razorpay integration and reconciliation. Splitting payouts from customer payments or tracking from dispatch would add deployments and contracts. Group those responsibilities within their current domains for the initial release.

Five deployments require cross-service tracing, compatible contracts, and retries that preserve business state. Revisit the boundaries if measured load, release coordination, or failure recovery shows that a split or consolidation would improve operations.
