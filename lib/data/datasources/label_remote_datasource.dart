import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/label_model.dart';

class LabelRemoteDataSource {
  final DioClient _dioClient;

  LabelRemoteDataSource(this._dioClient);

  /// `/api/v1` の一覧は `results` 付きページング形で返る。
  Future<List<WorkItemLabelModel>> getLabels(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/labels/',
    );
    final body = response.data;
    final data = body == null
        ? const <dynamic>[]
        : (body['results'] as List<dynamic>? ?? const <dynamic>[]);
    return data
        .map((json) =>
            WorkItemLabelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
