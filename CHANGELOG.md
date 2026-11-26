# Changelog

All notable changes to Buggy are recorded here, one section per release, following [ADR 011](docs/adr/ADR-011-release-versioning.md). All components share one version.

## [Unreleased] — 0.1.0 · Walking skeleton

All five services and three apps build in Jenkins and deploy to dev and staging. Scope is tracked in [open decision 16](docs/open-decisions.md#16-release-versioning-and-scope).

### Services

- Scaffolded the five Spring Boot services (Java 21) with health checks, OpenAPI documents, and Flyway migrations for PostgreSQL.
- Added Docker Compose with PostgreSQL 16, one database and login per service, and a shared Dockerfile.
- Fixed the catalog database name to `bgy-menu-db` in Compose and the provisioning script.

### Buggy Portal

- Scaffolded the React and TypeScript portal with Vite.

### Buggy customer app

- Scaffolded the Flutter app with a homepage.

### Buggy Delivery Partner app

- Scaffolded the Flutter app with a homepage.

### Build and delivery

- Documented AWS hosting, the API gateway, and the walking skeleton setup plan.
