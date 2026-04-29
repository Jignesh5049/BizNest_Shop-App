# BizNest Customer App

> Flutter storefront for BizNest customers.

BizNest Customer App is the shopper-facing experience for the BizNest platform. It covers browsing, cart, checkout, order tracking, favorites, and account management. The app is designed to stay visually consistent, contract-safe, and easy to extend without leaking backend concerns into screens.

## Snapshot

| Area | Details |
| --- | --- |
| Platform | Flutter (Android, iOS, Web, Windows) |
| State | `flutter_bloc` + `equatable` |
| Navigation | `go_router` |
| Networking | `dio` via `ApiService` |
| Auth | JWT plus optional Supabase session support |
| Shared Layer | `lib/core` |

## What Lives Here

Primary modules under `lib/features/customer`:

- Storefront home
- Business discovery
- Product browsing and detail views
- Cart and checkout
- Orders and reorder flow
- Favorites
- Profile, addresses, and support tickets

## Visual and UX Direction

The app uses a clean, modern storefront layout rather than a generic dashboard shell.

- Shared theme tokens live in `lib/core/theme`.
- Reusable widgets and loading states live in `lib/core/widgets`.
- Customer shell behavior is centralized so tabs, route state, and gestures stay in sync.
- Loading, empty, error, and success states should be treated as first-class UI states, not afterthoughts.

## Architecture

### 1. Presentation Layer

- Screens are organized by journey, not by widget type.
- Shared styling is centralized so the app keeps one visual language.
- Long build methods should be broken into focused widgets before they become hard to maintain.

### 2. State and Flow Control

- `flutter_bloc` and `equatable` drive predictable state transitions.
- Screen-local state should remain local unless it must survive routing or coordinate with shell state.
- Async UI work should remain mounted-safe and avoid stale context usage.

### 3. Navigation

- `go_router` manages auth redirects and customer shell routes.
- Tab state and router state should stay aligned.
- Route definitions should remain explicit so deep links remain stable.

### 4. Data Contracts

- API requests go through `ApiService` instead of direct `dio` calls from screens.
- Helpers in `lib/core/utils` normalize images, dates, status labels, and common payload shapes.
- If a backend payload changes, fix the mapping layer first and keep widgets simple.

## Directory Guide

- `lib/features/customer/` customer storefront and post-purchase flows
- `lib/features/customer/widgets/` shell and reusable customer widgets
- `lib/features/auth/` login and signup screens
- `lib/core/navigation/` router setup and shell wiring
- `lib/core/services/` API and token services
- `lib/core/theme/` app colors and theme definitions
- `lib/core/utils/` shared helper functions
- `lib/core/widgets/` reusable loading and CTA components

## Local Setup

### Prerequisites

- Flutter SDK compatible with the project constraints
- Dart SDK bundled with Flutter
- VS Code or Android Studio with Flutter tooling
- Running backend API in `../server`

### Environment

The app expects these runtime values in `lib/main.dart`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Run

```bash
flutter pub get
flutter run
```

If you are working from the repository root, run:

```bash
cd biznest_shop
flutter pub get
flutter run
```

### Recommended Checks

```bash
flutter analyze
flutter test
```

For customer-only work, you can narrow analysis to the touched area:

```bash
flutter analyze lib/features/customer
```

## Senior Dev Workflow Notes

- Keep changes feature-scoped unless the work truly belongs in a shared layer.
- Preserve backend field names expected by the API models.
- Reuse existing services and helpers for request mapping and formatting.
- Prefer small composable widgets over large build methods.
- Verify all UI states: loading, empty, error, and success.

## Troubleshooting

### Customer data does not load

- Ensure `../server` is running.
- Verify the API base URL and auth token validity.
- Check payload keys and response mapping at API boundaries.

### Analyzer warnings in touched files

- Run scoped analysis first: `flutter analyze lib/features/customer`
- Fix new warnings introduced by your change before widening the scope.

### App launch fails after dependency changes

- Re-run `flutter pub get`.
- Check `pubspec.yaml` for dependency drift.
- Confirm that local imports still resolve after moving files.

## Quality Bar Before PR

1. Customer journey works end to end with the backend.
2. Analyzer results are clean for touched files.
3. Loading and error states are verified on device.
4. Mobile layout is sanity-checked on a narrow viewport.
5. No hardcoded secrets or environment keys are committed.

## License

This project is part of the BizNest codebase and is intended for internal and demonstration use.
