import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/comment_model.dart';

class CommentRemoteDataSource {
  final DioClient _dioClient;

  CommentRemoteDataSource(this._dioClient);

  /// `/api/v1` の一覧は `results` 付きページング形
  /// （`results` / `next_cursor` / `next_page_results` ほか）で返る。
  Future<List<CommentModel>> getComments(
    String workspaceSlug,
    String projectId,
    String itemId,
  ) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/comments/',
    );
    final body = response.data;
    final data = body == null
        ? const <dynamic>[]
        : (body['results'] as List<dynamic>? ?? const <dynamic>[]);
    return data
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
