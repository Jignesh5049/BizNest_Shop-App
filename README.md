<div align="center">

# BizNest Shop

> A modern customer storefront and backend platform for BizNest.

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=node.js" alt="Node.js" />
  <img src="https://img.shields.io/badge/Express-API-000000?style=for-the-badge&logo=express" alt="Express" />
  <img src="https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb" alt="MongoDB" />
  <img src="https://img.shields.io/badge/License-Internal%20Use-gold?style=for-the-badge" alt="License" />
</p>

<p>
  <a href="#overview">Overview</a> •
  <a href="#project-structure">Project Structure</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#setup">Setup</a> •
  <a href="#api-surface">API Surface</a> •
  <a href="#contributing">Contributing</a>
</p>

</div>

---

## Overview

BizNest Shop is the customer-facing storefront for the BizNest platform.
It is split into two production surfaces so each side can evolve cleanly
without coupling app changes to backend internals.

- `biznest_shop/` for the Flutter customer app
- `server/` for the Express and MongoDB backend

The design goal is simple:
keep the customer journey fast, predictable, and easy to extend while
preserving stable contracts between UI and API layers.

## Project Structure

```text
BizNest-Shop/
├── biznest_shop/        # Flutter customer app
├── server/              # Node.js + Express API
└── README.md            # Root project guide
```

### Customer App

- Storefront home
- Business discovery
- Product browsing
- Cart and checkout
- Orders and reorder flow
- Favorites
- Profile, addresses, and support tickets

### Backend

- Authentication and user sessions
- Business, product, order, and expense APIs
- Customer portal APIs
- Reviews and support tickets
- File uploads and analytics

## Tech Stack

- Frontend: Flutter, Dart, `flutter_bloc`, `go_router`, `dio`
- Shared UI: `biznest_shop/lib/core`
- Backend: Node.js, Express
- Database: MongoDB, Mongoose
- Auth: JWT plus optional Supabase session support
- Media: `cached_network_image`, `flutter_svg`, `image_picker`

## Architecture

### Presentation Layer

- Screens are grouped by user journey rather than by widget type.
- Shared styling lives in `biznest_shop/lib/core/theme`.
- Reusable shells and cards stay in shared customer widgets.

### State and Flow Control

- `flutter_bloc` and `equatable` drive deterministic state transitions.
- Screen-local state stays local unless it must survive routing.
- Async UI work should stay mounted-safe and avoid stale context usage.

### Navigation

- `go_router` manages auth gating, shell routes, and deep-linkable paths.
- Customer tabs and route state should stay aligned.
- Route definitions should remain explicit and predictable.

### Data Contracts

- API requests go through `ApiService`.
- Helpers in `biznest_shop/lib/core/utils` normalize images and dates.
- Backend response changes should be handled in mapping layers.

## API Surface

Base path: `/api`

- Auth: `/api/auth`
- Business: `/api/business`
- Products: `/api/products`
- Customers: `/api/customers`
- Orders: `/api/orders`
- Expenses: `/api/expenses`
- Analytics: `/api/analytics`
- Storefront: `/api/store`
- Reviews: `/api/reviews`
- Support: `/api/support`
- Uploads: `/api/uploads`

Health check:

- `GET /api/health`

Static uploads:

- `/uploads/*`

## Setup

### Prerequisites

- Flutter SDK matching the project constraints
- Dart SDK bundled with Flutter
- Node.js and npm
- MongoDB instance or Atlas connection string
- VS Code or Android Studio with Flutter tooling

### Environment Variables

Create `server/.env`:

```env
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/biznest
JWT_SECRET=change-me
SUPABASE_JWT_SECRET=change-me-too
```

The Flutter app expects these runtime values in
`biznest_shop/lib/main.dart`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Run the Backend

```bash
cd server
npm install
npm start
```

### Run the Customer App

```bash
cd biznest_shop
flutter pub get
flutter run
```

## Useful Scripts

- `start`: `node server.js`
- `dev`: `node server.js`
- `backfill:order-images`: `node scripts/backfillOrderItemImages.js`

## Quality Bar

Before merging a change:

1. Run `flutter analyze` in `biznest_shop/` for the touched slice.
2. Run `flutter test` for the app if behavior changed.
3. Run the server locally and confirm `/api/health` responds.
4. Verify any changed API contract in both the server and the client.
5. Check loading, empty, error, and success states in the affected screens.

## Senior Engineering Notes

- Keep changes feature-scoped unless the work belongs in a shared layer.
- Prefer small composable widgets and pure helper functions.
- Preserve response shapes and field names expected by the client.
- Avoid a second source of truth for formatting, routing, or API mapping.
- Treat analyzer warnings in touched files as part of the delivery.

## Troubleshooting

### Customer data does not load

- Make sure the backend is running before launching the app.
- Confirm the configured API base URL matches the environment.
- Validate auth tokens and backend response keys.

### MongoDB connection fails

- Check `MONGODB_URI` in `server/.env`.
- Confirm the database is reachable from the current machine.
- Review `server/config/db.js` for the exact startup failure path.

### Build or analyzer issues

- Re-run `flutter pub get` after dependency changes.
- Start with the specific package or feature folder you edited.
- Fix new warnings in the touched code before widening the scope.

## Contributing

When extending the repository:

- Keep app and server changes aligned when an API contract changes.
- Update this README if setup, scripts, or routes change.
- Preserve existing response shapes where possible.
- Avoid hardcoded secrets and environment-specific values.

## License

This project is part of the BizNest codebase and is intended for internal
and demonstration use.
