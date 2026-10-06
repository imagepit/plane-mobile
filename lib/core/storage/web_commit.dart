// Hive 2.2.3 uses this IndexedDB SDK backend. Keep the check on the same
// primitive settings format and database; never read credentials here.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html';

import 'package:plane_mobile/core/constants/app_constants.dart';

/// Check persisted primitives after the preceding Hive write transaction.
/// Hive waits for request success, so a later readonly transaction must also
/// finish and see the intended values before the app reports a successful save.
Future<void> verifyWebCommit(Map<String, Object?> expected) async {
  final db = await window.indexedDB!.open(AppConstants.webHiveBoxName);
  try {
    final transaction = db.transaction('box', 'readonly');
    final store = transaction.objectStore('box');
    final reads = expected.keys.map(store.getObject).toList();
    final values =
        await Future.wait<dynamic>([...reads, transaction.completed]);
    var index = 0;
    for (final value in expected.values) {
      if (values[index++] != value) {
        throw StateError('Browser settings did not commit');
      }
    }
  } finally {
    db.close();
  }
}
