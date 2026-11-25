# Buggy DevOps

This folder explains how Buggy is built, deployed, and run. Architecture decisions still go in [`../adr/`](../adr), and decisions that are still open are tracked in [`../open-decisions.md`](../open-decisions.md). The pages here explain those decisions in plain language and record the setup details that follow from them.

| Page | What it covers |
| --- | --- |
| [AWS hosting](aws-hosting.md) | Where the services, databases, secrets, and Jenkins run on AWS, what each AWS service does, and how code moves from a push to a running service. |
| [API gateway](api-gateway.md) | The single entry point for the apps and Razorpay webhooks: routing, HTTPS, rate limiting, CORS, and how to build it in AWS and locally. |

## Related decisions

- [ADR 009](../adr/ADR-009-ci-pipeline.md) — Jenkins for continuous integration.
- [Open decision 9](../open-decisions.md#9-hosting-and-delivery-pipeline) — hosting and delivery pipeline.
- [Open decision 10](../open-decisions.md#10-app-entry-point-and-cors) — app entry point (API gateway) and CORS.
