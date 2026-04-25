import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/workspace_model.dart';

class WorkspaceRemoteDataSource {
  final DioClient _dioClient;

  WorkspaceRemoteDataSource(this._dioClient);

  Future<List<WorkspaceModel>> getWorkspaces() async {
    final response = await _dioClient.get<List<dynamic>>('/api/workspaces/');
    final data = response.data;
    if (data == null) return [];
    return data
        .map((json) => WorkspaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}