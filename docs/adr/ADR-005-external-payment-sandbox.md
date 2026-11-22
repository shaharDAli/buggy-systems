# ADR 005 — Use Razorpay Test Mode for simulated payments

- **Status** — Accepted
- **Date** — 2026-11-21

## Context

Buggy needs an external payment provider for demos and end-to-end testing without moving money. The flow covers customer checkout, confirmation that advances an order to `Paid`, and separate restaurant and delivery partner payouts after delivery. The [system context diagram](../c4-diagrams/buggy-system-context.md) already identifies Razorpay, and [ADR 002](ADR-002-backend-service-boundaries.md) gives `bgy-payment-service` ownership of the integration.

## Decision

Use **Razorpay Payments Test Mode** for simulated customer checkout and **RazorpayX Test Mode** for simulated payouts. Razorpay's test checkout offers a mock payment experience with successful and failed transactions. Verify that Buggy's test account has RazorpayX payout access before scheduling payout demos. [Razorpay test checkout](https://razorpay.com/docs/server-integration/python/test-app/) · [RazorpayX payout test mode](https://razorpay.com/blog/business-banking/razorpayx-payouts-experience/)

- Buggy starts checkout through `bgy-payment-service`. The service creates the provider order, verifies signed webhook deliveries, and reports a confirmed payment to Order Management. Deduplicate provider events and handle out-of-order delivery. [Razorpay webhook validation and testing](https://razorpay.com/docs/webhooks/validate-test/)
- After the order service commits `Delivered` with its payout outbox entry, `bgy-payment-service` submits two simulated payouts using test recipients. Track each recipient separately and reconcile ambiguous provider outcomes before retrying. [ADR 004](ADR-004-backend-databases.md)
- Use test-only credentials, webhook secrets, and synthetic payment and recipient data. Receive provider callbacks at a public HTTPS staging endpoint. Use local fixtures for automated tests that require deterministic failures or repeated events.

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Razorpay Test Mode | Exercises the checkout and webhook contracts already named in the architecture. End-to-end payout testing depends on RazorpayX test access. |
| Stripe sandbox | Provides simulated customer payments. Adopting it for demos would add a separate provider integration and exercise different API and webhook contracts. [Stripe testing documentation](https://docs.stripe.com/testing) |
| Self-hosted payment simulator | Makes failure cases repeatable and works offline. Buggy would own the mock checkout UI and webhook behavior, and would still need a provider sandbox to verify the real integration. |

## Validation and review triggers

Before using the sandbox for demos, verify that successful checkout advances the order to `Paid`, failed checkout leaves it `PendingPayment`, and duplicate webhook deliveries cause a single state transition. Complete a delivery and confirm that the restaurant and courier each get one simulated payout record, including when Buggy retries the payout request. Use fixtures to verify reconciliation after a timeout if the sandbox cannot reproduce that outcome on demand.

Revisit the decision if RazorpayX Test Mode is unavailable to the project or if the sandbox cannot exercise a required end-to-end flow. Evaluate live payment readiness separately.
