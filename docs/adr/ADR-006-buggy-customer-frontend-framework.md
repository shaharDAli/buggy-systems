# ADR 006 — Use Flutter for the Buggy customer app

- **Status** — Accepted
- **Date** — 2026-11-21

## Context

Customers browse restaurants and menus, place orders, pay, and track order status from Buggy. The [C4 container diagram](../c4-diagrams/buggy-container.md) models Buggy as a Flutter app. [ADR 005](ADR-005-external-payment-sandbox.md) selects Razorpay Test Mode for validating checkout.

## Decision

Use **Flutter and Dart** for the initial Android and iOS customer app. Share the browsing, cart, checkout, and order tracking UI across both platforms. Use the Razorpay Flutter plugin for the checkout interaction. The app starts checkout through `bgy-payment-service` and reads order status from `bgy-order-service`. A checkout callback updates the UI while the app waits for the server-confirmed order state. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms) · [Razorpay Flutter integration](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/standard/)

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Flutter | One mobile UI codebase with a documented Razorpay integration. Checkout still needs device testing on both platforms. |
| React Native | A shared TypeScript UI and a Razorpay integration are available. Adopting it would change the frontend toolchain already shown in the architecture. |
| Native Android and iOS | Direct access to each platform's payment SDK and UI conventions. The team would maintain two implementations of the shopping and checkout flows. |

## Consequences and review triggers

Test successful, failed, and cancelled checkout on Android and iOS with Razorpay Test Mode. Verify that the app recovers after interruption and displays the backend's final order status without submitting a duplicate order. Revisit the framework choice if the checkout plugin cannot support a required platform or payment flow.
