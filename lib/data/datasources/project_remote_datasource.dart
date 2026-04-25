import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/project_model.dart';

class ProjectRemoteDataSource {
  final DioClient _dioClient;

  ProjectRemoteDataSource(this._dioClient);

  Future<List<ProjectModel>> getProjects(String workspaceSlug) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectModel> getProject(String workspaceSlug, String projectId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/workspaces/$workspaceSlug/projects/$projectId/',
    );
    return ProjectModel.fromJson(response.data!);
  }
}