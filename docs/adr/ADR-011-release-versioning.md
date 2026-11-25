# ADR 011 — Use one Semantic Versioning product version for all components

- **Status** — Accepted
- **Date** — 2026-11-25

## Context

Buggy has eight deployable components in one repository: five Spring Boot services ([ADR 002](ADR-002-backend-service-boundaries.md)), Buggy Portal in React ([ADR 007](ADR-007-buggy-portal-frontend-framework.md)), and the customer and delivery partner apps in Flutter ([ADR 006](ADR-006-buggy-customer-frontend-framework.md), [ADR 008](ADR-008-buggy-delivery-partner-frontend-framework.md)). Before this decision their versions did not match: the services were at `0.1.0-SNAPSHOT`, the Flutter apps at `0.1.0`, and the portal at `0.0.0`. [AWS hosting](../devops/aws-hosting.md) tags Docker images only with the Git commit ID, and the [branching strategy](../branching-strategy.md) uses GitHub Flow with no release branches.

The first releases deliver one end-to-end flow, from checkout to payout, that crosses every component. A release is only useful when all the components that take part in a step of that flow work together.

[ADR 003](ADR-003-backend-language-and-framework.md) says each service keeps an independent build and release. This ADR keeps independent builds and deployments, but gives all components one shared release version until the triggers below are met.

## Decision

Use **one product version, following Semantic Versioning 2.0.0 (`MAJOR.MINOR.PATCH`)**, for all five services and three frontends.

- **Meaning before 1.0.0** — while the version is `0.x`, a minor release (`0.2.0`) adds a step of the order flow or makes a breaking change. A patch release (`0.2.1`) only fixes defects. `1.0.0` is the first release where the complete flow runs on staging. After `1.0.0`, follow Semantic Versioning strictly.
- **Version in the build files** — every component carries the version of the next release, with no `-SNAPSHOT` or other suffix:
  - `<version>` in each service's `pom.xml`
  - `version` in `frontends/bgy-portal/package.json` and its `package-lock.json`
  - `version` in each `pubspec.yaml`, written as `<version>+<build number>`, for example `0.1.0+1`. The build number goes up by one with every release, including patch releases, because the app stores reject a build number they have already seen.
- **Releasing** — open a pull request named `chore/release-v<version>` that bumps all eight components to the next version and updates the release notes. After it merges, tag the merge commit on `main` with an annotated tag `v<version>`, for example `v0.2.0`. Do not use release branches.
- **Patch releases** — fix the defect on `main` through a normal pull request and release it as the next patch version. If `main` already contains unreleased work that must not ship, revisit release branches before releasing.
- **Release notes** — keep a `CHANGELOG.md` at the repository root, with one section per release listing the changes for each component.
- **Docker images** — keep the Git commit ID tag. When a `v<version>` tag is pushed, Jenkins adds the version as a second tag to the images already built for that commit, without rebuilding them. Staging deploys only images that carry a version tag.
- **API versions** — the API version in the URL (`/v1`, [item 4](../open-decisions.md#4-api-conventions)) is separate from the release version. A release changes the API version only when it makes a breaking change to a published API.

What each release contains is tracked in [open decision 16](../open-decisions.md#16-release-versioning-and-scope).

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| One product version (chosen) | One tag and one set of release notes describe what was tested together. Simple to explain and fits GitHub Flow. A component that did not change still gets a new version number. |
| Independent version for each component | Each service and app can release on its own schedule, which matches ADR 003. Needs a compatibility record of which versions work together, one tag format per component, such as `bgy-order-service/v0.2.0`, and more release work while the flow is still being built. |
| Calendar versioning, for example `2026.12.0` | Shows when a release was made. Says nothing about breaking changes, and mobile app stores and Maven tools expect Semantic Versioning. |

## Consequences and review triggers

Every release touches all eight build files, so the release pull request must bump them together. Jenkins needs a stage that runs on `v*` tags and adds the version tag to the images. The [AWS hosting](../devops/aws-hosting.md) page must be updated when that stage exists.

Revisit this decision if components start releasing on different schedules, if a team takes sole ownership of a service, or if releasing everything together delays urgent fixes.
