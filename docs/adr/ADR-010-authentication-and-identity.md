# ADR 010 — Use Spring Security with a Spring Authorization Server token issuer

- **Status** — Proposed
- **Date** — 2026-11-25

## Context

Buggy has five Spring Boot services ([ADR 002](ADR-002-backend-service-boundaries.md), [ADR 003](ADR-003-backend-language-and-framework.md)) and three apps: the Buggy customer app and the Buggy Delivery Partner app in Flutter, and Buggy Portal in React ([ADR 006](ADR-006-buggy-customer-frontend-framework.md), [ADR 007](ADR-007-buggy-portal-frontend-framework.md), [ADR 008](ADR-008-buggy-delivery-partner-frontend-framework.md)). Customers, restaurant staff, and delivery partners all sign in.

The [container diagram](../c4-diagrams/buggy-container.md) says Customer / Identity (`bgy-account-service`) authenticates all three roles and issues tokens with a stable identity ID. A customer, a staff membership, and a delivery partner each link to that identity. Each service validates the identity and applies its own domain permissions. The [API gateway](../devops/api-gateway.md) proposal also keeps token validation in each service, not in the gateway.

Every service already includes `spring-boot-starter-security`, and every `SecurityConfiguration` denies all requests except health checks and `/openapi/v1.yaml`. No business endpoint can be built until this is decided.

Two separate jobs are needed:

- **Issuing tokens** — one place checks the sign-in (OTP or password), stores credentials, signs tokens with a private key, publishes the public keys, and refreshes expired tokens.
- **Validating tokens** — every service checks the signature and expiry of each request's token, then decides what the caller may do.

Without one issuer, each service would need its own sign-in logic and its own credential store, users would sign in to each service separately, and the mobile apps could not share one session across services.

## Decision

### Security framework — decided

Use **Spring Security** in all five services. Each service runs as an **OAuth2 resource server** (`spring-boot-starter-oauth2-resource-server`): it validates JWT access tokens against the issuer's JWKS endpoint and applies its own domain permissions with Spring Security's request and method authorization.

### Token issuer — proposed

Build the issuer into **`bgy-account-service` with Spring Authorization Server**. It stays on the same stack as the services, costs no licence fees, and keeps identity data in `bgy-account-db` as [ADR 004](ADR-004-backend-databases.md) already plans.

### Sign-in flow — proposed

- All three apps use the **OAuth2 authorization code flow with PKCE** as public clients. The Flutter apps open the sign-in page in the system browser (for example with `flutter_appauth`). The portal uses the same flow from the browser.
- **Customers and delivery partners** sign in with a **phone number and a one-time password (OTP)**. Spring Authorization Server has no built-in OTP sign-in, so `bgy-account-service` adds a custom login page and authentication provider for it. The SMS provider is still to choose.
- **Restaurant staff** sign in to the portal with **email and password**, stored as bcrypt or Argon2 hashes.

### Tokens — proposed

- **Access token** — a JWT signed with RS256, valid for **15 minutes**. Claims: `iss`, `sub` (the stable identity ID), `aud`, `exp`, `iat`, `scope`, and `roles` (`customer`, `staff`, `partner`).
- **Refresh token** — opaque, rotated on each use, valid for **30 days** in the mobile apps and **12 hours** in the portal. Revoked on sign-out.
- **Signing keys** — rotated regularly. The JWKS endpoint publishes the current and previous public keys, so tokens signed just before a rotation stay valid.
- The private signing key lives in the secrets store chosen in item 9 of the [open decisions](../open-decisions.md), never in the repository.

### Permissions — proposed

The token says **who** the caller is and their broad role. It does not carry domain permissions. Each service checks those against its own data:

| Service | Checks |
| --- | --- |
| `bgy-account-service` | The caller's `sub` owns the customer profile and saved addresses. |
| `bgy-rest-catalog-service` | Staff membership and staff permissions for the restaurant. |
| `bgy-order-service` | The customer owns the order. For staff actions, asks Catalog whether the identity has access to the order's restaurant. |
| `bgy-logistics-service` | The `sub` links to a delivery partner, and the partner is assigned to or eligible for the job. |
| `bgy-payment-service` | The customer owns the payment. Razorpay webhooks are authenticated by signature, not by token ([ADR 005](ADR-005-external-payment-sandbox.md)). |

### Service-to-service calls — proposed

Services call each other with tokens from the same issuer, using the **OAuth2 client credentials flow**. Each service is a registered client with only the scopes it needs, for example `catalog.staff-access:read` for Order Management. When a call acts for a user, the calling service passes the user's identity ID in the request so the receiver can log and check it.

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Spring Authorization Server in `bgy-account-service` | Same stack as the services, full control over claims and sign-in, no licence cost. Buggy builds and maintains the OTP sign-in, key rotation, and security patches itself. |
| Keycloak (self-hosted) | Mature open-source identity server with an admin console, user federation, and many sign-in options. Another server to run, upgrade, and back up, and phone OTP needs an extension. |
| Auth0 or Microsoft Entra External ID | Managed service with ready-made sign-in pages, MFA, and passwordless options. Monthly cost grows with active users, and identity data lives outside Buggy's database. |
| Firebase Auth | The quickest way to add phone OTP to Flutter apps, with a free tier. Tokens follow Google's format, and custom claims and portal staff management are more limited. |
| Session cookies in each service, no shared issuer | Simplest for one web app. Does not work across five services and two mobile apps without duplicating sign-in logic. |

## Consequences and review triggers

`bgy-account-service` becomes the most security-critical service. A fault in it stops sign-in across all three apps, so it needs its own availability target and alerts. The OTP sign-in needs rate limits per phone number and per IP address, OTP expiry, and attempt limits.

Each service adds the resource server dependency, sets `spring.security.oauth2.resourceserver.jwt.issuer-uri`, and replaces `denyAll()` with real rules. Item 5 of the [open decisions](../open-decisions.md) decides whether this setup is copied into each service or comes from a shared library.

Before accepting this ADR, confirm the issuer choice, pick the SMS provider, and verify that the Flutter apps can complete the authorization code flow on Android and iOS.

Revisit this decision if building and maintaining the OTP sign-in takes more effort than the team can give, if Buggy needs social sign-in or MFA that would be faster to adopt from a managed provider, or if a security review finds the in-house issuer too risky.
