import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/work_item_model.dart';

class WorkItemRemoteDataSource {
  final DioClient _dioClient;

  WorkItemRemoteDataSource(this._dioClient);

  Future<List<WorkItemModel>> getWorkItems(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/',
    );
    final data = response.data;
    if (data == null) return [];
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
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
    );
    return WorkItemModel.fromJson(response.data!);
  }

  Future<WorkItemModel> createWorkItem(
    String workspaceSlug,
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/',
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
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
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
      '/api/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
    );
  }
}