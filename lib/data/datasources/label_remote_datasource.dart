import 'work_item_remote_datasource.dart';
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
    return readAllCursorPages(
      (cursor) async => (await _dioClient.get<Map<String, dynamic>>(
        '/api/v1/workspaces/$workspaceSlug/projects/$projectId/labels/',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      ))
          .data,
      WorkItemLabelModel.fromJson,
      (item) => item.id,
    );
  }
}
