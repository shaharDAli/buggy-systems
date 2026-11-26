CREATE TABLE orders (
    id uuid PRIMARY KEY,
    customer_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    status text NOT NULL DEFAULT 'PendingPayment' CHECK (status IN (
        'PendingPayment', 'Paid', 'Preparing', 'ReadyForPickup', 'OutForDelivery', 'Delivered', 'Cancelled'
    )),
    total_minor bigint NOT NULL CHECK (total_minor >= 0),
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    delivery_address jsonb NOT NULL CHECK (jsonb_typeof(delivery_address) = 'object'),
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE INDEX orders_customer_created_idx ON orders (customer_id, created_at DESC);
CREATE INDEX orders_restaurant_status_idx ON orders (restaurant_id, status);

CREATE TABLE order_items (
    id uuid PRIMARY KEY,
    order_id uuid NOT NULL REFERENCES orders (id),
    menu_item_id uuid NOT NULL,
    item_name text NOT NULL,
    unit_price_minor bigint NOT NULL CHECK (unit_price_minor >= 0),
    quantity integer NOT NULL CHECK (quantity > 0)
);

CREATE INDEX order_items_order_idx ON order_items (order_id);

CREATE TABLE payout_outbox (
    id uuid PRIMARY KEY,
    order_id uuid NOT NULL UNIQUE REFERENCES orders (id),
    payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    published_at timestamptz
);

CREATE INDEX payout_outbox_pending_idx ON payout_outbox (created_at, id) WHERE published_at IS NULL;
