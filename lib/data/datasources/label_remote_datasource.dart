import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/label_model.dart';

class LabelRemoteDataSource {
  final DioClient _dioClient;

  LabelRemoteDataSource(this._dioClient);

  Future<List<WorkItemLabelModel>> getLabels(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/labels/',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((json) =>
            WorkItemLabelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}