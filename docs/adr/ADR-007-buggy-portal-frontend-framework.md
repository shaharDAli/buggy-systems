# ADR 007 — Use React for Buggy Portal

- **Status** — Accepted
- **Date** — 2026-11-22

## Context

Restaurant staff use Buggy Portal to onboard restaurants, manage menus and availability, and move paid orders through preparation. The [C4 container diagram](../c4-diagrams/buggy-container.md) calls for browser and mobile access to these signed-in workflows.

## Decision

Use **React and TypeScript** for Buggy Portal. Ship one responsive web app for desktop browsers and mobile browsers on Android and iOS. Use semantic HTML for forms and tables, and design the order queue and menu editor for keyboard, pointer, and touch input. Use the Catalog API for onboarding, menus, and availability, and the Order API for paid orders and preparation updates.

## Alternatives considered

| Option | Tradeoff |
| --- | --- |
| Flutter | One codebase for web and native mobile builds, with browser startup, accessibility, and input behavior to validate on staff devices. |
| Separate React web and native mobile apps | Each client can follow its platform's conventions. Staff workflows, testing, and releases would be maintained across multiple codebases. |

## Consequences and review triggers

Verify that staff can find and update an order using keyboard-only navigation, complete menu edits in Android and iOS browsers, and recover from a failed submission without losing input. Measure cold startup on representative browsers and hardware. Revisit mobile delivery if staff workflows require capabilities beyond those supported by their browsers.
