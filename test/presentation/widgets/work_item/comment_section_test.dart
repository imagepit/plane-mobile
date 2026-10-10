import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/presentation/widgets/work_item/comment_section.dart';

void main() {
  Future<void> mount(
          WidgetTester t, Future<CommentSendResult> Function(String) send,
          {String id = 'one', Map<String, String>? drafts}) =>
      t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CommentSection(
                  itemId: id,
                  comments: const [],
                  drafts: drafts,
                  onAddComment: send))));
  testWidgets(
      'matching revision is cleared only after success; double tap sends once',
      (t) async {
    final pending = Completer<CommentSendResult>();
    var calls = 0;
    await mount(t, (html) {
      calls++;
      return pending.future;
    });
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Draft');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pump();
    expect(find.text('Draft'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('send-comment')));
    expect(calls, 1);
    pending.complete(CommentSendResult.sent);
    await t.pumpAndSettle();
    expect(find.text('Draft'), findsNothing);
  });
  testWidgets(
      'edits during POST are fully retained; HTML special characters escaped',
      (t) async {
    final pending = Completer<CommentSendResult>();
    String? sent;
    await mount(t, (html) {
      sent = html;
      return pending.future;
    });
    await t.enterText(
        find.byKey(const ValueKey('comment-input')), '<tag>&\n日本語');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pump();
    expect(sent, '<p>&lt;tag&gt;&amp;<br>日本語</p>');
    await t.enterText(
        find.byKey(const ValueKey('comment-input')), 'Edited entire draft');
    pending.complete(CommentSendResult.sent);
    await t.pumpAndSettle();
    expect(find.text('Edited entire draft'), findsOneWidget);
  });
  testWidgets('failure retains all text and shows manual recovery', (t) async {
    await mount(t, (_) async => CommentSendResult.failed);
    await t.enterText(find.byKey(const ValueKey('comment-input')), '日本語の下書き');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pumpAndSettle();
    expect(find.text('日本語の下書き'), findsOneWidget);
    expect(find.textContaining('draft is kept'), findsOneWidget);
  });
  testWidgets('late success cannot clear a different item draft', (t) async {
    final pending = Completer<CommentSendResult>(),
        drafts = <String, String>{'two': 'Other draft'};
    Future<CommentSendResult> send(String s) => pending.future;
    await mount(t, send, drafts: drafts);
    await t.enterText(
        find.byKey(const ValueKey('comment-input')), 'First draft');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pump();
    await mount(t, send, id: 'two', drafts: drafts);
    pending.complete(CommentSendResult.sent);
    await t.pumpAndSettle();
    expect(find.text('Other draft'), findsOneWidget);
    expect(drafts['one'], 'First draft');
  });
  testWidgets(
      'unknown result prevents POST until history is explicitly checked',
      (t) async {
    var calls = 0;
    await mount(t, (_) async {
      calls++;
      return CommentSendResult.uncertain;
    });
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Unknown');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('send-comment')));
    expect(calls, 1);
    expect(find.text('Reload and check comments'), findsOneWidget);
  });
  testWidgets(
      'confirmed posted draft remains blocked across remount until edited',
      (t) async {
    final drafts = <String, String>{}, posted = <String, String>{};
    var calls = 0;
    Future<CommentSendResult> send(String s) async {
      calls++;
      return CommentSendResult.uncertain;
    }

    Future<void> page() => t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CommentSection(
                itemId: 'one',
                comments: const [],
                drafts: drafts,
                postedDrafts: posted,
                onAddComment: send,
                onCheckComments: () async => CommentCheckResult.posted))));
    await page();
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Posted');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pumpAndSettle();
    await t.tap(find.text('Reload and check comments'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('send-comment')));
    expect(calls, 1);
    await t.pumpWidget(const SizedBox());
    await page();
    await t.tap(find.byKey(const ValueKey('send-comment')));
    expect(calls, 1);
    await t.enterText(
        find.byKey(const ValueKey('comment-input')), 'New comment');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets('history confirmation belongs to sent snapshot, not edited draft',
      (t) async {
    final posted = <String, String>{}, pending = <String, String>{};
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CommentSection(
                itemId: 'one',
                comments: const [],
                postedDrafts: posted,
                pendingDrafts: pending,
                onAddComment: (_) async => CommentSendResult.uncertain,
                onCheckComments: () async => CommentCheckResult.posted))));
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Sent X');
    await t.tap(find.byKey(const ValueKey('send-comment')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Unsent Y');
    await t.tap(find.text('Reload and check comments'));
    await t.pumpAndSettle();
    expect(posted['one'], 'Sent X');
    expect(
        t
            .widget<IconButton>(find.byKey(const ValueKey('send-comment')))
            .onPressed,
        isNotNull);
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Sent X');
    await t.pump();
    expect(
        t
            .widget<IconButton>(find.byKey(const ValueKey('send-comment')))
            .onPressed,
        isNull);
  });
  testWidgets('delayed history confirmation persists after leaving the detail',
      (t) async {
    final pending = <String, String>{'one': 'Sent X'},
        posted = <String, String>{},
        drafts = <String, String>{'one': 'Edited Y'};
    final check = Completer<CommentCheckResult>();
    Future<void> page(bool uncertain) => t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CommentSection(
                itemId: 'one',
                comments: const [],
                uncertain: uncertain,
                drafts: drafts,
                pendingDrafts: pending,
                postedDrafts: posted,
                onAddComment: (_) async => CommentSendResult.sent,
                onCheckComments: () => check.future))));
    await page(true);
    await t.tap(find.text('Reload and check comments'));
    await t.pump();
    await t.pumpWidget(const SizedBox());
    check.complete(CommentCheckResult.posted);
    await t.pumpAndSettle();
    expect(posted['one'], 'Sent X');
    expect(pending, isEmpty);
    await page(false);
    expect(find.text('Edited Y'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('comment-input')), 'Sent X');
    await t.pump();
    expect(
        t
            .widget<IconButton>(find.byKey(const ValueKey('send-comment')))
            .onPressed,
        isNull);
  });
}
