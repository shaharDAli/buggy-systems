\set ON_ERROR_STOP on
\getenv account_password BUGGY_ACCOUNT_DB_PASSWORD
\getenv catalog_password BUGGY_CATALOG_DB_PASSWORD
\getenv order_password BUGGY_ORDER_DB_PASSWORD
\getenv payment_password BUGGY_PAYMENT_DB_PASSWORD
\getenv logistics_password BUGGY_LOGISTICS_DB_PASSWORD

BEGIN;
CREATE ROLE bgy_account LOGIN PASSWORD :'account_password';
CREATE ROLE bgy_catalog LOGIN PASSWORD :'catalog_password';
CREATE ROLE bgy_order LOGIN PASSWORD :'order_password';
CREATE ROLE bgy_payment LOGIN PASSWORD :'payment_password';
CREATE ROLE bgy_logistics LOGIN PASSWORD :'logistics_password';
COMMIT;

CREATE DATABASE "bgy-account-db" OWNER bgy_account;
CREATE DATABASE "bgy-menu-fb" OWNER bgy_catalog;
CREATE DATABASE "bgy-order-db" OWNER bgy_order;
CREATE DATABASE "bgy-payment-db" OWNER bgy_payment;
CREATE DATABASE "bgy-delivery-db" OWNER bgy_logistics;

BEGIN;
REVOKE CONNECT, TEMPORARY ON DATABASE "bgy-account-db", "bgy-menu-fb", "bgy-order-db",
    "bgy-payment-db", "bgy-delivery-db", postgres, template1 FROM PUBLIC;
COMMIT;
