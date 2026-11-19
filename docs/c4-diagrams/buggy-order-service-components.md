# Buggy — Order Service Component Diagram

C4 Level 3 · `bgy-order-service`

**Purpose.** Show how the order service handles requests, applies order rules, saves order status, and communicates with payment and logistics.

```mermaid
flowchart LR
    buggy["Buggy<br/>Flutter app"]
    portal["Buggy Portal<br/>Flutter web and app"]

    subgraph orderService["bgy-order-service"]
        api["Order API<br/>Handles order requests and queries"]
        confirmation["Payment Confirmation Handler<br/>Handles confirmed customer payments"]
        progress["Delivery Progress Handler<br/>Handles delivery updates and completion"]
        manager["Order Manager<br/>Enforces order rules and owns status transitions"]
        repository["Order Repository<br/>Reads and writes orders"]
        logisticsClient["Logistics Client<br/>Requests pickup assignments"]
        paymentClient["Payment Client<br/>Requests payouts"]

        api -->|Requests creation, queries, and preparation updates| manager
        confirmation -->|Requests transition to Paid| manager
        progress -->|Requests delivery status updates| manager
        manager -->|Loads and saves orders| repository
        manager -->|Requests pickup when food is nearly ready| logisticsClient
        manager -->|Requests payouts after saving Delivered status| paymentClient
    end

    payment["bgy-payment-service<br/>Backend application"]
    logistics["bgy-logistics-service<br/>Backend application"]
    orderDb[("bgy-order-db<br/>Orders and order status")]

    buggy -->|"Places orders and retrieves order status · HTTPS"| api
    portal -->|"Retrieves paid orders and updates acceptance and preparation · HTTPS"| api
    payment -->|"Reports confirmed customer payment · HTTPS"| confirmation
    logistics -->|"Reports delivery progress and completion · HTTPS"| progress
    repository -->|Reads and writes orders and status| orderDb
    logisticsClient -->|"Requests pickup assignment · HTTPS"| logistics
    paymentClient -->|"Requests restaurant and delivery partner payouts · HTTPS"| payment

    classDef component fill:#1168bd,stroke:#0b4884,color:#fff
    classDef container fill:#595959,stroke:#383838,color:#fff
    classDef datastore fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
    class api,confirmation,progress,manager,repository,logisticsClient,paymentClient component
    class buggy,portal,payment,logistics container
    class orderDb datastore
```

## Flow checks

- **Place an order.** Buggy submits the order through the Order API. The Order Manager validates it and uses the Order Repository to save it in `bgy-order-db` with status Pending Payment.
- **Confirm payment.** The payment service reports a confirmed customer payment to the Payment Confirmation Handler. The Order Manager validates the transition and saves Paid through the repository. Buggy Portal can then retrieve the order through the Order API.
- **Assign pickup and complete delivery.** When the portal reports that food is nearly ready, the Order Manager requests a pickup through the Logistics Client. The logistics service reports progress and completion to the Delivery Progress Handler. The Order Manager saves Delivered through the repository, then requests both payouts through the Payment Client.

The Order Manager owns all order status transitions. Pending Payment is the assumed initial status. The Delivery Progress Handler covers both in-progress updates and final delivery to match the Level 2 logistics relationship.
