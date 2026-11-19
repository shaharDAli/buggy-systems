# Buggy Food Delivery · C4 architecture

Buggy connects customers who order food, restaurant staff who prepare it, and delivery partners who pick it up and deliver it. Razorpay handles customer payments and payouts.

[ADR 001](adr/ADR-001-backend-architecture.md) chooses the microservices architecture shown in the C4 diagrams and records the tradeoffs against a modular monolith.

[ADR 002](adr/ADR-002-backend-service-boundaries.md) defines the five backend services and their ownership boundaries.

[ADR 003](adr/ADR-003-backend-language-and-framework.md) proposes Java and Spring Boot for the backend services.

## Read the diagrams in order

| Level | Diagram | What it helps you understand |
| --- | --- | --- |
| 1 · Context | [Buggy and its surroundings](c4-diagrams/buggy-system-context.md) | Who uses Buggy and how the system interacts with Razorpay. |
| 2 · Container | [Applications and data stores](c4-diagrams/buggy-container.md) | How the three frontends, backend services, and data stores communicate. |
| 3 · Component | [Inside the order service](c4-diagrams/buggy-order-service-components.md) | Where requests enter, which component applies order rules, and how orders are saved. |
| 4 · Code | [Inside the Order Manager](c4-diagrams/buggy-order-manager-code.md) | Which classes and methods load an order, validate delivery completion, and save the new status. |

Each level zooms in on part of the previous one. Start with **Buggy**, open **`bgy-order-service`**, then open **Order Manager**. Use a Markdown preview with Mermaid support to see the diagrams. Read each arrow from its source to its destination. At Levels 1–3, rounded boxes represent people, rectangles represent software, and cylinders represent data stores. At Level 4, boxes show classes, an interface, and an enumeration.

## Follow an order from checkout to payout

1. **Place the order.** The customer browses menus in the Buggy app and submits an order. The Order API passes it to the Order Manager, which stores it as `PendingPayment`.
2. **Confirm payment.** The app starts checkout through the payment service. Razorpay reports the payment result to that service by webhook. The payment service forwards the confirmed payment to the order service, which records `Paid`. Restaurant staff can now see the order in Buggy Portal and start preparing it.
3. **Arrange pickup.** Staff mark the food as nearly ready in Buggy Portal. The order service asks the logistics service to make the pickup available. The delivery partner claims it in the delivery app and reports progress there.
4. **Complete delivery.** The logistics service reports completion to the order service. The proposed Order Manager design loads the order, checks that it is `OutForDelivery`, and saves it as `Delivered`. After the save succeeds, the order service requests restaurant and delivery partner payouts through the payment service.

## Design assumptions

- The Order Manager controls order status. The order service stores that status in `bgy-order-db`, while the logistics service keeps its pickup and delivery records in `bgy-delivery-db`.
- The Code diagram shows a proposed object-oriented design. It assumes an earlier logistics update records `OutForDelivery` and focuses on the delivery status change. The Component diagram shows the subsequent payout request.
- The Container diagram uses the service-mediated payment and pickup flows from the later architecture discussion. The earlier [frontend sketch](c4-diagrams/buggy-frontends.md) records an earlier version of those handoffs.
