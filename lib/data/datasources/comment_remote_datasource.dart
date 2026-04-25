import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/comment_model.dart';

class CommentRemoteDataSource {
  final DioClient _dioClient;

  CommentRemoteDataSource(this._dioClient);

  Future<List<CommentModel>> getComments(
    String workspaceSlug,
    String projectId,
    String itemId,
  ) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/comments/',
    );
    final data = response.data;
    if (data == null) return [];
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
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/comments/',
      data: {'comment_html': commentHtml},
    );
    return CommentModel.fromJson(response.data!);
  }
}