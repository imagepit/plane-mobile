import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/core/errors/exceptions.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/data/datasources/work_item_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/comment_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/state_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/label_remote_datasource.dart';

class PageClient extends DioClient {
  final List<Object> replies;
  final calls = <(String, Map<String, dynamic>?)>[];
  PageClient(this.replies);
  @override
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    calls.add((path, queryParameters));
    final value = replies.removeAt(0);
    if (value is Exception) throw value;
    return Response<T>(
        data: value as T, requestOptions: RequestOptions(path: path));
  }
}

Map<String, dynamic> page(List<Map<String, dynamic>> items, {String? cursor}) =>
    {
      'results': items,
      'next_page_results': cursor != null,
      'next_cursor': cursor
    };
void main() {
  test('items/comments use opaque cursor query and keep expand', () async {
    final client = PageClient([
      page([
        {'id': '1', 'name': 'First'}
      ], cursor: 'https://other.example/page'),
      page([]),
      page([
        {'id': 'c', 'comment_html': '<p>Text</p>'}
      ])
    ]);
    final source = WorkItemRemoteDataSource(client);
    final first = await source.getWorkItems('w', 'p');
    expect(first.items.single.id, '1');
    expect(first.hasNext, true);
    final second =
        await source.getWorkItems('w', 'p', cursor: first.nextCursor);
    expect(second.hasNext, false);
    expect(second.items, isEmpty);
    expect(client.calls[1].$1, startsWith('/api/v1/'));
    expect(client.calls[1].$1, contains('expand=state,assignees,labels'));
    expect(client.calls[1].$2?['cursor'], 'https://other.example/page');
    final comments = await CommentRemoteDataSource(client)
        .getComments('w', 'p', '1', cursor: 'comment-cursor');
    expect(comments.items.single.id, 'c');
    expect(client.calls.last.$1, contains('expand=actor'));
    expect(client.calls.last.$2?['cursor'], 'comment-cursor');
  });
  test('state/label candidates fetch every page and deduplicate IDs', () async {
    for (final states in [true, false]) {
      final client = PageClient([
        page([
          {'id': '1', 'name': 'Old'}
        ], cursor: 'next'),
        page([
          {'id': '1', 'name': 'Updated'},
          {'id': '2', 'name': 'Second'}
        ])
      ]);
      final values = states
          ? await StateRemoteDataSource(client).getStates('w', 'p')
          : await LabelRemoteDataSource(client).getLabels('w', 'p');
      expect(values.length, 2);
      expect(client.calls.length, 2);
      expect(client.calls.last.$2?['cursor'], 'next');
    }
  });
  test('candidate partial failure and repeated cursor cannot look complete',
      () async {
    final broken = PageClient([
      page([
        {'id': '1'}
      ], cursor: 'next'),
      ServerException('Offline')
    ]);
    await expectLater(LabelRemoteDataSource(broken).getLabels('w', 'p'),
        throwsA(isA<ServerException>()));
    final repeat =
        PageClient([page([], cursor: 'same'), page([], cursor: 'same')]);
    await expectLater(StateRemoteDataSource(repeat).getStates('w', 'p'),
        throwsA(isA<ServerException>()));
    expect(repeat.calls.length, 2);
  });
  test('missing results or required next cursor is an error', () {
    expect(() => decodeCursorPage<String>({}, (x) => 'x'),
        throwsA(isA<ServerException>()));
    expect(
        () => decodeCursorPage<String>(
            {'results': [], 'next_page_results': true}, (x) => 'x'),
        throwsA(isA<ServerException>()));
  });
}
