CREATE TABLE payments (
    id uuid PRIMARY KEY,
    order_id uuid NOT NULL UNIQUE,
    status text NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Paid')),
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE payment_attempts (
    id uuid PRIMARY KEY,
    payment_id uuid NOT NULL REFERENCES payments (id),
    idempotency_key text NOT NULL CHECK (btrim(idempotency_key) <> ''),
    status text NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Failed', 'Confirmed')),
    amount_minor bigint NOT NULL CHECK (amount_minor > 0),
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    provider_checkout_id text UNIQUE,
    provider_payment_id text UNIQUE,
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    UNIQUE (payment_id, idempotency_key)
);

CREATE TABLE payment_webhook_events (
    provider_event_id text PRIMARY KEY,
    received_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE payouts (
    id uuid PRIMARY KEY,
    order_id uuid NOT NULL,
    recipient_type text NOT NULL CHECK (recipient_type IN ('Restaurant', 'DeliveryPartner')),
    recipient_id uuid NOT NULL,
    amount_minor bigint NOT NULL CHECK (amount_minor > 0),
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    status text NOT NULL DEFAULT 'Pending' CHECK (status IN (
        'Pending', 'Processing', 'Paid', 'Failed', 'ReconciliationRequired'
    )),
    provider_transfer_id text UNIQUE,
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    UNIQUE (order_id, recipient_type)
);
