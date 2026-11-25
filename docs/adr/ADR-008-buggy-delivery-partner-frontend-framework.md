# ADR 008 — Use Flutter for Buggy Delivery Partner

- **Status** — Accepted
- **Date** — 2026-11-21

## Context

Delivery partners manage availability, claim pickups, and report delivery progress from a phone. The [C4 container diagram](../c4-diagrams/buggy-container.md) assigns delivery tracking and assignment to the Logistics service. The mobile app must handle location permissions and intermittent connectivity during a delivery.

## Decision

Use **Flutter and Dart** for the initial Android and iOS delivery partner app. Share the pickup, assignment, and delivery status UI across platforms. Use platform integrations for location and permissions, adding platform-specific code where a plugin cannot meet the delivery workflow. Treat a pickup claim as confirmed once the Logistics API accepts it. After reconnecting, refresh the assignment and retry only updates the API can process idempotently. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms) · [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Flutter | Shares delivery screens and UI logic. Location, permission, and lifecycle behavior still requires validation on each OS. |
| React Native | Shares a TypeScript UI. The app would still need to validate native location integrations and would introduce a separate frontend toolchain. |
| Native Android and iOS | Gives direct control over location and lifecycle behavior. The team would build and maintain the pickup and delivery UI twice. |

## Consequences and review triggers

Test competing pickup claims, denied permissions, and progress updates across connection loss and recovery on both platforms. If the tracking workflow requires background location, validate accuracy, battery use, and behavior while the screen is locked before committing to a plugin. Revisit the framework if the required tracking behavior cannot be maintained through Flutter's native integration.
