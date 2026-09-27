import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/member_model.dart';

class MemberRemoteDataSource {
  final DioClient _dioClient;

  MemberRemoteDataSource(this._dioClient);

  /// members の一覧だけは `/api/v1` でも生配列で返る（2026-09-27 実測）。
  Future<List<WorkItemMemberModel>> getMembers(
    String workspaceSlug,
    String projectId,
  ) async {
    final response = await _dioClient.get<List<dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/members/',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
            (json) => WorkItemMemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
