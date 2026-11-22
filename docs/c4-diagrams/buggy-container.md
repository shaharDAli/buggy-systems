# Buggy — Container Diagram

**Purpose.** Show which applications and data stores make up Buggy and how they work together. In C4, a container is an application or a data store.

```mermaid
flowchart LR
    customer(["Customer<br/>Person"])
    staff(["Restaurant Staff<br/>Person"])
    partner(["Delivery Partner<br/>Person"])

    subgraph buggySystem["Buggy"]
        subgraph frontends["Frontends"]
            buggy["Buggy<br/>Flutter app<br/>Browse restaurants, place orders,<br/>pay, and track order status"]
            portal["Buggy Portal<br/>React web app<br/>Register restaurants, manage menus,<br/>and update order preparation"]
            delivery["Buggy Delivery Partner<br/>Flutter app<br/>Claim pickups and<br/>update delivery status"]
        end

        subgraph services["Backend services"]
            accounts["bgy-account-service<br/>Customer / Identity<br/>Authenticates users and manages customer profiles"]
            catalog["bgy-rest-catalog-service<br/>Restaurant Catalog<br/>Manages onboarding, staff membership,<br/>menus, and availability"]
            orders["bgy-order-service<br/>Order Management<br/>Owns the order lifecycle"]
            payment["bgy-payment-service<br/>Backend application<br/>Processes customer payments<br/>and restaurant and partner payouts"]
            logistics["bgy-logistics-service<br/>Delivery & Logistics<br/>Manages partners, fleet, assignments,<br/>and delivery tracking"]
        end

        subgraph databases["Data stores"]
            accountDb[("bgy-account-db<br/>PostgreSQL<br/>Sign-in accounts, customer profiles,<br/>and saved addresses")]
            orderDb[("bgy-order-db<br/>Orders, items, status,<br/>and checkout address")]
            menuDb[("bgy-menu-fb<br/>Restaurants, menus, availability,<br/>and restaurant staff memberships")]
            deliveryDb[("bgy-delivery-db<br/>Delivery jobs, partner profiles,<br/>vehicles, availability, and location")]
            paymentDb[("bgy-payment-db<br/>Customer payments and payout records")]
        end
    end

    razorpay["Razorpay<br/>External software system<br/>Processes customer payments and payouts"]
    restaurantAccount["Restaurant payout account<br/>External destination"]
    partnerAccount["Delivery partner payout account<br/>External destination"]

    customer -->|Browses, orders, pays, and tracks orders| buggy
    staff -->|Registers restaurant and manages menus and orders| portal
    partner -->|Claims pickups and reports delivery progress| delivery

    buggy -->|Signs in and manages profile and saved addresses — HTTPS| accounts
    portal -->|Signs in — HTTPS| accounts
    delivery -->|Signs in — HTTPS| accounts

    buggy -->|Browses restaurants and menus — HTTPS| catalog
    buggy -->|Submits orders and retrieves order status — HTTPS| orders
    buggy -->|Starts checkout — HTTPS| payment

    portal -->|Onboards restaurants, manages staff access, and maintains menus — HTTPS| catalog
    portal -->|Retrieves paid orders and updates acceptance and preparation status — HTTPS| orders

    delivery -->|Manages partner profile and availability, claims pickups, and reports progress — HTTPS| logistics

    orders -->|Checks restaurant open status and staff permissions — HTTPS| catalog

    payment -->|Initiates customer payments and requests payouts — HTTPS API| razorpay
    razorpay -->|Reports payment and payout results — HTTPS webhooks| payment
    payment -->|Reports confirmed customer payment — HTTPS| orders

    orders -->|Requests pickup when food is nearly ready — HTTPS| logistics
    logistics -->|Reports delivery progress and completion — HTTPS| orders
    orders -->|Requests payouts after recording Delivered status — HTTPS| payment

    orders -->|Reads and writes orders, items, and checkout snapshots| orderDb
    catalog -->|Reads and writes restaurant, menu, and staff membership data| menuDb
    logistics -->|Reads and writes jobs, partner and vehicle records, and tracking data| deliveryDb
    payment -->|Reads and writes payment and payout records| paymentDb
    accounts -->|Reads and writes credentials, customer profiles, and saved addresses| accountDb

    razorpay -->|Pays restaurant| restaurantAccount
    razorpay -->|Pays delivery partner| partnerAccount

    classDef person fill:#6b21a8,stroke:#4c1d75,color:#fff
    classDef application fill:#1168bd,stroke:#0b4884,color:#fff
    classDef database fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
    classDef external fill:#595959,stroke:#383838,color:#fff

    class customer,staff,partner person
    class buggy,portal,delivery,accounts,catalog,orders,payment,logistics application
    class accountDb,orderDb,menuDb,deliveryDb,paymentDb database
    class razorpay,restaurantAccount,partnerAccount external
```

Follow `bgy-order-service` to see where order status is stored. It writes to `bgy-order-db` and receives payment and delivery updates from the services that own those workflows. The restaurant portal reads paid orders from the order service, and the delivery app reads available pickups from the logistics service.

## Bounded contexts and data ownership

Each context owns its model and writes to its own data store. This design maps each context to an existing backend service. Customer / Identity issues tokens with a stable identity ID. A customer, a restaurant staff membership, and a delivery partner each have their own domain identifier and can link to the same sign-in identity. Each service validates the identity and applies its own domain permissions.

| Context | System of record | Model and responsibilities |
| --- | --- | --- |
| Restaurant Catalog | `bgy-menu-fb` | Owns the `Restaurant` aggregate and models menus, items, categories, address, operating hours, prices, and dietary tags. Owns staff memberships linking a sign-in identity to a restaurant and its staff permissions. |
| Order Management | `bgy-order-db` | Owns the `Order` aggregate, its `OrderItem` entities, status, delivery address, and total. At placement, the service checks Catalog for restaurant open status. The order enforces the edit cutoff when preparation starts. |
| Delivery & Logistics | `bgy-delivery-db` | Owns the `DeliveryJob` aggregate, tracking, delivery status, and ETA. Models `DeliveryPartner` as a separate aggregate because availability, location, and vehicle data persist across jobs. The assignment operation verifies that the partner is available and within 3 km of the pickup before assigning the job. |
| Customer / Identity | `bgy-account-db` | Owns authentication for all three roles and the `Customer` aggregate with `CustomerProfile`, `SavedAddress`, and `ContactNumber`. |
| Payments | `bgy-payment-db` | Owns payment and payout records, provider references, and transaction status. Razorpay processes payments and payouts. |

At checkout, the app submits the selected address as part of the order. Order Management stores its own `DeliveryAddress` snapshot so later edits to a saved address leave the order history intact. Order Management resolves staff access through Catalog using the authenticated identity and the restaurant ID on the order. Logistics owns assignment for both a partner claim and an automatic match and checks eligibility at assignment time.

Next, open the [Order Service Component Diagram](buggy-order-service-components.md) to see how the order service handles those updates.
