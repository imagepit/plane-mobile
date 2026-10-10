import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/data/models/project_model.dart';

void main() {
  test('identifier survives API/entity/JSON/copyWith', () {
    final model = ProjectModel.fromJson(
        {'id': 'project', 'name': '共通基盤', 'identifier': 'CORE'});
    expect(model.toEntity().identifier, 'CORE');
    expect(model.toJson()['identifier'], 'CORE');
    expect(model.toEntity().copyWith(name: 'Changed').identifier, 'CORE');
  });
  test('missing identifier is not fabricated from project name', () {
    expect(
        ProjectModel.fromJson({'id': 'p', 'name': 'CORE'})
            .toEntity()
            .identifier,
        isNull);
  });
}
