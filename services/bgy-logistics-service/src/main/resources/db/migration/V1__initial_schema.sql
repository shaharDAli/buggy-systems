CREATE TABLE delivery_partners (
    id uuid PRIMARY KEY,
    identity_id uuid NOT NULL UNIQUE,
    available boolean NOT NULL DEFAULT false,
    latitude double precision CHECK (latitude BETWEEN -90 AND 90),
    longitude double precision CHECK (longitude BETWEEN -180 AND 180),
    location_recorded_at timestamptz,
    CHECK (num_nonnulls(latitude, longitude, location_recorded_at) IN (0, 3))
);

CREATE TABLE vehicles (
    id uuid PRIMARY KEY,
    partner_id uuid NOT NULL REFERENCES delivery_partners (id),
    vehicle_type text NOT NULL,
    registration_number text
);

CREATE INDEX vehicles_partner_idx ON vehicles (partner_id);

CREATE TABLE delivery_jobs (
    id uuid PRIMARY KEY,
    order_id uuid NOT NULL,
    partner_id uuid REFERENCES delivery_partners (id),
    status text NOT NULL DEFAULT 'Available' CHECK (status IN (
        'Available', 'Assigned', 'OutForDelivery', 'Delivered', 'Cancelled'
    )),
    pickup_address jsonb NOT NULL CHECK (jsonb_typeof(pickup_address) = 'object'),
    pickup_latitude double precision NOT NULL CHECK (pickup_latitude BETWEEN -90 AND 90),
    pickup_longitude double precision NOT NULL CHECK (pickup_longitude BETWEEN -180 AND 180),
    dropoff_address jsonb NOT NULL CHECK (jsonb_typeof(dropoff_address) = 'object'),
    estimated_arrival_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT current_timestamp,
    CHECK (status NOT IN ('Assigned', 'OutForDelivery', 'Delivered') OR partner_id IS NOT NULL),
    CHECK (status <> 'Available' OR partner_id IS NULL)
);

CREATE UNIQUE INDEX delivery_jobs_non_cancelled_order_idx ON delivery_jobs (order_id)
    WHERE status <> 'Cancelled';
CREATE INDEX delivery_jobs_order_idx ON delivery_jobs (order_id);

CREATE TABLE delivery_location_samples (
    id uuid PRIMARY KEY,
    delivery_job_id uuid NOT NULL REFERENCES delivery_jobs (id),
    partner_id uuid NOT NULL REFERENCES delivery_partners (id),
    latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    recorded_at timestamptz NOT NULL
);

CREATE INDEX delivery_location_samples_job_time_idx ON delivery_location_samples (delivery_job_id, recorded_at);
