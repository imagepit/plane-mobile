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

1. **Server URL** — Your Plane self-hosted instance URL (e.g., `https://plane.example.com`)
2. **API Token** — Your personal API token from Plane

The app stores these credentials locally using Hive and sends them as `Authorization: Bearer {token}` on all API requests.

To change the configuration later, tap the settings icon on the workspace list page.

## Project Structure

- **Data Layer**: Remote data sources call Plane API via Dio; models map JSON to domain entities; repository implementations handle error mapping (DioExceptions → Failures via dartz Either).
- **Domain Layer**: Entities are plain Dart classes; repository interfaces define contracts; use cases encapsulate single-responsibility business logic.
- **Presentation Layer**: BLoCs manage state transitions; pages are minimal scaffolds providing BlocProviders; widgets are reusable UI components.

## API Endpoints Used

| Entity      | Method | Endpoint                                                          |
|-------------|--------|-------------------------------------------------------------------|
| Workspaces  | GET    | `/api/workspaces/`                                                |
| Projects    | GET    | `/api/workspaces/{slug}/projects/`                                |
| Work Items  | GET    | `/api/workspaces/{slug}/projects/{id}/work-items/`                |
| Work Items  | POST   | `/api/workspaces/{slug}/projects/{id}/work-items/`                |
| Work Items  | PATCH  | `/api/workspaces/{slug}/projects/{id}/work-items/{id}/`            |
| Work Items  | DELETE | `/api/workspaces/{slug}/projects/{id}/work-items/{id}/`            |
| States      | GET    | `/api/workspaces/{slug}/projects/{id}/states/`                    |
| Labels      | GET    | `/api/workspaces/{slug}/projects/{id}/labels/`                    |
| Members     | GET    | `/api/workspaces/{slug}/projects/{id}/members/`                   |
| Comments    | GET    | `/api/workspaces/{slug}/projects/{id}/work-items/{id}/comments/`   |
| Comments    | POST   | `/api/workspaces/{slug}/projects/{id}/work-items/{id}/comments/`   |
| User        | GET    | `/api/users/me/` (used for connection test)                      |

## Testing

```bash
flutter test
```

## License

MIT