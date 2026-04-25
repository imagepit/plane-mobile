# Plane Mobile App — Flutter Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Build a simple, elegant Flutter mobile app (Android + iOS) that lets users manage Plane self-hosted work items (issues/tickets) on the go, with configurable self-hosted URL.

**Architecture:** Flutter app using clean architecture (data/domain/presentation layers) with BLoC state management, Dio for HTTP, and Hive for local caching. The app connects to any Plane self-hosted instance via a configurable base URL and API token authentication.

**Tech Stack:**
- Flutter 3.x (Dart)
- flutter_bloc (state management)
- Dio (HTTP client)
- Hive (local storage/cache for settings)
- go_router (navigation)
- freezed/json_serializable (data models)
- Material 3 design system

---

## Plane API Reference (Self-Hosted Community Edition)

Base URL pattern: `{SELF_HOSTED_URL}/api/workspaces/{SLUG}/...`

Key endpoints (all require `Authorization: Bearer {API_TOKEN}`):

| Entity | Method | Endpoint |
|--------|--------|----------|
| **Workspaces** | GET | `/api/workspaces/` |
| **Projects** | GET | `/api/workspaces/{slug}/projects/` |
| **Work Items** | GET | `/api/workspaces/{slug}/projects/{project_id}/work-items/` |
| **Work Items** | POST | `/api/workspaces/{slug}/projects/{project_id}/work-items/` |
| **Work Items** | PATCH | `/api/workspaces/{slug}/projects/{project_id}/work-items/{id}/` |
| **Work Items** | DELETE | `/api/workspaces/{slug}/projects/{project_id}/work-items/{id}/` |
| **States** | GET | `/api/workspaces/{slug}/projects/{project_id}/states/` |
| **Labels** | GET | `/api/workspaces/{slug}/projects/{project_id}/labels/` |
| **Members** | GET | `/api/workspaces/{slug}/projects/{project_id}/members/` |
| **Cycles** | GET | `/api/workspaces/{slug}/projects/{project_id}/cycles/` |
| **Modules** | GET | `/api/workspaces/{slug}/projects/{project_id}/modules/` |
| **Comments** | GET | `/api/workspaces/{slug}/projects/{project_id}/work-items/{id}/comments/` |
| **Comments** | POST | `/api/workspaces/{slug}/projects/{project_id}/work-items/{id}/comments/` |
| **User** | GET | `/api/users/me/` |

---

## Phase 1: Project Setup & Core Infrastructure

### Task 1: Initialize Flutter project with folder structure

**Objective:** Create the Flutter project and set up clean architecture folder structure.

**Files:**
- Create: `lib/main.dart`
- Create: `lib/app.dart`
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/network/dio_client.dart`
- Create: `lib/core/network/api_interceptor.dart`
- Create: `lib/core/storage/local_storage.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/color_scheme.dart`
- Create: `lib/core/theme/typography.dart`

**Steps:**

1. Create Flutter project:
```bash
flutter create --org com.plane --project-name plane_mobile --platforms android,ios .
```

2. Set up clean architecture folder structure:
```
lib/
  app.dart                    # MaterialApp with router & theme
  main.dart                   # Entry point
  core/
    constants/
    network/
    storage/
    theme/
    utils/
    errors/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    blocs/
    pages/
    widgets/
```

3. Set up `pubspec.yaml` with all dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  dio: ^5.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  go_router: ^13.0.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  path_provider: ^2.1.1
  flutter_slidable: ^3.0.1
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  get_it: ^7.6.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  flutter_lints: ^3.0.1
```

4. Commit:
```bash
git init && git add -A && git commit -m "chore: initialize Flutter project with clean architecture structure"
```

---

### Task 2: Implement Dio HTTP client with configurable base URL

**Objective:** Create a Dio-based HTTP client that dynamically sets the base URL from user configuration, adds auth token headers, and handles errors.

**Files:**
- Create: `lib/core/network/dio_client.dart`
- Create: `lib/core/network/api_interceptor.dart`
- Create: `lib/core/errors/exceptions.dart`
- Create: `lib/core/errors/failures.dart`
- Test: `test/core/network/dio_client_test.dart`

Implementation includes:
- `DioClient` class wrapping Dio with dynamic `updateConfig(baseUrl, apiToken)`
- `ApiInterceptor` adding `Authorization: Bearer {token}` header
- Custom exceptions: `ServerException`, `UnauthorizedException`, `ConnectionException`
- GET, POST, PATCH, DELETE methods with error handling

---

### Task 3: Implement local storage for settings persistence

**Objective:** Create a Hive-based local storage module that persists the self-hosted URL and API token across app restarts.

**Files:**
- Create: `lib/core/storage/local_storage.dart`
- Test: `test/core/storage/local_storage_test.dart`

Stores: selfHostedUrl, apiToken, lastWorkspaceSlug, lastProjectId. Has `isConfigured` getter.

---

### Task 4: Implement Material 3 theme

**Objective:** Create a beautiful dark/light Material 3 theme inspired by Plane's design language (blue accent, clean surfaces).

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/color_scheme.dart`
- Create: `lib/core/theme/typography.dart`

Plane-inspired colors: Light primary `#3B76E1`, dark primary `#6B9EFF`, dark background `#0F0F1A`.

---

## Phase 2: Data Layer — Models & Repositories

### Task 5: Create data models with freezed

**Objective:** Create immutable data models for Workspace, Project, WorkItem, State, Label, and Member using freezed/json_serializable.

**Files:**
- Create: `lib/data/models/workspace_model.dart`
- Create: `lib/data/models/project_model.dart`
- Create: `lib/data/models/work_item_model.dart`
- Create: `lib/data/models/state_model.dart`
- Create: `lib/data/models/label_model.dart`
- Create: `lib/data/models/member_model.dart`
- Create: `lib/data/models/comment_model.dart`
- Create: `lib/domain/entities/` (corresponding domain entities)
- Run `build_runner` to generate freezed/json code

**Key Model — WorkItem:**
```dart
@freezed
class WorkItemModel with _$WorkItemModel {
  const factory WorkItemModel({
    required String id,
    required String name,
    @JsonKey(name: 'sequence_id') required int sequenceId,
    required String description,
    @JsonKey(name: 'description_html') String? descriptionHtml,
    @JsonKey(name: 'state_detail') StateModel? stateDetail,
    @JsonKey(name: 'label_ids') List<String>? labelIds,
    @JsonKey(name: 'labels') List<LabelModel>? labels,
    @JsonKey(name: 'assignees') List<MemberModel>? assignees,
    @JsonKey(name: 'assignees_ids') List<String>? assigneesIds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'target_date') String? targetDate,
    @JsonKey(name: 'priority') String? priority,
    @JsonKey(name: 'project') String? projectId,
    @JsonKey(name: 'workspace') String? workspaceSlug,
    @JsonKey(name: 'created_by') MemberModel? createdBy,
    String? estimatePoint,
    @JsonKey(name: 'attachment_count') int? attachmentCount,
    @JsonKey(name: 'link_count') int? linkCount,
    @JsonKey(name: 'is_favorite') bool? isFavorite,
  }) = _WorkItemModel;

  factory WorkItemModel.fromJson(Map<String, dynamic> json) =>
      _$WorkItemModelFromJson(json);
}
```

---

### Task 6: Create data sources (remote)

**Objective:** Create remote data sources that call the Plane API via DioClient.

**Files:**
- Create: `lib/data/datasources/work_item_remote_datasource.dart`
- Create: `lib/data/datasources/workspace_remote_datasource.dart`
- Create: `lib/data/datasources/project_remote_datasource.dart`
- Create: `lib/data/datasources/state_remote_datasource.dart`
- Create: `lib/data/datasources/label_remote_datasource.dart`
- Create: `lib/data/datasources/member_remote_datasource.dart`
- Create: `lib/data/datasources/comment_remote_datasource.dart`

Each data source uses DioClient and maps JSON responses to freezed models.

---

### Task 7: Create repository implementations

**Objective:** Create repository implementations that use data sources and map exceptions to failures.

**Files:**
- Create: `lib/data/repositories/work_item_repository_impl.dart`
- Create: `lib/data/repositories/workspace_repository_impl.dart`
- Create: `lib/data/repositories/project_repository_impl.dart`
- Create: `lib/domain/repositories/work_item_repository.dart`
- Create: `lib/domain/repositories/workspace_repository.dart`
- Create: `lib/domain/repositories/project_repository.dart`

---

## Phase 3: Domain Layer — Use Cases

### Task 8: Create use cases

**Objective:** Create domain use cases (one per feature action).

**Files:**
- Create: `lib/domain/usecases/get_work_items.dart`
- Create: `lib/domain/usecases/create_work_item.dart`
- Create: `lib/domain/usecases/update_work_item.dart`
- Create: `lib/domain/usecases/delete_work_item.dart`
- Create: `lib/domain/usecases/get_workspaces.dart`
- Create: `lib/domain/usecases/get_projects.dart`
- Create: `lib/domain/usecases/get_states.dart`
- Create: `lib/domain/usecases/get_labels.dart`
- Create: `lib/domain/usecases/get_members.dart`
- Create: `lib/domain/usecases/get_comments.dart`
- Create: `lib/domain/usecases/add_comment.dart`

Each use case follows the `Call<Future<Type>, Params>` pattern.

---

## Phase 4: Presentation Layer — BLoCs & Pages

### Task 9: Create Settings/Config BLoC

**Objective:** BLoC for managing the self-hosted URL configuration and API token.

**Files:**
- Create: `lib/presentation/blocs/settings/settings_bloc.dart`
- Create: `lib/presentation/blocs/settings/settings_event.dart`
- Create: `lib/presentation/blocs/settings/settings_state.dart`

**States:** SettingsInitial, SettingsConfigured, SettingsUnconfigured
**Events:** LoadSettings, SaveSettings(url, token), TestConnection, ResetSettings

---

### Task 10: Create WorkItem BLoC

**Objective:** BLoC for listing, creating, updating, and deleting work items.

**Files:**
- Create: `lib/presentation/blocs/work_item/work_item_bloc.dart`
- Create: `lib/presentation/blocs/work_item/work_item_event.dart`
- Create: `lib/presentation/blocs/work_item/work_item_state.dart`

**States:** WorkItemInitial, WorkItemLoading, WorkItemsLoaded, WorkItemDetail, WorkItemError
**Events:** LoadWorkItems, CreateWorkItem, UpdateWorkItem, DeleteWorkItem

---

### Task 11: Create Workspace/Project selection BLoCs

**Files:**
- Create: `lib/presentation/blocs/workspace/workspace_bloc.dart`
- Create: `lib/presentation/blocs/workspace/workspace_event.dart`
- Create: `lib/presentation/blocs/workspace/workspace_state.dart`
- Create: `lib/presentation/blocs/project/project_bloc.dart`
- Create: `lib/presentation/blocs/project/project_event.dart`
- Create: `lib/presentation/blocs/project/project_state.dart`

---

### Task 12: Build Settings/Server Config page

**Objective:** Beautiful onboarding screen to configure the self-hosted Plane URL and API token. This is the first screen unconfigured users see.

**Files:**
- Create: `lib/presentation/pages/settings/server_config_page.dart`
- Create: `lib/presentation/widgets/settings/server_config_form.dart`

**Features:** URL input, API token input (obscured), Test Connection button (pings `/api/users/me/`), Save & Connect button, error display, animated plane logo.

---

### Task 13: Build Workspace selection page

**Files:**
- Create: `lib/presentation/pages/workspace/workspace_list_page.dart`
- Create: `lib/presentation/widgets/workspace/workspace_card.dart`

**Features:** Settings gear icon, workspace cards (name, slug, member count), pull-to-refresh, tap → project list.

---

### Task 14: Build Project selection page

**Files:**
- Create: `lib/presentation/pages/project/project_list_page.dart`
- Create: `lib/presentation/widgets/project/project_card.dart`

**Features:** Workspace name in AppBar, project cards (name, description, state count, member avatars), pull-to-refresh, search bar.

---

### Task 15: Build Work Items list page (main screen)

**Files:**
- Create: `lib/presentation/pages/work_item/work_item_list_page.dart`
- Create: `lib/presentation/widgets/work_item/work_item_card.dart`
- Create: `lib/presentation/widgets/work_item/work_item_filter_bar.dart`
- Create: `lib/presentation/widgets/work_item/status_badge.dart`
- Create: `lib/presentation/widgets/work_item/priority_badge.dart`

**Features:** Project name AppBar, FAB for create, work item cards (sequence ID, title, state badge, priority icon, assignee avatars, label chips, dates), filter by state/priority/assignee, pull-to-refresh, swipe-to-delete, search, tab bar (All / My Issues).

---

### Task 16: Build Work Item detail page

**Files:**
- Create: `lib/presentation/pages/work_item/work_item_detail_page.dart`
- Create: `lib/presentation/widgets/work_item/work_item_header.dart`
- Create: `lib/presentation/widgets/work_item/work_item_properties.dart`
- Create: `lib/presentation/widgets/work_item/comment_section.dart`

**Features:** Editable title, state dropdown, priority dropdown, assignee/label selectors, date pickers, description, comments list + add comment, edit/save, delete option.

---

### Task 17: Build Create Work Item page

**Files:**
- Create: `lib/presentation/pages/work_item/create_work_item_page.dart`

**Features:** Name (required), description (optional, multiline), state/priority/assignee/label selectors, start/target date pickers, Create button, Cancel, loading indicator, form validation.

---

## Phase 5: Navigation & Dependency Injection

### Task 18: Set up go_router navigation

**Files:**
- Create: `lib/core/router/app_router.dart`

Routes:
- `/settings` → ServerConfigPage (with redirect guard for unconfigured users)
- `/workspaces` → WorkspaceListPage
- `/workspaces/:slug/projects` → ProjectListPage
- `/workspaces/:slug/projects/:projectId/items` → WorkItemListPage
- `/workspaces/:slug/projects/:projectId/items/new` → CreateWorkItemPage
- `/workspaces/:slug/projects/:projectId/items/:itemId` → WorkItemDetailPage

---

### Task 19: Set up dependency injection with GetIt

**Files:**
- Create: `lib/core/di/injection.dart`

Register all data sources, repositories, use cases, and BLoCs.

---

## Phase 6: Polish & App Entry

### Task 20: Build main.dart and app.dart with full wiring

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`

Wire Hive init, DI setup, theme, router, splash screen.

---

### Task 21: Add splash screen

**Files:**
- Create: `lib/presentation/pages/splash/splash_page.dart`

Splash with Plane logo → auto-check config → redirect.

---

### Task 22: Configure Android and iOS platform settings

**Files:**
- Modify: `android/app/build.gradle` (minSdk 21, targetSdk 34)
- Modify: `android/app/src/main/AndroidManifest.xml` (internet permission, cleartext traffic)
- Modify: `ios/Runner/Info.plist` (app name, NSAllowsArbitraryLoads)
- Create: `android/app/src/main/res/xml/network_security_config.xml`

Important: Self-hosted users may use HTTP, so allow cleartext traffic on both platforms.

---

## Phase 7: Testing & Final

### Task 23: Write unit and widget tests

**Files:**
- Create: `test/core/network/dio_client_test.dart`
- Create: `test/core/storage/local_storage_test.dart`
- Create: `test/data/datasources/work_item_remote_datasource_test.dart`
- Create: `test/presentation/blocs/work_item_bloc_test.dart`
- Create: `test/presentation/pages/server_config_page_test.dart`

---

### Task 24: Create README with build instructions

**Files:**
- Create: `README.md`
- Create: `CONTRIBUTING.md`

Contents: App description, prerequisites, setup, configuration, running, building, architecture overview, contributing guide.

---

## Risks, Tradeoffs, and Open Questions

1. **Plane API versioning:** Self-hosted Community Edition may have API differences vs. cloud. Use optional JSON fields.
2. **Auth token format:** Confirm `Bearer` vs `Token` prefix — Plan API tokens use `Bearer`.
3. **HTML descriptions:** Work item descriptions are often HTML. v1 renders plain text; v2 adds `flutter_html`.
4. **Offline support:** Not in v1. Consider Hive caching + sync for v2.
5. **Push notifications:** Not in v1. Would require WebSocket or polling in v2.
6. **Image attachments:** Not in v1 (binary upload). Viewing existing URLs can be added cheaply.

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-4 | Project setup, Dio client, local storage, theme |
| 2 | 5-7 | Data models, data sources, repositories |
| 3 | 8 | Domain use cases |
| 4 | 9-17 | BLoCs, all UI pages |
| 5 | 18-19 | Navigation + DI |
| 6 | 20-22 | App entry, splash, platform config |
| 7 | 23-24 | Testing, README |

Total: **24 tasks** across 7 phases.