import 'work_item_remote_datasource.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/state_model.dart';

class StateRemoteDataSource {
  final DioClient _dioClient;

  StateRemoteDataSource(this._dioClient);

  /// `/api/v1` の一覧は `results` 付きページング形で返る。
  Future<List<WorkItemStateModel>> getStates(
    String workspaceSlug,
    String projectId,
  ) async {
    return readAllCursorPages(
      (cursor) async => (await _dioClient.get<Map<String, dynamic>>(
        '/api/v1/workspaces/$workspaceSlug/projects/$projectId/states/',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      ))
          .data,
      WorkItemStateModel.fromJson,
      (item) => item.id,
    );
  }
}
