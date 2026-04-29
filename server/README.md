# BizNest Server

BizNest Server is the backend for the BizNest customer storefront and business workflows. It is a Node.js and Express API backed by MongoDB, designed to support authentication, catalog browsing, cart and checkout flows, order management, reviews, support tickets, analytics, and media uploads.

The service is intentionally lightweight at the edge and opinionated in the domain layer: clean REST routes, centralized auth, predictable error handling, and a small set of utility scripts for data maintenance.

## What It Does

- Authenticates users with JWT-based sessions.
- Serves customer-facing store APIs for browsing businesses, products, favorites, addresses, checkout, and order history.
- Supports business-side CRUD for products, customers, expenses, orders, and analytics.
- Handles file uploads and exposes uploaded assets from `/uploads`.
- Provides a health endpoint for deployment and monitoring.

## Runtime Architecture

- Framework: Express
- Database: MongoDB via Mongoose
- Auth: JWT, with optional Supabase token compatibility in middleware
- Uploads: Multer plus static file serving from the `uploads/` directory
- Configuration: Environment variables loaded through `dotenv`

## Project Structure

- `config/` database connection and app configuration helpers
- `middleware/` authentication and request handling middleware
- `models/` Mongoose models for the BizNest domain
- `routes/` route handlers grouped by feature area
- `scripts/` maintenance and backfill scripts
- `uploads/` persisted uploaded files served statically
- `server.js` application entry point

## API Surface

Base path: `/api`

Main route groups:

- `/api/auth` authentication
- `/api/business` business management
- `/api/products` product management
- `/api/customers` customer management
- `/api/orders` business order management
- `/api/expenses` expense tracking
- `/api/analytics` reporting and dashboards
- `/api/store` customer storefront APIs
- `/api/reviews` product reviews
- `/api/support` support tickets
- `/api/uploads` upload endpoints

Static assets:

- `/uploads/*` serves uploaded files directly

Health check:

- `GET /api/health` returns a simple `ok` response for uptime checks

## Environment Variables

Create a `.env` file in the `server/` directory with at least these values:

| Variable | Required | Purpose |
| --- | --- | --- |
| `MONGODB_URI` | Yes | MongoDB connection string |
| `JWT_SECRET` | Yes | Signing secret for application JWTs |
| `SUPABASE_JWT_SECRET` | No | Optional fallback secret used by auth middleware when Supabase tokens are present |
| `PORT` | No | Port for the HTTP server, defaults to `5000` |

Example:

```env
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/biznest
JWT_SECRET=change-me
SUPABASE_JWT_SECRET=change-me-too
```

## Getting Started

### 1. Install dependencies

```bash
npm install
```

### 2. Configure the environment

- Create `server/.env`
- Add the values listed above
- Make sure MongoDB is reachable before starting the server

### 3. Start the API

```bash
npm start
```

The server listens on `PORT` or `5000` if no port is provided.

## Available Scripts

| Script | Command | Purpose |
| --- | --- | --- |
| `start` | `node server.js` | Start the API in production mode |
| `dev` | `node server.js` | Start the API in the current environment |
| `backfill:order-images` | `node scripts/backfillOrderItemImages.js` | Backfill order item image data |

## Local Development Notes

- `npm run dev` currently behaves the same as `npm start`; there is no watcher configured.
- The API will exit early if `MONGODB_URI` is missing or invalid.
- Uploaded media is persisted under `uploads/` and exposed through the static `/uploads` route.
- The health endpoint is useful for deployment probes and quick smoke tests.

## Data Model Overview

The backend currently includes models for:

- Business
- Customer
- CustomerProfile
- Expense
- Order
- Product
- Review
- SupportTicket
- User

## Operational Guidance

### For Development

- Keep a local MongoDB instance running before starting the API.
- Use Postman, Insomnia, or similar tooling to validate route behavior.
- Prefer adding new business logic in routes or service helpers rather than scattering it across controllers.

### For Deployment

- Set `MONGODB_URI`, `JWT_SECRET`, and `PORT` in the target environment.
- Ensure the host allows persistent file storage if uploads need to survive restarts.
- Use the health endpoint for load balancer or platform-level checks.

## Validation Checklist

Before merging changes to the server, verify:

- The app starts cleanly with a valid `.env` file.
- `GET /api/health` returns success.
- Auth flows can connect to MongoDB and issue tokens.
- Customer portal routes return the expected payloads.
- Uploads still resolve under `/uploads`.

## Contributing

When extending the server:

- Keep routes small and feature-focused.
- Preserve existing response shapes where possible to avoid breaking the customer app.
- Update this README when adding new scripts, routes, or environment variables.
- Prefer explicit validation and consistent error messages over silent failure.

## License

This project is part of the BizNest codebase and is intended for internal and demonstration use.
