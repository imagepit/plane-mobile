import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/data/models/workspace_model.dart';

/// Workspace の一覧取得は行わない。
///
/// 自社CEでは PAT（`X-API-Key`）で列挙できるワークスペース一覧ルートが存在しない
/// （`/api/workspaces/` は 401、`/api/v1/workspaces/` は 404。2026-09-27 実測）ため、
/// 設定済みの Workspace slug から1件を作って返す。
class WorkspaceRemoteDataSource {
  final LocalStorage _localStorage;

  WorkspaceRemoteDataSource(this._localStorage);

  Future<List<WorkspaceModel>> getWorkspaces() async {
    final slug = _localStorage.workspaceSlug;
    if (slug == null || slug.isEmpty) return [];
    return [WorkspaceModel(id: slug, name: slug, slug: slug)];
  }
}
