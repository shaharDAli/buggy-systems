CREATE TABLE restaurants (
    id uuid PRIMARY KEY,
    name text NOT NULL CHECK (btrim(name) <> ''),
    address text NOT NULL,
    time_zone text NOT NULL
);

CREATE TABLE restaurant_hours (
    restaurant_id uuid NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    iso_weekday smallint NOT NULL CHECK (iso_weekday BETWEEN 1 AND 7),
    opens_at time NOT NULL,
    closes_at time NOT NULL,
    PRIMARY KEY (restaurant_id, iso_weekday, opens_at),
    CHECK (opens_at <> closes_at)
);

CREATE TABLE staff_memberships (
    restaurant_id uuid NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    identity_id uuid NOT NULL,
    permissions text[] NOT NULL,
    PRIMARY KEY (restaurant_id, identity_id)
);

CREATE TABLE menus (
    id uuid PRIMARY KEY,
    restaurant_id uuid NOT NULL REFERENCES restaurants (id),
    name text NOT NULL,
    status text NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft', 'Scheduled', 'Published', 'Archived')),
    scheduled_for timestamptz,
    published_at timestamptz,
    CHECK (status <> 'Scheduled' OR scheduled_for IS NOT NULL),
    CHECK (status <> 'Published' OR published_at IS NOT NULL)
);

CREATE INDEX menus_restaurant_idx ON menus (restaurant_id);

CREATE TABLE menu_categories (
    id uuid PRIMARY KEY,
    menu_id uuid NOT NULL REFERENCES menus (id) ON DELETE CASCADE,
    name text NOT NULL,
    UNIQUE (menu_id, id)
);

CREATE TABLE menu_items (
    id uuid PRIMARY KEY,
    menu_id uuid NOT NULL REFERENCES menus (id) ON DELETE CASCADE,
    category_id uuid,
    name text NOT NULL,
    price_minor bigint NOT NULL CHECK (price_minor >= 0),
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    available boolean NOT NULL DEFAULT true,
    dietary_tags text[] NOT NULL DEFAULT '{}',
    FOREIGN KEY (menu_id, category_id) REFERENCES menu_categories (menu_id, id)
);

CREATE INDEX menu_items_menu_category_idx ON menu_items (menu_id, category_id);
