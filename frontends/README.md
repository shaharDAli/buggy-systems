# Buggy frontend projects

Each project installs and runs independently. The starter screens run without backend services or credentials.

| Project | Target | Architecture decision |
| --- | --- | --- |
| [Buggy](bgy-customer) | Flutter for Android and iOS | [ADR 006](../docs/adr/ADR-006-buggy-customer-frontend-framework.md) |
| [Buggy Portal](bgy-portal) | React and TypeScript for desktop and mobile browsers | [ADR 007](../docs/adr/ADR-007-buggy-portal-frontend-framework.md) |
| [Buggy Delivery Partner](bgy-delivery-partner) | Flutter for Android and iOS | [ADR 008](../docs/adr/ADR-008-buggy-delivery-partner-frontend-framework.md) |

## Mobile apps

Use Flutter 3.38.9 or newer with Dart 3.10.8 or newer. Android development requires the Android SDK and a compatible JDK such as JDK 17 or 21. iOS builds require macOS and Xcode. See the [Flutter platform setup guide](https://docs.flutter.dev/install).

From either mobile project directory, run these commands with an emulator, simulator, or device available.

```sh
flutter pub get
flutter analyze
flutter run
```

## Buggy Portal

Use Node.js 24 and npm. From `frontends/bgy-portal`, install the locked dependencies and start the Vite development server.

```sh
npm ci
npm run dev
```

Run `npm run lint` to check the source and `npm run build` to type-check and produce the static site in `dist/`.

## Integration scope

- Buggy will use the Catalog, Order, and Payment APIs and the Razorpay Flutter plugin for checkout.
- Buggy Portal will use the Catalog API for restaurant setup and menus and the Order API for preparation updates.
- Buggy Delivery Partner will use the Logistics API for pickup claims and delivery progress, with location permissions and reconnect handling.

These workflows and sign-in are pending. The [backend scaffold](../services/README.md) currently exposes health probes and OpenAPI documents.
