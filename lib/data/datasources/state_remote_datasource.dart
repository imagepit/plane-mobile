import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/state_model.dart';

class StateRemoteDataSource {
  final DioClient _dioClient;

  StateRemoteDataSource(this._dioClient);

  Future<List<WorkItemStateModel>> getStates(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/states/',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((json) =>
            WorkItemStateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}