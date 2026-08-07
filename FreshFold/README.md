# FreshFold — Flutter app

Customer, rider and admin experience in one Flutter app, implementing the
screens exported from Claude Design (`../project/Laundry App Screens.dc.html`)
and talking to the existing Odoo `laundry_management` REST API
(`../project/uploads/laundry_management/`).

## First-time setup

This source tree was written without a local Flutter SDK available, so the
platform folders (`android/`, `ios/`, etc.) are **not included yet**. Generate
them once, from inside `app/`:

```bash
flutter create . --project-name freshfold_app --org com.yourcompany
```

This scaffolds `android/`, `ios/`, and friends around the existing
`lib/`/`pubspec.yaml` without touching your source files (answer "yes" if it
asks to overwrite — it only overwrites its own generated platform files).

Then:

```bash
flutter pub get
flutter analyze   # sanity check — this repo has not been run through the SDK
```

## Pointing the app at your Odoo backend

The API base URL is a compile-time define, defaulting to the Android
emulator's loopback alias (`http://10.0.2.2:8069`) so a local Odoo dev
server started with `./odoo-bin -c <config>` is reachable out of the box on
Android. Override it for iOS simulator, a real device, or a hosted server:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8069        # iOS simulator
flutter run --dart-define=API_BASE_URL=https://your-odoo-host.example.com
```

See `lib/core/config/app_config.dart`.

## Architecture

- **State management:** Riverpod (`flutter_riverpod`) — providers live next
  to the feature that owns them under `lib/features/<role>/{data,application}`.
- **Navigation:** `go_router`. Route paths are centralized in
  `lib/routing/app_routes.dart`; the route table itself is in
  `lib/routing/app_router.dart`. Each role (`customer`/`rider`/`admin`)
  mounts one shell widget with its own bottom nav; the shell manages tab
  switching internally rather than via nested router branches.
- **Networking:** `lib/core/network/api_client.dart` wraps Odoo's
  `type='jsonrpc'` controller routes (JSON-RPC 2.0 envelope in, `result`
  unwrapped out) and surfaces `{"status": false, "message": ...}` failures
  as `ApiException`.
- **Session:** the bearer token and role flags from `/api/v1/login` are
  cached in `flutter_secure_storage` (`lib/core/storage/auth_storage.dart`)
  so the app restores a session on cold start without a network call.

## Known gaps vs. the Odoo backend

The mobile API (`controllers/api_controller.py`) covers auth, profile,
service catalog, orders, and pickups end-to-end (Phases 1–2 of
`ROADMAP.md`). A few screens in the design go further than the current
backend:

- **Rider/assignee info** is not returned by `/api/v1/orders` or
  `/api/v1/pickup/list`, even though the Odoo models have a `rider_id`
  field — the admin Orders/Pickups screens show this as unavailable rather
  than inventing names.
- **B2B contract requests** (`laundry.contract.request`) have no REST
  endpoint at all yet (ROADMAP.md Phase 7, G3) — the customer "Business
  Enquiry" form and the admin "Business Requests" list both read/write an
  in-memory mock (`lib/features/shared/data/mock_contract_request_repository.dart`).
  Swap it for a real repository once that endpoint ships.
- **Service pricing is read-only** from the app — there's no
  create/update/delete endpoint for `service.type`, so the admin pricing
  screen's edit/add affordances are stubs.
- **Admin dashboard stats** (orders/revenue/open pickups today) are derived
  client-side from the orders/pickups lists rather than from a dedicated
  aggregation endpoint.

Search the codebase for `TODO` / "not wired up" comments for the exact
spots.
