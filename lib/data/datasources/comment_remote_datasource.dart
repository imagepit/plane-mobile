import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'work_item_remote_datasource.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/comment_model.dart';

class CommentRemoteDataSource {
  final DioClient _dioClient;

  CommentRemoteDataSource(this._dioClient);

  /// `/api/v1` の一覧は `results` 付きページング形
  /// （`results` / `next_cursor` / `next_page_results` ほか）で返る。
  /// `?expand=actor` を付けると `actor` が ID の代わりにオブジェクトで返り、
  /// 投稿者名を表示できる（2026-09-27 実測）。
  Future<CursorPage<CommentModel>> getComments(
      String workspaceSlug, String projectId, String itemId,
      {String? cursor}) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/comments/?expand=actor',
      queryParameters: {if (cursor != null) 'cursor': cursor},
    );
    return decodeCursorPage(response.data, CommentModel.fromJson);
  }

  Future<CommentModel> addComment(
    String workspaceSlug,
    String projectId,
    String itemId,
    String commentHtml,
  ) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/comments/',
      data: {'comment_html': commentHtml},
    );
    return CommentModel.fromJson(response.data!);
  }
}
