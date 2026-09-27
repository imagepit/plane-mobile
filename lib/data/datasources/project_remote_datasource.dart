import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/project_model.dart';

class ProjectRemoteDataSource {
  final DioClient _dioClient;

  ProjectRemoteDataSource(this._dioClient);

  /// `/api/v1` の一覧は `results` 付きページング形（count / next_cursor /
  /// next_page_results ほか）で返る。
  Future<List<ProjectModel>> getProjects(String workspaceSlug) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/',
    );
    final body = response.data;
    final data = body == null
        ? const <dynamic>[]
        : (body['results'] as List<dynamic>? ?? const <dynamic>[]);
    return data
        .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectModel> getProject(String workspaceSlug, String projectId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/',
    );
    return ProjectModel.fromJson(response.data!);
  }
}
