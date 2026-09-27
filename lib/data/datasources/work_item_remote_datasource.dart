import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/work_item_model.dart';

class WorkItemRemoteDataSource {
  final DioClient _dioClient;

  WorkItemRemoteDataSource(this._dioClient);

  /// `?expand=state,assignees,labels` を付けると `state` が
  /// `color/group/id/name` のオブジェクトで返り、状態名を表示できる。
  static const String _expand = 'state,assignees,labels';

  /// `/api/v1` の一覧は `results` 付きページング形で返る。
  Future<List<WorkItemModel>> getWorkItems(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/'
      '?expand=$_expand',
    );
    final body = response.data;
    final data = body == null
        ? const <dynamic>[]
        : (body['results'] as List<dynamic>? ?? const <dynamic>[]);
    return data
        .map((json) => WorkItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<WorkItemModel> getWorkItem(
    String workspaceSlug,
    String projectId,
    String itemId,
  ) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/'
      '?expand=$_expand',
    );
    return WorkItemModel.fromJson(response.data!);
  }

  Future<WorkItemModel> createWorkItem(
    String workspaceSlug,
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/',
      data: data,
    );
    return WorkItemModel.fromJson(response.data!);
  }

  Future<WorkItemModel> updateWorkItem(
    String workspaceSlug,
    String projectId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
      data: data,
    );
    return WorkItemModel.fromJson(response.data!);
  }

  Future<void> deleteWorkItem(
    String workspaceSlug,
    String projectId,
    String itemId,
  ) async {
    await _dioClient.delete(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
    );
  }
}
