import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/domain/entities/work_item_page.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/models/work_item_model.dart';

class WorkItemRemoteDataSource {
  final DioClient _dioClient;

  WorkItemRemoteDataSource(this._dioClient);

  /// `?expand=state,assignees,labels` を付けると `state` が
  /// `color/group/id/name` のオブジェクトで返り、状態名を表示できる。
  static const String _expand = 'state,assignees,labels';

  /// `/api/v1` の一覧は `results` 付きページング形で返る。
  Future<CursorPage<WorkItemModel>> getWorkItems(
      String workspaceSlug, String projectId,
      {String? cursor}) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/'
      '?expand=$_expand',
      queryParameters: {if (cursor != null) 'cursor': cursor},
    );
    return decodeCursorPage(response.data, WorkItemModel.fromJson);
  }

  Future<WorkItemModel> getWorkItem(
    String workspaceSlug,
    String projectId,
    String itemId,
  ) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/'
      '?expand=$_expand',
    );
    return WorkItemModel.fromJson(response.data!);
  }

  Future<WorkItemModel> createWorkItem(
    String workspaceSlug,
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/',
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
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
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
      '/api/v1/workspaces/$workspaceSlug/projects/$projectId/work-items/$itemId/',
    );
  }
}

CursorPage<T> decodeCursorPage<T>(
    Map<String, dynamic>? body, T Function(Map<String, dynamic>) decode) {
  if (body == null || body['results'] is! List)
    throw ServerException('Invalid page response');
  final hasNext = body['next_page_results'] == true;
  final cursor = body['next_cursor']?.toString();
  if (hasNext && (cursor == null || cursor.isEmpty))
    throw ServerException('Missing next cursor');
  try {
    return CursorPage(
        items: (body['results'] as List)
            .map((x) => decode(Map<String, dynamic>.from(x as Map)))
            .toList(),
        nextCursor: hasNext ? cursor : null,
        hasNext: hasNext);
  } catch (_) {
    throw ServerException('Invalid page item');
  }
}

Future<List<T>> readAllCursorPages<T>(
    Future<Map<String, dynamic>?> Function(String?) fetch,
    T Function(Map<String, dynamic>) decode,
    String Function(T) id) async {
  final result = <String, T>{};
  final seen = <String>{};
  String? cursor;
  do {
    final page = decodeCursorPage(await fetch(cursor), decode);
    for (final item in page.items) {
      result[id(item)] = item;
    }
    if (!page.hasNext) return result.values.toList();
    cursor = page.nextCursor!;
    if (!seen.add(cursor)) throw ServerException('Repeated pagination cursor');
  } while (true);
}
