# Plane Mobile

A Flutter mobile app for managing Plane self-hosted work items (issues/tickets) on the go.

## Features

- Connect to any Plane self-hosted instance via configurable URL + API token
- Browse workspaces and projects
- View, create, and edit work items (issues)
- Filter work items by state and priority
- Add and view comments on work items
- Dark/light theme support
- Pull-to-refresh on all list views

## Architecture

Clean architecture with BLoC state management:

```
lib/
  app.dart                  # MaterialApp.router with theme & BlocProviders
  main.dart                 # Entry point (Hive init + DI)
  core/
    constants/              # App constants
    di/                     # GetIt dependency injection
    errors/                 # Custom exceptions & failures
    network/                # Dio client & interceptor
    router/                 # GoRouter setup with auth guard
    storage/                # Hive local storage
    theme/                  # Material 3 theme (light/dark)
    utils/                  # Date formatter etc.
  data/
    datasources/            # Remote API data sources
    models/                 # Data models with fromJson/toJson
    repositories/           # Repository implementations
  domain/
    entities/              # Domain entities
    repositories/           # Repository interfaces
    usecases/               # Domain use cases
  presentation/
    blocs/                  # BLoC (event/state/bloc)
    pages/                  # Full-page screens
    widgets/                # Reusable UI components
```

## Tech Stack

| Layer     | Library            |
|-----------|--------------------|
| State     | flutter_bloc       |
| HTTP      | Dio                |
| Storage   | Hive + Hive Flutter |
| Routing   | go_router          |
| DI        | get_it             |
| FP        | dartz (Either)      |

## Prerequisites

- Flutter 3.x (Dart >= 3.0.0)
- Android SDK (API 21+) / Xcode (iOS 12+)
- A Plane self-hosted instance with API access

## Setup

```bash
# Clone the repository
git clone <repo-url> && cd plane-mobile

# Install dependencies
flutter pub get

# Generate code (if using freezed/json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running

```bash
# Run on connected device/emulator
flutter run

# Run with specific flavor (if configured)
flutter run --flavor dev
```

## Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

On first launch, the app displays a server configuration screen where you enter:

1. **Server URL** — Your Plane self-hosted instance URL (e.g., `https://plane.example.com`, or the private API route such as `http://<host>:8080`)
2. **Workspace Slug** — The workspace to open (Plane's API has no workspace-list route that accepts a personal access token, so the slug is entered explicitly)
3. **API Token** — Your personal API token from Plane

The app stores the URL and slug locally and the token in the platform secure store
(see "Credential storage"), and sends the token as `X-Api-Key: {token}` on all API
requests. The REST API lives under `/api/v1/` — the legacy `/api/` routes reject
API-token authentication.

To change the configuration later, tap the settings icon on the workspace list page.

## Smoke test

`integration_test/smoke_test.dart` drives the app against a real Plane CE
instance: settings entry → connection test → workspace/project/work-item
listing → work item creation → comment → deletion.

1. Copy `smoke.local.json` keys into a local `smoke.local.json` (gitignored) and
   fill in `SMOKE_API_TOKEN` with your personal access token. **Never commit or
   paste this file — it holds the token.** Keys: `SMOKE_BASE_URL`,
   `SMOKE_API_TOKEN`, `SMOKE_WORKSPACE_SLUG`, `SMOKE_PROJECT_ID`,
   `SMOKE_PROJECT_NAME`.
2. Use a dedicated test project (not a production one); test work items are
   created with a `smoke-` title prefix so leftovers can be spotted.
3. Run:

```bash
flutter test integration_test/smoke_test.dart \
  --dart-define-from-file=smoke.local.json -d <device-id>
```

Do not paste the full command line into logs together with a `--dart-define=`
token — keep the token in the gitignored file only. The log prints the created
work item id and HTTP statuses; it must not contain token values.

## Credential storage

The API token is stored only in the platform secure store (`flutter_secure_storage`:
iOS Keychain / Android Keystore) and is never written to Hive or other plain
storage.

- On first launch after upgrading from a version that stored the token in Hive,
  the legacy `api_token` entry is migrated to the secure store and removed from
  the Hive box automatically.
- Persistence goes through await-able paths only: `LocalStorage.saveConfig()` /
  `CredentialStore.saveToken()`. The synchronous `set apiToken` setter is kept for
  compatibility but updates the in-memory cache only and does not persist
  (the settings screen uses `saveConfig()` exclusively).
- `LocalStorage.clearConfig()` clears both the Hive settings and the secure store
  entry, so a reset leaves no token behind on the device.

## Project Structure

- **Data Layer**: Remote data sources call Plane API via Dio; models map JSON to domain entities; repository implementations handle error mapping (DioExceptions → Failures via dartz Either).
- **Domain Layer**: Entities are plain Dart classes; repository interfaces define contracts; use cases encapsulate single-responsibility business logic.
- **Presentation Layer**: BLoCs manage state transitions; pages are minimal scaffolds providing BlocProviders; widgets are reusable UI components.

## API Endpoints Used

All endpoints are under `{BASE_API}/api/v1/` and authenticate with `X-Api-Key`.
List responses are cursor-paginated objects (`results` / `next_cursor` /
`next_page_results`), except project members which return a bare array.

| Entity      | Method | Endpoint                                                          |
|-------------|--------|-------------------------------------------------------------------|
| Workspaces  | —      | (none: no list route accepts a token; the configured slug is used) |
| Projects    | GET    | `/api/v1/workspaces/{slug}/projects/`                              |
| Work Items  | GET    | `/api/v1/workspaces/{slug}/projects/{id}/work-items/?expand=state,assignees,labels` |
| Work Items  | POST   | `/api/v1/workspaces/{slug}/projects/{id}/work-items/`              |
| Work Items  | PATCH  | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/`         |
| Work Items  | DELETE | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/`         |
| States      | GET    | `/api/v1/workspaces/{slug}/projects/{id}/states/`                  |
| Labels      | GET    | `/api/v1/workspaces/{slug}/projects/{id}/labels/`                  |
| Members     | GET    | `/api/v1/workspaces/{slug}/projects/{id}/members/`                 |
| Comments    | GET    | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/comments/`|
| Comments    | POST   | `/api/v1/workspaces/{slug}/projects/{id}/work-items/{id}/comments/`|
| User        | GET    | `/api/v1/users/me/` (used for connection test)                    |

## Testing

```bash
flutter test
```

## License

MIT