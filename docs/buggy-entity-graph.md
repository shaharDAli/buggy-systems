# Buggy DDD entity graph

Proposed domain model for the five backend services in [ADR 002](adr/ADR-002-backend-service-boundaries.md). The [C4 container diagram](c4-diagrams/buggy-container.md) shows how those services communicate. Each aggregate root controls changes to the objects it owns. A reference across aggregates uses an ID. References across services travel through service contracts and use IDs from the owning context, as defined in [ADR 004](adr/ADR-004-backend-databases.md).

## Cross-service references

Read each arrow as “stores this reference to.” A recipient reference identifies either a restaurant or a delivery partner, depending on the payout type.

```mermaid
flowchart TB
    Order["Order · Order Management"] -->|customerId| Customer["Customer · Customer / Identity"]
    Order -->|restaurantId| Restaurant["Restaurant · Restaurant Catalog"]
    DeliveryJob["DeliveryJob · Logistics"] -->|orderId| Order
    Payment["Payment · Payments"] -->|orderId| Order
    Payout["Payout · Payments"] -->|orderId| Order
    Payout -->|restaurantId for restaurant payout| Restaurant
    Payout -->|deliveryPartnerId for partner payout| Partner["DeliveryPartner · Logistics"]
```

| Additional reference | Meaning |
| --- | --- |
| `StaffMembership.identityId → Identity` | Catalog uses the shared sign-in identity to determine staff permissions for a restaurant. |
| `DeliveryPartner.identityId → Identity` | Logistics uses the shared sign-in identity to identify an authenticated partner. |
| `OrderItem.menuItemId → MenuItem` | The order keeps the original menu item ID for traceability and captures its name and unit price at checkout. |

## Customer / Identity

`bgy-account-service` · `bgy-account-db`

```mermaid
flowchart TB
    Customer["Customer · aggregate root"] -->|identityId| Identity["Identity · aggregate root"]
    Customer -->|owns one| Profile["CustomerProfile · value object"]
    Customer -->|owns zero or more| Address["SavedAddress · entity"]
    Profile -->|may contain| Contact["ContactNumber · value object"]
```

- `Identity` owns sign-in identity and has a stable `IdentityId` shared by customer, staff, and partner roles. A sign-in identifier must be unique.
- `Customer` owns profile and address changes. A `SavedAddressId` lets a customer edit or remove a particular saved address. The proposed model allows one customer record per identity.

## Restaurant Catalog

`bgy-rest-catalog-service` · `bgy-menu-fb`

```mermaid
flowchart TB
    Restaurant["Restaurant · aggregate root"] -->|owns zero or more| Membership["StaffMembership · entity"]
    Restaurant -->|contains| Hours["OperatingHours · value object"]
    Menu["Menu · aggregate root"] -->|restaurantId| Restaurant
    Menu -->|owns zero or more| Item["MenuItem · entity"]
    Menu -->|owns zero or more| Category["MenuCategory · entity"]
    Item -->|categoryId when categorized| Category
    Item -->|contains| Price["Money · value object"]
```

- `Restaurant` owns restaurant details, operating hours, and staff grants. A staff grant belongs to one restaurant and authorizes operations for that restaurant. The proposed model uses one membership per restaurant and identity, with permissions on the membership.
- `Menu` has its own lifecycle. Authorized staff can edit, schedule, and publish a menu independently of restaurant updates. A menu owns its items and categories, and a category assigned to an item must belong to that same menu. Restaurant opening hours and the published menu's item availability support order placement checks.

## Order Management

`bgy-order-service` · `bgy-order-db`

```mermaid
flowchart TB
    Order["Order · aggregate root"] -->|owns one or more| Item["OrderItem · entity"]
    Order -->|captures at checkout| Address["DeliveryAddress · value object"]
    Order -->|stores total| Total["Money · value object"]
    Item -->|captures name and unit price| Snapshot["MenuItemSnapshot · value object"]
```

- Placement starts an order in `PendingPayment` with at least one item. Every item has a positive quantity and belongs to the selected restaurant. The checkout address and item prices are captured so later account or catalog edits preserve order history.
- `Order` controls status changes. Payment confirmation advances `PendingPayment` to `Paid`. Staff and customers cannot make price-changing edits once payment is confirmed, including before preparation. Preparation closes the edit window for any other changes. Logistics progress precedes the `OutForDelivery → Delivered` transition.
- Save `Delivered` and its payout request outbox entry in the same local transaction. The outbox is a persistence mechanism, so the aggregate graph focuses on the business objects.

## Payments

`bgy-payment-service` · `bgy-payment-db`

```mermaid
flowchart TB
    Payment["Payment · aggregate root"] -->|owns zero or more| Attempt["PaymentAttempt · entity"]
    Attempt -->|owns provider checkout and result references| Checkout["ProviderCheckoutReference · value object"]
    Attempt -->|contains checkout amount| Amount["Money · value object"]
    Payout["Payout · aggregate root"] -->|contains recipient type and ID| Recipient["PayoutRecipient · value object"]
    Payout -->|owns transfer reference when available| Transfer["ProviderTransferReference · value object"]
    Payout -->|contains payout amount| Amount
```

- The model uses one `Payment` aggregate per order. Each checkout try gets its own `PaymentAttemptId`, amount, status, and provider references as they become available. Starting a new try creates an attempt. Repeating the same start request with the same idempotency key returns the existing attempt.
- `Payment` owns the overall payment status. Process verified webhooks against the matching attempt and deduplicate by provider event ID. A failed attempt leaves an unpaid order in `PendingPayment`. The first confirmed attempt marks the payment as paid and triggers confirmation to Order Management. A later failure leaves that success in place, and any additional confirmed charge goes to reconciliation.
- `Payout` owns the status of one recipient’s transfer independently. The same delivery payout request can be retried and must yield one restaurant payout and one delivery partner payout. Use `(orderId, recipientType)` as the proposed business key for that flow. Reconcile an ambiguous provider result before retrying a transfer.

## Delivery & Logistics

`bgy-logistics-service` · `bgy-delivery-db`

```mermaid
flowchart TB
    Job["DeliveryJob · aggregate root"] -->|assigned partnerId when claimed| Partner["DeliveryPartner · aggregate root"]
    Job -->|stores pickup and drop-off| Stop["DeliveryStop · value object"]
    Partner -->|owns vehicle records| Vehicle["Vehicle · entity"]
    Partner -->|stores latest position| Location["GeoPoint · value object"]
    Sample["DeliveryLocationSample · append-only aggregate root"] -->|deliveryJobId| Job
    Sample -->|recorded partnerId| Partner
    Sample -->|captures position| Location
```

- A job is created for pickup when food is nearly ready. Assignment uses the same eligibility rule for partner claims and automatic matches. The partner must be available and within 3 km of pickup. An atomic claim lets only one partner win a concurrent claim for that job.
- `DeliveryJob` owns assignment and delivery status. Logistics can create a replacement with a new `DeliveryJobId` after cancellation. An order can have multiple historical jobs and at most one active job. Keep the cancelled job and its tracking history under its original ID.
- `DeliveryPartner` owns availability and the latest position across jobs. Append a timestamped `DeliveryLocationSample` for the assigned partner under the specific job ID. Each sample can be stored independently of the job's state changes, so tracking updates do not grow the `DeliveryJob` aggregate. Logistics reports progress and completion to Order Management, which owns the order status.
- The proposed model gives vehicle records stable IDs under a partner. If vehicles are managed or reassigned independently, their aggregate boundary should follow that workflow.
