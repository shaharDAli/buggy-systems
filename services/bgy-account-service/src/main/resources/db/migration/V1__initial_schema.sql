CREATE TABLE identities (
    id uuid PRIMARY KEY,
    sign_in_identifier text NOT NULL UNIQUE CHECK (btrim(sign_in_identifier) <> ''),
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE customers (
    id uuid PRIMARY KEY,
    identity_id uuid NOT NULL UNIQUE REFERENCES identities (id),
    display_name text NOT NULL CHECK (btrim(display_name) <> ''),
    contact_number text,
    created_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE saved_addresses (
    id uuid PRIMARY KEY,
    customer_id uuid NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
    address_line_1 text NOT NULL,
    address_line_2 text,
    locality text NOT NULL,
    region text,
    postal_code text NOT NULL,
    country_code text NOT NULL CHECK (country_code ~ '^[A-Z]{2}$')
);

CREATE INDEX saved_addresses_customer_idx ON saved_addresses (customer_id);
